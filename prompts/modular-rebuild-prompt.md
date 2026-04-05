I have a large orchestration skill file that's suffering from AI deprioritization — the AI picks what it wants from the long document and skips instructions it finds inconvenient. I've solved this problem before using a modular rebuild pattern and I want to apply it here.

## The Pattern

Break the monolithic skill into three layers:

### 1. Thin Router (~50-80 lines)
The main skill file becomes a lightweight coordinator that:
- Parses arguments and checks prerequisites
- Tracks phase in a state file on disk (e.g., `{phase, step, attempts, data}`)
- For each phase: loads the corresponding module, spawns a fresh-context agent with it, reads the summary back
- Handles closeout/judgment work itself (anything requiring cross-phase context)
- Manages pause/resume via state files

The router NEVER accumulates phase details — it only holds the current phase + summary from the last one.

### 2. Engine Modules (~30-50 lines each)
Each phase of the orchestration becomes its own instruction file:
- Gets loaded into a fresh agent context (no history from other phases)
- Reads its inputs from disk, does all its work, writes results to disk
- Returns a compact summary to the router
- Self-contained: includes what to read, what to do, what to write, what to return

### 3. Shell Scripts (for deterministic operations)
Anything that should produce consistent output regardless of AI interpretation:
- File/resource locking
- Status display rendering
- Build/deploy verification
- Formatted output generation

Scripts are called via bash, not interpreted by the AI. This prevents the AI from "creative reinterpretation" of formatting, locking logic, etc.

## Your Task

1. Read my main skill/orchestration file (I'll point you to it)
2. Identify: which sections are phases? Which are deterministic operations? Which require cross-phase judgment?
3. Produce a spec document (like an implementation plan) that maps the current monolith to:
   - A list of engine modules with their responsibilities and disk I/O
   - A list of scripts with their usage signatures
   - A thin router showing the phase state machine and dispatch logic
   - What stays unchanged (hooks, configs, other files)
4. Include a file structure showing where everything goes
5. Include the phase flow diagram (state machine with transitions)
6. Specify the implementation order

## Principles
- Each module should be short enough that the AI can't deprioritize parts of it
- All coordination state lives on disk, not in agent memory
- The router's context should never grow — it reads summaries, not raw details
- Scripts handle anything where "the AI does whatever it feels like" has burned you before
- Preserve all existing functionality — this is a restructure, not a rewrite

Please read the skill file and produce the spec. Don't implement yet — just the plan.
