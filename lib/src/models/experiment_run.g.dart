// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'experiment_run.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExperimentRun _$ExperimentRunFromJson(Map<String, dynamic> json) =>
    _ExperimentRun(
      generation: (json['generation'] as num).toInt(),
      variant: PromptVariant.fromJson(json['variant'] as Map<String, dynamic>),
      responses: (json['responses'] as List<dynamic>)
          .map((e) => TaskResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      evaluations: (json['evaluations'] as List<dynamic>)
          .map((e) => EvaluationResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      overallScore: (json['overallScore'] as num).toDouble(),
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: DateTime.parse(json['completedAt'] as String),
    );

Map<String, dynamic> _$ExperimentRunToJson(_ExperimentRun instance) =>
    <String, dynamic>{
      'generation': instance.generation,
      'variant': instance.variant,
      'responses': instance.responses,
      'evaluations': instance.evaluations,
      'overallScore': instance.overallScore,
      'startedAt': instance.startedAt.toIso8601String(),
      'completedAt': instance.completedAt.toIso8601String(),
    };
