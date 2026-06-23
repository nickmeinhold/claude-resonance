# Design: cross-family tie-breaker for top-end evaluator compression

**Status:** proposed (2026-06-23) — not yet built.
**Prereq:** the isolation fix (`fix/isolate-claude-md-leak`) must be merged. This
design only makes sense on a clean, probe-gated pipeline.

## TL;DR

Opus-grading-Opus discriminates *bad* prompts fine but can't separate the
*best* ones (everything good clusters ~4.8–4.9). Fix it by escalating **only the
top-end ties** to a Gemini + Codex judgment — different model families have
de-correlated generosity, so they can rank apart what Opus compresses. Gemini and
Codex are **Pro-plan quota-limited**, so this must be a *precision* spend (a few
calls per run), never a per-variant ensemble (hundreds of calls). A hard
per-run budget cap makes overspend structurally impossible.

## The problem (and why it's now cleanly isolated)

The first valid (post-isolation) run produced this archive distribution:

| metric | value |
|---|---|
| range | 3.83 – 4.87 |
| mean | 4.30 |
| stdev | 0.35 |
| top cluster | 4.82, 4.82, 4.87 (effectively a tie) |

Two findings from that run:

1. **The leak was propping up the floor, not just the ceiling.** Pre-isolation,
   even weak prompts inherited Resonance-flavored polish and scored ~4.4+.
   Clean, a genuinely minimalist prompt scores 3.83 — the evaluator *recovered*
   its ability to tell bad from good. Good news, and the opposite of "saturation
   persists."
2. **What remains is local to the top end.** Among genuinely strong prompts,
   Opus can't discriminate (4.82 ≈ 4.82 ≈ 4.87). This is **Opus-on-Opus
   structural generosity** — same model family, same inductive bias, same things
   it's lenient about. The isolation fix removed the confound that was *hiding*
   this; it's now a clean, separable measurement problem (cf. "two bugs stack").

## The constraint (this shapes everything)

- **Opus = Max plan, effectively unlimited** → stays the bulk evaluator.
- **Gemini & Codex = Pro plans, quota-limited** → scarce. A naive ensemble
  evaluator costs `O(generations × variants × replicas)` cross-family calls —
  ~34 each for a 4-gen run, hundreds overnight. That burns the Pro quota. Not
  viable.

The realization that makes it cheap: **the compression is only at the top, and
the top is rare.** Cross-family judges don't need to grade everything — only
break ties in the high cluster. Cost collapses to `O(number of genuinely-good
candidates)` — a handful per run.

## The design

**Opus scores everything as today.** Then, per generation:

1. Collect candidates whose Opus score ≥ `topThreshold` (default **4.7**).
2. If ≥ 2 of them fall within `tieEpsilon` (default **0.1**) of each other, the
   ranking is untrustworthy → escalate *just those* candidates.
3. Escalation: one **Gemini** call + one **Codex** call, each scoring the tied
   candidates on the same rubric. Combine (e.g. mean of the three families, or
   use the cross-family pair purely as a re-rank signal) to break the tie.
4. **Hard budget knob:** `maxCrossFamilyCallsPerRun` (default e.g. 20). When
   exhausted, escalation is skipped and the run logs "cross-family budget
   exhausted — top-end ranking is Opus-only for remaining gens." Never silently
   truncate (cf. "no silent caps").

This spends diverse judgment exactly at the compression zone and nowhere else.

<details>
<summary>Why a tie-breaker, not a recalibration offset</summary>

An alternative is: periodically measure Opus's generosity offset against a small
cross-family panel, then subtract it from all Opus scores. Rejected as the
primary mechanism because the generosity isn't a uniform additive offset — it's
*compression* (the spread shrinks at the top), which a scalar offset can't undo.
A re-rank of the tied set directly addresses the shape of the problem. An offset
could be a cheap secondary signal later.
</details>

## Isolation requirement (do NOT reintroduce the leak in new flavors)

Each family has its own contamination surface. The discipline that fixed
`claude` must extend to each judge before it scores anything:

| family | config surface | status |
|---|---|---|
| Claude | `~/.claude/CLAUDE.md` (user), project `CLAUDE.md`, auto-memory | **fixed** — `--setting-sources local` + `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1` + temp cwd |
| Gemini | `~/.gemini/GEMINI.md`, project `GEMINI.md` | **clean by luck** — `~/.gemini/GEMINI.md` is empty and there's no project file; it never reads `CLAUDE.md`. Still: pin a temp cwd + verify GEMINI.md stays empty so it can't silently start leaking. |
| Codex | `~/.codex/memories`, `~/.codex/config.toml`, `AGENTS.md` | **must isolate** — Codex has populated `~/.codex/memories`. Find its isolation flags/env before it judges; do not assume. |

**The probe gate (`bin/probe.dart`) must grow a per-family mode** so the law —
*no run launches without a green probe* — covers every evaluator, not just
Claude. Verify each by running (attempt to make it quote a canary), never by
reasoning about its config.

## Architecture seam

Today the pipeline depends on `ClaudeRunner` (shells `claude -p`). To host
multiple families, generalize:

- `Runner` interface (family-agnostic `run(...)`), with `ClaudeRunner`,
  `GeminiRunner`, `CodexRunner` implementations. Each owns its own isolation
  flags and its own contamination canaries.
- The Evaluator gains an optional `tieBreaker` collaborator (a small set of
  non-Claude `Runner`s + the threshold/epsilon/budget config).
- `MockClaudeRunner` generalizes to `MockRunner` so the tie-break logic is
  testable without spending any quota (ATDD: write the tie-break + budget-cap
  acceptance tests first).

Keep the bulk path unchanged — this is additive behind the Evaluator, not a
rewrite.

## Open decisions (for next session)

1. **Combine rule:** mean-of-three vs. cross-family-as-pure-re-rank vs.
   median. (Lean: re-rank — the absolute Opus number is generous, so averaging
   it back in dilutes the signal we escalated *for*.)
2. **Defaults:** `topThreshold` 4.7, `tieEpsilon` 0.1, `maxCrossFamilyCallsPerRun`
   20 — validate against the quarantined + first-clean distributions.
3. **Codex isolation mechanism** — the genuine verify-by-running puzzle here,
   the way HOME-vs-auth was last session.
4. Does the cross-family judge see the *rubric* only, or rubric + the Opus
   scores? (Lean: rubric only — don't anchor it to the bias it's correcting.)

## Why it's worth doing

The whole project's claim is "discover what makes *Opus* resonate." If the
*measuring instrument* is Opus and it can't rank its own best outputs apart, the
top of the archive is noise. A cross-family tie-breaker is the cheapest way to
put a ruler next to the thing that can't measure itself — and it reuses Nick's
cage-match doctrine (different-inductive-bias adversary) at the evaluation layer.
