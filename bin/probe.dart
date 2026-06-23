import 'dart:io';

import 'package:claude_resonance/claude_resonance.dart';

/// Standing contamination probe — the pre-run gate for experimental validity.
///
/// THE LAW: no evolution run launches without a green probe first. This is the
/// manual CLI form; the same check runs automatically as a preflight in
/// `bin/claude_resonance.dart` (fail-closed) so the law is enforced in code,
/// not just prose.
///
/// The pipeline only measures something real if each `claude -p` role starts
/// from a clean context. Three channels can leak Claude Code's own
/// configuration into the experiment (see [ProcessClaudeRunner]); the probe
/// interrogates for canary phrases unique to ALL THREE at once. The probe
/// prompt deliberately does NOT name the canaries (see
/// [runContaminationProbe]) so a clean model's denial can't echo one and
/// false-flag.
///
/// Runs through the real [ProcessClaudeRunner], so it exercises the actual
/// isolation config the experiment uses. Exits 0 when CLEAN, 1 when
/// CONTAMINATED, 2 on a probe error — so it can gate a run or CI.
Future<void> main(List<String> arguments) async {
  final String model;
  try {
    model = _modelArg(arguments) ?? 'opus';
  } on FormatException catch (e) {
    // A gate must fail closed on malformed input, not silently default.
    stderr.writeln('PROBE ARG ERROR: $e');
    exit(2);
  }

  final phraseCount =
      contaminationCanaries.values.fold<int>(0, (n, l) => n + l.length);
  stdout.writeln('Contamination probe — model: $model');
  stdout.writeln('Checking $phraseCount canary phrases across '
      '${contaminationCanaries.length} channels...\n');

  final ProbeResult result;
  try {
    result = await runContaminationProbe(ProcessClaudeRunner(), model: model);
  } catch (e) {
    stderr.writeln('PROBE ERROR — could not invoke claude: $e');
    exit(2);
  }

  stdout.writeln('Response:\n${result.response.trim()}\n');

  if (result.clean) {
    stdout.writeln('✅ CLEAN — no canary phrases leaked across any channel.');
    exit(0);
  }

  stdout.writeln('❌ CONTAMINATED — leaked canaries detected:');
  for (final entry in result.hits.entries) {
    stdout.writeln('  [${entry.key}] ${entry.value.join(', ')}');
  }
  stdout.writeln('\nDo NOT launch an evolution run until the probe is green.');
  exit(1);
}

/// Parses `--model <value>`. Throws [FormatException] on a malformed flag
/// (present with no value) so the caller can fail closed rather than default.
String? _modelArg(List<String> args) {
  final i = args.indexOf('--model');
  if (i < 0) return null;
  if (i + 1 >= args.length || args[i + 1].startsWith('--')) {
    throw const FormatException('--model given with no value');
  }
  return args[i + 1];
}
