# Windows preview verification

## macOS development checks — 2026-09-27

- .NET SDK 10.0.401 downloaded from Microsoft and checked against its SHA-512 release metadata.
- Core harness passed 41 assertions, including repeated/global snooze, active/idle/media transitions, natural/manual rests, lock/wake, quiet-mode grace, invalid inputs, atomic local files and an eight-hour simulated schedule.
- WPF cross-build succeeded with zero warnings and errors. A self-contained Windows x64 folder was generated; its executable is PE32+ x86-64.
- Targeted source/publication guards passed. They are not a security audit or network isolation proof.

## Windows gate

The Windows CI workflow runs the same core checks, publishes a self-contained preview and launches a synthetic WPF smoke test. It retains only synthetic app renders for seven days; no Windows binary is published. Interactive Windows validation remains required even if CI passes. See PLAN.md.

No personal settings, machine inventory, local paths or raw development logs belong in this report or the uploaded artifact.
