//! AC: AC-DECISION-03-03

use std::process::Command;

#[test]
fn validates_db_ping_is_ok() {
    let output = Command::new("coherence-core-db")
        .args(["db-ping"])
        .output()
        .expect("coherence-core-db db-ping runs");

    assert!(
        output.status.success(),
        "db-ping command failed\nstdout:\n{}\nstderr:\n{}",
        String::from_utf8_lossy(&output.stdout),
        String::from_utf8_lossy(&output.stderr)
    );

    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(
        stdout.contains("db-ping: ok"),
        "expected 'db-ping: ok' in stdout, got:\n{}",
        stdout
    );
}
