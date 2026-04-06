import 'dart:convert';

import 'package:claude_resonance/claude_resonance.dart';
import 'package:test/test.dart';

void main() {
  group('Model JSON serialization round-trips', () {
    test('PromptVariant', () {
      final variant = PromptVariant(
        id: 'test-id',
        systemPrompt: 'You are helpful.',
        generation: 1,
        parentId: 'parent-id',
        createdAt: DateTime.utc(2026, 3, 16),
        researcherHypothesis: 'Simple is better',
        researcherRationale: 'Testing minimal prompts',
      );

      final json = variant.toJson();
      final jsonString = jsonEncode(json);
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final restored = PromptVariant.fromJson(decoded);

      expect(restored, equals(variant));
      expect(restored.id, 'test-id');
      expect(restored.generation, 1);
      expect(restored.parentId, 'parent-id');
    });

    test('TestTask', () {
      const task = TestTask(
        id: 'task-1',
        name: 'Creative',
        category: 'creative',
        userMessage: 'Design something.',
      );

      final json = task.toJson();
      final restored = TestTask.fromJson(json);
      expect(restored, equals(task));
    });

    test('TaskResponse', () {
      const response = TaskResponse(
        taskId: 'task-1',
        variantId: 'variant-1',
        responseText: 'Here is my response...',
        latencyMs: 1500,
      );

      final json = response.toJson();
      final restored = TaskResponse.fromJson(json);
      expect(restored, equals(response));
      expect(restored.latencyMs, 1500);
    });

    test('DimensionScore', () {
      const score = DimensionScore(
        dimension: 'Specificity',
        score: 4,
        justification: 'Very specific details provided.',
      );

      final json = score.toJson();
      final restored = DimensionScore.fromJson(json);
      expect(restored, equals(score));
    });

    test('EvaluationResult', () {
      const result = EvaluationResult(
        taskId: 'task-1',
        variantId: 'variant-1',
        scores: [
          DimensionScore(
            dimension: 'Specificity',
            score: 4,
            justification: 'Good.',
          ),
          DimensionScore(
            dimension: 'Voice',
            score: 5,
            justification: 'Excellent.',
          ),
        ],
        aggregateScore: 4.5,
        notes: 'Strong response overall.',
      );

      final json = result.toJson();
      final jsonString = jsonEncode(json);
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final restored = EvaluationResult.fromJson(decoded);

      expect(restored, equals(result));
      expect(restored.scores.length, 2);
      expect(restored.notes, 'Strong response overall.');
    });

    test('ExperimentRun', () {
      final run = ExperimentRun(
        generation: 1,
        variant: PromptVariant(
          id: 'v1',
          systemPrompt: 'Be creative.',
          generation: 1,
          createdAt: DateTime.utc(2026, 3, 16),
        ),
        responses: [
          const TaskResponse(
            taskId: 'task-1',
            variantId: 'v1',
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
                score: 3,
                justification: 'Adequate.',
              ),
            ],
            aggregateScore: 3.0,
          ),
        ],
        overallScore: 3.0,
        startedAt: DateTime.utc(2026, 3, 16, 10),
        completedAt: DateTime.utc(2026, 3, 16, 10, 30),
      );

      final json = run.toJson();
      final jsonString = jsonEncode(json);
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final restored = ExperimentRun.fromJson(decoded);

      expect(restored.generation, 1);
      expect(restored.variant.id, 'v1');
      expect(restored.responses.length, 1);
      expect(restored.evaluations.length, 1);
      expect(restored.overallScore, 3.0);
    });
  });
}
