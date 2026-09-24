# Assignment 2 — Dockerized Diagnostic CLI

The Assignment 1 Bash diagnostic tool, repackaged as a small, self-contained
Docker CLI (`diagnostic`) that can be built and run locally with Docker or
Docker Compose.

## Structure

```
assignment-2/
├── README.md
├── app/
│   ├── diagnostic.sh     # CLI entrypoint (system / network / disk / help)
│   └── health-check.sh   # Docker HEALTHCHECK probe
├── Dockerfile
├── compose.yaml
├── .dockerignore
├── test.sh                # Image test suite
└── grade.sh                # Instructor-supplied local grader
```

## Requirements

- Docker Engine (with Docker Compose v2, `docker compose ...`).
- No other local dependencies — everything runs inside the container.

## Installation / Setup

```bash
git clone <your-repository-url>
cd assignment-2
chmod +x grade.sh test.sh app/*.sh
```

## Building the image

```bash
docker build -t diagnostic-tool .
```

## CLI Commands

```bash
docker run --rm diagnostic-tool system            # Linux system info
docker run --rm diagnostic-tool network <host>    # Connectivity check
docker run --rm diagnostic-tool disk               # Disk usage info
docker run --rm diagnostic-tool help                # Usage
```

### Exit codes

| Code | Meaning                        |
|------|----------------------------------|
| 0    | Success                          |
| 1    | Operational/runtime failure      |
| 2    | Invalid command or missing input |

Invalid commands (e.g. `docker run --rm diagnostic-tool bogus`) and missing
required arguments (e.g. `network` with no host) are rejected with exit
code 2 and a usage message — the container never crashes uncleanly.

## Docker Compose

```bash
docker compose run --rm diagnostic system
docker compose run --rm diagnostic help
```

`compose.yaml` builds the image from the local `Dockerfile` and defaults to
running `help` when no command override is given.

## Dockerfile notes

- Base image: `alpine:3.19` (lightweight).
- Installs only the packages the scripts need: `bash`, `coreutils`,
  `procps`, `iproute2`, `iputils`, `bind-tools`.
- Copies `app/` into `/app` and sets executable permissions explicitly.
- Defines both `HEALTHCHECK` (calls `health-check.sh`) and
  `ENTRYPOINT`/`CMD` (`ENTRYPOINT ["/app/diagnostic.sh"]`,
  `CMD ["help"]`) so `docker run --rm diagnostic-tool` with no arguments
  still does something useful.

## .dockerignore

Excludes `.git`, `logs/`, `*.log`, and other local/non-runtime files so
the build context stays small and clean.

## Testing

```bash
chmod +x grade.sh test.sh app/*.sh
./grade.sh
```

`grade.sh` checks project structure, Bash syntax, executable permissions,
the Dockerfile, `.dockerignore`, that the image builds, basic container
commands (`help`/`system`/`disk`), invalid-command handling, the Compose
configuration, and runs the student `test.sh` suite.

`test.sh` independently builds the image and exercises `help`, `system`,
`disk`, an invalid command, and the `network` command (missing host and
with `localhost`), asserting the expected exit code for each.

## Assumptions

- The container is expected to be run with `--rm` for one-shot diagnostic
  commands, as shown throughout this README and in `grade.sh`.
- `network <host>` requires an explicit host argument; omitting it returns
  exit code 2 per the CLI's invalid-input contract.
- No secrets, tokens, or machine-specific hardcoded values are baked into
  the image.

## Git Workflow

History includes multiple meaningful commits, a non-main feature branch
per major piece of work (CLI, Docker packaging, tests), merged into
`main`. See `git log --graph --oneline --all`.
