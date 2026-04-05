# Migration: Local JwareSolutions → Plugin Install

**Created:** 2026-04-05
**Purpose:** Migrate from the local development copy at `/Users/justinmalone/projects/JwareSolutions` to the plugin-installed version. Run this from the NEW plugin install directory.

**Tell Claude:** "Read `/Users/justinmalone/projects/JwareSolutions/docs/migration-to-plugin.md` and follow it."

---

## Context

JwareSolutions was developed locally at `/Users/justinmalone/projects/JwareSolutions`. It is now published as a Claude Code plugin at `github:jwaresolutions/JwareSolutionsForClaude`. The plugin install creates a clean copy, but the old directory has runtime state that must be migrated.

## Prerequisites

- Plugin is already installed (`/plugin marketplace add` + `/plugin install` completed)
- `$JWARE_HOME` resolves to the new plugin install directory (verify: `echo $JWARE_HOME`)
- Old directory still exists at `/Users/justinmalone/projects/JwareSolutions`

## Step 1: Verify Plugin Install

```bash
echo "JWARE_HOME=$JWARE_HOME"
test -f "$JWARE_HOME/.claude-plugin/plugin.json" && echo "PASS: Plugin found" || echo "FAIL: Plugin not found"
test -f "$JWARE_HOME/skills/jware/SKILL.md" && echo "PASS: Skills present" || echo "FAIL: Skills missing"
test -d "$JWARE_HOME/agents" && echo "PASS: Agents present" || echo "FAIL: Agents missing"
test -f "$JWARE_HOME/hooks/hooks.json" && echo "PASS: Hooks present" || echo "FAIL: Hooks missing"
```

If any fail, stop and troubleshoot the plugin install.

## Step 2: Migrate Central State

The `.jware/` directory contains the central registry and Jane's cross-project memory. The plugin install doesn't have this — it must be copied from the old location.

```bash
OLD="/Users/justinmalone/projects/JwareSolutions"

# Copy central .jware/ state to plugin directory
cp -r "$OLD/.jware" "$JWARE_HOME/.jware"

echo "Migrated:"
ls -la "$JWARE_HOME/.jware/"
ls -la "$JWARE_HOME/.jware/jane-global/"
```

Verify:
- `$JWARE_HOME/.jware/registry.json` exists and has content
- `$JWARE_HOME/.jware/jane-global/project-index.md` exists
- `$JWARE_HOME/.jware/jane-global/lessons-learned.md` exists
- `$JWARE_HOME/.jware/jane-global/cross-project-observations.md` exists

## Step 3: Migrate Specs (Optional)

The design specs are historical references. Copy them if you want to keep them accessible:

```bash
mkdir -p "$JWARE_HOME/docs/specs"
cp "$OLD/docs/specs/"*.md "$JWARE_HOME/docs/specs/"
echo "Migrated $(ls "$JWARE_HOME/docs/specs/"*.md | wc -l | tr -d ' ') spec files"
```

## Step 4: Remove Old Hooks from Global Settings

The old setup registered hooks manually in `~/.claude/settings.json`. The plugin now handles hook registration through `hooks/hooks.json`. Remove the old manual entries to avoid double-firing.

Read `~/.claude/settings.json`. In the `hooks` section, remove these entries:
- Any `SessionStart` hook referencing `jware-skill-size-hook.mjs`
- Any `UserPromptSubmit` hook referencing `jware-channel-hook.mjs`, `jware-tree-hook.mjs`, or `jware-meeting-hook.mjs`

**Only remove JWare hooks.** Leave any other hooks (e.g., omc hooks) untouched.

Also in the `env` section, remove the manual `JWARE_HOME` entry — the plugin's `settings.json` sets this automatically via `${CLAUDE_PLUGIN_ROOT}`.

## Step 5: Remove Old Scripts from ~/.claude/hud/

These scripts now live in the plugin at `$JWARE_HOME/scripts/`. The old copies in `~/.claude/hud/` are no longer needed.

```bash
rm -f ~/.claude/hud/jware-issue.sh
rm -f ~/.claude/hud/jware-file-lock.sh
rm -f ~/.claude/hud/jware-deploy-check.sh
rm -f ~/.claude/hud/jware-tree-update.sh
rm -f ~/.claude/hud/jware-task-counts.sh
rm -f ~/.claude/hud/jware-state-check.sh
rm -f ~/.claude/hud/jware-migrate-issues.sh
rm -f ~/.claude/hud/jware-spawn-team.sh
rm -f ~/.claude/hud/jware-channel-hook.mjs
rm -f ~/.claude/hud/jware-tree-hook.mjs
rm -f ~/.claude/hud/jware-meeting-hook.mjs
rm -f ~/.claude/hud/jware-skill-size-hook.mjs

echo "Removed $(ls ~/.claude/hud/jware-* 2>/dev/null | wc -l | tr -d ' ') remaining (should be 0)"
```

## Step 6: Update Global CLAUDE.md

The JWare section in `~/.claude/CLAUDE.md` already uses `$JWARE_HOME` paths. Verify it resolves correctly:

```bash
grep 'JWARE_HOME' ~/.claude/CLAUDE.md | head -5
```

These should all reference `$JWARE_HOME/...` (not hardcoded paths). If any still reference `/Users/justinmalone/projects/JwareSolutions`, replace them with `$JWARE_HOME`.

## Step 7: Verify Per-Project Files

Check that existing projects' CLAUDE.md files use `$JWARE_HOME`, not hardcoded paths:

```bash
for proj in watch-alarm organize captains-log-android Jware-Trader-X; do
  dir="/Users/justinmalone/projects/$proj"
  if [ -f "$dir/CLAUDE.md" ]; then
    hardcoded=$(grep -c '/Users/justinmalone/projects/JwareSolutions' "$dir/CLAUDE.md" 2>/dev/null)
    jware_var=$(grep -c 'JWARE_HOME' "$dir/CLAUDE.md" 2>/dev/null)
    echo "$proj: $hardcoded hardcoded, $jware_var using \$JWARE_HOME"
  fi
done
```

All should show 0 hardcoded. If any have hardcoded paths, replace `/Users/justinmalone/projects/JwareSolutions` with `$JWARE_HOME`.

## Step 8: Rename Old Directory

Do NOT delete — rename so it's available for rollback:

```bash
mv /Users/justinmalone/projects/JwareSolutions /Users/justinmalone/projects/JwareSolutions-pre-plugin
echo "Renamed to JwareSolutions-pre-plugin"
```

## Step 9: Smoke Test

Run these from any active JWare project directory (e.g., Jware-Trader-X):

```bash
# Scripts resolve
bash "$JWARE_HOME/scripts/jware-state-check.sh" "$(pwd)"
bash "$JWARE_HOME/scripts/jware-task-counts.sh" "$(pwd)"

# Registry accessible
cat "$JWARE_HOME/.jware/registry.json" | head -5

# Personality files accessible
ls "$JWARE_HOME/personalities/engineering/dev-lead-marcus-chen.md"
```

Then test a skill:
```
/jware-status
```

If status renders correctly, the migration is complete.

## Rollback

Rollback works from ANY point — whether migration failed at step 2, step 6, or after step 9. The old directory is never modified, only renamed. Every step below is safe to run regardless of what state the migration is in.

### Step R1: Restore Old Directory

```bash
# If old directory was renamed (step 8 completed)
if [ -d /Users/justinmalone/projects/JwareSolutions-pre-plugin ]; then
  # If current name is still in use (partial step 8), remove the broken state
  [ -d /Users/justinmalone/projects/JwareSolutions ] && mv /Users/justinmalone/projects/JwareSolutions /Users/justinmalone/projects/JwareSolutions-failed-migration
  mv /Users/justinmalone/projects/JwareSolutions-pre-plugin /Users/justinmalone/projects/JwareSolutions
  echo "RESTORED: JwareSolutions directory"
fi

# If old directory was never renamed (failed before step 8)
if [ -d /Users/justinmalone/projects/JwareSolutions ]; then
  echo "OK: JwareSolutions directory still in place"
fi
```

### Step R2: Restore JWARE_HOME Environment Variable

The migration may have removed `JWARE_HOME` from `~/.claude/settings.json` (step 4). Restore it pointing to the old location.

Read `~/.claude/settings.json`. In the `env` section, set:
```json
"JWARE_HOME": "/Users/justinmalone/projects/JwareSolutions"
```

If the `env` section already has `JWARE_HOME` pointing to the plugin directory, change it back. If it's missing entirely, add it.

### Step R3: Restore Manual Hooks

The migration may have removed JWare hooks from `~/.claude/settings.json` (step 4). If they were removed, re-add them.

In `~/.claude/settings.json`, the `hooks` section should have:

**SessionStart** — add if missing:
```json
{
  "type": "command",
  "command": "node /Users/justinmalone/.claude/hud/jware-skill-size-hook.mjs"
}
```

**UserPromptSubmit** — add these three if missing:
```json
{
  "type": "command",
  "command": "node /Users/justinmalone/.claude/hud/jware-channel-hook.mjs"
},
{
  "type": "command",
  "command": "node /Users/justinmalone/.claude/hud/jware-tree-hook.mjs"
},
{
  "type": "command",
  "command": "node /Users/justinmalone/.claude/hud/jware-meeting-hook.mjs"
}
```

**Only add hooks that are missing.** If the migration didn't reach step 4, they'll still be there.

### Step R4: Restore Old Scripts

The migration may have deleted scripts from `~/.claude/hud/` (step 5). If they're gone, copy them back from the old directory:

```bash
OLD="/Users/justinmalone/projects/JwareSolutions"
HUD="$HOME/.claude/hud"

for f in jware-issue.sh jware-file-lock.sh jware-deploy-check.sh jware-tree-update.sh jware-task-counts.sh jware-state-check.sh jware-migrate-issues.sh jware-spawn-team.sh; do
  if [ ! -f "$HUD/$f" ] && [ -f "$OLD/scripts/$f" ]; then
    cp "$OLD/scripts/$f" "$HUD/$f"
    chmod +x "$HUD/$f"
    echo "RESTORED: $f"
  else
    echo "OK: $f already exists"
  fi
done

for f in jware-channel-hook.mjs jware-tree-hook.mjs jware-meeting-hook.mjs jware-skill-size-hook.mjs; do
  if [ ! -f "$HUD/$f" ] && [ -f "$OLD/scripts/$f" ]; then
    cp "$OLD/scripts/$f" "$HUD/$f"
    echo "RESTORED: $f"
  else
    echo "OK: $f already exists"
  fi
done
```

**Note:** The scripts in the old directory's `scripts/` folder use `$JWARE_HOME` paths. The scripts in `~/.claude/hud/` use `~/.claude/hud/` paths. The old directory has BOTH versions — the `scripts/` copies (plugin-style) and the original copies were there before migration. If the `~/.claude/hud/` copies were deleted, restore from the old directory and verify they reference `~/.claude/hud/` paths, not `$JWARE_HOME/scripts/`. If they reference `$JWARE_HOME`, that's fine — `JWARE_HOME` now points to the old directory again (step R2).

### Step R5: Verify Rollback

```bash
echo "=== JWARE_HOME ==="
echo "$JWARE_HOME"

echo "=== Directory exists ==="
ls /Users/justinmalone/projects/JwareSolutions/skills/jware/SKILL.md && echo "PASS" || echo "FAIL"

echo "=== Registry ==="
cat /Users/justinmalone/projects/JwareSolutions/.jware/registry.json | head -3 && echo "PASS" || echo "FAIL"

echo "=== Scripts in hud ==="
ls ~/.claude/hud/jware-issue.sh && echo "PASS" || echo "FAIL"

echo "=== Hooks in settings ==="
grep -c 'jware-channel-hook' ~/.claude/settings.json && echo "hooks present" || echo "hooks MISSING"
```

All should pass. If so, the rollback is complete and JWare is running from the original local directory as before.

### Step R6: Clean Up Failed Migration Artifacts

After rollback is confirmed working:

```bash
# Remove the failed migration directory if it was created
rm -rf /Users/justinmalone/projects/JwareSolutions-failed-migration

# Optionally uninstall the plugin (it's harmless but unused after rollback)
# /plugin uninstall jware-solutions
```

### What about the plugin?

After rollback, the plugin is still installed but `JWARE_HOME` points to the old directory, so the old directory's skills, engines, and scripts are what actually gets used. The plugin's copies sit dormant. You can uninstall the plugin later (`/plugin uninstall jware-solutions`) or leave it — it won't conflict.

---

## Post-Migration Cleanup

After confirming everything works for at least one full `/jware-auto` cycle:

1. Delete `JwareSolutions-pre-plugin` when confident
2. The auto-memory files at `~/.claude/projects/-Users-justinmalone-projects-JwareSolutions/memory/` are tied to the old path — they won't load from the new plugin path. Review them and recreate any important memories in the new context if needed:

```bash
# View old memories
ls ~/.claude/projects/-Users-justinmalone-projects-JwareSolutions/memory/
cat ~/.claude/projects/-Users-justinmalone-projects-JwareSolutions/memory/MEMORY.md
```
