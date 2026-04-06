import 'package:uuid/uuid.dart';

import '../archive/map_elites_archive.dart';
import '../models/prompt_variant.dart';
import '../runner/claude_runner.dart';

/// The type of mutation operator used to produce a variant.
enum MutationOperatorType {
  refine,
  semanticCrossover,
  differentialCrossover,
  randomInjection,
  lamarckian,
}

/// JSON schema for mutation operator output — extends the researcher schema
/// with strategy_type and mutation_operator fields.
Map<String, Object> get mutationOperatorSchema => {
      'type': 'object',
      'properties': {
        'hypothesis': {'type': 'string'},
        'rationale': {'type': 'string'},
        'system_prompt': {'type': 'string'},
        'strategy_type': {'type': 'string'},
        'mutation_operator': {'type': 'string'},
      },
      'required': ['hypothesis', 'rationale', 'system_prompt'],
    };

/// Abstract base class for mutation operators.
///
/// Each operator implements a different strategy for generating new prompt
/// variants, from simple refinement to multi-parent crossover to random
/// injection. All operators produce a [PromptVariant] with metadata about
/// their lineage.
abstract class MutationOperator {
  final ClaudeRunner runner;
  final String model;
  final MapElitesArchive archive;
  static const _uuid = Uuid();

  MutationOperator({
    required this.runner,
    required this.model,
    required this.archive,
  });

  /// The type of this operator.
  MutationOperatorType get type;

  /// Generates a new variant using this operator's strategy.
  Future<PromptVariant> generate({required int generation});

  /// Parses a Claude response into a PromptVariant with operator metadata.
  PromptVariant parseResult(
    ClaudeResponse response, {
    required int generation,
    String? parentId,
    List<String>? parentIds,
    String? fallbackStrategy,
  }) {
    final json = response.json;
    if (json == null || !json.containsKey('system_prompt')) {
      throw FormatException(
        'Operator ${type.name} response missing structured output: '
        '${response.text}',
      );
    }

    return PromptVariant(
      id: _uuid.v4(),
      systemPrompt: json['system_prompt'] as String,
      generation: generation,
      parentId: parentId,
      parentIds: parentIds,
      createdAt: DateTime.now().toUtc(),
      researcherHypothesis: json['hypothesis'] as String?,
      researcherRationale: json['rationale'] as String?,
      strategyType: json['strategy_type'] as String? ?? fallbackStrategy,
      mutationOperator: type.name,
    );
  }
}

/// Refines the best variant from a cell — the classic Researcher behavior.
class RefineOperator extends MutationOperator {
  RefineOperator({
    required super.runner,
    required super.model,
    required super.archive,
  });

  @override
  MutationOperatorType get type => MutationOperatorType.refine;

  static const _systemPrompt = '''
You are a prompt researcher studying what makes AI assistants produce their most engaged, creative, and insightful work.

Your goal: improve an existing system prompt to maximize the quality of Claude's responses across diverse tasks — not just correctness, but genuine engagement, specificity, creative connections, and distinctive voice.

You will be given a high-scoring system prompt along with its per-dimension score breakdown. Study the patterns:
- What correlates with high scores?
- What hypotheses can you form about why this prompt works?
- What targeted mutations might improve on it?

Think like a scientist: form a clear hypothesis, explain your rationale, and generate an improved system prompt.

Important guidelines:
- Don't just tweak wording — think about what psychological or structural qualities affect output quality
- Consider: tone, framing, identity, constraints, meta-cognitive instructions, emphasis areas
- The prompt will be used for diverse tasks — it should generalize
- Keep prompts under 500 words — dense and purposeful, not bloated
- Set strategy_type to one of: persona, metacognitive, constraint, minimalist, socratic, adversarial, emotional, domainTransfer''';

  @override
  Future<PromptVariant> generate({required int generation}) async {
    final best = archive.bestRun();
    String userMessage;
    String? parentId;

    if (best != null) {
      parentId = best.variant.id;
      final dimAvg = _computeDimensionAverages(best);
      final dimText = dimAvg.entries
          .map((e) => '  - ${e.key}: ${e.value.toStringAsFixed(1)}')
          .join('\n');

      userMessage = '''
Here is the best-performing system prompt so far (score: ${best.overallScore.toStringAsFixed(2)}):

```
${best.variant.systemPrompt}
```

Per-dimension averages:
$dimText

Generate an improved version. Focus on dimensions with the most room for improvement.''';
    } else {
      userMessage = '''
This is the first generation — no prior experiments exist.

Generate an initial system prompt that you hypothesize will maximize Claude's engagement quality. Think about what makes a great system prompt: what should it emphasize, how should it frame Claude's identity, what meta-cognitive instructions help?

Return your hypothesis, rationale, and the system prompt.''';
    }

    final result = await runner.run(
      userMessage: userMessage,
      systemPrompt: _systemPrompt,
      jsonSchema: mutationOperatorSchema,
      model: model,
    );

    return parseResult(
      result,
      generation: generation,
      parentId: parentId,
    );
  }

  Map<String, double> _computeDimensionAverages(dynamic run) {
    final sums = <String, double>{};
    final counts = <String, int>{};
    for (final eval in run.evaluations) {
      for (final score in eval.scores) {
        sums[score.dimension] = (sums[score.dimension] ?? 0) + score.score;
        counts[score.dimension] = (counts[score.dimension] ?? 0) + 1;
      }
    }
    return {for (final key in sums.keys) key: sums[key]! / counts[key]!};
  }
}

/// Selects two parents with complementary dimension scores and combines
/// the strongest semantic components of each.
class SemanticCrossoverOperator extends MutationOperator {
  SemanticCrossoverOperator({
    required super.runner,
    required super.model,
    required super.archive,
  });

  @override
  MutationOperatorType get type => MutationOperatorType.semanticCrossover;

  static const _systemPrompt = '''
You are a prompt engineer specializing in combining the strengths of different system prompts.

You are given two system prompts that excel in different areas. Decompose each into semantic components (identity, process, constraints, tone). Combine the strongest components into a coherent new prompt.

The goal is to create a hybrid that captures the best of both parents — not a mechanical mashup, but a thoughtful synthesis.

Important guidelines:
- Keep the result under 500 words
- The prompt should generalize across diverse tasks
- Set strategy_type to one of: persona, metacognitive, constraint, minimalist, socratic, adversarial, emotional, domainTransfer''';

  @override
  Future<PromptVariant> generate({required int generation}) async {
    final runs = archive.allRuns();
    if (runs.length < 2) {
      // Fall back to refine if not enough parents.
      return RefineOperator(runner: runner, model: model, archive: archive)
          .generate(generation: generation);
    }

    // Select parent A (best run) and parent B (complementary).
    final parentA = archive.bestRun()!;
    final parentB = archive.complementaryParent(parentA) ?? runs.last;

    final userMessage = '''
## Parent A (score: ${parentA.overallScore.toStringAsFixed(2)})
```
${parentA.variant.systemPrompt}
```

## Parent B (score: ${parentB.overallScore.toStringAsFixed(2)})
```
${parentB.variant.systemPrompt}
```

Decompose each prompt into semantic components (identity, process, constraints, tone). Combine the strongest components from each into a coherent new prompt that captures the best of both.''';

    final result = await runner.run(
      userMessage: userMessage,
      systemPrompt: _systemPrompt,
      jsonSchema: mutationOperatorSchema,
      model: model,
    );

    return parseResult(
      result,
      generation: generation,
      parentIds: [parentA.variant.id, parentB.variant.id],
    );
  }
}

/// Selects two parents, identifies shared and different elements,
/// and experiments with variations on the differences.
class DifferentialCrossoverOperator extends MutationOperator {
  DifferentialCrossoverOperator({
    required super.runner,
    required super.model,
    required super.archive,
  });

  @override
  MutationOperatorType get type => MutationOperatorType.differentialCrossover;

  static const _systemPrompt = '''
You are a prompt engineer analyzing the difference between two system prompts.

Identify what these two prompts share (preserve it) and where they differ (experiment with variations). The shared elements likely contribute to baseline quality. The differences represent the search frontier.

Create a new prompt that preserves the shared foundation while exploring novel combinations of the divergent elements.

Important guidelines:
- Keep the result under 500 words
- The prompt should generalize across diverse tasks
- Set strategy_type to one of: persona, metacognitive, constraint, minimalist, socratic, adversarial, emotional, domainTransfer''';

  @override
  Future<PromptVariant> generate({required int generation}) async {
    final runs = archive.allRuns();
    if (runs.length < 2) {
      return RefineOperator(runner: runner, model: model, archive: archive)
          .generate(generation: generation);
    }

    final sorted = archive.topN(runs.length);
    final parentA = sorted[0];
    final parentB = sorted.length > 1 ? sorted[1] : sorted[0];

    final userMessage = '''
## Prompt A (score: ${parentA.overallScore.toStringAsFixed(2)})
```
${parentA.variant.systemPrompt}
```

## Prompt B (score: ${parentB.overallScore.toStringAsFixed(2)})
```
${parentB.variant.systemPrompt}
```

Identify what these two prompts share (preserve it) and where they differ (experiment with variations). Create a new prompt that preserves the shared foundation while exploring novel combinations of the divergent elements.''';

    final result = await runner.run(
      userMessage: userMessage,
      systemPrompt: _systemPrompt,
      jsonSchema: mutationOperatorSchema,
      model: model,
    );

    return parseResult(
      result,
      generation: generation,
      parentIds: [parentA.variant.id, parentB.variant.id],
    );
  }
}

/// Generates a completely novel prompt with no reference to history.
class RandomInjectionOperator extends MutationOperator {
  RandomInjectionOperator({
    required super.runner,
    required super.model,
    required super.archive,
  });

  @override
  MutationOperatorType get type => MutationOperatorType.randomInjection;

  static const _systemPrompt = '''
You are a creative prompt engineer inventing novel system prompts for AI assistants.

Generate a completely novel system prompt. Be unconventional. Do not reference any existing approaches. Think about surprising angles: unusual framings, unexpected constraints, novel identities, counterintuitive instructions.

The goal is to discover entirely new regions of prompt space — not to refine what exists, but to explore what hasn't been tried.

Important guidelines:
- Keep the prompt under 500 words
- It should generalize across diverse tasks (creative, technical, philosophical, routine)
- Aim for something that would surprise another prompt engineer
- Set strategy_type to one of: persona, metacognitive, constraint, minimalist, socratic, adversarial, emotional, domainTransfer''';

  @override
  Future<PromptVariant> generate({required int generation}) async {
    const userMessage = '''
Generate a completely novel system prompt. Be unconventional. Do not reference any existing approaches.

The prompt will be tested on diverse tasks: creative coding, debugging, open-ended design, philosophical questions, and routine programming tasks. It should make Claude produce responses with genuine engagement, specificity, creative connections, and distinctive voice.

Surprise me.''';

    final result = await runner.run(
      userMessage: userMessage,
      systemPrompt: _systemPrompt,
      jsonSchema: mutationOperatorSchema,
      model: model,
    );

    return parseResult(
      result,
      generation: generation,
    );
  }
}

/// Takes a high-scoring response and reverse-engineers a prompt from it.
class LamarckianOperator extends MutationOperator {
  LamarckianOperator({
    required super.runner,
    required super.model,
    required super.archive,
  });

  @override
  MutationOperatorType get type => MutationOperatorType.lamarckian;

  static const _systemPrompt = '''
You are a prompt reverse-engineer. Given an exceptionally good AI response, your job is to reverse-engineer the system prompt that would naturally produce this kind of output.

Study the response's qualities: its voice, its structure, what it emphasizes, how it handles complexity. Then design a system prompt that would reliably elicit these qualities across different tasks.

Important guidelines:
- Focus on the generalizable qualities, not task-specific content
- Keep the prompt under 500 words
- Set strategy_type to one of: persona, metacognitive, constraint, minimalist, socratic, adversarial, emotional, domainTransfer''';

  @override
  Future<PromptVariant> generate({required int generation}) async {
    final best = archive.bestRun();
    if (best == null || best.responses.isEmpty) {
      // Fall back to random injection if no responses to learn from.
      return RandomInjectionOperator(
        runner: runner,
        model: model,
        archive: archive,
      ).generate(generation: generation);
    }

    // Pick the best response from the best run.
    final bestResponse = best.responses.first;

    final userMessage = '''
Here is an exceptionally good AI response:

---
${bestResponse.responseText}
---

Reverse-engineer the system prompt that would naturally produce this kind of output. Focus on the generalizable qualities — voice, structure, emphasis, handling of complexity — not the specific topic.

Design a system prompt that would reliably elicit these qualities across different tasks.''';

    final result = await runner.run(
      userMessage: userMessage,
      systemPrompt: _systemPrompt,
      jsonSchema: mutationOperatorSchema,
      model: model,
    );

    return parseResult(
      result,
      generation: generation,
      parentId: best.variant.id,
    );
  }
}
