import 'dart:convert';
import 'dart:io' as io;
import 'dart:io' show Process, ProcessException, ProcessResult;

/// Token usage from a Claude CLI invocation.
class TokenUsage {
  final int inputTokens;
  final int outputTokens;
  final int cacheCreationInputTokens;
  final int cacheReadInputTokens;
  final double costUsd;

  const TokenUsage({
    required this.inputTokens,
    required this.outputTokens,
    this.cacheCreationInputTokens = 0,
    this.cacheReadInputTokens = 0,
    required this.costUsd,
  });

  int get totalTokens => inputTokens + outputTokens;

  Map<String, dynamic> toJson() => {
        'inputTokens': inputTokens,
        'outputTokens': outputTokens,
        'cacheCreationInputTokens': cacheCreationInputTokens,
        'cacheReadInputTokens': cacheReadInputTokens,
        'costUsd': costUsd,
      };

  factory TokenUsage.fromJson(Map<String, dynamic> json) => TokenUsage(
        inputTokens: json['inputTokens'] as int? ?? 0,
        outputTokens: json['outputTokens'] as int? ?? 0,
        cacheCreationInputTokens:
            json['cacheCreationInputTokens'] as int? ?? 0,
        cacheReadInputTokens: json['cacheReadInputTokens'] as int? ?? 0,
        costUsd: (json['costUsd'] as num?)?.toDouble() ?? 0.0,
      );

  @override
  String toString() =>
      'TokenUsage(in: $inputTokens, out: $outputTokens, cost: \$${costUsd.toStringAsFixed(4)})';
}

/// Response from a Claude CLI invocation.
class ClaudeResponse {
  /// The text content of Claude's response.
  final String text;

  /// Parsed JSON if `--output-format json` was used, otherwise null.
  final Map<String, dynamic>? json;

  /// How long the invocation took.
  final Duration latency;

  /// Token usage and cost, available when `--verbose` is used.
  final TokenUsage? usage;

  const ClaudeResponse({
    required this.text,
    this.json,
    required this.latency,
    this.usage,
  });
}

/// Abstract interface for invoking Claude.
///
/// Pipeline components depend on this interface, not the concrete
/// implementation, enabling clean testing with [MockClaudeRunner].
abstract class ClaudeRunner {
  /// Sends a message to Claude and returns the response.
  Future<ClaudeResponse> run({
    required String userMessage,
    String? systemPrompt,
    Map<String, Object>? jsonSchema,
    String model = 'sonnet',
    double? maxBudgetUsd,
  });
}

/// Real implementation — shells out to `claude -p`.
///
/// Builds the CLI argument list from the parameters and invokes the
/// process, capturing stdout as the response. Uses `--output-format json`
/// for structured output and `--json-schema` when schema enforcement is
/// needed (Evaluator, Researcher).
///
/// ## Contamination isolation (critical for experimental validity)
///
/// Without isolation, every role inherits the dart process's environment and
/// leaks Claude Code's own configuration into the experiment — making the
/// pipeline measure an echo of its own instructions rather than the prompt on
/// trial. There are THREE distinct leak channels, each closed by a different
/// lever (all three empirically verified clean, 2026-06-23; OAuth auth
/// survives all three, unlike `--bare`/`HOME` override which break login):
///
/// 1. **Global `~/.claude/CLAUDE.md`** (the `user` setting source) and
///    **project `CLAUDE.md`** (the `project` source) → closed by
///    `--setting-sources local` (drops both, keeps local/auth).
/// 2. **Project auto-memory** (`MEMORY.md` + `project_*.md`), loaded by a
///    mechanism orthogonal to setting-sources and keyed by the project slug
///    derived from cwd → closed two ways for redundancy:
///    `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1` in the subprocess env, AND running
///    in a fresh temp [workingDirectory] (a slug with no memory dir). The
///    cwd is created per-call and deleted in a `finally`, so no cwd-local
///    artifact the CLI might write can carry state from one role to the next
///    (Researcher → Subject → Evaluator stay mutually isolated).
///
/// ### Named tradeoff: the env is inherit-all + one kill switch, not a denylist
///
/// `environment:` is *merged onto* the parent env (`includeParentEnvironment`
/// defaults true), so the subprocess inherits every parent variable plus the
/// auto-memory kill switch. This is deliberate: overriding `HOME` or passing a
/// minimal allow-list breaks the CLI's OAuth/keychain auth (verified — `HOME`
/// override yields `Not logged in`). The contamination channels we actually
/// observed (CLAUDE.md × 2, auto-memory) are each closed by a *specific* lever
/// above; a hypothetical `CLAUDE_*`/`ANTHROPIC_*` env-var contaminant is not a
/// known channel here. If one is ever found, close it with another targeted
/// override rather than flipping to `includeParentEnvironment: false` (which
/// reintroduces the auth break). The standing probe gate is what would catch
/// such a regression.
class ProcessClaudeRunner implements ClaudeRunner {
  @override
  Future<ClaudeResponse> run({
    required String userMessage,
    String? systemPrompt,
    Map<String, Object>? jsonSchema,
    String model = 'sonnet',
    double? maxBudgetUsd,
  }) async {
    final args = <String>[
      '-p',
      userMessage,
      '--output-format',
      'json',
      '--model',
      model,
      '--no-session-persistence',
      '--dangerously-skip-permissions',
      // Drop the user (global ~/.claude/CLAUDE.md) and project CLAUDE.md
      // setting sources; keep only local. Auth is not a setting source and
      // is unaffected. See class doc — channel 1.
      '--setting-sources',
      'local',
    ];

    if (maxBudgetUsd != null) {
      args.addAll(['--max-budget-usd', maxBudgetUsd.toString()]);
    }

    if (systemPrompt != null) {
      args.addAll(['--system-prompt', systemPrompt]);
    }

    if (jsonSchema != null) {
      args.addAll(['--json-schema', jsonEncode(jsonSchema)]);
    }

    final stopwatch = Stopwatch()..start();

    // Channel 2: a fresh, slug-less working directory created per call and
    // removed in the `finally` below, so the subprocess can neither read the
    // project's CLAUDE.md/auto-memory nor leave artifacts visible to the next
    // role's call.
    final isolatedCwd =
        io.Directory.systemTemp.createTempSync('claude_resonance_iso_');
    try {
      return await _runIn(
        isolatedCwd: isolatedCwd,
        args: args,
        jsonSchema: jsonSchema,
        stopwatch: stopwatch,
      );
    } finally {
      try {
        isolatedCwd.deleteSync(recursive: true);
      } on io.FileSystemException {
        // Best-effort cleanup; the OS reaps systemTemp regardless.
      }
    }
  }

  /// Invokes the CLI inside [isolatedCwd] and parses the response.
  ///
  /// Split out from [run] purely so the per-call temp-dir lifecycle (create →
  /// use → delete) is expressed as a single `try`/`finally` around one call.
  Future<ClaudeResponse> _runIn({
    required io.Directory isolatedCwd,
    required List<String> args,
    required Map<String, Object>? jsonSchema,
    required Stopwatch stopwatch,
  }) async {
    // Retry with rate-limit awareness: if we hit the usage limit,
    // sleep until the reset time instead of failing.
    late ProcessResult result;
    const maxTransientRetries = 3;
    var transientAttempts = 0;

    while (true) {
      result = await Process.run(
        'claude',
        args,
        // `environment` is merged onto the parent env (includeParentEnvironment
        // defaults true), so OAuth/keychain auth is preserved. See class doc —
        // "Named tradeoff: inherit-all + one kill switch".
        workingDirectory: isolatedCwd.path,
        environment: const {'CLAUDE_CODE_DISABLE_AUTO_MEMORY': '1'},
      );
      if (result.exitCode == 0) break;

      final stdout = (result.stdout as String).trim();
      final stderr = (result.stderr as String).trim();
      final output = stderr.isNotEmpty ? stderr : stdout;

      // Check for rate limit: parse reset time from the error.
      final resetWait = _parseRateLimitReset(output);
      if (resetWait != null) {
        final minutes = resetWait.inMinutes;
        io.stdout.writeln(
          '  ⏸ Rate limited — sleeping ${minutes}m until reset...',
        );
        await Future<void>.delayed(resetWait);
        // After sleeping, reset transient counter and retry.
        transientAttempts = 0;
        continue;
      }

      // Budget exceeded is deterministic — the same call costs the same
      // again, so retrying multiplies spend on a guaranteed failure.
      if (output.contains('"subtype":"error_max_budget_usd"')) {
        throw ProcessException(
          'claude',
          args,
          'Call exceeded --max-budget-usd. Every CLI invocation carries '
          '~27k tokens of system-prompt overhead, so per-call budgets '
          'below ~\$0.10 (opus) cannot succeed. Raise the budget or pass '
          '--no-budget. Error: $output',
          result.exitCode,
        );
      }

      // Transient failure — retry with backoff.
      transientAttempts++;
      if (transientAttempts <= maxTransientRetries) {
        final waitSec = transientAttempts * 15;
        io.stderr.writeln(
          '  [retry $transientAttempts/$maxTransientRetries] Claude CLI failed '
          '(exit ${result.exitCode}): '
          '${output.isEmpty ? "(no output)" : output.substring(0, output.length.clamp(0, 100))} '
          '— retrying in ${waitSec}s...',
        );
        await Future<void>.delayed(Duration(seconds: waitSec));
      } else {
        throw ProcessException(
          'claude',
          args,
          'Claude CLI failed after $maxTransientRetries attempts '
          '(exit ${result.exitCode}): $output',
          result.exitCode,
        );
      }
    }
    stopwatch.stop();

    final stdout = result.stdout as String;

    // claude --output-format json wraps the response in a JSON envelope:
    // - `result` contains the text response
    // - `structured_output` contains parsed JSON when --json-schema is used
    // - `usage` contains token counts (input_tokens, output_tokens, etc.)
    // - `total_cost_usd` contains the billing cost
    Map<String, dynamic>? parsed;
    String text;
    TokenUsage? usage;
    try {
      parsed = jsonDecode(stdout) as Map<String, dynamic>;
      text = parsed['result'] as String? ?? stdout;
      usage = _parseUsage(parsed);

      if (jsonSchema != null && parsed.containsKey('structured_output')) {
        final structured =
            parsed['structured_output'] as Map<String, dynamic>;
        return ClaudeResponse(
          text: jsonEncode(structured),
          json: structured,
          latency: stopwatch.elapsed,
          usage: usage,
        );
      }
    } on FormatException {
      // stdout wasn't JSON at all
      text = stdout;
    }

    return ClaudeResponse(
      text: text,
      json: parsed,
      latency: stopwatch.elapsed,
      usage: usage,
    );
  }

  /// Extracts token usage from the `--output-format json` envelope.
  ///
  /// The envelope includes `usage` (with `input_tokens`, `output_tokens`,
  /// cache fields) and `total_cost_usd` — no `--verbose` flag needed.
  static TokenUsage? _parseUsage(Map<String, dynamic> envelope) {
    try {
      final usageMap = envelope['usage'] as Map<String, dynamic>?;
      if (usageMap == null) return null;

      return TokenUsage(
        inputTokens: usageMap['input_tokens'] as int? ?? 0,
        outputTokens: usageMap['output_tokens'] as int? ?? 0,
        cacheCreationInputTokens:
            usageMap['cache_creation_input_tokens'] as int? ?? 0,
        cacheReadInputTokens:
            usageMap['cache_read_input_tokens'] as int? ?? 0,
        costUsd:
            (envelope['total_cost_usd'] as num?)?.toDouble() ?? 0.0,
      );
    } catch (_) {
      return null;
    }
  }

  /// Parses a rate limit reset time from the CLI error output.
  ///
  /// Expected format in the JSON result field:
  ///   "You've hit your limit · resets 10am (Australia/Melbourne)"
  ///   "You've hit your limit · resets 3pm (Australia/Melbourne)"
  ///
  /// Returns a Duration to sleep until reset, or null if not a rate limit.
  static Duration? _parseRateLimitReset(String output) {
    // Try to find the reset message in the output.
    final resetPattern = RegExp(
      r"hit your limit.*resets?\s+(\d{1,2})(am|pm)\s*\(([^)]+)\)",
      caseSensitive: false,
    );
    final match = resetPattern.firstMatch(output);
    if (match == null) return null;

    final hour = int.parse(match.group(1)!);
    final amPm = match.group(2)!.toLowerCase();

    // Convert to 24h.
    var resetHour = hour;
    if (amPm == 'pm' && hour != 12) resetHour += 12;
    if (amPm == 'am' && hour == 12) resetHour = 0;

    // Use local time (the CLI reports in the user's timezone).
    final now = DateTime.now();
    var resetTime = DateTime(now.year, now.month, now.day, resetHour);

    // If reset time is in the past, it means tomorrow.
    if (resetTime.isBefore(now)) {
      resetTime = resetTime.add(const Duration(days: 1));
    }

    // Add a 2-minute buffer so we don't hit the edge.
    final wait = resetTime.difference(now) + const Duration(minutes: 2);
    return wait;
  }
}

/// Test implementation — returns canned responses keyed by user message.
class MockClaudeRunner implements ClaudeRunner {
  final Map<String, ClaudeResponse> _responses = {};
  final List<MockInvocation> invocations = [];

  /// Registers a canned response for a given user message prefix.
  void stubResponse(String messagePrefix, ClaudeResponse response) {
    _responses[messagePrefix] = response;
  }

  /// Registers a canned response that matches any message.
  void stubAny(ClaudeResponse response) {
    _responses['*'] = response;
  }

  @override
  Future<ClaudeResponse> run({
    required String userMessage,
    String? systemPrompt,
    Map<String, Object>? jsonSchema,
    String model = 'sonnet',
    double? maxBudgetUsd,
  }) async {
    invocations.add(MockInvocation(
      userMessage: userMessage,
      systemPrompt: systemPrompt,
      jsonSchema: jsonSchema,
      model: model,
    ));

    // Try prefix match first, then wildcard.
    for (final entry in _responses.entries) {
      if (entry.key != '*' && userMessage.startsWith(entry.key)) {
        return entry.value;
      }
    }
    if (_responses.containsKey('*')) {
      return _responses['*']!;
    }

    throw StateError(
      'MockClaudeRunner: no stub for message starting with '
      '"${userMessage.substring(0, userMessage.length.clamp(0, 60))}"',
    );
  }
}

/// Records a single invocation to [MockClaudeRunner] for test assertions.
class MockInvocation {
  final String userMessage;
  final String? systemPrompt;
  final Map<String, Object>? jsonSchema;
  final String model;

  const MockInvocation({
    required this.userMessage,
    this.systemPrompt,
    this.jsonSchema,
    required this.model,
  });
}
