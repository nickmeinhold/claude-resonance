import 'dart:convert';
import 'dart:math';

import 'package:claude_resonance/claude_resonance.dart';
import 'package:test/test.dart';

void main() {
  group('Researcher', () {
    late MockClaudeRunner runner;
    late Researcher researcher;

    setUp(() {
      runner = MockClaudeRunner();
      researcher = Researcher(runner);
    });

    test('produces valid variant from empty history', () async {
      final researcherResponse = {
        'hypothesis': 'A persona-based prompt will increase engagement',
        'rationale': 'Giving Claude a specific identity encourages '
            'more distinctive voice and deeper engagement.',
        'system_prompt': 'You are a curious polymath who loves '
            'finding unexpected connections.',
      };

      runner.stubAny(ClaudeResponse(
        text: jsonEncode(researcherResponse),
        json: researcherResponse,
        latency: const Duration(seconds: 3),
      ));

      final variant = await researcher.generateVariant(
        history: [],
        generation: 1,
      );

      expect(variant.id, isNotEmpty);
      expect(variant.systemPrompt, contains('polymath'));
      expect(variant.generation, 1);
      expect(variant.parentId, isNull);
      expect(variant.researcherHypothesis,
          contains('persona-based'));
      expect(variant.researcherRationale, isNotNull);
    });

    test('produces valid variant from prior history', () async {
      final history = [
        ExperimentRun(
          generation: 0,
          variant: PromptVariant(
            id: 'seed-1',
            systemPrompt: 'Be helpful.',
            generation: 0,
            createdAt: DateTime.utc(2026, 3, 16),
          ),
          responses: [],
          evaluations: [
            const EvaluationResult(
              taskId: 'task-1',
              variantId: 'seed-1',
              scores: [
                DimensionScore(
                    dimension: 'Specificity',
                    score: 3,
                    justification: 'ok'),
                DimensionScore(
                    dimension: 'Voice',
                    score: 2,
                    justification: 'generic'),
              ],
              aggregateScore: 2.5,
            ),
          ],
          overallScore: 2.5,
          startedAt: DateTime.utc(2026, 3, 16),
          completedAt: DateTime.utc(2026, 3, 16, 0, 30),
        ),
      ];

      final researcherResponse = {
        'hypothesis': 'Adding meta-cognitive instructions will '
            'improve Voice scores',
        'rationale': 'The previous prompt scored low on Voice (2.0). '
            'Explicit instructions to think before responding may help.',
        'system_prompt': 'Before responding, consider what is most '
            'interesting about this problem.',
      };

      runner.stubAny(ClaudeResponse(
        text: jsonEncode(researcherResponse),
        json: researcherResponse,
        latency: const Duration(seconds: 3),
      ));

      final variant = await researcher.generateVariant(
        history: history,
        generation: 1,
      );

      expect(variant.parentId, 'seed-1');
      expect(variant.generation, 1);
      expect(variant.systemPrompt, contains('interesting'));

      // Verify the runner was given history context.
      final inv = runner.invocations.first;
      expect(inv.userMessage, contains('Experiment History'));
      expect(inv.userMessage, contains('Be helpful.'));
      expect(inv.jsonSchema, isNotNull);
    });

    test('selectOperator can return bisociativeRecombination in early gens',
        () async {
      // Seeded Random makes the schedule deterministic and reproducible.
      final seeded = Researcher(runner, random: Random(42));
      final archive = MapElitesArchive();

      final seen = <MutationOperatorType>{};
      // Sweep many rolls in an early generation (progress < 0.3).
      for (var i = 0; i < 200; i++) {
        seen.add(seeded.selectOperator(0, 10, archive));
      }

      expect(
        seen,
        contains(MutationOperatorType.bisociativeRecombination),
        reason: 'bisociative should be reachable early (exploration)',
      );
    });

    test('selectOperator keeps bisociative reachable across the schedule',
        () async {
      final seeded = Researcher(runner, random: Random(7));
      final archive = MapElitesArchive();

      // Late generation (progress >= 0.7) — bisociative tapers but never zero.
      final lateSeen = <MutationOperatorType>{};
      for (var i = 0; i < 500; i++) {
        lateSeen.add(seeded.selectOperator(9, 10, archive));
      }
      expect(
        lateSeen,
        contains(MutationOperatorType.bisociativeRecombination),
        reason: 'bisociative must never be starved to zero even late',
      );

      // The ladder must be exhaustive across all phases: every roll resolves
      // to a real operator, and every operator is reachable somewhere.
      final allSeen = <MutationOperatorType>{};
      for (final gen in [0, 5, 9]) {
        for (var i = 0; i < 500; i++) {
          allSeen.add(seeded.selectOperator(gen, 10, archive));
        }
      }
      expect(allSeen, equals(MutationOperatorType.values.toSet()),
          reason: 'no operator should be starved in the probability ladder');
    });
  });
}
