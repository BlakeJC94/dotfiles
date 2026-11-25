//! A program that exceeds its deadline is stopped with its child processes;
//! a call that finishes in time preserves its input, output, and exit code.

use std::path::{Path, PathBuf};
use std::process::Command;
use std::time::{Duration, Instant};

use herdr_gitview::deadline::output_within;

fn scratch(name: &str) -> PathBuf {
    let dir = std::env::temp_dir().join(format!("gitview-deadline-{name}-{}", std::process::id()));
    let _ = std::fs::remove_dir_all(&dir);
    std::fs::create_dir_all(&dir).unwrap();
    dir
}

/// Whether the pid in `file` is a live process.
fn alive(file: &Path) -> bool {
    let pid = std::fs::read_to_string(file).unwrap();
    Command::new("kill")
        .args(["-0", pid.trim()])
        .status()
        .unwrap()
        .success()
}

/// Wait up to 2 s for `file` to have a pid in it.
fn pid_in(file: &Path) {
    let until = Instant::now() + Duration::from_secs(2);
    while std::fs::read_to_string(file).map_or(true, |s| s.trim().is_empty()) {
        assert!(
            Instant::now() < until,
            "no pid written to {}",
            file.display()
        );
        std::thread::sleep(Duration::from_millis(20));
    }
}

#[test]
fn a_program_past_its_deadline_is_stopped_with_what_it_started() {
    let dir = scratch("unit");
    let pid = dir.join("child.pid");
    let t = Instant::now();
    let err = output_within(
        Command::new("sh").args([
            "-c",
            &format!("sleep 30 & echo $! > '{}'; wait", pid.display()),
        ]),
        None,
        Duration::from_millis(500),
    )
    .unwrap_err();
    assert!(t.elapsed() < Duration::from_secs(3), "{:?}", t.elapsed());
    assert!(format!("{err:#}").contains("sh took more than"), "{err:#}");
    pid_in(&pid);
    assert!(!alive(&pid), "what it started is still running");

    // In time: input in, output and exit code out.
    let out = output_within(
        Command::new("sh").args(["-c", "tr a-z A-Z; echo err >&2; exit 3"]),
        Some(b"hello\n"),
        Duration::from_secs(10),
    )
    .unwrap();
    assert_eq!(out.stdout, b"HELLO\n");
    assert_eq!(out.stderr, b"err\n");
    assert_eq!(out.status.code(), Some(3));
    let _ = std::fs::remove_dir_all(&dir);
}
