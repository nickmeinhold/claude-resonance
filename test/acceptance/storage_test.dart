import 'dart:io';

import 'package:claude_resonance/claude_resonance.dart';
import 'package:test/test.dart';

void main() {
  group('JsonStore persistence round-trip', () {
    late Directory tempDir;
    late JsonStore store;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('resonance_test_');
      store = JsonStore(tempDir.path);
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    ExperimentRun _makeRun(int generation, double score) {
      return ExperimentRun(
        generation: generation,
        variant: PromptVariant(
          id: 'variant-$generation',
          systemPrompt: 'Prompt for gen $generation',
          generation: generation,
          createdAt: DateTime.utc(2026, 3, 16, generation),
        ),
        responses: [
          TaskResponse(
            taskId: 'task-1',
            variantId: 'variant-$generation',
            responseText: 'Response for gen $generation',
            latencyMs: 1000 + generation * 100,
          ),
        ],
        evaluations: [
          EvaluationResult(
            taskId: 'task-1',
            variantId: 'variant-$generation',
            scores: [
              DimensionScore(
                dimension: 'Specificity',
                score: generation + 1,
                justification: 'Gen $generation specificity.',
              ),
            ],
            aggregateScore: score,
          ),
        ],
        overallScore: score,
        startedAt: DateTime.utc(2026, 3, 16, generation),
        completedAt: DateTime.utc(2026, 3, 16, generation, 30),
      );
    }

    test('writeRun creates a file and readAllRuns restores it', () async {
      final run = _makeRun(1, 3.5);

      final path = await store.writeRun(run);
      expect(File(path).existsSync(), isTrue);

      final runs = await store.readAllRuns();
      expect(runs, hasLength(1));
      expect(runs.first.generation, 1);
      expect(runs.first.overallScore, 3.5);
      expect(runs.first.variant.systemPrompt, 'Prompt for gen 1');
    });

    test('multiple runs are sorted by generation', () async {
      await store.writeRun(_makeRun(3, 4.0));
      await store.writeRun(_makeRun(1, 3.0));
      await store.writeRun(_makeRun(2, 3.5));

      final runs = await store.readAllRuns();
      expect(runs.map((r) => r.generation).toList(), [1, 2, 3]);
    });

    test('writeExperimentLog creates a consolidated file', () async {
      final runs = [_makeRun(1, 3.0), _makeRun(2, 4.0)];

      final path = await store.writeExperimentLog(runs);
      expect(File(path).existsSync(), isTrue);

      final restored = await store.readExperimentLog();
      expect(restored, hasLength(2));
      expect(restored.first.generation, 1);
      expect(restored.last.generation, 2);
    });

    test('atomic writes leave no .tmp files', () async {
      await store.writeRun(_makeRun(1, 3.0));

      final files = tempDir.listSync();
      expect(files.where((f) => f.path.endsWith('.tmp')), isEmpty);
    });

    test('readAllRuns returns empty list for non-existent directory',
        () async {
      final emptyStore = JsonStore('${tempDir.path}/nonexistent');
      final runs = await emptyStore.readAllRuns();
      expect(runs, isEmpty);
    });
  });
}
