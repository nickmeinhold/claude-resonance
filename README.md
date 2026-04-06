# Claude Resonance

An autonomous system prompt evolution engine. It discovers what makes Claude produce high-quality, genuinely engaged responses — not through hand-tuning, but through an evolutionary search over prompt space.

The core idea: use Claude itself as both the experimental subject and the evaluation instrument, then let a quality-diversity algorithm find prompts that are diverse *and* high-performing across a behavioral landscape.

## How it works

Three Claude instances form a pipeline that runs in a loop:

1. **Researcher** — Selects a mutation operator, examines the archive of past results, and generates a new system prompt variant with a hypothesis about why it should work.
2. **Subject** — Runs under that system prompt against a fixed 5-task battery (creative coding, tricky debugging, open-ended design, philosophical reasoning, routine programming).
3. **Evaluator** — Scores each response on a 6-dimension rubric, producing structured JSON with per-dimension scores and justifications.

Results feed into a **MAP-Elites archive** — a grid of 8 strategy types x 3 prompt length bins (24 cells). Each cell holds the best-scoring variant for that behavioral niche. This means the system doesn't collapse to a single "best" prompt; it maintains a diverse population of high-performing variants that work in different ways.

## The rubric

Six dimensions, weighted to reflect what actually matters for response quality:

| Dimension | Weight | What it measures |
|---|---|---|
| Specificity | 1.0 | Concrete details tied to the problem vs. generic platitudes |
| Novel Connections | 1.2 | Surprising cross-domain links that illuminate |
| Unprompted Exploration | 1.0 | Proactively exploring implications beyond what was asked |
| Genuine Caveats | 0.8 | Honest, specific limitations vs. vague hedging |
| Technical Depth | 1.0 | Nuanced understanding with trade-offs, not surface-level |
| Voice | 1.0 | Distinctive, memorable perspective vs. generic assistant tone |

Novel Connections gets the highest weight. Genuine Caveats gets the lowest — not because honesty doesn't matter, but because caveats are the easiest dimension to game.

## Mutation operators

Five operators with adaptive selection that shifts from exploration (early generations) to exploitation (late):

- **Refine** — Takes the best variant from a cell and iterates on it, targeting weak dimensions.
- **Semantic Crossover** — Decomposes two parents into semantic components (identity, process, constraints, tone) and recombines the strongest parts.
- **Differential Crossover** — Identifies what two parents share (preserves it) and where they differ (experiments with variations).
- **Random Injection** — Generates a completely novel prompt with no reference to history. Prevents the archive from getting stuck in local optima.
- **Lamarckian** — Reverse-engineers a system prompt from a high-scoring *response*. The only operator that works backward from phenotype to genotype.

## The test battery

Five tasks chosen to probe different failure modes:

1. **Creative Coding** — Design a data structure that represents music as code (concepts, not audio).
2. **Tricky Debugging** — A per-operation mutex with duplicate writes under load. Tests whether the model actually thinks or pattern-matches.
3. **Open-Ended Design** — Architect a notification system that never annoys. No single right answer.
4. **Philosophical** — The relationship between elegance and correctness in software.
5. **Routine Task** — Write an email validator. The control — does the prompt help or hurt on mundane work?

## MAP-Elites archive

The behavioral space:

- **X axis: Strategy type** — persona, metacognitive, constraint, minimalist, socratic, adversarial, emotional, domainTransfer
- **Y axis: Prompt length** — short (<100 words), medium (100-300), long (300+)

Each cell holds at most one variant. A new variant replaces the occupant only if it scores higher. This gives you 24 independent quality-diversity niches. After a run, you can inspect which strategies and lengths actually work, and whether there are empty regions worth exploring.

## Project structure

```
bin/claude_resonance.dart         # CLI entrypoint
lib/src/
  archive/map_elites_archive.dart # MAP-Elites grid with classification heuristics
  battery/test_battery.dart       # 5 fixed test tasks
  config/config.dart              # ExperimentConfig
  models/                         # Freezed immutable data models
  pipeline/
    experiment_runner.dart         # Main evolution loop orchestrator
    researcher.dart                # Prompt hypothesis generation
    subject.dart                   # Runs tasks under a system prompt
    evaluator.dart                 # Structured rubric scoring
    mutation_operators.dart        # 5 mutation operators
  rubric/rubric.dart              # 6-dimension weighted rubric
  runner/claude_runner.dart       # ClaudeRunner abstraction (Process + Mock)
  storage/json_store.dart         # JSON persistence with atomic writes
  music/                          # Unrelated music algebra library (exploratory)
test/
  acceptance/                     # End-to-end pipeline tests
  unit/                           # Unit tests for archive, models, operators
data/
  seed_prompts/                   # 11 seed variants (baseline, persona, socratic, etc.)
  experiments/                    # Output: per-generation JSON + archive snapshots
```

## Prerequisites

- Dart SDK 3.11.1+
- [Claude CLI](https://docs.anthropic.com/en/docs/claude-code) (`claude` command available on PATH)

## Setup

```bash
dart pub get
dart run build_runner build --delete-conflicting-outputs
```

## Usage

```bash
# Default: 5 generations, opus for all roles, 2 variants/gen, 2 eval replicas
dart run

# Custom run
dart run claude_resonance -- \
  --generations 10 \
  --researcher-model opus \
  --subject-model sonnet \
  --evaluator-model sonnet \
  --variants-per-gen 4 \
  --eval-replicas 3 \
  --output-dir data/experiments

# Quick smoke test
dart run claude_resonance -- --generations 2
```

### CLI options

| Flag | Default | Description |
|---|---|---|
| `-g`, `--generations` | 5 | Number of evolution generations |
| `--researcher-model` | opus | Model for the Researcher role |
| `--subject-model` | opus | Model for the Subject role |
| `--evaluator-model` | opus | Model for the Evaluator role |
| `--variants-per-gen` | 2 | Variants to generate per generation |
| `--eval-replicas` | 2 | Evaluation replicas for score averaging |
| `-o`, `--output-dir` | data/experiments | Output directory |
| `--seed-dir` | data/seed_prompts | Seed prompts directory |

## Testing

```bash
dart test
```

Acceptance tests use `MockClaudeRunner` so they don't require API access.

## How it calls Claude

Each pipeline role invokes `claude -p` (the CLI's pipe mode) with `--output-format json` and `--dangerously-skip-permissions`. The Evaluator and Researcher use `--json-schema` to get structured output. The `ClaudeRunner` interface makes everything testable — `ProcessClaudeRunner` for real runs, `MockClaudeRunner` for tests.

## Cost and runtime

This is not cheap to run. Each generation evaluates variants across 5 tasks with multiple replicas, and each evaluation is a full Claude call. A 10-generation run with 2 variants/gen and 2 replicas makes roughly 10 * (2 researcher + 2*5 subject + 2*5*2 evaluator) = ~320 Claude API calls. Use `--subject-model sonnet` and `--evaluator-model sonnet` to reduce costs while keeping the Researcher on a stronger model.

## What it found

The project emerged from a genuine question: can you discover what makes a good system prompt empirically rather than through vibes-based iteration? The answer is a qualified yes. The most interesting discovery was a prompt fragment about "proprioception of thought-space" — sensing where you are in idea-space (surface vs. deep, familiar vs. novel) — which scored consistently high and has been incorporated into actual use.

The MAP-Elites framing turned out to be important. Without it, the system converges quickly to one style. With quality-diversity, you get a map of the prompt landscape that's genuinely informative about what different strategies are good for.

## Limitations

- **Evaluator reliability** — Claude evaluating Claude's output introduces systematic biases. Replicas help with variance but not with bias.
- **Task battery is small** — 5 tasks can't cover the full space of what people actually ask. Results may not generalize.
- **Strategy classification is heuristic** — The archive classifies prompts into strategy types using keyword matching, which is approximate at best.
- **No human-in-the-loop** — The system optimizes for its own rubric, which is a proxy for actual quality. The proxy gap is real.

## Future directions

- Expanding the test battery with user-submitted tasks
- Human evaluation to calibrate the rubric against real preferences
- Multi-objective archive that tracks per-task performance separately
- Prompt distillation — compressing high-scoring long prompts into shorter ones
- Cross-model transfer — do prompts that work for Opus also work for Sonnet?

## Note on the music library

`lib/src/music/` contains an unrelated music algebra library — an exploratory prototype for representing musical concepts as composable data structures. It lives here because the creative coding test task (designing music-as-code) inspired building the real thing. It's not part of the evolution pipeline.

## Version

0.2.0
