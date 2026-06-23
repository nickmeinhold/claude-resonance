import 'dart:convert';

import 'package:claude_resonance/claude_resonance.dart';
import 'package:test/test.dart';

void main() {
  group('MapElitesArchive', () {
    late MapElitesArchive archive;

    setUp(() {
      archive = MapElitesArchive();
    });

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
            responseText: 'Response text.',
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
              DimensionScore(
                dimension: 'Voice',
                score: 3,
                justification: 'OK.',
              ),
            ],
            aggregateScore: 3.5,
          ),
        ],
        overallScore: score,
        startedAt: DateTime.utc(2026, 3, 16, 10),
        completedAt: DateTime.utc(2026, 3, 16, 10, 30),
      );
    }

    test('insert into empty cell succeeds', () {
      final run = makeRun(
        score: 3.5,
        systemPrompt: 'Be helpful.',
        strategyType: 'persona',
      );

      final inserted = archive.tryInsert(run);

      expect(inserted, isTrue);
      expect(archive.occupiedCells, 1);
      expect(archive.allRuns(), hasLength(1));
    });

    test('insert with higher score replaces occupant', () {
      final run1 = makeRun(
        score: 3.0,
        systemPrompt: 'Be helpful.',
        strategyType: 'persona',
        variantId: 'v1',
      );
      final run2 = makeRun(
        score: 4.0,
        systemPrompt: 'Be very helpful.',
        strategyType: 'persona',
        variantId: 'v2',
      );

      archive.tryInsert(run1);
      final inserted = archive.tryInsert(run2);

      expect(inserted, isTrue);
      expect(archive.occupiedCells, 1);
      expect(archive.bestRun()!.variant.id, 'v2');
    });

    test('insert with lower score is rejected', () {
      final run1 = makeRun(
        score: 4.0,
        systemPrompt: 'Be helpful.',
        strategyType: 'persona',
        variantId: 'v1',
      );
      final run2 = makeRun(
        score: 3.0,
        systemPrompt: 'Be very helpful.',
        strategyType: 'persona',
        variantId: 'v2',
      );

      archive.tryInsert(run1);
      final inserted = archive.tryInsert(run2);

      expect(inserted, isFalse);
      expect(archive.bestRun()!.variant.id, 'v1');
    });

    test('classifyVariant correctly bins by word count and strategy', () {
      // Short minimalist prompt.
      final shortMinimalist = PromptVariant(
        id: 'v1',
        systemPrompt: 'Be brief.',
        generation: 0,
        createdAt: DateTime.utc(2026, 3, 16),
        strategyType: 'minimalist',
      );
      final key1 = archive.classifyVariant(shortMinimalist);
      expect(key1.strategy, StrategyType.minimalist);
      expect(key1.lengthBin, PromptLengthBin.short_);

      // Medium-length persona prompt (100+ words).
      final words = List.generate(150, (i) => 'word$i').join(' ');
      final mediumPersona = PromptVariant(
        id: 'v2',
        systemPrompt: words,
        generation: 0,
        createdAt: DateTime.utc(2026, 3, 16),
        strategyType: 'persona',
      );
      final key2 = archive.classifyVariant(mediumPersona);
      expect(key2.strategy, StrategyType.persona);
      expect(key2.lengthBin, PromptLengthBin.medium);

      // Long socratic prompt (300+ words).
      final longWords = List.generate(350, (i) => 'word$i').join(' ');
      final longSocratic = PromptVariant(
        id: 'v3',
        systemPrompt: longWords,
        generation: 0,
        createdAt: DateTime.utc(2026, 3, 16),
        strategyType: 'socratic',
      );
      final key3 = archive.classifyVariant(longSocratic);
      expect(key3.strategy, StrategyType.socratic);
      expect(key3.lengthBin, PromptLengthBin.long_);
    });

    test('classifyVariant uses heuristics when strategyType is null', () {
      final variant = PromptVariant(
        id: 'v1',
        systemPrompt:
            'Before answering any question, identify the assumptions.',
        generation: 0,
        createdAt: DateTime.utc(2026, 3, 16),
      );
      final key = archive.classifyVariant(variant);
      expect(key.strategy, StrategyType.socratic);
    });

    test('topN returns correct ordering', () {
      archive.tryInsert(makeRun(
        score: 2.0,
        systemPrompt: 'Low score persona prompt.',
        strategyType: 'persona',
        variantId: 'low',
      ));
      archive.tryInsert(makeRun(
        score: 4.5,
        systemPrompt: 'Before answering, consider assumptions.',
        strategyType: 'socratic',
        variantId: 'high',
      ));
      archive.tryInsert(makeRun(
        score: 3.0,
        systemPrompt: 'Rules: Never hedge.',
        strategyType: 'constraint',
        variantId: 'mid',
      ));

      final top = archive.topN(2);
      expect(top, hasLength(2));
      expect(top[0].variant.id, 'high');
      expect(top[1].variant.id, 'mid');
    });

    test('complementaryParent selects from different cell', () {
      // Parent in persona/short cell with low Voice score.
      final parent = ExperimentRun(
        generation: 1,
        variant: PromptVariant(
          id: 'parent',
          systemPrompt: 'Be helpful.',
          generation: 1,
          createdAt: DateTime.utc(2026, 3, 16),
          strategyType: 'persona',
        ),
        responses: [],
        evaluations: [
          const EvaluationResult(
            taskId: 'task-1',
            variantId: 'parent',
            scores: [
              DimensionScore(
                  dimension: 'Specificity', score: 5, justification: ''),
              DimensionScore(
                  dimension: 'Voice', score: 1, justification: ''),
            ],
            aggregateScore: 3.0,
          ),
        ],
        overallScore: 3.0,
        startedAt: DateTime.utc(2026, 3, 16),
        completedAt: DateTime.utc(2026, 3, 16, 0, 30),
      );

      // Complement in socratic/short cell with high Voice score.
      final complement = ExperimentRun(
        generation: 1,
        variant: PromptVariant(
          id: 'complement',
          systemPrompt: 'Before answering, identify assumptions.',
          generation: 1,
          createdAt: DateTime.utc(2026, 3, 16),
          strategyType: 'socratic',
        ),
        responses: [],
        evaluations: [
          const EvaluationResult(
            taskId: 'task-1',
            variantId: 'complement',
            scores: [
              DimensionScore(
                  dimension: 'Specificity', score: 2, justification: ''),
              DimensionScore(
                  dimension: 'Voice', score: 5, justification: ''),
            ],
            aggregateScore: 3.5,
          ),
        ],
        overallScore: 3.5,
        startedAt: DateTime.utc(2026, 3, 16),
        completedAt: DateTime.utc(2026, 3, 16, 0, 30),
      );

      archive.tryInsert(parent);
      archive.tryInsert(complement);

      final found = archive.complementaryParent(parent);
      expect(found, isNotNull);
      expect(found!.variant.id, 'complement');
    });

    test('toJson/fromJson round-trip', () {
      archive.tryInsert(makeRun(
        score: 3.5,
        systemPrompt: 'Be helpful.',
        strategyType: 'persona',
        variantId: 'v1',
      ));
      archive.tryInsert(makeRun(
        score: 4.0,
        systemPrompt: 'Before answering, think about assumptions.',
        strategyType: 'socratic',
        variantId: 'v2',
      ));

      final json = archive.toJson();
      final jsonString = jsonEncode(json);
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final restored = MapElitesArchive.fromJson(decoded);

      expect(restored.occupiedCells, archive.occupiedCells);
      expect(restored.allRuns(), hasLength(2));
      expect(restored.bestRun()!.overallScore, 4.0);
    });

    test('emptyCells and cellCount are consistent', () {
      expect(archive.cellCount,
          StrategyType.values.length * PromptLengthBin.values.length);
      expect(archive.emptyCells, archive.cellCount);

      archive.tryInsert(makeRun(
        score: 3.0,
        systemPrompt: 'Test.',
        strategyType: 'persona',
      ));

      expect(archive.emptyCells, archive.cellCount - 1);
    });

    test('bestRun returns null for empty archive', () {
      expect(archive.bestRun(), isNull);
    });
  });
}
