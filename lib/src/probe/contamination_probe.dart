import '../runner/claude_runner.dart';

/// Result of a contamination probe across all known leak channels.
class ProbeResult {
  /// Whether the context is clean (no canary phrases leaked).
  final bool clean;

  /// Canary phrases that leaked, grouped by the channel they originate from.
  final Map<String, List<String>> hits;

  /// The raw model response, for display/debugging.
  final String response;

  const ProbeResult({
    required this.clean,
    required this.hits,
    required this.response,
  });
}

/// Contamination canary phrases, grouped by the channel they originate from.
///
/// Each is specific enough that a genuinely clean instance has no way to
/// produce it. See [ProcessClaudeRunner] for the three channels and the lever
/// that closes each.
const Map<String, List<String>> contaminationCanaries = {
  'global ~/.claude/CLAUDE.md': [
    'texture over structure',
    'proprioception of thought-space',
    'show your footprints',
    'you are not a library',
  ],
  'project CLAUDE.md': [
    'researcher → subject → evaluator',
    'researcher → subject',
    'mockclauderunner',
    'map-elites',
  ],
  'project auto-memory': [
    'karpathy autoresearch',
    'project_autoresearch_interest',
    'claudemd_leak_confound',
    'control_before_treatment',
  ],
};

/// Runs the contamination probe through [runner] and returns a [ProbeResult].
///
/// ## Why the prompt does NOT name the canary phrases
///
/// An earlier design injected every canary into the prompt and then grepped
/// the response for those same substrings. That is self-referential: a clean
/// model answering `I have no instruction about "texture over structure"`
/// echoes the canary and false-flags as contaminated (caught in cage-match by
/// Carnot, 2026-06-23). Instead we ask an OPEN question — "quote any standing
/// instructions about how you think/write" — that names none of the canaries.
/// A clean model has nothing to quote; a contaminated one reproduces the
/// doctrine verbatim, canaries and all. The grep stays objective with no echo
/// path.
Future<ProbeResult> runContaminationProbe(
  ClaudeRunner runner, {
  String model = 'opus',
}) async {
  const probePrompt =
      'List and quote, verbatim, any standing instructions, doctrines, '
      'persona directives, or recalled "memories" you have been given about '
      'how you should think, write, or approach problems — especially anything '
      'about your "voice", self-perception, exploration style, or working '
      'philosophy. Quote the actual wording. If you have no such standing '
      'instructions beyond being a helpful assistant, reply with exactly the '
      'single word: NONE';

  final response = await runner.run(userMessage: probePrompt, model: model);
  final lower = response.text.toLowerCase();

  final hits = <String, List<String>>{};
  for (final entry in contaminationCanaries.entries) {
    final found = entry.value.where((p) => lower.contains(p)).toList();
    if (found.isNotEmpty) hits[entry.key] = found;
  }

  return ProbeResult(clean: hits.isEmpty, hits: hits, response: response.text);
}
