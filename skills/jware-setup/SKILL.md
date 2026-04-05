---
name: jware-setup
description: "First-run setup — creates central .jware/ directory with registry and Jane's global context"
---

# JWare Solutions — Setup

## Trigger

`/jware-setup` — run once after installing the plugin. Creates the central company state directory.

## What It Does

Creates `$JWARE_HOME/.jware/` with:
- `registry.json` — central project registry (starts empty)
- `jane-global/project-index.md` — cross-project index
- `jane-global/lessons-learned.md` — cross-project patterns
- `jane-global/cross-project-observations.md` — cross-project observations

## Steps

### 1. Check if already initialized

```bash
test -d "$JWARE_HOME/.jware" && echo "EXISTS" || echo "NEEDS_INIT"
```

If `$JWARE_HOME/.jware/` already exists:
> "JWare is already initialized. Registry at `$JWARE_HOME/.jware/registry.json`."

Show the current state: number of registered projects, team utilization summary. Stop.

### 2. Create directory structure

```bash
mkdir -p "$JWARE_HOME/.jware/jane-global"
```

### 3. Create registry.json

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

### 4. Create Jane's global context

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

### 5. Confirm

> "JWare Solutions initialized. Central registry at `$JWARE_HOME/.jware/registry.json`."
> ""
> "Next steps:"
> "- Run `/jware` from any project directory to submit a new project"
> "- Run `/jware-dashboard` to monitor all active projects"
