import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../archive/map_elites_archive.dart';
import '../models/experiment_run.dart';

/// Persists experiment data as human-readable JSON files.
///
/// Uses atomic writes (write to `.tmp`, then rename) to prevent
/// corruption if the process is killed mid-write.
class JsonStore {
  final String directory;

  JsonStore(this.directory);

  /// Ensures the storage directory exists.
  Future<void> initialize() async {
    await Directory(directory).create(recursive: true);
  }

  /// Writes a single experiment run to a JSON file.
  ///
  /// Filename format: `gen_<generation>_<timestamp>.json`
  Future<String> writeRun(ExperimentRun run) async {
    await initialize();

    final timestamp =
        run.completedAt.toUtc().toIso8601String().replaceAll(':', '-');
    final filename = 'gen_${run.generation.toString().padLeft(3, '0')}'
        '_$timestamp.json';
    final filePath = p.join(directory, filename);
    final tmpPath = '$filePath.tmp';

    final jsonString =
        const JsonEncoder.withIndent('  ').convert(run.toJson());

    // Atomic write: write to .tmp then rename.
    final tmpFile = File(tmpPath);
    await tmpFile.writeAsString(jsonString);
    await tmpFile.rename(filePath);

    return filePath;
  }

  /// Writes the full experiment log (all runs) to a single file.
  Future<String> writeExperimentLog(
    List<ExperimentRun> runs, {
    String filename = 'experiment_log.json',
  }) async {
    await initialize();

    final filePath = p.join(directory, filename);
    final tmpPath = '$filePath.tmp';

    final data = {
      'runs': runs.map((r) => r.toJson()).toList(),
      'totalGenerations': runs.length,
      'bestScore': runs.isEmpty
          ? 0.0
          : runs
              .map((r) => r.overallScore)
              .reduce((a, b) => a > b ? a : b),
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(data);

    final tmpFile = File(tmpPath);
    await tmpFile.writeAsString(jsonString);
    await tmpFile.rename(filePath);

    return filePath;
  }

  /// Writes the MAP-Elites archive to a JSON file.
  Future<String> writeArchive(
    MapElitesArchive archive, {
    String filename = 'archive.json',
  }) async {
    await initialize();

    final filePath = p.join(directory, filename);
    final tmpPath = '$filePath.tmp';

    final jsonString =
        const JsonEncoder.withIndent('  ').convert(archive.toJson());

    final tmpFile = File(tmpPath);
    await tmpFile.writeAsString(jsonString);
    await tmpFile.rename(filePath);

    return filePath;
  }

  /// Reads the MAP-Elites archive from a JSON file.
  Future<MapElitesArchive?> readArchive({
    String filename = 'archive.json',
  }) async {
    final filePath = p.join(directory, filename);
    final file = File(filePath);
    if (!await file.exists()) return null;

    final content = await file.readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;
    return MapElitesArchive.fromJson(json);
  }

  /// Reads all experiment runs from individual JSON files in the directory.
  Future<List<ExperimentRun>> readAllRuns() async {
    final dir = Directory(directory);
    if (!await dir.exists()) return [];

    final runs = <ExperimentRun>[];

    await for (final entity in dir.list()) {
      if (entity is File &&
          entity.path.endsWith('.json') &&
          !entity.path.endsWith('.tmp') &&
          !p.basename(entity.path).startsWith('experiment_log') &&
          !p.basename(entity.path).startsWith('archive') &&
          !p.basename(entity.path).startsWith('dashboard_state')) {
        try {
          final content = await entity.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;

          // Handle both single-run files and log files.
          if (json.containsKey('runs')) {
            final list = json['runs'] as List;
            for (final item in list) {
              runs.add(
                ExperimentRun.fromJson(item as Map<String, dynamic>),
              );
            }
          } else {
            runs.add(ExperimentRun.fromJson(json));
          }
        } on FormatException {
          // Skip malformed files.
        }
      }
    }

    runs.sort((a, b) => a.generation.compareTo(b.generation));
    return runs;
  }

  /// Writes a lightweight dashboard state file optimized for live visualization.
  ///
  /// Updated after every variant evaluation so the dashboard can poll it.
  Future<String> writeDashboardState(
    MapElitesArchive archive, {
    required int currentGeneration,
    required int totalGenerations,
    required List<Map<String, dynamic>> history,
    String filename = 'dashboard_state.json',
  }) async {
    await initialize();

    final cells = <Map<String, dynamic>>[];
    for (final key in archive.occupiedCellKeys) {
      final run = archive.getCell(key)!;
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

      cells.add({
        'strategy': key.strategy.name,
        'lengthBin': key.lengthBin.name,
        'score': run.overallScore,
        'generation': run.generation,
        'variantId': run.variant.id,
        'systemPrompt': run.variant.systemPrompt,
        'hypothesis': run.variant.researcherHypothesis,
        'operator': run.variant.mutationOperator,
        'dimensions': dimAvgs,
      });
    }

    final data = {
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'currentGeneration': currentGeneration,
      'totalGenerations': totalGenerations,
      'archive': {
        'cells': cells,
        'occupiedCells': archive.occupiedCells,
        'totalCells': archive.cellCount,
      },
      'history': history,
    };

    final filePath = p.join(directory, filename);
    final tmpPath = '$filePath.tmp';
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);

    final tmpFile = File(tmpPath);
    await tmpFile.writeAsString(jsonString);
    await tmpFile.rename(filePath);

    return filePath;
  }

  /// Reads the experiment log file.
  Future<List<ExperimentRun>> readExperimentLog({
    String filename = 'experiment_log.json',
  }) async {
    final filePath = p.join(directory, filename);
    final file = File(filePath);
    if (!await file.exists()) return [];

    final content = await file.readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;
    final list = json['runs'] as List;

    return list
        .map((item) =>
            ExperimentRun.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
