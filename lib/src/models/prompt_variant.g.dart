// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prompt_variant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PromptVariant _$PromptVariantFromJson(Map<String, dynamic> json) =>
    _PromptVariant(
      id: json['id'] as String,
      systemPrompt: json['systemPrompt'] as String,
      generation: (json['generation'] as num).toInt(),
      parentId: json['parentId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      researcherHypothesis: json['researcherHypothesis'] as String?,
      researcherRationale: json['researcherRationale'] as String?,
      strategyType: json['strategyType'] as String?,
      parentIds: (json['parentIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      mutationOperator: json['mutationOperator'] as String?,
    );

Map<String, dynamic> _$PromptVariantToJson(_PromptVariant instance) =>
    <String, dynamic>{
      'id': instance.id,
      'systemPrompt': instance.systemPrompt,
      'generation': instance.generation,
      'parentId': instance.parentId,
      'createdAt': instance.createdAt.toIso8601String(),
      'researcherHypothesis': instance.researcherHypothesis,
      'researcherRationale': instance.researcherRationale,
      'strategyType': instance.strategyType,
      'parentIds': instance.parentIds,
      'mutationOperator': instance.mutationOperator,
    };
