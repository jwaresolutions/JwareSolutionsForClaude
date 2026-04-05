# Issue Operations Reference

Use `$JWARE_HOME/scripts/jware-issue.sh` for all issue operations. Never write issue JSON directly.

## Common Commands

```bash
# Create
bash $JWARE_HOME/scripts/jware-issue.sh create "$(pwd)" --title "..." --desc "..." --priority high --labels "bug,auth"

# List (with filters)
bash $JWARE_HOME/scripts/jware-issue.sh list "$(pwd)" --status open --format table

# Get single issue
bash $JWARE_HOME/scripts/jware-issue.sh get "$(pwd)" 14

# Update fields
bash $JWARE_HOME/scripts/jware-issue.sh update "$(pwd)" 14 --status done
bash $JWARE_HOME/scripts/jware-issue.sh update "$(pwd)" 14 --add-label "reviewed" --priority high
bash $JWARE_HOME/scripts/jware-issue.sh update "$(pwd)" 14 --blocked-by "3,5"

# Review and vote
bash $JWARE_HOME/scripts/jware-issue.sh review "$(pwd)" 14 "Dev Lead" approve "Looks good"
bash $JWARE_HOME/scripts/jware-issue.sh vote "$(pwd)" 14 approve "Ship it"

# Quick wins (all reviewers approved, high/medium, not done/closed)
bash $JWARE_HOME/scripts/jware-issue.sh quickwins "$(pwd)"

# Delete (cleans blockedBy refs and assets)
bash $JWARE_HOME/scripts/jware-issue.sh delete "$(pwd)" 14

# Initialize tracker in a new project
bash $JWARE_HOME/scripts/jware-issue.sh init "$(pwd)" "Project Name"
```

## Rules

- **ONLY Jane writes to the issue tracker** — other agents request through their team lead
- **Always use the script** — atomic writes and cycle detection are built in
- **For full schema**: read `engine/issue-schema.md`

## Automatic Behavior

- When code resolves an issue: **suggest** (don't auto-update) marking it done
- When commits reference `#N`, `fixes #N`, `closes #N`: **suggest** updating the issue
- Always confirm before changes — never auto-update
