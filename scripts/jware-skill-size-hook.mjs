#!/usr/bin/env node
/**
 * JWare Skill Size Monitor
 * Fires on SessionStart. Scans all skill and engine module files
 * for size. Warns if any exceed thresholds.
 *
 * Thresholds:
 *   WARNING:  > 200 lines — getting large, plan a refactor
 *   CRITICAL: > 400 lines — AI deprioritization likely, refactor now
 */

import { readFileSync, readdirSync, statSync, existsSync } from "node:fs";
import { join } from "node:path";

const JWARE_ROOT = process.env.JWARE_HOME || process.env.HOME + "/.jware";
const WARN_THRESHOLD = 200;
const CRIT_THRESHOLD = 400;

function countLines(filePath) {
  try {
    const content = readFileSync(filePath, "utf8");
    return content.split("\n").length;
  } catch {
    return 0;
  }
}

function scanDir(dir, pattern) {
  const results = [];
  if (!existsSync(dir)) return results;

  try {
    const entries = readdirSync(dir, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = join(dir, entry.name);
      if (entry.isDirectory()) {
        // Check for SKILL.md inside skill directories
        const skillFile = join(fullPath, "SKILL.md");
        if (existsSync(skillFile)) {
          results.push({ path: skillFile, name: entry.name, type: "skill" });
        }
      } else if (entry.isFile() && entry.name.endsWith(".md")) {
        results.push({ path: fullPath, name: entry.name, type: "engine" });
      }
    }
  } catch {
    // Directory not readable
  }
  return results;
}

// Scan skills and engine modules
const files = [
  ...scanDir(join(JWARE_ROOT, "skills"), "SKILL.md"),
  ...scanDir(join(JWARE_ROOT, "engine"), "*.md"),
];

const warnings = [];
const criticals = [];

for (const file of files) {
  const lines = countLines(file.path);
  if (lines > CRIT_THRESHOLD) {
    criticals.push({ ...file, lines });
  } else if (lines > WARN_THRESHOLD) {
    warnings.push({ ...file, lines });
  }
}

// Build output
if (criticals.length === 0 && warnings.length === 0) {
  // All clear — no output needed
  process.exit(0);
}

const parts = [];

if (criticals.length > 0) {
  parts.push("SKILL SIZE ALERT — Files exceeding " + CRIT_THRESHOLD + " lines (AI deprioritization likely):");
  for (const f of criticals) {
    parts.push(`  CRITICAL: ${f.type}/${f.name} — ${f.lines} lines`);
  }
}

if (warnings.length > 0) {
  if (parts.length > 0) parts.push("");
  parts.push("Skill size warnings — Files exceeding " + WARN_THRESHOLD + " lines (plan a refactor):");
  for (const f of warnings) {
    parts.push(`  WARNING: ${f.type}/${f.name} — ${f.lines} lines`);
  }
}

parts.push("");
parts.push("Run /jware-status or check docs/specs/2026-04-05-skill-modular-rebuild.md for the refactor plan.");

// Output as hook context
const output = JSON.stringify({ additionalContext: parts.join("\n") });
process.stdout.write(output);
