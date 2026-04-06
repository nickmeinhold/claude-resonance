import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_response.freezed.dart';
part 'task_response.g.dart';

/// The Subject's verbatim response to a test task under a given variant.
@freezed
abstract class TaskResponse with _$TaskResponse {
  const factory TaskResponse({
    required String taskId,
    required String variantId,
    required String responseText,

    /// How long Claude took to respond, in milliseconds.
    required int latencyMs,

    /// Token counts from verbose output. Null for legacy/mock data.
    int? inputTokens,
    int? outputTokens,
    int? cacheCreationInputTokens,
    int? cacheReadInputTokens,
    double? costUsd,
  }) = _TaskResponse;

  factory TaskResponse.fromJson(Map<String, dynamic> json) =>
      _$TaskResponseFromJson(json);
}
