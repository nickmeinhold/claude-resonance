# Claude Resonance

Autonomous system prompt evolution — discovers what makes Claude resonate
through a Researcher → Subject → Evaluator pipeline.

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
  --output-dir data/experiments

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
