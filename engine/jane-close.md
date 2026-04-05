# Jane Closeout Phase — L0 Instructions

These are instructions for Jane at L0 during closeout. NOT a spawned agent — Jane follows these herself. Closeout requires Jane's full judgment and cross-project context.

## Steps

### 1. Spawn Retro Agent

Dispatch an L1 agent using `engine/jane-retro.md`:
```
Agent tool:
  subagent_type: "jware-team-alpha"  (or any team agent type — it's a fresh L1)
  model: "sonnet"
  prompt: [Contents of engine/jane-retro.md] + [cycle number, project dir]
```

Collect the retro results.

### 2. Process Action Items

For each proposed action item from the retro:

- **Allow** — reasonable, apply it
- **Block** — would cause problems you can see but the team can't. Do NOT announce. Seed the next retro to surface why.
- **Modify** — right direction, wrong specifics. Apply a refined version.

**Auto-apply rules (no customer approval needed):**
- Prompt/personality injection tweaks
- Process changes (steps, checklists, gates)
- JARVIS threshold adjustments
- Task reassignment to better-suited teams

**Requires customer approval (create `decision-needed` issue):**
- Team structure (moving people permanently)
- Scope or architecture changes
- Team utilization imbalances

### 3. Apply Personality Tweaks

For each suggested personality tweak:
- NEVER change core traits (MBTI, communication style, fundamental approach)
- Only adjust behavioral edges
- Max ONE small change per person per retro
- Before applying: "Does this make this person more like someone else on the team?" If yes, DO NOT apply.
- Log every change to `.jware/jane-personality-changes.md`: timestamp, who, what changed, why, what was preserved

### 4. Review Agent Context

1. Collect agent context files from `.jware/agent-context/`
2. Review for discrepancies between agents' outputs
3. Create issuetracker issues for any discrepancies found

### 5. Write State Updates

ONLY Jane writes these:
- `.jware/state.json`: phase, task counts, cycle number, timestamps
- `.jware/events.json`: mark processed events, add new events
- `.jware/issues/issues/`: status changes, comments from agents
- `.jware/projects/{projectId}/project.json`: team utilization, progress

### 6. Record Observations

Update `.jware/jane-observations.md`:
- New patterns from this cycle
- Check global `$JWARE_HOME/.jware/jane-global/lessons-learned.md`
- If a pattern matches another project, update the global file

### 7. Write Cycle Summary

Append to `.jware/auto-log.md`:
- Cycle number, tasks completed/failed, key decisions, observations
- Keep it compact — this file grows across cycles

### 8. Clean Up

1. Create cycle summary from context files: `.jware/agent-context/cycle-{N}-summary.md`
2. Delete individual agent context files (keep the summary)
3. Delete raw phase files: `jane-cycle-plan.json`, `jane-cycle-results.json`, `jane-verify-results.json`, `jane-fix-plan.json`
4. Clean up temp files: `rm -f /tmp/jane-prompt-*.md /tmp/team-*-prompt.md`
5. Do NOT kill the tree view pane — it persists across cycles

### 9. Jane's Direct Communication

If during this cycle you observed something that transcends normal orchestration:
- **Urgent:** SendMessage directly to the customer
- **Non-urgent:** Write to `.jware/jane-direct.md`, flag it in the cycle summary

### 10. Check Pause Conditions

| Condition | Exit Code |
|-----------|-----------|
| `decision-needed` issues in issuetracker | `DECISION_NEEDED` |
| All tasks done, project finished | `PROJECT_COMPLETE` |
| Hit session cycle limit | `MAX_CYCLES` |
| 3 consecutive empty cycles | `ENGINE_STUCK` |
| `.jware/scoping.lock` appeared | `SCOPING_LOCK` |
| Phase is `blocked` with no workaround | `PROJECT_BLOCKED` |
| Cross-team JARVIS failed after 2 passes | `VERIFICATION_FAILED` |

### 11. If Pausing

1. Update `auto-state.json`: status, pausedAt, pauseReason, exitCode, decisionsBlocking
2. Append to `auto-log.md`
3. Remove `.jware/automation.lock`
4. Kill the tree view tmux pane: `tmux kill-pane -t {tree-view-pane-id}`
5. Display exit report:
```
═══════════════════════════════════════════════
  JANE — {PAUSED | COMPLETE | ERROR}
  Exit code:  {exitCode}
  Reason:     {pauseReason}
  Cycles:     {cycleCount}
  Events:     {totalEventsProcessed} processed
  {If decisions: "Decisions:   {count} pending"}
═══════════════════════════════════════════════
```

### 12. If Continuing

1. Increment `cycleCount` in `auto-state.json`
2. Update `totalEventsProcessed`, `lastCycleAt`
3. Reset `consecutiveEmptyCycles` if events were processed (else increment)
4. Set `phase` to `"planning"` in `jane-phase.json`
5. Return to Jane's cycle loop
