import 'dart:convert';
import 'dart:io';

import 'package:claude_resonance/claude_resonance.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

void main(List<String> arguments) async {
  final config = _parseArgs(arguments);

  stdout.writeln('╔════════════════════════════════════════╗');
  stdout.writeln('║        Claude Resonance v0.2.0         ║');
  stdout.writeln('║   MAP-Elites System Prompt Evolution   ║');
  stdout.writeln('╚════════════════════════════════════════╝');
  stdout.writeln();
  stdout.writeln('Config:');
  stdout.writeln('  Generations:        ${config.generations}');
  stdout.writeln('  Variants/gen:       ${config.variantsPerGeneration}');
  stdout.writeln('  Eval replicas:      ${config.evaluationReplicas}');
  stdout.writeln('  Researcher model:   ${config.researcherModel}');
  stdout.writeln('  Subject model:      ${config.subjectModel}');
  stdout.writeln('  Evaluator model:    ${config.evaluatorModel}');
  stdout.writeln('  Subject budget:     \$${config.subjectBudgetUsd?.toStringAsFixed(2) ?? "unlimited"}/call');
  stdout.writeln('  Evaluator budget:   \$${config.evaluatorBudgetUsd?.toStringAsFixed(2) ?? "unlimited"}/call');

  final runner = ProcessClaudeRunner();
  final store = JsonStore(config.experimentsDir);

  // THE LAW (enforced in code, not just prose): no run launches without a
  // green contamination probe. Every result is invalid if any role inherits
  // Claude Code's own config, so we fail CLOSED — abort unless the gate is
  // green. `--skip-probe` is the explicit, loud fail-open escape hatch.
  if (arguments.contains('--skip-probe')) {
    stdout.writeln('\n⚠  --skip-probe: contamination gate BYPASSED by request.\n');
  } else {
    stdout.writeln('\n  Contamination probe (gate)...');
    final probe = await runContaminationProbe(runner, model: config.subjectModel);
    if (!probe.clean) {
      stderr.writeln('\n❌ CONTAMINATED — pre-run gate failed. Leaked canaries:');
      probe.hits.forEach(
          (channel, phrases) => stderr.writeln('   [$channel] ${phrases.join(", ")}'));
      stderr.writeln('\nAborting: results would be invalid. Fix isolation '
          '(see lib/src/runner/claude_runner.dart) or pass --skip-probe to '
          'override at your own risk.');
      exit(1);
    }
    stdout.writeln('  ✅ Probe CLEAN — proceeding.\n');
  }

  // Load seed prompts.
  final seeds = await _loadSeedPrompts(config.seedPromptsDir);
  stdout.writeln('  Seed prompts:       ${seeds.length}');

  final experimentRunner = ExperimentRunner(
    runner: runner,
    config: config,
    store: store,
    seedVariants: seeds,
    onGenerationComplete: (run) {
      stdout.writeln('  [Gen ${run.generation}] '
          'Score: ${run.overallScore.toStringAsFixed(2)}');
    },
  );

  try {
    await experimentRunner.run();
  } catch (e, st) {
    stderr.writeln('Error: $e');
    stderr.writeln(st);
    exit(1);
  }
}

ExperimentConfig _parseArgs(List<String> args) {
  var generations = 5;
  var researcherModel = 'opus';
  var subjectModel = 'opus';
  var evaluatorModel = 'opus';
  var experimentsDir = 'data/experiments';
  var seedDir = 'data/seed_prompts';
  var variantsPerGen = 2;
  var evalReplicas = 2;
  double? subjectBudget = 0.50;
  double? evaluatorBudget = 0.30;

  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--generations' || '-g':
        generations = int.parse(args[++i]);
      case '--researcher-model':
        researcherModel = args[++i];
      case '--subject-model':
        subjectModel = args[++i];
      case '--evaluator-model':
        evaluatorModel = args[++i];
      case '--output-dir' || '-o':
        experimentsDir = args[++i];
      case '--seed-dir':
        seedDir = args[++i];
      case '--variants-per-gen':
        variantsPerGen = int.parse(args[++i]);
      case '--eval-replicas':
        evalReplicas = int.parse(args[++i]);
      case '--subject-budget':
        subjectBudget = double.parse(args[++i]);
      case '--evaluator-budget':
        evaluatorBudget = double.parse(args[++i]);
      case '--no-budget':
        subjectBudget = null;
        evaluatorBudget = null;
      case '--skip-probe':
        // Handled directly in main() as a fail-open escape; no config field.
        break;
      case '--help' || '-h':
        _printUsage();
        exit(0);
      default:
        stderr.writeln('Unknown argument: ${args[i]}');
        _printUsage();
        exit(1);
    }
  }

  return ExperimentConfig(
    generations: generations,
    researcherModel: researcherModel,
    subjectModel: subjectModel,
    evaluatorModel: evaluatorModel,
    experimentsDir: experimentsDir,
    seedPromptsDir: seedDir,
    variantsPerGeneration: variantsPerGen,
    evaluationReplicas: evalReplicas,
    subjectBudgetUsd: subjectBudget,
    evaluatorBudgetUsd: evaluatorBudget,
  );
}

void _printUsage() {
  stdout.writeln('''
Usage: dart run claude_resonance [options]

Options:
  -g, --generations <n>       Number of evolution generations (default: 5)
  --researcher-model <model>  Model for the Researcher (default: opus)
  --subject-model <model>     Model for the Subject (default: opus)
  --evaluator-model <model>   Model for the Evaluator (default: opus)
  -o, --output-dir <path>     Output directory (default: data/experiments)
  --seed-dir <path>           Seed prompts directory (default: data/seed_prompts)
  --variants-per-gen <n>      Variants per generation (default: 2)
  --eval-replicas <n>         Evaluation replicas for averaging (default: 2)
  -h, --help                  Show this help
''');
}

Future<List<PromptVariant>> _loadSeedPrompts(String dir) async {
  final directory = Directory(dir);
  if (!await directory.exists()) return [];

  const uuid = Uuid();
  final variants = <PromptVariant>[];

  await for (final entity in directory.list()) {
    if (entity is File && entity.path.endsWith('.json')) {
      try {
        final content = await entity.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        variants.add(PromptVariant(
          id: uuid.v4(),
          systemPrompt: json['system_prompt'] as String,
          generation: 0,
          createdAt: DateTime.now().toUtc(),
          researcherHypothesis: json['hypothesis'] as String?,
          researcherRationale: p.basenameWithoutExtension(entity.path),
          strategyType: json['strategy_type'] as String?,
        ));
      } on FormatException {
        stderr.writeln('Warning: skipping malformed seed file ${entity.path}');
      }
    }
  }

  return variants;
}
