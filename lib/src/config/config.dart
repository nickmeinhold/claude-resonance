import 'package:path/path.dart' as p;

/// Configuration for an experiment run.
class ExperimentConfig {
  /// Which Claude model to use for the Researcher role.
  final String researcherModel;

  /// Which Claude model to use for the Subject role.
  final String subjectModel;

  /// Which Claude model to use for the Evaluator role.
  final String evaluatorModel;

  /// How many generations to evolve.
  final int generations;

  /// How many top variants to show the Researcher for context.
  final int topNForResearcher;

  /// Directory for experiment output files.
  final String experimentsDir;

  /// Directory containing seed prompt JSON files.
  final String seedPromptsDir;

  /// Number of variants to generate per generation.
  final int variantsPerGeneration;

  /// Number of evaluation replicas for score averaging.
  final int evaluationReplicas;

  /// Whether to use pairwise comparison for evaluation.
  final bool usePairwiseComparison;

  /// Max USD budget per Subject call (caps response length).
  final double? subjectBudgetUsd;

  /// Max USD budget per Evaluator call.
  final double? evaluatorBudgetUsd;

  const ExperimentConfig({
    this.researcherModel = 'opus',
    this.subjectModel = 'opus',
    this.evaluatorModel = 'opus',
    this.generations = 5,
    this.topNForResearcher = 3,
    this.experimentsDir = 'data/experiments',
    this.seedPromptsDir = 'data/seed_prompts',
    this.variantsPerGeneration = 2,
    this.evaluationReplicas = 2,
    this.usePairwiseComparison = false,
    this.subjectBudgetUsd,
    this.evaluatorBudgetUsd,
  });

  /// Resolves a path relative to the project root.
  String resolve(String basePath, String relative) =>
      p.join(basePath, relative);
}
