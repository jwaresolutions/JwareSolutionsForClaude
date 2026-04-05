---
name: jware-setup
description: "First-run setup — locates plugin, sets JWARE_HOME, creates central .jware/ directory"
---

# JWare Solutions — Setup

## Trigger

`/jware-setup` — run once after installing the plugin.

## Steps

### 1. Locate the Plugin Install Directory

Find where JWare is installed by searching for the plugin marker:

```bash
find ~/.claude/plugins -path "*jware-solutions*/.claude-plugin/plugin.json" -not -path "*/cache/*" 2>/dev/null | head -1
```

Extract the plugin root (parent of `.claude-plugin/`). If not found:

```bash
# Fallback: check cache
find ~/.claude/plugins -path "*jware-solutions*/.claude-plugin/plugin.json" 2>/dev/null | head -1
```

If still not found: "JWare plugin not installed. Run `/plugin marketplace add https://github.com/jwaresolutions/JwareSolutionsForClaude` then `/plugin install jware-solutions`."

Save the resolved path as `PLUGIN_ROOT`.

### 2. Set JWARE_HOME in Claude Code Settings

Read `~/.claude/settings.json`. Add `JWARE_HOME` to the `env` section pointing to the resolved plugin root:

```json
"env": {
  "JWARE_HOME": "{PLUGIN_ROOT}"
}
```

If `env` already has `JWARE_HOME`, update it. If `env` doesn't exist, create it. Preserve all other env entries.

**Important:** Write the actual resolved path (e.g., `/Users/you/.claude/plugins/marketplaces/jware-solutions`), not a variable — env vars in settings.json don't expand other variables.

Verify it was written:

```bash
jq '.env.JWARE_HOME' ~/.claude/settings.json
```

### 3. Check if .jware/ Already Exists

```bash
test -d "{PLUGIN_ROOT}/.jware" && echo "EXISTS" || echo "NEEDS_INIT"
```

If already exists, show current state (project count, etc.) and skip to Step 5.

### 4. Create Central State Directory

```bash
JWARE_HOME="{PLUGIN_ROOT}"
mkdir -p "$JWARE_HOME/.jware/jane-global"
```

Create `registry.json`:
```bash
cat > "$JWARE_HOME/.jware/registry.json" << 'EOF'
{
  "companyName": "JWare Solutions",
  "totalHeadcount": 48,
  "projects": [],
  "teamUtilization": {},
  "updatedAt": null
}
EOF
```

Create Jane's global context:
```bash
cat > "$JWARE_HOME/.jware/jane-global/project-index.md" << 'EOF'
# Jane — Project Index

| Project | Path | Phase | Started |
|---------|------|-------|---------|
EOF

cat > "$JWARE_HOME/.jware/jane-global/lessons-learned.md" << 'EOF'
# Jane — Cross-Project Lessons Learned

(none yet — Jane will populate as she identifies patterns across projects)
EOF

cat > "$JWARE_HOME/.jware/jane-global/cross-project-observations.md" << 'EOF'
# Jane — Cross-Project Observations

(none yet — Jane will populate when she sees patterns across multiple projects)
EOF
```

### 5. Verify

```bash
echo "JWARE_HOME=$(jq -r '.env.JWARE_HOME' ~/.claude/settings.json)"
test -f "$(jq -r '.env.JWARE_HOME' ~/.claude/settings.json)/.jware/registry.json" && echo "PASS: Registry exists" || echo "FAIL"
test -f "$(jq -r '.env.JWARE_HOME' ~/.claude/settings.json)/skills/jware/SKILL.md" && echo "PASS: Skills accessible" || echo "FAIL"
```

### 6. Confirm

> "JWare Solutions initialized."
> ""
> "`JWARE_HOME` set to `{PLUGIN_ROOT}`"
> ""
> "**Restart Claude Code** for the environment variable to take effect, then:"
> "- `/jware` from any project directory to submit a new project"
> "- `/jware-dashboard` to monitor all active projects"

**The restart is required** — env vars in settings.json are loaded at session start, not mid-session.
