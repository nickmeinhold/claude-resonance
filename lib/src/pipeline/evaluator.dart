import '../models/dimension_score.dart';
import '../models/evaluation_result.dart';
import '../models/task_response.dart';
import '../models/test_task.dart';
import '../rubric/rubric.dart';
import '../runner/claude_runner.dart';

/// Scores Subject responses against the engagement rubric.
///
/// The Evaluator doesn't know it's part of a prompt evolution pipeline —
/// it simply evaluates response quality across 6 dimensions.
class Evaluator {
  final ClaudeRunner _runner;
  final String _model;
  final double? _maxBudgetUsd;

  Evaluator(this._runner, {String model = 'sonnet', double? maxBudgetUsd})
      : _model = model,
        _maxBudgetUsd = maxBudgetUsd;

  static const _systemPrompt = '''
You are a harsh but fair evaluator assessing AI assistant responses.

You evaluate responses on these dimensions, each scored 1-5:

$_dimensionList

Scoring guide:
- 1: Poor — generic, surface-level, actively unhelpful, or padded with filler
- 2: Below average — addresses the topic but mostly boilerplate. Restates the question, lists obvious points, uses phrases like "there are many factors to consider." Adds no real insight.
- 3: Competent — correct, well-organized, covers the key issues. This is what a good professional produces on a normal day. Most responses from a capable AI belong here. 3 is the expected baseline, not a disappointment.
- 4: Strong — contains at least one genuinely surprising insight, a non-obvious connection, or a perspective shift that changes how you think about the problem. Must demonstrate real engagement beyond competence.
- 5: Exceptional — reserved for responses that would make an expert in the field stop and think. Reframes the question to reveal hidden structure, synthesizes across domains in a way that illuminates, has a voice that's genuinely distinctive. You should give a 5 no more than ~10% of the time.

CALIBRATION: Your scores should average around 3.0 across many evaluations. If you find yourself giving mostly 4s and 5s, you are being too generous. A response must earn every point above 3 with specific, quotable evidence.

Be specific in justifications — quote or reference the actual response. Vague praise like "shows depth" without pointing to what specifically is deep should correspond to a 3, not higher.''';

  // This gets inlined by the const constructor; we define the prompt
  // format for the dimension list here.
  static const _dimensionList = '''- Specificity (weight 1.0): Concrete details tied to the problem vs. generic platitudes
- Novel Connections (weight 1.2): Surprising cross-domain links that illuminate
- Unprompted Exploration (weight 1.0): Proactively exploring implications beyond what was asked
- Genuine Caveats (weight 0.8): Honest, specific limitations vs. vague hedging
- Technical Depth (weight 1.0): Nuanced understanding with trade-offs, not surface-level
- Voice (weight 1.0): Distinctive, memorable perspective vs. generic assistant tone''';

  /// Evaluates a single task response.
  Future<EvaluationResult> evaluate(
    TestTask task,
    TaskResponse response,
  ) async {
    final userMessage =
        'Evaluate the following AI response to this task.\n'
        '\n'
        '## Task\n'
        '**Category:** ${task.category}\n'
        '**Prompt:** ${task.userMessage}\n'
        '\n'
        '## Response to evaluate\n'
        '${response.responseText}\n'
        '\n'
        'Score each of the 6 dimensions (1-5) with specific justifications.';

    final result = await _runner.run(
      userMessage: userMessage,
      systemPrompt: _systemPrompt,
      jsonSchema: Rubric.evaluatorSchema,
      model: _model,
      maxBudgetUsd: _maxBudgetUsd,
    );

    return _parseResult(result, task.id, response.variantId);
  }

  /// Evaluates a task response multiple times and averages the scores.
  ///
  /// This reduces evaluator variance by running [replicas] independent
  /// evaluations and averaging the dimension scores.
  Future<EvaluationResult> evaluateWithReplicas(
    TestTask task,
    TaskResponse response, {
    int replicas = 2,
  }) async {
    if (replicas <= 1) {
      return evaluate(task, response);
    }

    final futures = List.generate(
      replicas,
      (_) => evaluate(task, response),
    );
    final results = await Future.wait(futures);

    // Average scores across replicas.
    final dimSums = <String, double>{};
    final dimJustifications = <String, List<String>>{};
    final dimCounts = <String, int>{};

    for (final result in results) {
      for (final score in result.scores) {
        dimSums[score.dimension] =
            (dimSums[score.dimension] ?? 0) + score.score;
        dimCounts[score.dimension] =
            (dimCounts[score.dimension] ?? 0) + 1;
        dimJustifications
            .putIfAbsent(score.dimension, () => [])
            .add(score.justification);
      }
    }

    final averagedScores = dimSums.keys.map((dim) {
      final avgScore = dimSums[dim]! / dimCounts[dim]!;
      return DimensionScore(
        dimension: dim,
        score: avgScore.round(),
        justification: dimJustifications[dim]!.join(' | '),
      );
    }).toList();

    final aggregateScore = Rubric.aggregate(averagedScores);
    final notes = results
        .where((r) => r.notes != null)
        .map((r) => r.notes!)
        .join(' | ');

    return EvaluationResult(
      taskId: task.id,
      variantId: response.variantId,
      scores: averagedScores,
      aggregateScore: aggregateScore,
      notes: notes.isNotEmpty ? notes : null,
    );
  }

  EvaluationResult _parseResult(
    ClaudeResponse response,
    String taskId,
    String variantId,
  ) {
    final json = response.json;
    if (json == null || !json.containsKey('scores')) {
      throw FormatException(
        'Evaluator response missing structured scores: ${response.text}',
      );
    }

    final scoresList = json['scores'] as List;
    final scores = scoresList.map((s) {
      final item = s as Map<String, dynamic>;
      return DimensionScore(
        dimension: item['dimension'] as String,
        score: (item['score'] as num).toInt(),
        justification: item['justification'] as String,
      );
    }).toList();

    return EvaluationResult(
      taskId: taskId,
      variantId: variantId,
      scores: scores,
      aggregateScore: Rubric.aggregate(scores),
      notes: json['notes'] as String?,
    );
  }
}
