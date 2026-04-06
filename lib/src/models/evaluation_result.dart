import 'package:freezed_annotation/freezed_annotation.dart';

import 'dimension_score.dart';

part 'evaluation_result.freezed.dart';
part 'evaluation_result.g.dart';

/// Full evaluation of one task response across all rubric dimensions.
@freezed
abstract class EvaluationResult with _$EvaluationResult {
  const factory EvaluationResult({
    required String taskId,
    required String variantId,
    required List<DimensionScore> scores,
    required double aggregateScore,
    String? notes,
  }) = _EvaluationResult;

  factory EvaluationResult.fromJson(Map<String, dynamic> json) =>
      _$EvaluationResultFromJson(json);
}
