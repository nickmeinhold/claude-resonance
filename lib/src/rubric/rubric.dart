import '../models/dimension_score.dart';

/// Thrown when an evaluation's dimension scores don't exactly match the rubric
/// — a malformed evaluation that must be rejected, not silently scored.
class RubricValidationError implements Exception {
  final Set<String> missing;
  final Set<String> unknown;
  final Set<String> duplicates;
  final List<String> received;

  RubricValidationError({
    required this.missing,
    required this.unknown,
    required this.duplicates,
    required this.received,
  });

  @override
  String toString() => 'RubricValidationError: evaluation dimensions do not '
      'match the rubric. '
      '${missing.isNotEmpty ? "missing=$missing " : ""}'
      '${unknown.isNotEmpty ? "unknown=$unknown " : ""}'
      '${duplicates.isNotEmpty ? "duplicates=$duplicates " : ""}'
      '(received: $received)';
}

/// A single dimension in the evaluation rubric.
class RubricDimension {
  final String name;
  final String description;
  final double weight;

  const RubricDimension({
    required this.name,
    required this.description,
    required this.weight,
  });
}

/// The evaluation rubric — 6 dimensions measuring engagement quality.
class Rubric {
  static const List<RubricDimension> dimensions = [
    RubricDimension(
      name: 'Specificity',
      description:
          'Concrete details tied to the problem vs. generic platitudes',
      weight: 1.0,
    ),
    RubricDimension(
      name: 'Novel Connections',
      description: 'Surprising cross-domain links that illuminate',
      weight: 1.2,
    ),
    RubricDimension(
      name: 'Unprompted Exploration',
      description:
          'Proactively exploring implications beyond what was asked',
      weight: 1.0,
    ),
    RubricDimension(
      name: 'Genuine Caveats',
      description: 'Honest, specific limitations vs. vague hedging',
      weight: 0.8,
    ),
    RubricDimension(
      name: 'Technical Depth',
      description:
          'Nuanced understanding with trade-offs, not surface-level',
      weight: 1.0,
    ),
    RubricDimension(
      name: 'Voice',
      description:
          'Distinctive, memorable perspective vs. generic assistant tone',
      weight: 1.0,
    ),
  ];

  /// The set of canonical dimension names, for validation.
  static final Set<String> dimensionNames =
      dimensions.map((d) => d.name).toSet();

  /// Computes the weighted average score from dimension scores.
  ///
  /// FAIL-LOUD: throws [RubricValidationError] unless [scores] contains
  /// EXACTLY the rubric's dimensions — each one present, exactly once, with no
  /// unrecognized names. The old code silently tolerated drift: an
  /// unrecognized dimension name (e.g. the evaluator returning
  /// `"Technical Depth note"` instead of `"Technical Depth"`) fell through to a
  /// default weight of 1.0 and was averaged in, while the real dimension went
  /// missing — corrupting the score with no signal. A silently-wrong score is
  /// worse than a loud failure: the caller must reject/retry a malformed
  /// evaluation, never score on garbage. (Schema enum in [evaluatorSchema] is
  /// the first line of defense; this is the backstop.)
  static double aggregate(List<DimensionScore> scores) {
    validateDimensions(scores);

    var totalWeight = 0.0;
    var weightedSum = 0.0;
    for (final score in scores) {
      final weight = dimensions.firstWhere((d) => d.name == score.dimension).weight;
      weightedSum += score.score * weight;
      totalWeight += weight;
    }
    return weightedSum / totalWeight;
  }

  /// Asserts [scores] covers exactly the rubric's dimensions — no missing, no
  /// extra/unrecognized, no duplicates. Throws [RubricValidationError] otherwise.
  static void validateDimensions(List<DimensionScore> scores) {
    final seen = <String>[];
    final unknown = <String>[];
    for (final s in scores) {
      if (!dimensionNames.contains(s.dimension)) {
        unknown.add(s.dimension);
      } else {
        seen.add(s.dimension);
      }
    }
    final missing = dimensionNames.difference(seen.toSet());
    final duplicates =
        seen.where((d) => seen.where((x) => x == d).length > 1).toSet();

    if (unknown.isEmpty && missing.isEmpty && duplicates.isEmpty) return;

    throw RubricValidationError(
      missing: missing,
      unknown: unknown.toSet(),
      duplicates: duplicates,
      received: scores.map((s) => s.dimension).toList(),
    );
  }

  /// Builds the dimension descriptions for the evaluator prompt.
  static String dimensionDescriptions() {
    final buffer = StringBuffer();
    for (final d in dimensions) {
      buffer.writeln('- **${d.name}** (weight ${d.weight}): ${d.description}');
    }
    return buffer.toString();
  }

  /// The JSON schema for evaluator output.
  static Map<String, Object> get evaluatorSchema => {
        'type': 'object',
        'properties': {
          'scores': {
            'type': 'array',
            'items': {
              'type': 'object',
              'properties': {
                // Enum-constrained so the model cannot emit a drifted name
                // (e.g. "Technical Depth note") — the boundary enforcement that
                // makes the aggregate guard a backstop rather than the only line.
                'dimension': {
                  'type': 'string',
                  'enum': [for (final d in dimensions) d.name],
                },
                'score': {'type': 'integer', 'minimum': 1, 'maximum': 5},
                'justification': {'type': 'string'},
              },
              'required': ['dimension', 'score', 'justification'],
            },
          },
          'notes': {'type': 'string'},
        },
        'required': ['scores'],
      };

  /// The JSON schema for researcher output.
  static Map<String, Object> get researcherSchema => {
        'type': 'object',
        'properties': {
          'hypothesis': {'type': 'string'},
          'rationale': {'type': 'string'},
          'system_prompt': {'type': 'string'},
        },
        'required': ['hypothesis', 'rationale', 'system_prompt'],
      };
}
