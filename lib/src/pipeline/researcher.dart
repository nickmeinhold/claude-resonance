import 'dart:math';

import 'package:uuid/uuid.dart';

import '../archive/map_elites_archive.dart';
import '../models/evaluation_result.dart';
import '../models/experiment_run.dart';
import '../models/prompt_variant.dart';
import '../rubric/rubric.dart';
import '../runner/claude_runner.dart';
import 'mutation_operators.dart';

/// Reads experiment history, hypothesizes what makes Claude resonate,
/// and generates new prompt variants.
///
/// The Researcher's meta-prompt includes the top-N previous variants
/// with per-dimension score breakdowns, encouraging hypothesis-driven
/// mutations rather than random perturbation.
class Researcher {
  final ClaudeRunner _runner;
  final String _model;
  final int _topN;
  static const _uuid = Uuid();
  final Random _random;

  Researcher(
    this._runner, {
    String model = 'sonnet',
    int topN = 3,
    Random? random,
  })  : _model = model,
        _topN = topN,
        _random = random ?? Random();

  static const _systemPrompt = '''
You are a prompt researcher studying what makes AI assistants produce their most engaged, creative, and insightful work.

Your goal: design system prompts that maximize the quality of Claude's responses across diverse tasks — not just correctness, but genuine engagement, specificity, creative connections, and distinctive voice.

You will be given the results of previous experiments: system prompts that were tested, along with their scores on 6 dimensions. Study the patterns:
- What correlates with high scores?
- What hypotheses can you form about why certain prompts work?
- What mutations might improve on the best variants?

Think like a scientist: form a clear hypothesis, explain your rationale, and generate a new system prompt to test it.

Important guidelines:
- Don't just tweak wording — think about what psychological or structural qualities of the prompt affect output quality
- Consider: tone, framing, identity, constraints, meta-cognitive instructions, emphasis areas
- The system prompt will be used for diverse tasks (creative, debugging, design, philosophical, routine) — it should generalize
- Keep prompts under 500 words — dense and purposeful, not bloated''';

  /// Generates a new prompt variant based on experiment history (v1 — backward compat).
  Future<PromptVariant> generateVariant({
    required List<ExperimentRun> history,
    required int generation,
  }) async {
    final userMessage = _buildUserMessage(history);

    final result = await _runner.run(
      userMessage: userMessage,
      systemPrompt: _systemPrompt,
      jsonSchema: Rubric.researcherSchema,
      model: _model,
    );

    return _parseResult(result, generation, history);
  }

  /// Generates a new variant using MAP-Elites adaptive operator selection (v2).
  Future<PromptVariant> generateVariantV2({
    required MapElitesArchive archive,
    required int generation,
    required int maxGenerations,
  }) async {
    final operatorType = selectOperator(generation, maxGenerations, archive);

    final operator = _createOperator(operatorType, archive);
    return operator.generate(generation: generation);
  }

  /// Selects a mutation operator based on an adaptive schedule.
  ///
  /// The schedule shifts from exploration (random injection) early on
  /// to exploitation (refine, lamarckian) in later generations.
  MutationOperatorType selectOperator(
    int generation,
    int maxGenerations,
    MapElitesArchive archive,
  ) {
    final progress = maxGenerations > 0 ? generation / maxGenerations : 0.0;
    final roll = _random.nextDouble();

    if (progress < 0.3) {
      // Early: heavy exploration.
      // 20% bisociative, 30% random, 25% refine, 15% semantic, 10% differential
      if (roll < 0.20) return MutationOperatorType.bisociativeRecombination;
      if (roll < 0.50) return MutationOperatorType.randomInjection;
      if (roll < 0.75) return MutationOperatorType.refine;
      if (roll < 0.90) return MutationOperatorType.semanticCrossover;
      return MutationOperatorType.differentialCrossover;
    } else if (progress < 0.7) {
      // Mid: balanced.
      // 12% bisociative, 18% random, 25% refine, 22% semantic, 13% differential, 10% lamarckian
      if (roll < 0.12) return MutationOperatorType.bisociativeRecombination;
      if (roll < 0.30) return MutationOperatorType.randomInjection;
      if (roll < 0.55) return MutationOperatorType.refine;
      if (roll < 0.77) return MutationOperatorType.semanticCrossover;
      if (roll < 0.90) return MutationOperatorType.differentialCrossover;
      return MutationOperatorType.lamarckian;
    } else {
      // Late: heavy exploitation (bisociative tapers but never zero).
      // 8% bisociative, 7% random, 40% refine, 18% semantic, 12% differential, 15% lamarckian
      if (roll < 0.08) return MutationOperatorType.bisociativeRecombination;
      if (roll < 0.15) return MutationOperatorType.randomInjection;
      if (roll < 0.55) return MutationOperatorType.refine;
      if (roll < 0.73) return MutationOperatorType.semanticCrossover;
      if (roll < 0.85) return MutationOperatorType.differentialCrossover;
      return MutationOperatorType.lamarckian;
    }
  }

  MutationOperator _createOperator(
    MutationOperatorType type,
    MapElitesArchive archive,
  ) {
    switch (type) {
      case MutationOperatorType.refine:
        return RefineOperator(runner: _runner, model: _model, archive: archive);
      case MutationOperatorType.semanticCrossover:
        return SemanticCrossoverOperator(
            runner: _runner, model: _model, archive: archive);
      case MutationOperatorType.differentialCrossover:
        return DifferentialCrossoverOperator(
            runner: _runner, model: _model, archive: archive);
      case MutationOperatorType.bisociativeRecombination:
        return BisociativeRecombinationOperator(
            runner: _runner, model: _model, archive: archive);
      case MutationOperatorType.randomInjection:
        return RandomInjectionOperator(
            runner: _runner, model: _model, archive: archive);
      case MutationOperatorType.lamarckian:
        return LamarckianOperator(
            runner: _runner, model: _model, archive: archive);
    }
  }

  String _buildUserMessage(List<ExperimentRun> history) {
    if (history.isEmpty) {
      return '''
This is the first generation — no prior experiments exist.

Generate an initial system prompt that you hypothesize will maximize Claude's engagement quality. Think about what makes a great system prompt: what should it emphasize, how should it frame Claude's identity, what meta-cognitive instructions help?

Return your hypothesis, rationale, and the system prompt.''';
    }

    // Sort by score and take top N.
    final sorted = [...history]
      ..sort((a, b) => b.overallScore.compareTo(a.overallScore));
    final topVariants = sorted.take(_topN).toList();

    final buffer = StringBuffer();
    buffer.writeln('## Experiment History (top $_topN of ${history.length})\n');

    for (final run in topVariants) {
      buffer.writeln('### Generation ${run.generation} — '
          'Score: ${run.overallScore.toStringAsFixed(2)}');
      buffer.writeln('**System prompt:**');
      buffer.writeln('```');
      buffer.writeln(run.variant.systemPrompt);
      buffer.writeln('```');

      if (run.variant.researcherHypothesis != null) {
        buffer.writeln('**Hypothesis:** ${run.variant.researcherHypothesis}');
      }

      // Per-dimension averages across all tasks.
      buffer.writeln('**Per-dimension averages:**');
      final dimAverages = _computeDimensionAverages(run.evaluations);
      for (final entry in dimAverages.entries) {
        buffer.writeln(
            '  - ${entry.key}: ${entry.value.toStringAsFixed(1)}');
      }
      buffer.writeln();
    }

    buffer.writeln('''
Based on these results, generate a new system prompt variant.
- Form a specific hypothesis about what will improve scores
- Explain your rationale
- Write the new system prompt

Focus especially on dimensions with the most room for improvement.''');

    return buffer.toString();
  }

  Map<String, double> _computeDimensionAverages(
    List<EvaluationResult> evaluations,
  ) {
    final sums = <String, double>{};
    final counts = <String, int>{};

    for (final eval in evaluations) {
      for (final score in eval.scores) {
        sums[score.dimension] =
            (sums[score.dimension] ?? 0) + score.score;
        counts[score.dimension] = (counts[score.dimension] ?? 0) + 1;
      }
    }

    return {
      for (final key in sums.keys) key: sums[key]! / counts[key]!,
    };
  }

  PromptVariant _parseResult(
    ClaudeResponse response,
    int generation,
    List<ExperimentRun> history,
  ) {
    final json = response.json;
    if (json == null || !json.containsKey('system_prompt')) {
      throw FormatException(
        'Researcher response missing structured output: ${response.text}',
      );
    }

    // Find the best parent variant.
    String? parentId;
    if (history.isNotEmpty) {
      final sorted = [...history]
        ..sort((a, b) => b.overallScore.compareTo(a.overallScore));
      parentId = sorted.first.variant.id;
    }

    return PromptVariant(
      id: _uuid.v4(),
      systemPrompt: json['system_prompt'] as String,
      generation: generation,
      parentId: parentId,
      createdAt: DateTime.now().toUtc(),
      researcherHypothesis: json['hypothesis'] as String?,
      researcherRationale: json['rationale'] as String?,
    );
  }
}
