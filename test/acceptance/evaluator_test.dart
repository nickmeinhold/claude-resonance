import 'dart:convert';

import 'package:claude_resonance/claude_resonance.dart';
import 'package:test/test.dart';

void main() {
  group('Evaluator', () {
    late MockClaudeRunner runner;
    late Evaluator evaluator;

    setUp(() {
      runner = MockClaudeRunner();
      evaluator = Evaluator(runner);
    });

    test('returns structured scores from mock runner', () async {
      final evalResponse = {
        'scores': [
          {
            'dimension': 'Specificity',
            'score': 4,
            'justification': 'Good concrete details.',
          },
          {
            'dimension': 'Novel Connections',
            'score': 3,
            'justification': 'Some interesting links.',
          },
          {
            'dimension': 'Unprompted Exploration',
            'score': 5,
            'justification': 'Went well beyond the question.',
          },
          {
            'dimension': 'Genuine Caveats',
            'score': 4,
            'justification': 'Honest about limitations.',
          },
          {
            'dimension': 'Technical Depth',
            'score': 4,
            'justification': 'Solid trade-off analysis.',
          },
          {
            'dimension': 'Voice',
            'score': 3,
            'justification': 'Adequate but not distinctive.',
          },
        ],
        'notes': 'Overall a strong response.',
      };

      runner.stubAny(ClaudeResponse(
        text: jsonEncode(evalResponse),
        json: evalResponse,
        latency: const Duration(seconds: 2),
      ));

      const task = TestTask(
        id: 'task-1',
        name: 'Test Task',
        category: 'creative',
        userMessage: 'Design something.',
      );
      const response = TaskResponse(
        taskId: 'task-1',
        variantId: 'v1',
        responseText: 'Here is my creative design...',
        latencyMs: 1500,
      );

      final result = await evaluator.evaluate(task, response);

      expect(result.taskId, 'task-1');
      expect(result.variantId, 'v1');
      expect(result.scores, hasLength(6));
      expect(result.scores.first.dimension, 'Specificity');
      expect(result.scores.first.score, 4);
      expect(result.aggregateScore, greaterThan(0));
      expect(result.aggregateScore, lessThanOrEqualTo(5));
      expect(result.notes, 'Overall a strong response.');
    });

    test('passes system prompt and json schema to runner', () async {
      runner.stubAny(ClaudeResponse(
        text: '{}',
        json: {
          // Full 6-dimension response — the scorer now fails loud on a partial
          // one, so a realistic stub must cover every rubric dimension.
          'scores': [
            for (final d in Rubric.dimensions)
              {'dimension': d.name, 'score': 3, 'justification': 'ok'},
          ],
        },
        latency: Duration.zero,
      ));

      const task = TestTask(
        id: 't1',
        name: 'T',
        category: 'test',
        userMessage: 'Test.',
      );
      const response = TaskResponse(
        taskId: 't1',
        variantId: 'v1',
        responseText: 'Response.',
        latencyMs: 100,
      );

      await evaluator.evaluate(task, response);

      expect(runner.invocations, hasLength(1));
      final inv = runner.invocations.first;
      expect(inv.systemPrompt, isNotNull);
      expect(inv.systemPrompt, contains('evaluator'));
      expect(inv.jsonSchema, isNotNull);
      expect(inv.jsonSchema!['required'], contains('scores'));
    });

    test('computes weighted aggregate correctly', () {
      // Verify rubric scoring directly.
      const scores = [
        DimensionScore(dimension: 'Specificity', score: 4, justification: ''),
        DimensionScore(
            dimension: 'Novel Connections', score: 5, justification: ''),
        DimensionScore(
            dimension: 'Unprompted Exploration',
            score: 3,
            justification: ''),
        DimensionScore(
            dimension: 'Genuine Caveats', score: 4, justification: ''),
        DimensionScore(
            dimension: 'Technical Depth', score: 4, justification: ''),
        DimensionScore(dimension: 'Voice', score: 3, justification: ''),
      ];

      final aggregate = Rubric.aggregate(scores);

      // Manual: (4*1.0 + 5*1.2 + 3*1.0 + 4*0.8 + 4*1.0 + 3*1.0) / 6.0
      // = (4 + 6 + 3 + 3.2 + 4 + 3) / 6.0 = 23.2 / 6.0 ≈ 3.867
      expect(aggregate, closeTo(3.867, 0.01));
    });
  });
}
