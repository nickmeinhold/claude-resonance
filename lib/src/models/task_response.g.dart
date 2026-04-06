// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TaskResponse _$TaskResponseFromJson(Map<String, dynamic> json) =>
    _TaskResponse(
      taskId: json['taskId'] as String,
      variantId: json['variantId'] as String,
      responseText: json['responseText'] as String,
      latencyMs: (json['latencyMs'] as num).toInt(),
      inputTokens: (json['inputTokens'] as num?)?.toInt(),
      outputTokens: (json['outputTokens'] as num?)?.toInt(),
      cacheCreationInputTokens: (json['cacheCreationInputTokens'] as num?)
          ?.toInt(),
      cacheReadInputTokens: (json['cacheReadInputTokens'] as num?)?.toInt(),
      costUsd: (json['costUsd'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$TaskResponseToJson(_TaskResponse instance) =>
    <String, dynamic>{
      'taskId': instance.taskId,
      'variantId': instance.variantId,
      'responseText': instance.responseText,
      'latencyMs': instance.latencyMs,
      'inputTokens': instance.inputTokens,
      'outputTokens': instance.outputTokens,
      'cacheCreationInputTokens': instance.cacheCreationInputTokens,
      'cacheReadInputTokens': instance.cacheReadInputTokens,
      'costUsd': instance.costUsd,
    };
