# Migration: Local JwareSolutions → Plugin Install

**Created:** 2026-04-05
**Purpose:** Migrate from the local development copy at `/Users/justinmalone/projects/JwareSolutions` to the plugin-installed version. Run this from the NEW plugin install directory.

**Tell Claude:** "Read `/Users/justinmalone/projects/JwareSolutions/docs/migration-to-plugin.md` and follow it."

---

## Context

JwareSolutions was developed locally at `/Users/justinmalone/projects/JwareSolutions`. It is now published as a Claude Code plugin at `github:jwaresolutions/JwareSolutionsForClaude`. The plugin install creates a clean copy, but the old directory has runtime state and the old install left artifacts in `~/.claude/settings.json` that block a clean plugin install.

---

## Step 0: Clean Stale Artifacts (MUST run before plugin install)

The old manual installation left entries in `~/.claude/settings.json` that conflict with the plugin system. These must be removed BEFORE running `/plugin marketplace add` and `/plugin install`.

### 0.1 Save Rollback Snapshot

Before changing anything, save the current settings so rollback can restore them exactly:

```bash
cp ~/.claude/settings.json ~/.claude/settings.json.pre-jware-migration
echo "Saved rollback snapshot"
```

### 0.2 Remove Stale enabledPlugins Entry

Read `~/.claude/settings.json`. In `enabledPlugins`, delete:
```
"jware-solutions@jware-solutions": true
```

This was from the old manual install. The plugin system will re-add it with the correct key after install.

### 0.3 Remove Stale JWARE_HOME from env

In `~/.claude/settings.json`, in the `env` section, delete:
```
"JWARE_HOME": "/Users/justinmalone/projects/JwareSolutions"
```

The plugin's own `settings.json` sets `JWARE_HOME` to `${CLAUDE_PLUGIN_ROOT}` automatically.

### 0.4 Remove Manual Hook Registrations

In `~/.claude/settings.json`, in the `hooks` section:

**Remove the entire `SessionStart` block** if it only contains JWare hooks:
```json
"SessionStart": [
  {
    "matcher": "",
    "hooks": [
      {
        "type": "command",
        "command": "node /Users/justinmalone/.claude/hud/jware-skill-size-hook.mjs"
      }
    ]
  }
]
```

**In the `UserPromptSubmit` block**, remove these three hooks (leave any non-JWare hooks):
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

If `UserPromptSubmit` becomes empty after removing these, delete the entire `UserPromptSubmit` block. If `hooks` becomes empty, delete the entire `hooks` section.

### 0.5 Remove Old Scripts from ~/.claude/hud/

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

echo "Remaining jware files (should be 0 or just jware-hud.mjs):"
ls ~/.claude/hud/jware-* 2>/dev/null || echo "none"
```

Note: `jware-hud.mjs` is the HUD statusline — leave it if present, it's separate from the plugin.

### 0.6 Remove Stale Cache/Marketplace Directories

```bash
rm -rf ~/.claude/plugins/cache/jware-solutions
rm -rf ~/.claude/plugins/marketplaces/jware-solutions
echo "Cache cleared"
```

### 0.7 Verify Clean State

```bash
echo "=== enabledPlugins (should not contain jware-solutions) ==="
jq '.enabledPlugins | keys[] | select(test("jware"))' ~/.claude/settings.json 2>/dev/null || echo "CLEAN"

echo "=== env.JWARE_HOME (should not exist) ==="
jq '.env.JWARE_HOME // "CLEAN"' ~/.claude/settings.json

echo "=== hooks referencing jware (should be 0) ==="
grep -c 'jware' ~/.claude/settings.json

echo "=== hud scripts (should be 0 or just hud.mjs) ==="
ls ~/.claude/hud/jware-* 2>/dev/null | grep -v hud.mjs || echo "CLEAN"

echo "=== plugin cache (should not exist) ==="
ls ~/.claude/plugins/cache/jware-solutions 2>/dev/null || echo "CLEAN"
```

All should show CLEAN. If any don't, re-check the step that handles that artifact.

---

## Step 1: Install Plugin

```
/plugin marketplace add https://github.com/jwaresolutions/JwareSolutionsForClaude
/plugin install jware-solutions
```

When prompted for scope, select **"Install for you (user scope)"**.

### Verify

```bash
echo "JWARE_HOME=$JWARE_HOME"
test -f "$JWARE_HOME/.claude-plugin/plugin.json" && echo "PASS: Plugin found" || echo "FAIL: Plugin not found"
test -f "$JWARE_HOME/skills/jware/SKILL.md" && echo "PASS: Skills present" || echo "FAIL: Skills missing"
test -d "$JWARE_HOME/agents" && echo "PASS: Agents present" || echo "FAIL: Agents missing"
test -f "$JWARE_HOME/hooks/hooks.json" && echo "PASS: Hooks present" || echo "FAIL: Hooks missing"
```

If any fail, stop and troubleshoot the plugin install.

---

## Step 2: Migrate Central State

The `.jware/` directory contains the central registry and Jane's cross-project memory. The plugin install doesn't have this — it must be copied from the old location.

```bash
OLD="/Users/justinmalone/projects/JwareSolutions"

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

---

## Step 3: Migrate Specs (Optional)

The design specs are historical references. Copy them if you want to keep them accessible:

```bash
mkdir -p "$JWARE_HOME/docs/specs"
cp "$OLD/docs/specs/"*.md "$JWARE_HOME/docs/specs/"
echo "Migrated $(ls "$JWARE_HOME/docs/specs/"*.md | wc -l | tr -d ' ') spec files"
```

---

## Step 4: Update Global CLAUDE.md

The JWare section in `~/.claude/CLAUDE.md` already uses `$JWARE_HOME` paths. Verify it resolves correctly:

```bash
grep 'JWARE_HOME' ~/.claude/CLAUDE.md | head -5
```

These should all reference `$JWARE_HOME/...` (not hardcoded paths). If any still reference `/Users/justinmalone/projects/JwareSolutions`, replace them with `$JWARE_HOME`.

---

## Step 5: Verify Per-Project Files

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

---

## Step 6: Rename Old Directory

Do NOT delete — rename so it's available for rollback:

```bash
mv /Users/justinmalone/projects/JwareSolutions /Users/justinmalone/projects/JwareSolutions-pre-plugin
echo "Renamed to JwareSolutions-pre-plugin"
```

---

## Step 7: Smoke Test

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

---

## Rollback

Rollback works from ANY point — whether migration failed at step 0, step 3, or after step 7. The rollback snapshot saved in step 0.1 contains the exact pre-migration state of settings.json.

### Step R1: Restore settings.json

```bash
if [ -f ~/.claude/settings.json.pre-jware-migration ]; then
  cp ~/.claude/settings.json.pre-jware-migration ~/.claude/settings.json
  echo "RESTORED: settings.json from pre-migration snapshot"
else
  echo "WARNING: No snapshot found. Manual restoration needed (see R1-manual below)"
fi
```

**R1-manual** — If the snapshot is missing, manually restore these to `~/.claude/settings.json`:

In `env`, add:
```json
"JWARE_HOME": "/Users/justinmalone/projects/JwareSolutions"
```

In `enabledPlugins`, add:
```json
"jware-solutions@jware-solutions": true
```

In `hooks.SessionStart`, add:
```json
{
  "matcher": "",
  "hooks": [
    {
      "type": "command",
      "command": "node /Users/justinmalone/.claude/hud/jware-skill-size-hook.mjs"
    }
  ]
}
```

In `hooks.UserPromptSubmit`, add these three hooks to the existing hooks array:
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

### Step R2: Restore Old Directory

```bash
# If directory was renamed (step 6 completed)
if [ -d /Users/justinmalone/projects/JwareSolutions-pre-plugin ]; then
  [ -d /Users/justinmalone/projects/JwareSolutions ] && mv /Users/justinmalone/projects/JwareSolutions /Users/justinmalone/projects/JwareSolutions-failed-migration
  mv /Users/justinmalone/projects/JwareSolutions-pre-plugin /Users/justinmalone/projects/JwareSolutions
  echo "RESTORED: JwareSolutions directory"
fi

# If directory was never renamed (failed before step 6)
if [ -d /Users/justinmalone/projects/JwareSolutions ]; then
  echo "OK: JwareSolutions directory still in place"
fi
```

### Step R3: Restore Old Scripts

If scripts were deleted from `~/.claude/hud/` (step 0.5):

```bash
OLD="/Users/justinmalone/projects/JwareSolutions"
HUD="$HOME/.claude/hud"

for f in jware-issue.sh jware-file-lock.sh jware-deploy-check.sh jware-tree-update.sh jware-task-counts.sh jware-state-check.sh jware-migrate-issues.sh jware-spawn-team.sh; do
  if [ ! -f "$HUD/$f" ] && [ -f "$OLD/scripts/$f" ]; then
    cp "$OLD/scripts/$f" "$HUD/$f"
    chmod +x "$HUD/$f"
    echo "RESTORED: $f"
  else
    echo "OK: $f"
  fi
done

for f in jware-channel-hook.mjs jware-tree-hook.mjs jware-meeting-hook.mjs jware-skill-size-hook.mjs; do
  if [ ! -f "$HUD/$f" ] && [ -f "$OLD/scripts/$f" ]; then
    cp "$OLD/scripts/$f" "$HUD/$f"
    echo "RESTORED: $f"
  else
    echo "OK: $f"
  fi
done
```

### Step R4: Verify Rollback

```bash
echo "=== JWARE_HOME ==="
jq -r '.env.JWARE_HOME' ~/.claude/settings.json

echo "=== Directory exists ==="
ls /Users/justinmalone/projects/JwareSolutions/skills/jware/SKILL.md 2>/dev/null && echo "PASS" || echo "FAIL"

echo "=== Registry ==="
cat /Users/justinmalone/projects/JwareSolutions/.jware/registry.json 2>/dev/null | head -3 && echo "PASS" || echo "FAIL"

echo "=== Scripts in hud ==="
ls ~/.claude/hud/jware-issue.sh 2>/dev/null && echo "PASS" || echo "FAIL"

echo "=== Hooks in settings ==="
grep -c 'jware-channel-hook' ~/.claude/settings.json && echo "hooks present" || echo "hooks MISSING"

echo "=== enabledPlugins ==="
jq '.enabledPlugins["jware-solutions@jware-solutions"]' ~/.claude/settings.json
```

All should pass. If so, rollback is complete.

### Step R5: Clean Up

After rollback is confirmed:

```bash
rm -rf /Users/justinmalone/projects/JwareSolutions-failed-migration 2>/dev/null
# Optionally uninstall the plugin:
# /plugin uninstall jware-solutions
```

After rollback, the plugin may still be installed but `JWARE_HOME` points to the old directory, so the old copy is what's used. The plugin sits dormant.

---

## Post-Migration Cleanup

After confirming everything works for at least one full `/jware-auto` cycle:

1. Delete rollback snapshot: `rm ~/.claude/settings.json.pre-jware-migration`
2. Delete old directory: `rm -rf /Users/justinmalone/projects/JwareSolutions-pre-plugin`
3. The auto-memory files at `~/.claude/projects/-Users-justinmalone-projects-JwareSolutions/memory/` are tied to the old path — they won't load from the new plugin path. Review them and recreate any important memories in the new context if needed:

```bash
cat ~/.claude/projects/-Users-justinmalone-projects-JwareSolutions/memory/MEMORY.md
```
