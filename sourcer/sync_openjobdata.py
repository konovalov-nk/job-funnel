#!/usr/bin/env python3
from __future__ import annotations

import argparse
import fcntl
import json
import os
import shutil
import sys
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterator

from huggingface_hub import list_bucket_tree, sync_bucket


BUCKET_ID = "Invicto69/Jobs-Dataset-bucket"
BUCKET_URI = f"hf://buckets/{BUCKET_ID}"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Mirror OpenJobData Parquet files and record source manifests."
    )
    parser.add_argument(
        "--variant",
        choices=("full", "minimal", "all"),
        default=os.getenv("OPENJOBDATA_VARIANT", "full"),
        help="full includes raw JSON fields; minimal is the compact projection",
    )
    parser.add_argument(
        "--data-dir",
        type=Path,
        default=Path(os.getenv("OPENJOBDATA_DATA_DIR", "data/openjobdata")),
    )
    parser.add_argument(
        "--state-dir",
        type=Path,
        default=Path(os.getenv("OPENJOBDATA_STATE_DIR", "state/openjobdata")),
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="show the official sync plan without downloading files",
    )
    return parser.parse_args()


def selected(item: Any, variant: str) -> bool:
    if item.type != "file":
        return False
    if variant == "all":
        return True
    return (
        item.path.startswith(f"data/{variant}/")
        or item.path.startswith("data/companies/")
        or item.path in {"README.md", ".gitattributes"}
    )


def manifest(variant: str) -> dict[str, Any]:
    files = []
    for item in list_bucket_tree(BUCKET_ID, recursive=True):
        if selected(item, variant):
            files.append(
                {
                    "path": item.path,
                    "size": item.size,
                    "xet_hash": item.xet_hash,
                    "mtime": item.mtime.isoformat() if item.mtime else None,
                    "uploaded_at": (
                        item.uploaded_at.isoformat() if item.uploaded_at else None
                    ),
                }
            )
    files.sort(key=lambda value: value["path"])
    return {
        "bucket": BUCKET_ID,
        "variant": variant,
        "captured_at": datetime.now(timezone.utc).isoformat(),
        "file_count": len(files),
        "total_size": sum(item["size"] for item in files),
        "files": files,
    }


def comparable(value: dict[str, Any]) -> list[tuple[str, int, str]]:
    return [
        (item["path"], item["size"], item["xet_hash"]) for item in value["files"]
    ]


def load_json(path: Path) -> dict[str, Any] | None:
    if not path.exists():
        return None
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def write_json_atomic(path: Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    with temporary.open("w", encoding="utf-8") as handle:
        json.dump(value, handle, ensure_ascii=True, indent=2)
        handle.write("\n")
    temporary.replace(path)


@contextmanager
def exclusive_lock(path: Path) -> Iterator[None]:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        try:
            fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise RuntimeError("another OpenJobData sync is already running") from None
        handle.write(str(os.getpid()))
        handle.flush()
        yield


def archive_changed_deltas(
    previous: dict[str, Any] | None,
    current: dict[str, Any],
    data_dir: Path,
    state_dir: Path,
) -> None:
    if previous is None:
        return
    previous_by_path = {item["path"]: item for item in previous["files"]}
    for item in current["files"]:
        old = previous_by_path.get(item["path"])
        if (
            old is None
            or old["xet_hash"] == item["xet_hash"]
            or "/changes/" not in item["path"]
        ):
            continue
        source = data_dir / item["path"]
        if source.exists():
            destination = state_dir / "archive" / old["xet_hash"] / item["path"]
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, destination)


def validate_downloads(source_manifest: dict[str, Any], data_dir: Path) -> None:
    failures = []
    for item in source_manifest["files"]:
        path = data_dir / item["path"]
        if not path.is_file():
            failures.append(f"missing: {item['path']}")
        elif path.stat().st_size != item["size"]:
            failures.append(
                f"wrong size: {item['path']} "
                f"({path.stat().st_size} != {item['size']})"
            )
        elif path.suffix == ".parquet":
            with path.open("rb") as handle:
                header = handle.read(4)
                handle.seek(-4, os.SEEK_END)
                footer = handle.read(4)
            if header != b"PAR1" or footer != b"PAR1":
                failures.append(f"invalid Parquet envelope: {item['path']}")
    if failures:
        details = "\n".join(failures[:20])
        raise RuntimeError(f"local mirror validation failed:\n{details}")


def sync(args: argparse.Namespace) -> None:
    data_dir = args.data_dir.resolve()
    state_dir = args.state_dir.resolve()
    latest_path = state_dir / f"latest-{args.variant}.json"

    with exclusive_lock(state_dir / "sync.lock"):
        before = manifest(args.variant)
        gib = before["total_size"] / 1024**3
        print(
            f"Source: {before['file_count']} files, {gib:.2f} GiB "
            f"(variant={args.variant})"
        )

        if args.dry_run:
            data_dir.mkdir(parents=True, exist_ok=True)
            plan = sync_bucket(
                BUCKET_URI,
                str(data_dir),
                include=include_patterns(args.variant),
                dry_run=True,
            )
            print(json.dumps(plan.summary(), sort_keys=True))
            return

        archive_changed_deltas(load_json(latest_path), before, data_dir, state_dir)
        data_dir.mkdir(parents=True, exist_ok=True)
        sync_bucket(
            BUCKET_URI,
            str(data_dir),
            include=include_patterns(args.variant),
        )

        after = manifest(args.variant)
        if comparable(before) != comparable(after):
            raise RuntimeError(
                "source changed during download; rerun sync to avoid a mixed snapshot"
            )
        validate_downloads(after, data_dir)

        timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
        write_json_atomic(state_dir / "manifests" / f"{timestamp}-{args.variant}.json", after)
        write_json_atomic(latest_path, after)
        print(f"Mirror is current: {data_dir}")


def include_patterns(variant: str) -> list[str] | None:
    if variant == "all":
        return None
    return [
        f"data/{variant}/**",
        "data/companies/**",
        "README.md",
        ".gitattributes",
    ]


def main() -> int:
    try:
        sync(parse_args())
    except (OSError, RuntimeError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
