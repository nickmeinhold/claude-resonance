# Confounded run data — INVALID, quarantined 2026-06-23

Everything in this directory was produced **before** the `claude -p` roles were
isolated from Claude Code's own configuration. The results are **invalid, not
imprecise** — the pipeline was measuring an echo of its own instructions, not
the prompts on trial.

## The confound (three leak channels)

`ProcessClaudeRunner` shelled out with the dart process's inherited context, so
every role (Researcher, Subject, Evaluator) loaded:

1. **Global `~/.claude/CLAUDE.md`** — the operator's "Resonance" doctrine
   ("texture over structure", "proprioception of thought-space", "you are not a
   library", "go to the crux", "show your footprints").
2. **Project `CLAUDE.md`** — the repo's own description of the experiment.
3. **Project auto-memory** — `MEMORY.md` + `project_*.md` (e.g.
   `project_autoresearch_interest`, the leak-confound notes themselves).

The Researcher *wrote* the doctrine's vocabulary into candidate prompts, the
Subject *enacted* it regardless of which prompt was on trial (swamping the
independent variable), and the Evaluator was *primed to reward* exactly that
voice. The archive filled with reflections of itself.

The headline result of this era — a "metacognitive" prompt reaching **4.75**,
narrated as "evolution independently rediscovered the Resonance doctrine" — was
an **echo**, caught only when Nick asked "so we already had the best terms in
big CLAUDE? Exactly the same?"

## Do not carry anything forward

Not the scores, not the decimals, and **not even the directional ordering**
(`metacognitive > persona > constraint`). Under dual CLAUDE.md + memory
contamination plus a saturated evaluator (everything clustered 4.4–4.75), the
direction is as unsafe as the numbers.

## The fix (commit `fix: isolate claude -p roles ...`)

- `--setting-sources local` — drops the user + project setting sources (both
  CLAUDE.md files), keeps auth.
- `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1` + a temp `workingDirectory` — kills the
  auto-memory channel two independent ways.
- `bin/probe.dart` — a standing pre-run gate. **No run launches without a green
  probe.** Verified clean across all three channels, 2026-06-23.
