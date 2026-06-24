import 'package:claude_resonance/src/models/dimension_score.dart';
import 'package:claude_resonance/src/rubric/rubric.dart';
import 'package:test/test.dart';

/// One DimensionScore per rubric dimension, all at [score].
List<DimensionScore> _fullScores({int score = 4}) => [
      for (final d in Rubric.dimensions)
        DimensionScore(
          dimension: d.name,
          score: score,
          justification: 'because',
        ),
    ];

void main() {
  group('Rubric.aggregate', () {
    test('weighted average over exactly the 6 dimensions', () {
      // All 4s → weighted average is 4.0 regardless of weights.
      expect(Rubric.aggregate(_fullScores(score: 4)), closeTo(4.0, 1e-9));
    });

    test('weights bias the average (Novel Connections is 1.2)', () {
      final scores = _fullScores(score: 4)
          .map((s) => s.dimension == 'Novel Connections'
              ? DimensionScore(
                  dimension: s.dimension, score: 5, justification: 'x')
              : s)
          .toList();
      // One dimension nudged up, weighted — result must exceed 4.0.
      expect(Rubric.aggregate(scores), greaterThan(4.0));
    });

    test('FAIL-LOUD on an unrecognized dimension name (the real bug)', () {
      final scores = _fullScores()
          .map((s) => s.dimension == 'Technical Depth'
              ? DimensionScore(
                  dimension: 'Technical Depth note', // the drift seen in data
                  score: s.score,
                  justification: s.justification)
              : s)
          .toList();
      expect(
        () => Rubric.aggregate(scores),
        throwsA(isA<RubricValidationError>()),
      );
    });

    test('FAIL-LOUD on a missing dimension', () {
      final scores = _fullScores()
          .where((s) => s.dimension != 'Voice')
          .toList(); // only 5 dims
      expect(
        () => Rubric.aggregate(scores),
        throwsA(isA<RubricValidationError>()),
      );
    });

    test('FAIL-LOUD on a duplicate dimension', () {
      final scores = [
        ..._fullScores(),
        DimensionScore(dimension: 'Voice', score: 3, justification: 'dup'),
      ];
      expect(
        () => Rubric.aggregate(scores),
        throwsA(isA<RubricValidationError>()),
      );
    });
  });
}
