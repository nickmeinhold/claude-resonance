# Claude Resonance

Autonomous system prompt evolution — discovers what makes Claude resonate
through a Researcher → Subject → Evaluator pipeline.

## ▶ Next crux (read first)

The CLAUDE.md/auto-memory leak is **fixed** (`fix/isolate-claude-md-leak`) — the
pipeline now generates its own ideas instead of echoing the operator's doctrine.
The first clean run exposed the next problem: **top-end evaluator compression**
(Opus-grading-Opus can tell bad prompts from good, but can't rank the *best*
ones apart — they cluster ~4.8–4.9).

The proposed fix is a **cross-family tie-breaker** (Gemini + Codex judge only the
top-end ties, bounded by a hard quota cap because they're Pro-plan limited).
Full design, constraints, isolation requirements, and open decisions:
**[`docs/design/cross-family-evaluator.md`](docs/design/cross-family-evaluator.md)**.
Start there.

**The law:** no evolution run launches without a green contamination probe first
(`dart run bin/probe.dart --model opus` → must print `✅ CLEAN`).

## Build

```bash
dart pub get
dart run build_runner build --delete-conflicting-outputs
```

## Test

```bash
dart test
```

## Run

```bash
# ALWAYS gate a run on a green contamination probe first (the law):
dart run bin/probe.dart --model opus   # must print: ✅ CLEAN

# Default: 5 generations, opus for all roles
dart run

# Custom configuration (note: no `--` separator — it's read as an arg)
dart run bin/claude_resonance.dart \
  --generations 10 \
  --researcher-model opus \
  --subject-model opus \
  --evaluator-model opus \
  --output-dir data/experiments \
  --no-budget

# Quick test run
dart run bin/claude_resonance.dart --generations 2
```

## Project Structure

- `lib/src/models/` — Freezed data models (PromptVariant, ExperimentRun, etc.)
- `lib/src/runner/` — ClaudeRunner abstraction (ProcessClaudeRunner + MockClaudeRunner)
- `lib/src/pipeline/` — Researcher, Subject, Evaluator, ExperimentRunner
- `lib/src/rubric/` — 6-dimension evaluation rubric with weights
- `lib/src/battery/` — 5 fixed test tasks
- `lib/src/storage/` — JSON file persistence with atomic writes
- `data/seed_prompts/` — Initial prompt variants (baseline, persona, metacognitive)
- `data/experiments/` — Output: per-generation JSON + experiment log

## Architecture

Each pipeline role calls Claude via `claude -p` with `--output-format json`,
`--json-schema` (for Evaluator/Researcher), and `--dangerously-skip-permissions`.
The `ClaudeRunner` interface makes everything testable with `MockClaudeRunner`.
