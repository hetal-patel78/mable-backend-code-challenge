# Contract: `.github/workflows/ci.yml`

What the GitHub Actions workflow must hold, and must not ([FR-020](../spec.md#fr-020), [FR-021](../spec.md#fr-021); [DEC-36](../../../docs/design-analysis/design-decisions.md#dec-36); [page 10 pick 50](../../../docs/solution-design/10-traceability-glossary-assumptions.md#pick-50); [plan items 3](../plan.md#item-3), [4](../plan.md#item-4) and [6](../plan.md#item-6)).

## Must hold

| Key | Value | Why |
|---|---|---|
| `name` | `CI` | The name shown next to each commit |
| `on` | `push`, with no `branches` filter | Every push to any branch ([DEC-36](../../../docs/design-analysis/design-decisions.md#dec-36)) |
| `jobs` | exactly one job, `checks` | One job ([page 10 pick 50](../../../docs/solution-design/10-traceability-glossary-assumptions.md#pick-50)) |
| `jobs.checks.runs-on` | `ubuntu-latest` | The latest Ubuntu runner ([page 10 pick 50](../../../docs/solution-design/10-traceability-glossary-assumptions.md#pick-50)) |
| step 1 | `uses: actions/checkout@v5` | Gets the code |
| step 2 | `uses: ruby/setup-ruby@v1`, with no `with:` inputs | Ruby from [`.ruby-version`](../../../.ruby-version), which the action reads when no version is given |
| step 3 | `run: bundle install`, with `env: BUNDLE_FROZEN: "true"` | Installs the locked gems; fails instead of changing [`Gemfile.lock`](../../../Gemfile.lock) |
| step 4 | `run: bundle exec rspec` | The whole suite, in random order ([`spec_helper.rb`](../../../spec/spec_helper.rb)), with SimpleCov |
| step 5 | `run: bundle exec rubocop` | Zero offences ([NFR-05](../../../docs/solution-design/03-non-functional-requirements.md#nfr-05)) |

Each step has a short `name` (`Check out the code`, `Set up Ruby`, `Install the gems`, `Run RSpec`, `Run RuboCop`).

## Must not hold

- A `strategy` or `matrix` key (no OS or Ruby-version matrix; [page 10 pick 50](../../../docs/solution-design/10-traceability-glossary-assumptions.md#pick-50)).
- A `ruby-version` input or any Ruby version number (one source, [`.ruby-version`](../../../.ruby-version)).
- `bundler-cache` (deployment mode into `vendor/bundle`; [plan item 3](../plan.md#item-3)).
- `continue-on-error`, `|| true`, or any other way to ignore a failing step ([US4](../spec.md#us4) scenario 2).
- A coverage minimum, a coverage upload, a badge, or any step beyond the five above ([FR-021](../spec.md#fr-021)).
- A `pull_request`, `schedule` or `workflow_dispatch` trigger (only `push`, [spec item 9](../spec.md#item-9)).

## Outcomes

- A push starts one run for that commit. Every step exits with 0: the run's status is success ([US4](../spec.md#us4) scenario 1).
- A spec fails or RuboCop finds an offence: that step exits non-zero, later steps are skipped, and the run's status is failure ([US4](../spec.md#us4) scenario 2, checked by reading the file, [spec item 9](../spec.md#item-9)).
