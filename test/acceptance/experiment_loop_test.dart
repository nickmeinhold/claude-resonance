import 'dart:convert';
import 'dart:io';

import 'package:claude_resonance/claude_resonance.dart';
import 'package:test/test.dart';

void main() {
  group('ExperimentRunner full loop', () {
    late Directory tempDir;
    late MockClaudeRunner runner;
    late JsonStore store;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('resonance_loop_');
      runner = MockClaudeRunner();
      store = JsonStore(tempDir.path);
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    ClaudeResponse _makeEvalResponse({double baseScore = 3.0}) {
      final scores = Rubric.dimensions.map((d) {
        return {
          'dimension': d.name,
          'score': baseScore.round(),
          'justification': 'Mock evaluation for ${d.name}.',
        };
      }).toList();
      final json = {'scores': scores, 'notes': 'Mock evaluation.'};
      return ClaudeResponse(
        text: jsonEncode(json),
        json: json,
        latency: const Duration(seconds: 1),
      );
    }

    ClaudeResponse _makeResearcherResponse(int gen) {
      final json = {
        'hypothesis': 'Hypothesis for generation $gen',
        'rationale': 'Rationale for generation $gen',
        'system_prompt': 'Evolved prompt for generation $gen. '
            'Be creative and specific.',
        'strategy_type': 'persona',
        'mutation_operator': 'refine',
      };
      return ClaudeResponse(
        text: jsonEncode(json),
        json: json,
        latency: const Duration(seconds: 2),
      );
    }

    ClaudeResponse _makeSubjectResponse(String taskId) {
      return ClaudeResponse(
        text: 'Mock response to task $taskId with interesting details.',
        latency: const Duration(seconds: 3),
      );
    }

    test('produces valid experiment log with 2 generations', () async {
      // The v2 runner uses mutation operators which send various message formats.
      // Stub the mutation operator messages (RefineOperator sends "Here is the best-performing")
      runner.stubResponse(
        'Here is the best-performing',
        _makeResearcherResponse(1),
      );
      // RandomInjectionOperator sends "Generate a completely novel"
      runner.stubResponse(
        'Generate a completely novel',
        _makeResearcherResponse(1),
      );
      // SemanticCrossover sends "## Parent A"
      runner.stubResponse(
        '## Parent A',
        _makeResearcherResponse(1),
      );
      // DifferentialCrossover sends "## Prompt A"
      runner.stubResponse(
        '## Prompt A',
        _makeResearcherResponse(1),
      );
      // LamarckianOperator sends "Here is an exceptionally"
      runner.stubResponse(
        'Here is an exceptionally',
        _makeResearcherResponse(1),
      );
      // Old-style researcher messages (for backward compat tests).
      runner.stubResponse(
        'This is the first generation',
        _makeResearcherResponse(1),
      );
      runner.stubResponse(
        '## Experiment History',
        _makeResearcherResponse(2),
      );

      // Evaluator responses.
      runner.stubResponse(
        'Evaluate the following',
        _makeEvalResponse(baseScore: 3),
      );

      // For Subject responses (the actual test battery messages),
      // use wildcard as fallback.
      runner.stubAny(_makeSubjectResponse('generic'));

      final seed = PromptVariant(
        id: 'seed-1',
        systemPrompt: 'Be helpful and creative.',
        generation: 0,
        createdAt: DateTime.utc(2026, 3, 16),
        strategyType: 'minimalist',
      );

      final config = ExperimentConfig(
        generations: 2,
        experimentsDir: tempDir.path,
        variantsPerGeneration: 1,
        evaluationReplicas: 1,
      );

      final completedRuns = <ExperimentRun>[];
      final experimentRunner = ExperimentRunner(
        runner: runner,
        config: config,
        store: store,
        seedVariants: [seed],
        onGenerationComplete: completedRuns.add,
      );

      final history = await experimentRunner.run();

      // 1 seed + 2 generations * 1 variant each = 3 total runs.
      expect(history, hasLength(3));
      expect(completedRuns, hasLength(3));

      // Verify seed run (generation 0).
      expect(history[0].generation, 0);
      expect(history[0].variant.id, 'seed-1');
      expect(history[0].responses, hasLength(5)); // 5 test tasks
      expect(history[0].evaluations, hasLength(5));

      // Verify evolved runs.
      expect(history[1].generation, 1);
      expect(history[2].generation, 2);

      // All runs should have valid scores.
      for (final run in history) {
        expect(run.overallScore, greaterThan(0));
        expect(run.overallScore, lessThanOrEqualTo(5));
        expect(run.responses.length, TestBattery.tasks.length);
        expect(run.evaluations.length, TestBattery.tasks.length);
      }

      // Verify archive has entries.
      expect(experimentRunner.archive.occupiedCells, greaterThan(0));

      // Verify persistence.
      final persisted = await store.readAllRuns();
      expect(persisted, hasLength(3));

      // Verify experiment log was written.
      final logPath =
          '${tempDir.path}/experiment_log.json';
      expect(File(logPath).existsSync(), isTrue);
    });
  });
}
