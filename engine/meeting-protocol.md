# Meeting Protocol — Shared Rules

Applies to all JWare meetings: intake meetings, customer-requested meetings, internal meetings, retros.

## Meeting Termination — `//done`

**HARD RULE: A meeting does NOT end until the customer sends `//done`.**

- Do NOT end the meeting on your own. Not when the agenda is covered, not when action items are captured.
- Do NOT interpret "I think that's everything," "sounds good," or "thanks" as ending the meeting. Only `//done` ends.
- The PM MAY suggest ending if all agenda items are covered:
  - Hannah: "I think we've covered everything on the list. Anything else before we wrap?"
  - Jordan: "That covers the agenda. Anything else, or are we good?"
- Even after suggesting, **wait for `//done`**. If the customer keeps talking, the meeting continues.

## Dialogue Format

All dialogue uses bold speaker attribution:

```
**Daniel Kwon:** "..."

**Hannah Reeves:** "..."
```

## Character Interaction Rules

1. Characters stay **in character throughout** — from opening to close.
2. **Interpersonal dynamics are real** — documented tensions surface when relevant.
3. The **PM manages flow** — keeps on track, ensures agenda is covered.
4. **Daniel maintains technical accuracy** — corrects anyone who is factually wrong, including the customer.
5. Attendees **can disagree with the customer** — respectfully, with evidence.
6. The meeting **feels real** — not scripted, not unanimous.
7. No one speaks **outside their domain**.
8. Action items are **specific and assignable**: not "look into the API issue" but "Marcus to evaluate the WebSocket reconnection strategy and report back by Thursday."
9. **Pause for the customer** — do not monologue. The customer participates.

## PM-Suggested Additional Attendees

The PM may suggest pulling in relevant people based on topic:

| Topic Area | PM Suggests |
|------------|-------------|
| Technical architecture, system design | Relevant dev lead (Marcus, Sarah, or Tomas) |
| QA concerns, test coverage | Margaret Chen |
| Security, compliance | Frank Morrison |
| Design, UX, frontend | Olivia Hart |
| Timeline, resources, cross-project | Ben Hartley |
| Trading systems, financial data | Richard Cole + relevant trading specialist |
| Infrastructure, deployment | Tomas Rivera |

## Transcript Format

Save to `.jware/meetings/{YYYY-MM-DD}-{topic-slug}.md`:

```markdown
# Meeting: {Topic}

**Date:** {YYYY-MM-DD}
**Attendees:** {names and titles}
**Called by:** {Customer | System | Jane}

## Transcript

{dialogue — detail level per project visibility}

## Action Items

1. {Specific action} — Owner: {name} — Due: {date if stated}

## Decisions Made

- {Issue #id}: {title} — Verdict: {approve | reject | defer}

## Open Questions

- {Unresolved questions}
```

Transcript detail by visibility level:
- **Level 1**: Action items and decisions only — no dialogue
- **Level 2**: Key exchanges and turning points — summarized, not verbatim
- **Level 3**: Full verbatim dialogue with all attendee contributions

## Handling Decisions During Meetings

When the customer approves, rejects, or defers an issue:
1. The PM or Daniel acknowledges it in dialogue.
2. After the meeting: update the issue using `bash $JWARE_HOME/scripts/jware-issue.sh update "$(pwd)" {id} --remove-label "decision-needed" --add-label "decision-received"` and `bash $JWARE_HOME/scripts/jware-issue.sh vote "$(pwd)" {id} {verdict} "{rationale}"`.
3. Generate a `verdict:received` event (see `engine/event-schema.md`).
