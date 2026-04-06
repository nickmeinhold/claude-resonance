import 'package:claude_resonance/claude_resonance.dart';
import 'package:test/test.dart';

void main() {
  group('MockClaudeRunner', () {
    late MockClaudeRunner runner;

    setUp(() {
      runner = MockClaudeRunner();
    });

    test('returns stubbed response for matching prefix', () async {
      runner.stubResponse(
        'Hello',
        const ClaudeResponse(
          text: 'Hi there!',
          latency: Duration(seconds: 1),
        ),
      );

      final response = await runner.run(userMessage: 'Hello world');

      expect(response.text, 'Hi there!');
      expect(response.latency, const Duration(seconds: 1));
    });

    test('records invocations with all parameters', () async {
      runner.stubAny(
        const ClaudeResponse(text: 'ok', latency: Duration.zero),
      );

      await runner.run(
        userMessage: 'Test message',
        systemPrompt: 'You are helpful.',
        jsonSchema: {'type': 'object'},
        model: 'opus',
      );

      expect(runner.invocations, hasLength(1));
      final inv = runner.invocations.first;
      expect(inv.userMessage, 'Test message');
      expect(inv.systemPrompt, 'You are helpful.');
      expect(inv.jsonSchema, {'type': 'object'});
      expect(inv.model, 'opus');
    });

    test('wildcard matches any message', () async {
      runner.stubAny(
        const ClaudeResponse(text: 'wildcard', latency: Duration.zero),
      );

      final r1 = await runner.run(userMessage: 'foo');
      final r2 = await runner.run(userMessage: 'bar');

      expect(r1.text, 'wildcard');
      expect(r2.text, 'wildcard');
    });

    test('prefix match takes priority over wildcard', () async {
      runner.stubAny(
        const ClaudeResponse(text: 'wildcard', latency: Duration.zero),
      );
      runner.stubResponse(
        'specific',
        const ClaudeResponse(text: 'matched', latency: Duration.zero),
      );

      final r1 = await runner.run(userMessage: 'specific message');
      final r2 = await runner.run(userMessage: 'other message');

      expect(r1.text, 'matched');
      expect(r2.text, 'wildcard');
    });

    test('throws when no stub matches', () async {
      expect(
        () => runner.run(userMessage: 'unmatched'),
        throwsA(isA<StateError>()),
      );
    });
  });
}
