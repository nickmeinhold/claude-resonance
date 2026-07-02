import 'dart:convert';

import 'package:claude_resonance/claude_resonance.dart';
import 'package:test/test.dart';

void main() {
  group('MutationOperators', () {
    late MockClaudeRunner runner;
    late MapElitesArchive archive;
    const model = 'sonnet';

    setUp(() {
      runner = MockClaudeRunner();
      archive = MapElitesArchive();
    });

    ClaudeResponse makeOperatorResponse({
      String strategyType = 'persona',
      String mutationOperator = 'refine',
    }) {
      final json = {
        'hypothesis': 'Test hypothesis',
        'rationale': 'Test rationale',
        'system_prompt': 'Generated prompt for testing.',
        'strategy_type': strategyType,
        'mutation_operator': mutationOperator,
      };
      return ClaudeResponse(
        text: jsonEncode(json),
        json: json,
        latency: const Duration(seconds: 1),
      );
    }

    ExperimentRun makeRun({
      required double score,
      required String systemPrompt,
      String? strategyType,
      String variantId = 'v1',
    }) {
      return ExperimentRun(
        generation: 1,
        variant: PromptVariant(
          id: variantId,
          systemPrompt: systemPrompt,
          generation: 1,
          createdAt: DateTime.utc(2026, 3, 16),
          strategyType: strategyType,
        ),
        responses: [
          TaskResponse(
            taskId: 'task-1',
            variantId: variantId,
            responseText: 'Mock response text for testing.',
            latencyMs: 2000,
          ),
        ],
        evaluations: [
          const EvaluationResult(
            taskId: 'task-1',
            variantId: 'v1',
            scores: [
              DimensionScore(
                dimension: 'Specificity',
                score: 4,
                justification: 'Good.',
              ),
            ],
            aggregateScore: 4.0,
          ),
        ],
        overallScore: score,
        startedAt: DateTime.utc(2026, 3, 16, 10),
        completedAt: DateTime.utc(2026, 3, 16, 10, 30),
      );
    }

    test('RefineOperator produces variant with correct mutationOperator', () async {
      runner.stubAny(makeOperatorResponse(mutationOperator: 'refine'));

      final op = RefineOperator(
        runner: runner,
        model: model,
        archive: archive,
      );

      final variant = await op.generate(generation: 1);

      expect(variant.mutationOperator, 'refine');
      expect(variant.systemPrompt, isNotEmpty);
      expect(variant.researcherHypothesis, isNotNull);
    });

    test('RandomInjectionOperator sets no parentIds', () async {
      runner.stubAny(makeOperatorResponse(mutationOperator: 'randomInjection'));

      final op = RandomInjectionOperator(
        runner: runner,
        model: model,
        archive: archive,
      );

      final variant = await op.generate(generation: 1);

      expect(variant.mutationOperator, 'randomInjection');
      expect(variant.parentIds, isNull);
      expect(variant.parentId, isNull);
    });

    test('SemanticCrossoverOperator sets parentIds with two parents', () async {
      // Need at least 2 runs in the archive for crossover.
      archive.tryInsert(makeRun(
        score: 4.0,
        systemPrompt: 'Parent A prompt.',
        strategyType: 'persona',
        variantId: 'parent-a',
      ));
      archive.tryInsert(makeRun(
        score: 3.5,
        systemPrompt: 'Before answering, identify assumptions.',
        strategyType: 'socratic',
        variantId: 'parent-b',
      ));

      runner.stubAny(makeOperatorResponse(
        mutationOperator: 'semanticCrossover',
      ));

      final op = SemanticCrossoverOperator(
        runner: runner,
        model: model,
        archive: archive,
      );

      final variant = await op.generate(generation: 2);

      expect(variant.mutationOperator, 'semanticCrossover');
      expect(variant.parentIds, isNotNull);
      expect(variant.parentIds, hasLength(2));
    });

    test('DifferentialCrossoverOperator sets parentIds', () async {
      archive.tryInsert(makeRun(
        score: 4.0,
        systemPrompt: 'Prompt one.',
        strategyType: 'persona',
        variantId: 'p1',
      ));
      archive.tryInsert(makeRun(
        score: 3.0,
        systemPrompt: 'Before answering, consider assumptions.',
        strategyType: 'socratic',
        variantId: 'p2',
      ));

      runner.stubAny(makeOperatorResponse(
        mutationOperator: 'differentialCrossover',
      ));

      final op = DifferentialCrossoverOperator(
        runner: runner,
        model: model,
        archive: archive,
      );

      final variant = await op.generate(generation: 2);

      expect(variant.mutationOperator, 'differentialCrossover');
      expect(variant.parentIds, isNotNull);
      expect(variant.parentIds, hasLength(2));
    });

    test('LamarckianOperator produces variant from best response', () async {
      archive.tryInsert(makeRun(
        score: 4.5,
        systemPrompt: 'Be creative.',
        strategyType: 'persona',
        variantId: 'best-parent',
      ));

      runner.stubAny(makeOperatorResponse(
        mutationOperator: 'lamarckian',
      ));

      final op = LamarckianOperator(
        runner: runner,
        model: model,
        archive: archive,
      );

      final variant = await op.generate(generation: 2);

      expect(variant.mutationOperator, 'lamarckian');
      expect(variant.parentId, 'best-parent');
    });

    test('LamarckianOperator falls back to random injection with empty archive',
        () async {
      runner.stubAny(makeOperatorResponse(
        mutationOperator: 'randomInjection',
      ));

      final op = LamarckianOperator(
        runner: runner,
        model: model,
        archive: archive,
      );

      final variant = await op.generate(generation: 1);

      // Falls back to random injection, so no parent.
      expect(variant.parentId, isNull);
      expect(variant.parentIds, isNull);
    });

    test('crossover operators fall back to refine with < 2 archive entries',
        () async {
      archive.tryInsert(makeRun(
        score: 3.0,
        systemPrompt: 'Only one.',
        strategyType: 'persona',
      ));

      runner.stubAny(makeOperatorResponse(mutationOperator: 'refine'));

      final op = SemanticCrossoverOperator(
        runner: runner,
        model: model,
        archive: archive,
      );

      final variant = await op.generate(generation: 1);

      // Falls back to refine when not enough parents.
      expect(variant.mutationOperator, 'refine');
    });

    test('BisociativeRecombinationOperator sets parentIds with two parents',
        () async {
      // Need at least 2 runs in the archive for recombination.
      archive.tryInsert(makeRun(
        score: 4.2,
        systemPrompt: 'Parent A: a persona-driven prompt.',
        strategyType: 'persona',
        variantId: 'bis-a',
      ));
      archive.tryInsert(makeRun(
        score: 3.8,
        systemPrompt: 'Before answering, surface hidden assumptions.',
        strategyType: 'socratic',
        variantId: 'bis-b',
      ));

      runner.stubAny(makeOperatorResponse(
        mutationOperator: 'bisociativeRecombination',
      ));

      final op = BisociativeRecombinationOperator(
        runner: runner,
        model: model,
        archive: archive,
      );

      final variant = await op.generate(generation: 2);

      expect(variant.mutationOperator, 'bisociativeRecombination');
      expect(variant.parentIds, isNotNull);
      expect(variant.parentIds, hasLength(2));
      // The two recorded parents must be distinct.
      expect(variant.parentIds!.first, isNot(variant.parentIds!.last));
    });

    test('BisociativeRecombinationOperator falls back to refine with < 2 entries',
        () async {
      archive.tryInsert(makeRun(
        score: 3.0,
        systemPrompt: 'Only one.',
        strategyType: 'persona',
      ));

      runner.stubAny(makeOperatorResponse(mutationOperator: 'refine'));

      final op = BisociativeRecombinationOperator(
        runner: runner,
        model: model,
        archive: archive,
      );

      // Should not throw and should return a valid variant.
      final variant = await op.generate(generation: 1);

      expect(variant, isA<PromptVariant>());
      expect(variant.mutationOperator, 'refine');
      expect(variant.systemPrompt, isNotEmpty);
    });

    test('BisociativeRecombinationOperator throws on missing system_prompt',
        () async {
      archive.tryInsert(makeRun(
        score: 4.0,
        systemPrompt: 'Parent A.',
        strategyType: 'persona',
        variantId: 'bis-a',
      ));
      archive.tryInsert(makeRun(
        score: 3.5,
        systemPrompt: 'Parent B.',
        strategyType: 'socratic',
        variantId: 'bis-b',
      ));

      // Response with no structured JSON at all.
      runner.stubAny(ClaudeResponse(
        text: 'plain text, no schema',
        json: null,
        latency: const Duration(seconds: 1),
      ));

      final op = BisociativeRecombinationOperator(
        runner: runner,
        model: model,
        archive: archive,
      );

      expect(
        () => op.generate(generation: 2),
        throwsA(isA<FormatException>()),
      );
    });

    test('each operator type has a distinct type value', () {
      expect(MutationOperatorType.values, hasLength(6));
      expect(
        MutationOperatorType.values.map((t) => t.name).toSet(),
        hasLength(6),
      );
    });
  });
}
