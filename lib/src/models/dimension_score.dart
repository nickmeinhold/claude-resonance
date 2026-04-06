import 'package:freezed_annotation/freezed_annotation.dart';

part 'dimension_score.freezed.dart';
part 'dimension_score.g.dart';

/// A score on a single rubric dimension (1–5) with justification.
@freezed
abstract class DimensionScore with _$DimensionScore {
  const factory DimensionScore({
    required String dimension,
    required int score,
    required String justification,
  }) = _DimensionScore;

  factory DimensionScore.fromJson(Map<String, dynamic> json) =>
      _$DimensionScoreFromJson(json);
}
