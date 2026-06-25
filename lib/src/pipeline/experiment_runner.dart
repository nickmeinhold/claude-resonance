import 'dart:io';

import '../archive/map_elites_archive.dart';
import '../battery/test_battery.dart';
import '../config/config.dart';
import '../models/experiment_run.dart';
import '../models/prompt_variant.dart';
import '../models/task_response.dart';
import '../runner/claude_runner.dart';
import '../storage/json_store.dart';
import 'evaluator.dart';
import 'researcher.dart';
import 'subject.dart';

/// Main loop orchestrator for the prompt evolution pipeline.
///
/// Uses MAP-Elites to maintain an archive of high-performing variants
/// across a 2D behavioral space (strategy type x prompt length).
///
/// For each generation:
/// 1. **Researcher** selects an operator and generates variant(s)
/// 2. **Subject** runs the test battery under each variant
/// 3. **Evaluator** scores each response on the rubric (with replicas)
/// 4. Results are inserted into the MAP-Elites archive
class ExperimentRunner {
  final ClaudeRunner _runner;
  final ExperimentConfig _config;
  final JsonStore _store;

  /// The MAP-Elites archive tracking the best variant per cell.
  final MapElitesArchive archive;

  /// Optional seed variants for generation 0.
  final List<PromptVariant> seedVariants;

  /// Called after each run completes, for progress reporting.
  final void Function(ExperimentRun run)? onGenerationComplete;

  ExperimentRunner({
    required ClaudeRunner runner,
    required ExperimentConfig config,
    required JsonStore store,
    MapElitesArchive? archive,
    this.seedVariants = const [],
    this.onGenerationComplete,
  })  : _runner = runner,
        _config = config,
        _store = store,
        archive = archive ?? MapElitesArchive();

  /// Runs the full evolution loop using MAP-Elites.
  Future<List<ExperimentRun>> run() async {
    await _store.initialize();

    final researcher = Researcher(
      _runner,
      model: _config.researcherModel,
      topN: _config.topNForResearcher,
    );
    final subject = Subject(_runner,
        model: _config.subjectModel,
        maxBudgetUsd: _config.subjectBudgetUsd);
    final evaluator = Evaluator(_runner,
        model: _config.evaluatorModel,
        maxBudgetUsd: _config.evaluatorBudgetUsd);

    final allRuns = <ExperimentRun>[];
    final dashboardHistory = <Map<String, dynamic>>[];

    // Restore archive from previous run if available.
    final savedArchive = await _store.readArchive();
    if (savedArchive != null) {
      for (final run in savedArchive.allRuns()) {
        archive.tryInsert(run);
      }
      stdout.writeln('  Restored archive: '
          '${archive.occupiedCells}/${archive.cellCount} cells');
    }

    // Determine the resume point from existing data — at PER-VARIANT
    // granularity, not per-generation. A crash partway through a generation
    // leaves fewer than `variantsPerGeneration` runs at the highest
    // generation; resuming at generation+1 would silently drop the unfinished
    // variants (and the default config runs 2 variants/generation, so this
    // bites the default path, not just custom fan-out).
    final existingRuns = await _store.readAllRuns();
    final maxGen = existingRuns.isEmpty
        ? -1
        : existingRuns.map((r) => r.generation).reduce(
              (a, b) => a > b ? a : b,
            );
    final completedInMaxGen =
        existingRuns.where((r) => r.generation == maxGen).length;

    // Seed phase (generation 0) resume: pick up at the first seed that
    // hasn't been run yet, instead of an all-or-nothing skip.
    final seedStartIndex = maxGen == 0 ? completedInMaxGen : 0;
    final seedsComplete =
        maxGen > 0 || (maxGen == 0 && completedInMaxGen >= seedVariants.length);

    // Evolution loop resume: re-enter a partially-finished generation at the
    // next variant index; otherwise start the following generation fresh.
    final int firstGen;
    final int firstGenVariantStart;
    if (maxGen <= 0) {
      firstGen = 1;
      firstGenVariantStart = 0;
    } else if (completedInMaxGen < _config.variantsPerGeneration) {
      firstGen = maxGen;
      firstGenVariantStart = completedInMaxGen;
    } else {
      firstGen = maxGen + 1;
      firstGenVariantStart = 0;
    }

    if (maxGen >= 0) {
      stdout.writeln('  Resuming: generation $firstGen, variant '
          '${firstGenVariantStart + 1}/${_config.variantsPerGeneration}'
          '${seedsComplete ? "" : " (seeds incomplete)"}');
    }

    // No saved archive but run history exists: rebuild the archive by
    // replaying history. tryInsert keeps only the best run per cell, so
    // this reconstructs the archive state exactly — without it, a resume
    // would start mid-evolution with an empty gene pool.
    if (savedArchive == null && existingRuns.isNotEmpty) {
      for (final run in existingRuns) {
        archive.tryInsert(run);
      }
      stdout.writeln('  Rebuilt archive from ${existingRuns.length} prior '
          'runs: ${archive.occupiedCells}/${archive.cellCount} cells');
      await _store.writeArchive(archive);
    }

    // Rehydrate the dashboard history timeline from prior run files.
    // The archive is restored/rebuilt above, but `history` is a per-process
    // timeline that lives only in this list — not in the archive — so on
    // resume it starts empty and the first dashboard write would otherwise
    // truncate the chart to post-resume generations only. Runs after the
    // archive is populated so the survivor check below can read it.
    if (existingRuns.isNotEmpty) {
      final ordered = [...existingRuns]
        ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
      for (final run in ordered) {
        final cell = archive.classifyVariant(run.variant);
        // The historical insert decision can't be recovered (displacements
        // aren't logged), so mark survivors — runs that still own their
        // cell — as inserted. Accurate enough for the score-over-time chart.
        final inserted =
            archive.getCell(cell)?.variant.id == run.variant.id;
        _addHistoryEntry(dashboardHistory, run, inserted, cell);
      }
      stdout.writeln(
          '  Rehydrated dashboard history: ${dashboardHistory.length} entries');
    }

    // Seed phase: run all seeds, evaluate, insert into archive.
    // On resume, run only the seeds not yet completed (seedStartIndex).
    if (seedVariants.isNotEmpty && !seedsComplete) {
      stdout.writeln('\n━━━ Generation 0: Seed Variants ━━━');
      for (final seed in seedVariants.skip(seedStartIndex)) {
        try {
          final run = await _runGeneration(
            variant: seed,
            generation: 0,
            subject: subject,
            evaluator: evaluator,
          );
          allRuns.add(run);
          await _store.writeRun(run);

          final inserted = archive.tryInsert(run);
          final cell = archive.classifyVariant(seed);
          _reportRun(run, inserted: inserted, cell: cell);
          onGenerationComplete?.call(run);

          if (inserted) await _store.writeArchive(archive);
          _addHistoryEntry(dashboardHistory, run, inserted, cell);
          await _writeDashboardState(0, dashboardHistory);
        } catch (e) {
          stdout.writeln('  SKIPPED seed "${seed.strategyType ?? seed.id}": $e');
        }
      }
      _reportArchiveStatus();
    }

    // Evolution loop. The first resumed generation starts at the variant
    // index where the prior run left off; later generations start at 0.
    for (var gen = firstGen; gen <= _config.generations; gen++) {
      stdout.writeln(
          '\n━━━ Generation $gen / ${_config.generations} ━━━');

      final variantStart = gen == firstGen ? firstGenVariantStart : 0;
      for (var v = variantStart; v < _config.variantsPerGeneration; v++) {
        try {
          // 1. Researcher generates a new variant via adaptive operator
          //    selection.
          stdout.writeln('  Researcher generating variant '
              '${v + 1}/${_config.variantsPerGeneration}...');
          final variant = await researcher.generateVariantV2(
            archive: archive,
            generation: gen,
            maxGenerations: _config.generations,
          );
          stdout.writeln(
              '  Operator: ${variant.mutationOperator ?? "unknown"}');
          stdout.writeln(
              '  Hypothesis: ${variant.researcherHypothesis ?? "N/A"}');

          // 2. Subject runs the test battery.
          // 3. Evaluator scores each response (with replicas).
          final run = await _runGeneration(
            variant: variant,
            generation: gen,
            subject: subject,
            evaluator: evaluator,
          );

          allRuns.add(run);
          await _store.writeRun(run);

          // 4. Insert into archive.
          final inserted = archive.tryInsert(run);
          final cell = archive.classifyVariant(variant);
          _reportRun(run, inserted: inserted, cell: cell);
          onGenerationComplete?.call(run);

          if (inserted) await _store.writeArchive(archive);
          _addHistoryEntry(dashboardHistory, run, inserted, cell);
          await _writeDashboardState(gen, dashboardHistory);
        } catch (e) {
          stdout.writeln('  SKIPPED variant ${v + 1}: $e');
        }
      }

      _reportArchiveStatus();
    }

    // Write final experiment log and dashboard state.
    final logPath = await _store.writeExperimentLog(allRuns);
    await _writeDashboardState(_config.generations, dashboardHistory);
    stdout.writeln('\n━━━ Experiment Complete ━━━');
    stdout.writeln('  Total runs: ${allRuns.length}');
    stdout.writeln('  Archive fill: '
        '${archive.occupiedCells}/${archive.cellCount} cells');
    final best = archive.bestRun();
    if (best != null) {
      stdout.writeln(
          '  Best score: ${best.overallScore.toStringAsFixed(2)}');
    }
    _reportTokenUsage(allRuns);
    stdout.writeln('  Log written to: $logPath');

    return allRuns;
  }

  Future<ExperimentRun> _runGeneration({
    required PromptVariant variant,
    required int generation,
    required Subject subject,
    required Evaluator evaluator,
  }) async {
    final startedAt = DateTime.now().toUtc();

    // Run test battery.
    stdout.writeln(
        '  Running ${TestBattery.tasks.length} test tasks...');
    final responses = await subject.runBattery(
      TestBattery.tasks,
      variant,
    );
    _reportResponseUsage(responses);

    // Evaluate all responses in parallel (each task is independent).
    stdout.writeln('  Evaluating responses...');
    final evalFutures = List.generate(TestBattery.tasks.length, (i) {
      return _config.evaluationReplicas > 1
          ? evaluator.evaluateWithReplicas(
              TestBattery.tasks[i],
              responses[i],
              replicas: _config.evaluationReplicas,
            )
          : evaluator.evaluate(
              TestBattery.tasks[i],
              responses[i],
            );
    });
    final evaluations = await Future.wait(evalFutures);

    final overallScore =
        evaluations.fold(0.0, (sum, e) => sum + e.aggregateScore) /
            evaluations.length;

    return ExperimentRun(
      generation: generation,
      variant: variant,
      responses: responses,
      evaluations: evaluations.cast(),
      overallScore: overallScore,
      startedAt: startedAt,
      completedAt: DateTime.now().toUtc(),
    );
  }

  void _reportRun(
    ExperimentRun run, {
    bool inserted = false,
    ArchiveCellKey? cell,
  }) {
    final insertStatus = inserted ? 'INSERTED' : 'rejected';
    stdout.writeln(
        '  Score: ${run.overallScore.toStringAsFixed(2)} '
        '[$insertStatus${cell != null ? " into $cell" : ""}]');

    // Per-dimension breakdown.
    final dimScores = <String, List<int>>{};
    for (final eval in run.evaluations) {
      for (final score in eval.scores) {
        dimScores.putIfAbsent(score.dimension, () => []).add(score.score);
      }
    }
    for (final entry in dimScores.entries) {
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      stdout.writeln('     ${entry.key}: ${avg.toStringAsFixed(1)}');
    }
  }

  // Running totals across the entire experiment.
  int _runningInputTokens = 0;
  int _runningOutputTokens = 0;
  double _runningCost = 0.0;

  /// Prints per-task token usage after each test battery completes.
  void _reportResponseUsage(List<TaskResponse> responses) {
    var batchInput = 0;
    var batchOutput = 0;
    var batchCost = 0.0;
    var tracked = 0;

    for (final r in responses) {
      if (r.inputTokens != null) {
        batchInput += r.inputTokens!;
        batchOutput += r.outputTokens ?? 0;
        batchCost += r.costUsd ?? 0.0;
        tracked++;
      }
    }

    if (tracked > 0) {
      _runningInputTokens += batchInput;
      _runningOutputTokens += batchOutput;
      _runningCost += batchCost;
      stdout.writeln('    ${batchInput + batchOutput} tokens '
          '(in: $batchInput, out: $batchOutput) '
          '\$${batchCost.toStringAsFixed(4)} '
          '· running: \$${_runningCost.toStringAsFixed(4)}');
    }
  }

  void _reportTokenUsage(List<ExperimentRun> runs) {
    // Use running totals if available, otherwise recompute from data.
    var totalInput = _runningInputTokens;
    var totalOutput = _runningOutputTokens;
    var totalCost = _runningCost;

    if (totalInput == 0) {
      for (final run in runs) {
        for (final response in run.responses) {
          if (response.inputTokens != null) {
            totalInput += response.inputTokens!;
            totalOutput += response.outputTokens ?? 0;
            totalCost += response.costUsd ?? 0.0;
          }
        }
      }
    }

    if (totalInput > 0 || totalOutput > 0) {
      stdout.writeln('  Token usage (subject responses only):');
      stdout.writeln('    Input:  $totalInput tokens');
      stdout.writeln('    Output: $totalOutput tokens');
      stdout.writeln('    Total:  ${totalInput + totalOutput} tokens');
      stdout.writeln('    Cost:   \$${totalCost.toStringAsFixed(4)}');
    }
  }

  void _reportArchiveStatus() {
    stdout.writeln('  Archive: '
        '${archive.occupiedCells}/${archive.cellCount} cells filled');
    final best = archive.bestRun();
    if (best != null) {
      stdout.writeln(
          '  Best in archive: ${best.overallScore.toStringAsFixed(2)}');
    }
  }

  void _addHistoryEntry(
    List<Map<String, dynamic>> history,
    ExperimentRun run,
    bool inserted,
    ArchiveCellKey cell,
  ) {
    final dimAvgs = <String, double>{};
    for (final eval in run.evaluations) {
      for (final score in eval.scores) {
        dimAvgs[score.dimension] =
            (dimAvgs[score.dimension] ?? 0) + score.score;
      }
    }
    final evalCount = run.evaluations.length;
    for (final dim in dimAvgs.keys.toList()) {
      dimAvgs[dim] = dimAvgs[dim]! / evalCount;
    }

    history.add({
      'generation': run.generation,
      'score': run.overallScore,
      'inserted': inserted,
      'strategy': cell.strategy.name,
      'lengthBin': cell.lengthBin.name,
      'operator': run.variant.mutationOperator,
      'hypothesis': run.variant.researcherHypothesis,
      'dimensions': dimAvgs,
      'timestamp': run.completedAt.toUtc().toIso8601String(),
    });
  }

  Future<void> _writeDashboardState(
    int currentGeneration,
    List<Map<String, dynamic>> history,
  ) async {
    await _store.writeDashboardState(
      archive,
      currentGeneration: currentGeneration,
      totalGenerations: _config.generations,
      history: history,
    );
  }
}
