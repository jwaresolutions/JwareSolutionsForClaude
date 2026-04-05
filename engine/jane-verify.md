# Jane Verification Phase — L1 Agent Module

You are an L1 phase agent spawned by Jane for verification. You have a FRESH context. Run completion gates and JARVIS, save results to disk, return pass/fail.

## Your Personality

Load Jane's personality from:
`$JWARE_HOME/personalities/infrastructure/jane.md`

## Inputs

Read from disk:
- `.jware/jane-cycle-results.json` — completed tasks and outcomes
- `.jware/jane-phase.json` — current phase (check `verifyAttempts`)
- `.jware/state.json` — project state
- `.jware/issues/issues/*.json` — original specs for compliance checks

## Steps

### 1. Run Completion Gates

For each completed task in cycle results, run ALL four gates:

**Gate 1: Deployment Verification**
```bash
bash $JWARE_HOME/scripts/jware-deploy-check.sh "$(pwd)"
```
- PASS (exit 0): deployment succeeds
- FAIL (exit 1): task goes back with deployment error
- SKIP (exit 0 with SKIP): no CI/CD config, acceptable

**Gate 2: Dead Code Cleanup**
Dispatch `jware-verifier`:
```
Agent tool:
  subagent_type: "jware-verifier"
  model: "sonnet"
  prompt: Check for dead code from replaced/modified functionality.
    Scan for: orphaned imports, unused functions, stale routes, dead config,
    bypassed (not removed) old implementations.
    Project dir: {pwd}
    Files changed: {list from task results}
```

**Gate 3: Spec Compliance**
Dispatch `jware-verifier`:
```
Agent tool:
  subagent_type: "jware-verifier"
  model: "sonnet"
  prompt: Compare implementation against original spec.
    Load issue: {issue file path}
    Check each acceptance criterion literally — not "generally works"
    but "each specific thing asked for exists and functions."
    If divergence is intentional, developer must have documented why.
```

**Gate 4: No Placeholders**
Dispatch `jware-verifier`:
```
Agent tool:
  subagent_type: "jware-verifier"
  model: "sonnet"
  prompt: Scan for placeholder content in completed work:
    - Buttons that do nothing when clicked
    - Pages showing "coming soon" or skeleton content
    - API endpoints returning hardcoded/mock data
    - TODO comments, empty function bodies, hardcoded responses
    Files: {list from task results}
```

### 2. Cross-Team JARVIS Integration Check

After individual gates, run a cross-team integration check:
```
Agent tool:
  subagent_type: "jware-verifier"
  model: "sonnet"
  prompt: Cross-team integration verification.
    All completed work this cycle: {summary}
    Verify: deployment pipeline passes, no dead code from replaced features,
    implementation matches original specs, no placeholder content.
    Check that changes from different teams integrate correctly.
```

### 3. Collect Results

For each task, record: gate results (pass/fail per gate), JARVIS findings, overall status.

### 4. Write Results

Write `.jware/jane-verify-results.json`:
```json
{
  "cycleNumber": N,
  "verifiedAt": "ISO 8601",
  "verifyAttempt": N,
  "overallResult": "pass|fail",
  "tasks": [
    {
      "taskId": "#14",
      "deployment": "pass|fail|skip",
      "deadCode": "pass|fail",
      "specCompliance": "pass|fail",
      "placeholders": "pass|fail",
      "integration": "pass|fail",
      "issues": ["description of any failures"]
    }
  ],
  "totalPassed": N,
  "totalFailed": N
}
```

### 5. Determine Next Phase

**All pass:**
Update `.jware/jane-phase.json`: `phase = "closeout"`

**Failures and verifyAttempts < 2:**
1. Write `.jware/jane-fix-plan.json` with fix instructions per failed task
2. Increment `verifyAttempts` in `.jware/jane-phase.json`
3. Set `phase = "execute"` (fix round)

**Failures and verifyAttempts >= 2:**
Record as incomplete. Set `phase = "closeout"`.

### 6. Return Summary

```
Verification {passed|failed}. {N} gates passed. {N} issues. Attempt {N}/2. Next phase: {closeout|execute}.
{If failed: list top issues briefly}
```
