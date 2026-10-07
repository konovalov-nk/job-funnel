.PHONY: bootstrap dry-run sync sync-minimal sync-all install-timer status logs query query-example evidence evidence-refresh evidence-logs evidence-down

bootstrap:
	python3 -m venv .venv
	.venv/bin/python -m pip install -r requirements.txt

dry-run:
	./bin/openjobdata-sync --dry-run

sync:
	./bin/openjobdata-sync --variant full

sync-minimal:
	./bin/openjobdata-sync --variant minimal

sync-all:
	./bin/openjobdata-sync --variant all

install-timer:
	./bin/install-user-timer

status:
	systemctl --user status openjobdata-sync.timer openjobdata-sync.service --no-pager

logs:
	journalctl --user -u openjobdata-sync.service -n 100 --no-pager

query:
	docker compose run --rm duckdb

query-example:
	docker compose run --rm duckdb -init /sql/init.sql /workspace/openjobdata.duckdb -c "SELECT status, count(*) AS jobs FROM jobs GROUP BY status ORDER BY status;"

evidence:
	docker compose up --build -d evidence

evidence-refresh:
	docker compose restart evidence

evidence-logs:
	docker compose logs -f evidence

evidence-down:
	docker compose stop evidence
