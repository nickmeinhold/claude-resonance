// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'evaluation_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EvaluationResult _$EvaluationResultFromJson(Map<String, dynamic> json) =>
    _EvaluationResult(
      taskId: json['taskId'] as String,
      variantId: json['variantId'] as String,
      scores: (json['scores'] as List<dynamic>)
          .map((e) => DimensionScore.fromJson(e as Map<String, dynamic>))
          .toList(),
      aggregateScore: (json['aggregateScore'] as num).toDouble(),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$EvaluationResultToJson(_EvaluationResult instance) =>
    <String, dynamic>{
      'taskId': instance.taskId,
      'variantId': instance.variantId,
      'scores': instance.scores,
      'aggregateScore': instance.aggregateScore,
      'notes': instance.notes,
    };
