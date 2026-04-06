import 'package:claude_resonance/src/util/email_validator.dart';
import 'package:test/test.dart';

void main() {
  const validator = EmailValidator();

  group('EmailValidator', () {
    group('accepts valid addresses', () {
      final validEmails = [
        'user@example.com',
        'firstname.lastname@example.com',
        'user+tag@example.com',
        'user@sub.domain.example.com',
        'disposable.style.email.with+symbol@example.com',
        'x@example.com', // single-char local
        'user@example.co.uk', // multi-part domain
        "mailhost!username@example.org", // bang path (valid char)
        'user%host@example.com', // percent relay
        '_______@example.com', // underscores
        'user@example.museum', // long TLD
      ];

      for (final email in validEmails) {
        test(email, () {
          final result = validator.validate(email);
          expect(result.isValid, isTrue, reason: 'Expected valid: $email');
        });
      }
    });

    group('rejects invalid addresses', () {
      final invalidEmails = <String, String>{
        '': 'empty',
        'plainaddress': 'no @ symbol',
        '@example.com': 'empty local part',
        'user@': 'empty domain',
        'user@.com': 'domain starts with dot',
        'user@example': 'single-label domain',
        'user@example.': 'trailing dot in domain',
        'user@example..com': 'consecutive dots in domain',
        '.user@example.com': 'local starts with dot',
        'user.@example.com': 'local ends with dot',
        'user..name@example.com': 'consecutive dots in local',
        'user@exam ple.com': 'space in domain',
        'user name@example.com': 'space in local',
        'user@example.123': 'numeric TLD',
        'user@example.c': 'single-char TLD',
        'user@-example.com': 'domain label starts with hyphen',
        'user@example-.com': 'domain label ends with hyphen',
      };

      invalidEmails.forEach((email, description) {
        test('$description ($email)', () {
          final result = validator.validate(email);
          expect(result.isValid, isFalse, reason: 'Expected invalid: $email');
          expect(result.reason, isNotNull);
        });
      });
    });

    group('edge cases', () {
      test('length limit — 254 chars total', () {
        // 64 char local + @ + domain that pushes past 254
        final longLocal = 'a' * 64;
        final longDomain = '${'a' * 63}.com';
        final justRight = '$longLocal@$longDomain';
        expect(justRight.length, lessThanOrEqualTo(254));
        expect(validator.isValid(justRight), isTrue);
      });

      test('local part over 64 chars', () {
        final tooLong = '${'a' * 65}@example.com';
        expect(validator.isValid(tooLong), isFalse);
      });

      test('uses lastIndexOf for @ — handles @ in local part area', () {
        // "a@b"@example.com isn't valid in our practical rules (no quotes),
        // but we should at least not crash
        final result = validator.validate('a@b@example.com');
        // local = "a@b" which contains @ — our char check rejects it
        expect(result.isValid, isFalse);
      });

      test('isValid convenience method matches validate', () {
        expect(validator.isValid('test@example.com'), isTrue);
        expect(validator.isValid('nope'), isFalse);
      });

      test('ValidationResult toString', () {
        expect(
          const ValidationResult.valid().toString(),
          equals('Valid'),
        );
        expect(
          const ValidationResult.invalid('bad').toString(),
          equals('Invalid: bad'),
        );
      });
    });
  });
}
