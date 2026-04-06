/// Email address validation with explicit strictness levels.
///
/// True email validation is impossible without sending a message — RFC 5321
/// permits addresses like `"hello world"@example.com` that almost no real
/// system accepts. This library offers three levels so callers can pick the
/// right tradeoff.
///
/// ```dart
/// EmailValidator.pragmatic('user@example.com'); // true
/// EmailValidator.pragmatic('"quoted spaces"@example.com'); // false (rejected by most servers)
/// EmailValidator.rfc5322('"quoted spaces"@example.com');   // true (technically valid)
/// ```
library email_validator;

/// Validation strictness levels, from most to least permissive.
enum EmailStrictness {
  /// Accepts anything the RFC technically allows. Useful when you must not
  /// reject valid addresses (e.g. storing user-submitted data for later use).
  rfc5322,

  /// Rejects RFC exotica (quoted local-parts, IP literals, comments) that
  /// real mail servers rarely support. The right default for most apps.
  pragmatic,

  /// Applies extra heuristics: no single-label TLDs, minimum TLD length of 2,
  /// no consecutive dots anywhere. Good for sign-up forms.
  strict,
}

/// Result of an email validation, including the reason for rejection.
class EmailValidationResult {
  const EmailValidationResult.valid(this.normalized)
      : isValid = true,
        reason = null;

  const EmailValidationResult.invalid(this.reason)
      : isValid = false,
        normalized = null;

  /// Whether the address passed validation.
  final bool isValid;

  /// If valid, a normalized (lowercased domain) version of the address.
  final String? normalized;

  /// Human-readable rejection reason, or null if valid.
  final String? reason;

  @override
  String toString() =>
      isValid ? 'valid: $normalized' : 'invalid: $reason';
}

/// Validates email addresses at configurable strictness levels.
abstract final class EmailValidator {
  // RFC 5321 limits.
  static const int _maxLocalLength = 64;
  static const int _maxDomainLength = 253;
  static const int _maxTotalLength = 320;

  /// Validates using [EmailStrictness.rfc5322] rules.
  static EmailValidationResult rfc5322(String email) =>
      _validate(email, EmailStrictness.rfc5322);

  /// Validates using [EmailStrictness.pragmatic] rules (recommended default).
  static EmailValidationResult pragmatic(String email) =>
      _validate(email, EmailStrictness.pragmatic);

  /// Validates using [EmailStrictness.strict] rules (sign-up forms, etc.).
  static EmailValidationResult strict(String email) =>
      _validate(email, EmailStrictness.strict);

  static EmailValidationResult _validate(
    String email,
    EmailStrictness strictness,
  ) {
    // ── Length checks ──────────────────────────────────────────────────────
    if (email.isEmpty) {
      return const EmailValidationResult.invalid('empty string');
    }
    if (email.length > _maxTotalLength) {
      return EmailValidationResult.invalid(
        'exceeds $_maxTotalLength character limit',
      );
    }

    // ── Split on the *last* @ (local-parts may contain @ in quoted strings,
    //    but we handle that below for pragmatic/strict). ────────────────────
    final atIndex = email.lastIndexOf('@');
    if (atIndex < 1) {
      return const EmailValidationResult.invalid('missing @ sign');
    }

    final local = email.substring(0, atIndex);
    final domain = email.substring(atIndex + 1);

    // ── Local-part validation ──────────────────────────────────────────────
    final localResult = _validateLocal(local, strictness);
    if (!localResult.isValid) return localResult;

    // ── Domain validation ──────────────────────────────────────────────────
    final domainResult = _validateDomain(domain, strictness);
    if (!domainResult.isValid) return domainResult;

    // Normalize: lowercase the domain (local-part is case-sensitive per RFC,
    // but in practice all major providers treat it as case-insensitive too).
    final normalized = '$local@${domain.toLowerCase()}';
    return EmailValidationResult.valid(normalized);
  }

  // ── Local-part ───────────────────────────────────────────────────────────

  static EmailValidationResult _validateLocal(
    String local,
    EmailStrictness strictness,
  ) {
    if (local.isEmpty) {
      return const EmailValidationResult.invalid('local-part is empty');
    }
    if (local.length > _maxLocalLength) {
      return EmailValidationResult.invalid(
        'local-part exceeds $_maxLocalLength characters',
      );
    }

    // Quoted local-parts: RFC allows `"any chars"`, pragmatic/strict reject.
    if (local.startsWith('"') && local.endsWith('"')) {
      if (strictness == EmailStrictness.rfc5322) {
        return const EmailValidationResult.valid(null); // content unchecked
      }
      return const EmailValidationResult.invalid(
        'quoted local-parts are not supported by most mail servers',
      );
    }

    // RFC 5321 printable characters allowed unquoted.
    // Excluded: space, @, comma, brackets, backslash (require quoting).
    final invalidChar =
        RegExp(r"""[^a-zA-Z0-9!#$%&'*+/=?^_`{|}~.\-]""").firstMatch(local);
    if (invalidChar != null) {
      return EmailValidationResult.invalid(
        'invalid character "${invalidChar.group(0)}" in local-part',
      );
    }

    // Dot rules: no leading, trailing, or consecutive dots.
    if (local.startsWith('.') || local.endsWith('.')) {
      return const EmailValidationResult.invalid(
        'local-part may not start or end with a dot',
      );
    }
    if (local.contains('..')) {
      return const EmailValidationResult.invalid(
        'local-part may not contain consecutive dots',
      );
    }

    return const EmailValidationResult.valid(null);
  }

  // ── Domain ───────────────────────────────────────────────────────────────

  static EmailValidationResult _validateDomain(
    String domain,
    EmailStrictness strictness,
  ) {
    if (domain.isEmpty) {
      return const EmailValidationResult.invalid('domain is empty');
    }
    if (domain.length > _maxDomainLength) {
      return EmailValidationResult.invalid(
        'domain exceeds $_maxDomainLength characters',
      );
    }

    // IP address literals: `[192.0.2.1]` or `[IPv6:2001:db8::1]` — RFC valid,
    // pragmatic/strict reject because they almost never appear in real usage.
    if (domain.startsWith('[') && domain.endsWith(']')) {
      if (strictness == EmailStrictness.rfc5322) {
        return const EmailValidationResult.valid(null);
      }
      return const EmailValidationResult.invalid(
        'IP address literals in domains are not supported',
      );
    }

    // Labels separated by dots.
    if (domain.startsWith('.') || domain.endsWith('.')) {
      return const EmailValidationResult.invalid(
        'domain may not start or end with a dot',
      );
    }
    if (domain.contains('..')) {
      return const EmailValidationResult.invalid(
        'domain may not contain consecutive dots',
      );
    }

    final labels = domain.split('.');

    for (final label in labels) {
      if (label.isEmpty) {
        return const EmailValidationResult.invalid('empty domain label');
      }
      if (label.length > 63) {
        return EmailValidationResult.invalid(
          'domain label "$label" exceeds 63 characters',
        );
      }
      // Labels may contain letters, digits, hyphens — not leading/trailing hyphen.
      if (label.startsWith('-') || label.endsWith('-')) {
        return EmailValidationResult.invalid(
          'domain label "$label" may not start or end with a hyphen',
        );
      }
      if (!RegExp(r'^[a-zA-Z0-9-]+$').hasMatch(label)) {
        return EmailValidationResult.invalid(
          'domain label "$label" contains invalid characters '
          '(internationalized domains must be punycode-encoded first)',
        );
      }
    }

    // Strict: require at least two labels (no bare `user@localhost`) and a
    // TLD of at least 2 characters.
    if (strictness == EmailStrictness.strict) {
      if (labels.length < 2) {
        return const EmailValidationResult.invalid(
          'domain must have at least one dot (single-label domains rejected)',
        );
      }
      final tld = labels.last;
      if (tld.length < 2) {
        return EmailValidationResult.invalid(
          'TLD "$tld" is too short (minimum 2 characters)',
        );
      }
      // TLDs are letters-only (numeric TLDs don't exist in practice).
      if (!RegExp(r'^[a-zA-Z]+$').hasMatch(tld)) {
        return EmailValidationResult.invalid(
          'TLD "$tld" must contain only letters',
        );
      }
    }

    return const EmailValidationResult.valid(null);
  }
}
