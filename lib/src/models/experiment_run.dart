import 'package:freezed_annotation/freezed_annotation.dart';

import 'evaluation_result.dart';
import 'prompt_variant.dart';
import 'task_response.dart';

part 'experiment_run.freezed.dart';
part 'experiment_run.g.dart';

/// One complete generation in the evolution loop.
///
/// Contains the variant tested, all task responses, all evaluations,
/// and the overall aggregate score for this generation.
@freezed
abstract class ExperimentRun with _$ExperimentRun {
  const factory ExperimentRun({
    required int generation,
    required PromptVariant variant,
    required List<TaskResponse> responses,
    required List<EvaluationResult> evaluations,
    required double overallScore,
    required DateTime startedAt,
    required DateTime completedAt,
  }) = _ExperimentRun;

  factory ExperimentRun.fromJson(Map<String, dynamic> json) =>
      _$ExperimentRunFromJson(json);
}
