import '../models/experiment_run.dart';
import '../models/prompt_variant.dart';

/// Strategy types for MAP-Elites behavioral dimension.
enum StrategyType {
  persona,
  metacognitive,
  constraint,
  minimalist,
  socratic,
  adversarial,
  emotional,
  domainTransfer,
}

/// Prompt length bins for MAP-Elites behavioral dimension.
enum PromptLengthBin {
  short_, // <100 words
  medium, // 100-300 words
  long_, // 300+ words
}

/// A cell key in the MAP-Elites archive, combining two behavioral dimensions.
class ArchiveCellKey {
  final StrategyType strategy;
  final PromptLengthBin lengthBin;

  const ArchiveCellKey(this.strategy, this.lengthBin);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArchiveCellKey &&
          strategy == other.strategy &&
          lengthBin == other.lengthBin;

  @override
  int get hashCode => Object.hash(strategy, lengthBin);

  @override
  String toString() => '($strategy, $lengthBin)';

  Map<String, dynamic> toJson() => {
        'strategy': strategy.name,
        'lengthBin': lengthBin.name,
      };

  factory ArchiveCellKey.fromJson(Map<String, dynamic> json) {
    return ArchiveCellKey(
      StrategyType.values.byName(json['strategy'] as String),
      PromptLengthBin.values.byName(json['lengthBin'] as String),
    );
  }
}

/// A MAP-Elites archive that maintains the best-performing variant
/// in each cell of a 2D behavioral space (strategy x prompt length).
class MapElitesArchive {
  final Map<ArchiveCellKey, ExperimentRun> _cells = {};

  /// Creates an empty archive.
  MapElitesArchive();

  /// Total number of possible cells in the archive.
  int get cellCount => StrategyType.values.length * PromptLengthBin.values.length;

  /// Number of occupied cells.
  int get occupiedCells => _cells.length;

  /// Number of empty cells.
  int get emptyCells => cellCount - occupiedCells;

  /// Attempts to insert a run into its classified cell.
  ///
  /// Returns true if the run was inserted (cell was empty or new score
  /// is higher than the current occupant).
  bool tryInsert(ExperimentRun run) {
    final key = classifyVariant(run.variant);
    final existing = _cells[key];

    if (existing == null || run.overallScore > existing.overallScore) {
      _cells[key] = run;
      return true;
    }
    return false;
  }

  /// Classifies a variant into an archive cell based on its strategy type
  /// and prompt word count.
  ArchiveCellKey classifyVariant(PromptVariant variant) {
    final strategy = _classifyStrategy(variant);
    final lengthBin = _classifyLength(variant.systemPrompt);
    return ArchiveCellKey(strategy, lengthBin);
  }

  /// Returns all runs currently in the archive.
  List<ExperimentRun> allRuns() => _cells.values.toList();

  /// Returns the best-scoring run across all cells, or null if empty.
  ExperimentRun? bestRun() {
    if (_cells.isEmpty) return null;
    return _cells.values.reduce(
      (a, b) => a.overallScore >= b.overallScore ? a : b,
    );
  }

  /// Returns the top N runs by score across all cells.
  List<ExperimentRun> topN(int n) {
    final runs = allRuns()..sort((a, b) => b.overallScore.compareTo(a.overallScore));
    return runs.take(n).toList();
  }

  /// Returns the run in the given cell, or null if empty.
  ExperimentRun? getCell(ArchiveCellKey key) => _cells[key];

  /// All occupied cell keys.
  Iterable<ArchiveCellKey> get occupiedCellKeys => _cells.keys;

  /// Finds a parent in a different cell whose dimension scores are most
  /// complementary to the given parent (strong where parent is weak).
  ///
  /// Returns null if no other runs exist in the archive.
  ExperimentRun? complementaryParent(ExperimentRun parent) {
    final parentKey = classifyVariant(parent.variant);
    final parentDimScores = _computeDimensionAverages(parent);

    ExperimentRun? bestComplement;
    var bestComplementScore = -1.0;

    for (final entry in _cells.entries) {
      if (entry.key == parentKey) continue;

      final candidate = entry.value;
      final candidateDimScores = _computeDimensionAverages(candidate);

      // Complementarity: how well does the candidate fill the parent's gaps?
      // Higher score = candidate is strong where parent is weak.
      var complementarity = 0.0;
      for (final dim in parentDimScores.keys) {
        final parentScore = parentDimScores[dim] ?? 3.0;
        final candidateScore = candidateDimScores[dim] ?? 3.0;
        // Reward when candidate is strong (high) and parent is weak (low).
        complementarity += (candidateScore - parentScore).clamp(0.0, 5.0);
      }

      if (complementarity > bestComplementScore) {
        bestComplementScore = complementarity;
        bestComplement = candidate;
      }
    }

    return bestComplement;
  }

  Map<String, double> _computeDimensionAverages(ExperimentRun run) {
    final sums = <String, double>{};
    final counts = <String, int>{};
    for (final eval in run.evaluations) {
      for (final score in eval.scores) {
        sums[score.dimension] = (sums[score.dimension] ?? 0) + score.score;
        counts[score.dimension] = (counts[score.dimension] ?? 0) + 1;
      }
    }
    return {
      for (final key in sums.keys) key: sums[key]! / counts[key]!,
    };
  }

  StrategyType _classifyStrategy(PromptVariant variant) {
    // Use explicit strategyType if set.
    if (variant.strategyType != null) {
      try {
        return StrategyType.values.byName(variant.strategyType!);
      } on ArgumentError {
        // Fall through to heuristics.
      }
    }

    // Fallback heuristics based on prompt text.
    final text = variant.systemPrompt.toLowerCase();

    if (text.contains('socratic') ||
        text.contains('assumption') ||
        text.contains('before answering')) {
      return StrategyType.socratic;
    }
    if (text.contains('skeptic') ||
        text.contains('counterargument') ||
        text.contains('wrong') ||
        text.contains('contrarian') ||
        text.contains('adversarial')) {
      return StrategyType.adversarial;
    }
    if (text.contains('rule') ||
        text.contains('never') ||
        text.contains('always') ||
        text.contains('constraint')) {
      return StrategyType.constraint;
    }
    if (text.contains('analogy') ||
        text.contains('different field') ||
        text.contains('cross-domain') ||
        text.contains('domain transfer')) {
      return StrategyType.domainTransfer;
    }
    if (text.contains('feel') ||
        text.contains('care') ||
        text.contains('emotion') ||
        text.contains('satisfaction') ||
        text.contains('beautiful')) {
      return StrategyType.emotional;
    }
    if (text.contains('persona') ||
        text.contains('polymath') ||
        text.contains('engineer') ||
        text.contains('colleague') ||
        text.contains('explaining')) {
      return StrategyType.persona;
    }
    if (text.contains('before respond') ||
        text.contains('consider') ||
        text.contains('meta') ||
        text.contains('think about')) {
      return StrategyType.metacognitive;
    }

    // Very short prompts are likely minimalist.
    if (variant.systemPrompt.split(RegExp(r'\s+')).length < 30) {
      return StrategyType.minimalist;
    }

    return StrategyType.persona; // Default fallback.
  }

  PromptLengthBin _classifyLength(String prompt) {
    final wordCount = prompt.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    if (wordCount < 100) return PromptLengthBin.short_;
    if (wordCount <= 300) return PromptLengthBin.medium;
    return PromptLengthBin.long_;
  }

  /// Serializes the archive to JSON.
  Map<String, dynamic> toJson() {
    final cells = <Map<String, dynamic>>[];
    for (final entry in _cells.entries) {
      cells.add({
        'key': entry.key.toJson(),
        'run': entry.value.toJson(),
      });
    }
    return {'cells': cells};
  }

  /// Deserializes the archive from JSON.
  factory MapElitesArchive.fromJson(Map<String, dynamic> json) {
    final archive = MapElitesArchive();
    final cells = json['cells'] as List;
    for (final cell in cells) {
      final cellMap = cell as Map<String, dynamic>;
      final key = ArchiveCellKey.fromJson(cellMap['key'] as Map<String, dynamic>);
      final run = ExperimentRun.fromJson(cellMap['run'] as Map<String, dynamic>);
      archive._cells[key] = run;
    }
    return archive;
  }
}
