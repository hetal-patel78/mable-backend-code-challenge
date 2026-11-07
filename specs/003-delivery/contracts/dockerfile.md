# Contract: `Dockerfile` and the Docker commands

What the Dockerfile must hold, and the commands the README gives (FR-022 to FR-024, FR-005; [DEC-01](../../../docs/design-analysis/design-decisions.md#dec-01), [DEC-36](../../../docs/design-analysis/design-decisions.md#dec-36), [DEC-37](../../../docs/design-analysis/design-decisions.md#dec-37); spec Clarifications; plan items 1, 5 to 8).

## The Dockerfile: exactly six instructions, in this order

| # | Instruction | Rule |
|---|---|---|
| 1 | `FROM ruby:<version>` | `<version>` is exactly the text of `.ruby-version` (plan item 1). The full official image, not `-slim` or `-alpine`. If C-18 finds no time-zone data, `ruby:<version>-bookworm` instead (plan item 7). |
| 2 | `WORKDIR /app` | The project root in the container (FR-023) |
| 3 | `COPY . .` | Copies the project in (DEC-36) |
| 4 | `ENV BUNDLE_FROZEN=true` | The install fails instead of changing `Gemfile.lock` (plan item 6) |
| 5 | `RUN bundle install` | Installs the locked gems, development gems included, so the tests run in the image |
| 6 | `CMD ["bin/run"]` | Exec form: `bin/run` with no arguments, directly, not through `bundle exec`; a command after the image name replaces it (spec Clarifications) |

Nothing else: no `apt-get`, no `USER`, no `ENTRYPOINT`, no `EXPOSE`, no other gem, no comment that explains the design, and no `.dockerignore` file in the repository (FR-024).

## Commands the README gives

The image name is `mable-transfers` (spec item 5). The examples use `TZ=Australia/Sydney`; the README says to use your own time zone.

| Purpose | Command |
|---|---|
| Build | `docker build -t mable-transfers .` |
| Run the sample files, POSIX shell | `docker run --rm -e TZ=Australia/Sydney -v "$(pwd)/output:/app/output" mable-transfers` |
| Run the sample files, PowerShell | `docker run --rm -e TZ=Australia/Sydney -v "${PWD}/output:/app/output" mable-transfers` |
| Run the tests | `docker run --rm mable-transfers bundle exec rspec` |

None of them adds `--user` (spec Clarifications) or `-it`.

## Outcomes (from the spec)

| Command | Standard output | Standard error | Exit status | Scenario |
|---|---|---|---|---|
| Build | (nothing; BuildKit writes no standard output) | build log | 0 | US3-1 |
| Run, `TZ` and mount | the sample report, `<run time>` in that time zone | (nothing) | 0 | US3-2 |
| Run with `-e LOG_LEVEL=info` added | the sample report | the six AC-09.5 info lines | 0 | US3-4 |
| Run with the command `bin/run -h` | (nothing) | the two AC-09.2 usage lines | 1 | US3-4 |
| Tests | RSpec in documentation format, 0 failures, SimpleCov's line | (nothing required) | 0 | US3-3 |
| Run with no `TZ` | the sample report, `<run time>` in UTC | (nothing) | 0 | edge case |
| Run with no mount | the sample report | (nothing) | 0; no file on the host | edge case |
| Run with a typed output path that exists in the mounted folder | (nothing) | `Error: output file already exists: output/<name>. Delete it or give another output path.` then `E, [<timestamp> #<pid>] ERROR -- : Run stopped: start checks failed (output file already exists)` | 1; the file unchanged | edge case |
