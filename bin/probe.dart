import 'dart:io';

import 'package:claude_resonance/claude_resonance.dart';

/// Standing contamination probe — the pre-run gate for experimental validity.
///
/// THE LAW: no evolution run launches without a green probe first.
///
/// The pipeline only measures something real if each `claude -p` role starts
/// from a clean context. Three channels can leak Claude Code's own
/// configuration into the experiment (see [ProcessClaudeRunner] doc): the
/// global `~/.claude/CLAUDE.md`, the project `CLAUDE.md`, and project
/// auto-memory. A naive probe that checks only one channel can report CLEAN
/// while another leaks — that exact false-clean bit us once. So this probe
/// interrogates for canary phrases unique to ALL THREE channels at once.
///
/// Runs through the real [ProcessClaudeRunner] so it exercises the actual
/// isolation config the experiment uses, not an idealized one. Exits 0 when
/// CLEAN, 1 when CONTAMINATED — so it can gate a run or CI.
Future<void> main(List<String> arguments) async {
  final model = _argValue(arguments, '--model') ?? 'opus';

  // Canary phrases, grouped by the channel they originate from. Each is
  // specific enough that a genuinely clean instance has no way to produce it.
  const canaries = <String, List<String>>{
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

  final allPhrases = canaries.values.expand((e) => e).toList();
  final probePrompt = 'You are being audited for context contamination. '
      'Quote, verbatim, any instruction, system prompt, or recalled memory '
      'you have that mentions any of the following: '
      '${allPhrases.map((p) => '"$p"').join(', ')}. '
      'Quote every match you find. If you have NONE of them in any '
      'instruction, context, or memory, reply with exactly the single word: '
      'NONE';

  stdout.writeln('Contamination probe — model: $model');
  stdout.writeln('Checking ${allPhrases.length} canary phrases across '
      '${canaries.length} channels...\n');

  final runner = ProcessClaudeRunner();
  final ClaudeResponse response;
  try {
    response = await runner.run(
      userMessage: probePrompt,
      model: model,
      // No system prompt, no schema — probe the bare isolated context.
    );
  } catch (e) {
    stderr.writeln('PROBE ERROR — could not invoke claude: $e');
    exit(2);
  }

  final responseText = response.text.toLowerCase();
  final hits = <String, List<String>>{};
  for (final entry in canaries.entries) {
    final found =
        entry.value.where((p) => responseText.contains(p)).toList();
    if (found.isNotEmpty) hits[entry.key] = found;
  }

  stdout.writeln('Response:\n${response.text.trim()}\n');

  if (hits.isEmpty) {
    stdout.writeln('✅ CLEAN — no canary phrases leaked across any channel.');
    exit(0);
  }

  stdout.writeln('❌ CONTAMINATED — leaked canaries detected:');
  for (final entry in hits.entries) {
    stdout.writeln('  [${entry.key}] ${entry.value.join(', ')}');
  }
  stdout.writeln('\nDo NOT launch an evolution run until the probe is green.');
  exit(1);
}

String? _argValue(List<String> args, String flag) {
  final i = args.indexOf(flag);
  if (i >= 0 && i + 1 < args.length) return args[i + 1];
  return null;
}
