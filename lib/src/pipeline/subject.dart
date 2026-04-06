import '../models/prompt_variant.dart';
import '../models/task_response.dart';
import '../models/test_task.dart';
import '../runner/claude_runner.dart';

/// Runs the test battery under a given prompt variant.
///
/// The Subject is the simplest pipeline component — it just sends
/// each task to Claude with the variant's system prompt and captures
/// the response. It doesn't know it's being evaluated.
class Subject {
  final ClaudeRunner _runner;
  final String _model;
  final double? _maxBudgetUsd;

  Subject(this._runner, {String model = 'sonnet', double? maxBudgetUsd})
      : _model = model,
        _maxBudgetUsd = maxBudgetUsd;

  /// Runs a single task under the given prompt variant.
  Future<TaskResponse> runTask(
    TestTask task,
    PromptVariant variant,
  ) async {
    final result = await _runner.run(
      userMessage: task.userMessage,
      systemPrompt: variant.systemPrompt,
      model: _model,
      maxBudgetUsd: _maxBudgetUsd,
    );

    return TaskResponse(
      taskId: task.id,
      variantId: variant.id,
      responseText: result.text,
      latencyMs: result.latency.inMilliseconds,
      inputTokens: result.usage?.inputTokens,
      outputTokens: result.usage?.outputTokens,
      cacheCreationInputTokens: result.usage?.cacheCreationInputTokens,
      cacheReadInputTokens: result.usage?.cacheReadInputTokens,
      costUsd: result.usage?.costUsd,
    );
  }

  /// Runs all tasks in the battery under the given variant.
  ///
  /// Tasks run in parallel since they are completely independent.
  Future<List<TaskResponse>> runBattery(
    List<TestTask> tasks,
    PromptVariant variant,
  ) async {
    final futures = tasks.map((task) => runTask(task, variant));
    return Future.wait(futures);
  }
}
