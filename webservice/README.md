# App Suite Data Seeder — Web Service

A small web UI + service that fills an OX App Suite test account with demo data —
the same thing `Demo/demo.sh` does on the command line, but through a browser with
live progress.

It reuses the `AppsuiteCore` library from the `../appsuite` package (the CLI and this
service share the exact same importers and generators), so behavior stays identical to
the CLI.

## Features

- Enter an App Suite URL, username and password.
- Choose which categories to seed (all on by default): **Mails, Contacts, Appointments,
  Tasks, Files**.
- Bundled demo data is preselected; per category you can switch to **Upload my own**
  file(s) instead.
- Pick which of the bundled gold accounts supplies the mail tree.
- **Check Drive** button (and an automatic preflight): if the Drive capability is not
  enabled for the user, the file upload is skipped and the other categories still run.
- Live per-operation and per-file progress via Server-Sent Events.

## Run locally

Requires a Swift 6.2 toolchain.

```bash
cd webservice
APPSUITE_DEMO_DIR=../Demo swift run AppsuiteWeb
```

Then open <http://localhost:8080>.

Environment variables:

- `APPSUITE_DEMO_DIR` — path to the bundled `Demo/` data (default `../Demo`).
- `PORT` — port to bind (default `8080`).

## Run in a container

The image bundles the binary, the UI, and the subset of `Demo/` that is actually used
(gold accounts, test files, JSON templates, and the Male/Female avatar sets — the 97 MB
comic avatars and the `testmails` folder are excluded).

```bash
cd webservice
docker compose up --build
```

Open <http://localhost:8080>. The Docker build context is the repository root (set in
`compose.yaml`) because the web package depends on the sibling `../appsuite` package.

## HTTP API

- `GET  /` — the UI.
- `GET  /api/config` — `{ accounts: [..], demoAvailable: Bool }`.
- `POST /api/check-drive` — body is the credentials object; returns `{ enabled: Bool }`.
- `POST /api/run` — starts a seeding job; returns `{ jobId }`.
- `GET  /api/run/{jobId}/events` — Server-Sent Events stream of progress for the job.

## Security note

This service accepts arbitrary App Suite credentials and pushes data to whatever server
is entered. Credentials are used only for the duration of a request and are never stored.
Still, on a real server put it behind authentication and/or network controls — do not
expose it openly on the internet.
