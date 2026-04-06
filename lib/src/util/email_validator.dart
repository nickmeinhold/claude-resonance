/// Validates email addresses against practical, real-world rules.
///
/// This intentionally doesn't implement the full RFC 5321 spec (which allows
/// absurdities like `" "@example.com`). Instead it covers the subset of
/// addresses that actual mail servers will accept — which is what you almost
/// always want.
class EmailValidator {
  // One instance, no state — const constructor lets it live at compile time.
  const EmailValidator();

  /// The local part (before @) allows alphanumerics plus these characters.
  /// Periods are allowed but handled separately (no leading/trailing/consecutive).
  static final _localCharPattern = RegExp(r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+$");

  /// Each label in the domain must start and end with alphanumeric,
  /// can contain hyphens in between, and be 1-63 characters.
  static final _domainLabelPattern = RegExp(r'^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$');

  /// Validates [email] and returns a [ValidationResult] explaining what's wrong
  /// (if anything). More useful than a bare bool for UI feedback.
  ValidationResult validate(String email) {
    if (email.isEmpty) {
      return const ValidationResult.invalid('Email address is empty');
    }

    // Overall length limit per RFC 5321
    if (email.length > 254) {
      return const ValidationResult.invalid(
        'Email exceeds 254 character limit',
      );
    }

    // Use lastIndexOf so quoted local parts with '@' still work in theory,
    // but also reject unquoted multiple '@' signs — real providers don't
    // allow them and they're almost always a typo.
    final atIndex = email.lastIndexOf('@');
    if (atIndex == -1) {
      return const ValidationResult.invalid('Missing @ symbol');
    }
    if (email.indexOf('@') != atIndex) {
      return const ValidationResult.invalid(
        'Multiple @ symbols — did you mean to have only one?',
      );
    }

    final local = email.substring(0, atIndex);
    final domain = email.substring(atIndex + 1);

    // --- Local part checks ---
    if (local.isEmpty) {
      return const ValidationResult.invalid('Local part (before @) is empty');
    }
    if (local.length > 64) {
      return const ValidationResult.invalid(
        'Local part exceeds 64 character limit',
      );
    }
    if (!_localCharPattern.hasMatch(local)) {
      return const ValidationResult.invalid(
        'Local part contains invalid characters',
      );
    }
    if (local.startsWith('.') || local.endsWith('.')) {
      return const ValidationResult.invalid(
        'Local part cannot start or end with a period',
      );
    }
    if (local.contains('..')) {
      return const ValidationResult.invalid(
        'Local part cannot have consecutive periods',
      );
    }

    // --- Domain checks ---
    if (domain.isEmpty) {
      return const ValidationResult.invalid('Domain (after @) is empty');
    }

    final labels = domain.split('.');

    // Need at least two labels (e.g., "example.com"), and the TLD
    // must be alphabetic (no "user@example.123").
    if (labels.length < 2) {
      return const ValidationResult.invalid(
        'Domain must have at least two parts (e.g., example.com)',
      );
    }

    final tld = labels.last;
    if (tld.isEmpty || !RegExp(r'^[a-zA-Z]{2,}$').hasMatch(tld)) {
      return const ValidationResult.invalid(
        'Top-level domain must be at least 2 alphabetic characters',
      );
    }

    for (final label in labels) {
      if (label.isEmpty) {
        return const ValidationResult.invalid(
          'Domain contains an empty label (consecutive dots)',
        );
      }
      if (!_domainLabelPattern.hasMatch(label)) {
        return ValidationResult.invalid(
          'Domain label "$label" is invalid — must be alphanumeric '
          '(hyphens allowed in the middle), max 63 characters',
        );
      }
    }

    return const ValidationResult.valid();
  }

  /// Convenience for when you just want a bool.
  bool isValid(String email) => validate(email).isValid;
}

/// The result of validating an email address.
///
/// Carries a human-readable [reason] when invalid, which is handy for
/// form error messages without having to duplicate the logic.
class ValidationResult {
  final bool isValid;
  final String? reason;

  const ValidationResult.valid()
      : isValid = true,
        reason = null;

  const ValidationResult.invalid(this.reason) : isValid = false;

  @override
  String toString() => isValid ? 'Valid' : 'Invalid: $reason';
}
