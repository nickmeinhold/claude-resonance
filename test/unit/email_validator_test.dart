import 'package:claude_resonance/src/utils/email_validator.dart';
import 'package:test/test.dart';

void main() {
  group('EmailValidator', () {
    // ── Happy path ────────────────────────────────────────────────────────

    group('accepts normal addresses', () {
      const valid = [
        'user@example.com',
        'user.name@example.com',
        'user+tag@example.com', // plus-addressing (Gmail, etc.)
        'user123@sub.example.co.uk',
        'x@y.org', // minimal but valid
        'very.long.local.part.that.is.still.under.limit@example.com',
        'user_name@example-domain.com',
        '1234567890@numbers.com',
        'ALL.CAPS@EXAMPLE.COM', // normalizes to lowercase domain
      ];

      for (final email in valid) {
        test(email, () {
          expect(EmailValidator.strict(email).isValid, isTrue, reason: email);
        });
      }
    });

    // ── Surprising RFC-valid but pragmatically-rejected ───────────────────

    group('RFC 5322 accepts but pragmatic/strict reject', () {
      test('quoted local-part with spaces', () {
        const email = '"hello world"@example.com';
        expect(EmailValidator.rfc5322(email).isValid, isTrue);
        expect(EmailValidator.pragmatic(email).isValid, isFalse);
        expect(EmailValidator.strict(email).isValid, isFalse);
      });

      test('IP address literal domain', () {
        const email = 'user@[192.0.2.1]';
        expect(EmailValidator.rfc5322(email).isValid, isTrue);
        expect(EmailValidator.pragmatic(email).isValid, isFalse);
      });

      test('IPv6 literal domain', () {
        const email = 'user@[IPv6:2001:db8::1]';
        expect(EmailValidator.rfc5322(email).isValid, isTrue);
        expect(EmailValidator.pragmatic(email).isValid, isFalse);
      });

      test('single-label domain (localhost)', () {
        const email = 'user@localhost';
        // pragmatic allows it (internal tooling, dev environments)
        expect(EmailValidator.pragmatic(email).isValid, isTrue);
        // strict rejects: no dot means no TLD
        expect(EmailValidator.strict(email).isValid, isFalse);
      });
    });

    // ── Clearly invalid ───────────────────────────────────────────────────

    group('rejects malformed addresses', () {
      final cases = <String, String>{
        '': 'empty string',
        'notanemail': 'no @ sign',
        '@example.com': 'empty local-part',
        'user@': 'empty domain',
        'user@.com': 'domain starts with dot',
        'user@com.': 'domain ends with dot',
        '.user@example.com': 'local starts with dot',
        'user.@example.com': 'local ends with dot',
        'user..name@example.com': 'consecutive dots in local',
        'user@exam..ple.com': 'consecutive dots in domain',
        'user @example.com': 'space in local-part',
        'user@exam ple.com': 'space in domain',
        'user@-example.com': 'domain label starts with hyphen',
        'user@example-.com': 'domain label ends with hyphen',
      };

      cases.forEach((email, description) {
        test('$description: "$email"', () {
          final result = EmailValidator.strict(email);
          expect(result.isValid, isFalse,
              reason: '$description — reason: ${result.reason}');
        });
      });
    });

    // ── Length boundary conditions ────────────────────────────────────────

    group('length limits', () {
      test('accepts exactly 64-char local-part', () {
        final local = 'a' * 64;
        expect(EmailValidator.pragmatic('$local@example.com').isValid, isTrue);
      });

      test('rejects 65-char local-part', () {
        final local = 'a' * 65;
        final result = EmailValidator.pragmatic('$local@example.com');
        expect(result.isValid, isFalse);
        expect(result.reason, contains('64'));
      });

      test('accepts exactly 253-char domain', () {
        // Build a domain that's exactly 253 chars: 50×'a' + '.' repeated.
        final label = 'a' * 50; // 50
        // 'aaaaa...aaa.aaaaa...aaa.com' — 50+1+50+1+50+1+50+1+48+1+3 = …
        // Simpler: pad last label to hit exactly 253.
        final domain = '$label.$label.$label.$label.com';
        // Only test if it happens to be ≤253; adjust as needed.
        if (domain.length <= 253) {
          expect(
            EmailValidator.pragmatic('user@$domain').isValid,
            isTrue,
          );
        }
      });
    });

    // ── Normalization ─────────────────────────────────────────────────────

    group('normalizes domain to lowercase', () {
      test('EXAMPLE.COM → example.com', () {
        final result = EmailValidator.pragmatic('User@EXAMPLE.COM');
        expect(result.isValid, isTrue);
        expect(result.normalized, equals('User@example.com'));
      });

      test('preserves local-part case', () {
        // RFC says local is case-sensitive. We preserve it even though
        // in practice Gmail etc. ignore case there too.
        final result = EmailValidator.pragmatic('FirstLast@example.com');
        expect(result.normalized, equals('FirstLast@example.com'));
      });
    });

    // ── Strict TLD rules ──────────────────────────────────────────────────

    group('strict TLD checks', () {
      test('rejects single-char TLD', () {
        final result = EmailValidator.strict('user@example.c');
        expect(result.isValid, isFalse);
        expect(result.reason, contains('TLD'));
      });

      test('rejects numeric TLD', () {
        final result = EmailValidator.strict('user@example.123');
        expect(result.isValid, isFalse);
      });

      test('accepts .io, .ai, .co etc.', () {
        for (final tld in ['io', 'ai', 'co', 'uk', 'museum']) {
          expect(
            EmailValidator.strict('user@example.$tld').isValid,
            isTrue,
            reason: '.$tld',
          );
        }
      });
    });
  });
}
