//! AC: AC-DECISION-03-02

use std::process::Command;

#[test]
fn validates_catalog_preflight_is_ok() {
    let output = Command::new("coherence-core-db")
        .args(["project", "catalog-preflight"])
        .output()
        .expect("coherence-core-db project catalog-preflight runs");

    assert!(
        output.status.success(),
        "catalog-preflight command failed\nstdout:\n{}\nstderr:\n{}",
        String::from_utf8_lossy(&output.stdout),
        String::from_utf8_lossy(&output.stderr)
    );
    assert!(
        String::from_utf8_lossy(&output.stdout).contains("catalog-preflight: ok"),
        "expected catalog-preflight: ok in stdout, got:\n{}",
        String::from_utf8_lossy(&output.stdout)
    );
}
