# Project cleanup

A direnv project can run a command after you stop working in it, for example
to stop its containers or delete build output. Add one line to its `.envrc`:

```bash
use flake
cleanup_on_idle 1h 'project-cleanup docker-stop; cargo clean'
```

Then run `direnv allow`. The delay accepts `s`, `m`, `h` and `d`, also
combined (`1h30m`).

A project is in use while any of your processes has its working directory
inside it: shells, editors started there, agents, builds. A systemd user timer
(`modules/services/project-cleanup.nix`) checks `/proc` every 5 minutes. The
command runs once the project has been idle for the delay, then not again
until the project is in use again. Each run sends a notification.

The command runs through `direnv exec`, so it has the devShell's tools and
only runs while the `.envrc` is allowed. A failed run or a run longer than 15
minutes is reported and not retried until the project is in use again.
Removing `cleanup_on_idle` from the `.envrc` unregisters the project at its
next cleanup.

## Commands

| Command | Action |
| --- | --- |
| `project-cleanup status [--json]` | projects, their last activity and cleanup state; `--json` feeds the notification center |
| `project-cleanup now [DIR]` | run the cleanup now |
| `project-cleanup forget [DIR]` | unregister a project |
| `project-cleanup docker-stop` | stop the Compose containers whose project directory is inside the current one |

`docker-stop` keeps the containers and their volumes; use `docker compose
down` in the command to remove them. It does nothing while Docker isn't
running, so it never starts the daemon.

Logs: `journalctl --user -u project-cleanup`. State:
`~/.local/state/project-cleanup/`.

## Limits

- A program counts only if its working directory is inside the project. An
  editor started from `~` that opens project files does not.
- A shell left open in the project keeps it in use.
- Containers started with plain `docker run` have no Compose label, so
  `docker-stop` doesn't find them.
