import 'package:freezed_annotation/freezed_annotation.dart';

part 'prompt_variant.freezed.dart';
part 'prompt_variant.g.dart';

/// A system prompt variant being tested in the evolution pipeline.
///
/// Each variant is produced by the Researcher (except seed prompts) and
/// carries metadata about its lineage and the hypothesis behind it.
@freezed
abstract class PromptVariant with _$PromptVariant {
  const factory PromptVariant({
    required String id,
    required String systemPrompt,
    required int generation,

    /// Single parent for backward compatibility (simple mutations).
    String? parentId,

    required DateTime createdAt,
    String? researcherHypothesis,
    String? researcherRationale,

    /// The MAP-Elites strategy classification for this variant.
    String? strategyType,

    /// Multiple parent IDs for crossover offspring.
    List<String>? parentIds,

    /// Which mutation operator produced this variant.
    String? mutationOperator,
  }) = _PromptVariant;

  factory PromptVariant.fromJson(Map<String, dynamic> json) =>
      _$PromptVariantFromJson(json);
}
