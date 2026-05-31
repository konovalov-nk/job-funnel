//! AC: AC-DECISION-03-01

use std::process::Command;

#[test]
fn validates_coherence_core_db_version() {
    let output = Command::new("coherence-core-db")
        .args(["--version"])
        .output()
        .expect("coherence-core-db --version runs");

    assert!(
        output.status.success(),
        "coherence-core-db --version failed\nstdout:\n{}\nstderr:\n{}",
        String::from_utf8_lossy(&output.stdout),
        String::from_utf8_lossy(&output.stderr)
    );

    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(
        stdout.contains("coherence-core-db 0.2.0"),
        "expected 'coherence-core-db 0.2.0' in stdout, got:\n{}",
        stdout
    );
}
