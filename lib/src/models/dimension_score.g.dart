// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dimension_score.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DimensionScore _$DimensionScoreFromJson(Map<String, dynamic> json) =>
    _DimensionScore(
      dimension: json['dimension'] as String,
      score: (json['score'] as num).toInt(),
      justification: json['justification'] as String,
    );

Map<String, dynamic> _$DimensionScoreToJson(_DimensionScore instance) =>
    <String, dynamic>{
      'dimension': instance.dimension,
      'score': instance.score,
      'justification': instance.justification,
    };
