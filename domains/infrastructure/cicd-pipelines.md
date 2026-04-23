# Domain: CI/CD Pipelines
**Loaded when:** Agent is configuring build pipelines, deployment workflows, or release automation.
**Key concern:** Environment parity. If CI tests pass against a different setup than production runs, the pipeline is theater.

---

## Pipeline Stages

Fail fast: cheap checks first. Each stage gates the next.

```
lint -> test -> build -> publish -> deploy-staging -> integration-test -> deploy-production
```

| Stage | Fail means |
|---|---|
| **Lint** | Code doesn't meet standards |
| **Test** | Behavior is broken |
| **Build** | Artifact can't be produced |
| **Deploy staging** | Infra or config issue |
| **Integration test** | Feature broken in real environment |

## Environment Promotion

Same artifact deploys to every environment. Never rebuild for production. Differences are strictly config: env vars, secrets, feature flags. No code branches per environment.

```
dev (every push) -> staging (merge to main) -> production (manual approval or tag)
```

## Deployment Strategies

| Strategy | Rollback speed | Risk |
|---|---|---|
| **Rolling** | Minutes | Mixed versions during rollout |
| **Blue-green** | Seconds (switch back) | 2x resource cost |
| **Canary** | Seconds (route back) | Requires traffic splitting |

Default to rolling. Blue-green for zero-downtime critical. Canary to validate with real traffic.

## Rollback

Every deployment needs a rollback plan executable in under 5 minutes. Keep last 3 artifacts.

## Caching

Cache dependencies by lockfile hash:
```yaml
- uses: actions/cache@v4
  with:
    path: ~/.npm
    key: npm-${{ hashFiles('**/package-lock.json') }}
```

## Artifact Management

Build once, deploy everywhere. Tag with commit SHA for traceability, semver for releases. Never overwrite a published tag.

## Secrets

Use the CI platform's secret store. Inject as env vars at runtime. Mask in logs. Rotate on schedule. Never hardcode in pipeline YAML or commit `.env` files.

## Flaky Tests

Quarantine flaky tests into a separate allowed-to-fail suite. Fix them. A growing quarantine list is a red flag.

```yaml
test:
  script: pytest --ignore=tests/quarantine/
quarantine-tests:
  allow_failure: true
  script: pytest tests/quarantine/
```

## Common Pitfalls

| Pitfall | Why it breaks | Fix |
|---|---|---|
| Rebuilding per environment | Staging tested different code than prod | Build once, promote same artifact |
| No rollback plan | Forward-fix under pressure | Document and test rollback |
| Different DB version in CI vs prod | Tests pass, prod breaks | Pin service versions to match production |
| Secrets in config files | Exposed in repo history | Use CI secret store |
| Retry-until-pass for flaky tests | Hides real failures | Quarantine and fix |
| No caching | 20-min feedback loops | Cache by lockfile hash |
| Manual deploy steps | Human error | Automate everything, approval gates for decisions |
