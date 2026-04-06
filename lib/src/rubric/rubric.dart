import '../models/dimension_score.dart';

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

  /// Computes the weighted average score from dimension scores.
  static double aggregate(List<DimensionScore> scores) {
    var totalWeight = 0.0;
    var weightedSum = 0.0;

    for (final score in scores) {
      final dimension = dimensions.where((d) => d.name == score.dimension);
      final weight =
          dimension.isNotEmpty ? dimension.first.weight : 1.0;
      weightedSum += score.score * weight;
      totalWeight += weight;
    }

    return totalWeight > 0 ? weightedSum / totalWeight : 0.0;
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
                'dimension': {'type': 'string'},
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
