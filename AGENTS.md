# Molaway agent guide

Molaway is a privacy-first break reminder for macOS, with a separate Windows preview. It is a personal, non-commercial open-source project by Burak Yelkenci, derived from Offscreen under the MIT license.

## Working with the product owner

- Use Turkish with Burak unless he asks for another language. Keep explanations concise, plain, and outcome-focused.
- End reports with a recommendation, the next step, and any action expected from Burak; explicitly say when none is needed. Explain clearly why any expected delivery or publication has not happened.
- Burak is not a software developer. Handle implementation, tests, Git, GitHub, documentation, packaging, and routine investigation end to end. Ask him only for decisions, account authentication, or physical checks that cannot be completed in the current environment.
- Public repository text and screenshots are English. The app UI supports English and Turkish and defaults to the system language.
- Never publish personal settings, statistics, logs, credentials, machine names, local paths, network details, signing material, or other private development data.

## Load context selectively

Read [docs/PROJECT_CONTEXT.md](docs/PROJECT_CONTEXT.md) when starting a new Molaway task or when product intent is unclear. Then open only the files relevant to the work:

- Product features and public claims: `README.md` and `CHANGELOG.md`
- Privacy, permissions, or security: `SECURITY.md`, `docs/PRIVACY.md`, and `VERIFICATION.md`
- Licensing or attribution: `LICENSE`, `UPSTREAM.md`, and `THIRD_PARTY_NOTICES.md`
- macOS install or release work: `docs/INSTALL.md`
- Windows work: `Windows/README.md`, `Windows/PLAN.md`, and `Windows/VERIFICATION.md`

Do not read every document for every task. Treat the current Git branch, working tree, tests, and GitHub state as fresher than status prose.

## Product boundaries

- Keep the app local-first, account-free, telemetry-free, and permission-minimal. Do not add network access, automatic update requests, private APIs, privileged helpers, or broad permissions without an explicit product decision and updated security documentation.
- Preserve the Offscreen copyright notice, MIT license, upstream attribution, and AI-assistance disclosure.
- Keep macOS and Windows implementations isolated. Do not describe Windows as stable until it passes the physical Windows checks in `Windows/PLAN.md`.
- Distinguish implemented, automated-tested, and physically verified behavior. Never turn a narrow script result into a broad security claim.
- Prefer the smallest maintainable change. Avoid dependencies unless their benefit clearly outweighs privacy, security, licensing, and maintenance costs.

## Delivery workflow

- Inspect `git status`, the current branch, and related open work before editing. Preserve unfinished work.
- Use a focused branch and pull request for repository changes. `main` is protected; required checks must pass before merge.
- Run tests that cover the change. Before a macOS release, run the repository security, publication, build, test, and installation checks documented in `CONTRIBUTING.md`. Windows work follows its own verification plan.
- Update public documentation only for behavior that is actually shipped or clearly labeled as preview.
- Keep `docs/PROJECT_CONTEXT.md` short and update it only when durable decisions, platform status, or the next major milestone changes.

- After each planned job is complete, remind Burak to start a new chat and provide the full next-job prompt plus recommended model and effort. Keep fixes and review of the same job in the current chat.
