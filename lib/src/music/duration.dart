/// Duration — the horizontal dimension of music.
///
/// Musical duration is a *rational* number (fraction of a whole note), not a
/// floating-point value. Using doubles would make "two eighth notes equals one
/// quarter note" only approximately true — which is incorrect. Duration arithmetic
/// must be exact because measures must add up to exactly their time signature.
///
/// The system of durations is beautifully regular: each value is half the previous.
/// Dotting adds half again (a dotted quarter = 3/8), double-dotting adds 3/4.
/// Tuplets (triplets, quintuplets) introduce other rational subdivisions.
library;

/// An exact musical duration, represented as a fraction of a whole note.
///
/// A quarter note is 1/4, an eighth note 1/8, a whole note 1/1, a dotted
/// quarter 3/8. All arithmetic stays in the rational domain.
///
/// ```dart
/// final bar44 = Duration.whole;
/// final twoBeats = Duration.quarter * 2;
/// final dottedHalf = Duration.half.dotted;
/// assert(twoBeats == dottedHalf.halved); // 1/2 == 1/2
/// ```
final class Duration implements Comparable<Duration> {
  final int _numerator;
  final int _denominator;

  /// Creates a duration of [numerator]/[denominator] whole notes.
  /// Automatically reduces to lowest terms.
  const Duration._(int numerator, int denominator)
      : _numerator = numerator,
        _denominator = denominator;

  factory Duration(int numerator, int denominator) {
    assert(denominator > 0, 'Duration denominator must be positive');
    assert(numerator >= 0, 'Duration must be non-negative');
    final g = _gcd(numerator, denominator);
    return Duration._(numerator ~/ g, denominator ~/ g);
  }

  int get numerator => _numerator;
  int get denominator => _denominator;

  // ─── Standard note values ─────────────────────────────────────────────────

  static final Duration zero = Duration(0, 1);
  static final Duration sixtyfourth = Duration(1, 64);
  static final Duration thirtySecond = Duration(1, 32);
  static final Duration sixteenth = Duration(1, 16);
  static final Duration eighth = Duration(1, 8);
  static final Duration quarter = Duration(1, 4);
  static final Duration half = Duration(1, 2);
  static final Duration whole = Duration(1, 1);
  static final Duration breve = Duration(2, 1); // double whole note

  // ─── Augmentation dots ───────────────────────────────────────────────────

  /// A single dot adds half the original value: ♩. = ♩ + ♪ = 3/8.
  Duration get dotted => Duration(_numerator * 3, _denominator * 2);

  /// A double dot adds half + quarter: ♩.. = ♩ + ♪ + ♬ = 7/16.
  Duration get doubleDotted => Duration(_numerator * 7, _denominator * 4);

  // ─── Tuplets ──────────────────────────────────────────────────────────────

  /// Creates a tuplet: [count] of these fit in the space of [inSpace].
  ///
  /// A quarter-note triplet: three quarter notes in the time of two.
  /// ```dart
  /// final tripletQuarter = Duration.quarter.tuplet(3, inSpace: 2);
  /// // = 1/4 * (2/3) = 1/6 of a whole note
  /// ```
  Duration tuplet(int count, {required int inSpace}) =>
      Duration(_numerator * inSpace, _denominator * count);

  // ─── Arithmetic ──────────────────────────────────────────────────────────

  Duration operator +(Duration other) => Duration(
        _numerator * other._denominator + other._numerator * _denominator,
        _denominator * other._denominator,
      );

  Duration operator -(Duration other) {
    final n =
        _numerator * other._denominator - other._numerator * _denominator;
    final d = _denominator * other._denominator;
    assert(n >= 0, 'Duration subtraction would go negative: $this - $other');
    return Duration(n, d);
  }

  Duration operator *(int scalar) => Duration(_numerator * scalar, _denominator);

  Duration operator ~/(int scalar) => Duration(_numerator, _denominator * scalar);

  bool operator <(Duration other) =>
      _numerator * other._denominator < other._numerator * _denominator;
  bool operator >(Duration other) =>
      _numerator * other._denominator > other._numerator * _denominator;
  bool operator <=(Duration other) => !(this > other);
  bool operator >=(Duration other) => !(this < other);

  @override
  int compareTo(Duration other) {
    final lhs = _numerator * other._denominator;
    final rhs = other._numerator * _denominator;
    return lhs.compareTo(rhs);
  }

  @override
  bool operator ==(Object other) =>
      other is Duration &&
      _numerator == other._numerator &&
      _denominator == other._denominator;

  @override
  int get hashCode => Object.hash(_numerator, _denominator);

  @override
  String toString() => '$_numerator/$_denominator';

  static int _gcd(int a, int b) {
    while (b != 0) {
      final t = b;
      b = a % b;
      a = t;
    }
    return a;
  }
}

/// A time signature: how many beats per measure, and what note value gets one beat.
///
/// 4/4 = four quarter-note beats per measure (common time).
/// 6/8 = six eighth-note beats — but felt in 2, not 6 (compound duple meter).
/// 5/4 = five quarter beats — asymmetric, grouping usually 3+2 or 2+3.
///
/// The [beatGrouping] captures the felt pulse structure of compound and
/// asymmetric meters, which isn't derivable from the numbers alone.
final class TimeSignature {
  /// Beats per measure (the top number).
  final int beats;

  /// What note value gets one beat (the bottom number: 4=quarter, 8=eighth).
  final int beatUnit;

  /// How beats cluster into felt pulses.
  /// 6/8 → [3, 3] (two groups of three eighths each).
  /// 5/4 → [3, 2] or [2, 3] depending on the piece.
  /// Simple meters like 4/4 → [1, 1, 1, 1] (each beat is its own pulse).
  final List<int> beatGrouping;

  const TimeSignature(
    this.beats,
    this.beatUnit, {
    List<int>? beatGrouping,
  }) : beatGrouping = beatGrouping ?? const [];

  /// Duration of a single beat in this meter.
  Duration get beatDuration => Duration(1, beatUnit);

  /// Total duration of one full measure.
  Duration get measureDuration => Duration(beats, beatUnit);

  static const TimeSignature commonTime = TimeSignature(4, 4);
  static const TimeSignature cutTime = TimeSignature(2, 2);
  static const TimeSignature waltz = TimeSignature(3, 4);
  static const TimeSignature sixEight =
      TimeSignature(6, 8, beatGrouping: [3, 3]);
  static const TimeSignature fiveFour =
      TimeSignature(5, 4, beatGrouping: [3, 2]);
  static const TimeSignature sevenEight =
      TimeSignature(7, 8, beatGrouping: [2, 2, 3]);

  @override
  String toString() => '$beats/$beatUnit';
}

/// Musical tempo — how fast the pulse moves.
///
/// Expressed as beats per minute (BPM), plus an optional character marking
/// (Allegro, Adagio) that carries expressive information beyond raw speed.
final class Tempo {
  /// Beats per minute.
  final double bpm;

  /// The note value that gets one beat (defaults to quarter note).
  final Duration beatUnit;

  /// Optional character marking (Allegro, Largo, etc.).
  final String? marking;

  const Tempo(
    this.bpm, {
    Duration? beatUnit,
    this.marking,
  }) : beatUnit = beatUnit ?? const Duration._(1, 4);

  /// Duration of one beat in real time (milliseconds).
  double get beatMilliseconds => 60000 / bpm;

  /// Convert a musical [duration] to real time in milliseconds.
  double toMilliseconds(Duration duration) =>
      beatMilliseconds * duration._numerator / duration._denominator * beatUnit._denominator / beatUnit._numerator;

  static const Tempo grave = Tempo(40, marking: 'Grave');
  static const Tempo largo = Tempo(50, marking: 'Largo');
  static const Tempo adagio = Tempo(66, marking: 'Adagio');
  static const Tempo andante = Tempo(76, marking: 'Andante');
  static const Tempo moderato = Tempo(108, marking: 'Moderato');
  static const Tempo allegro = Tempo(132, marking: 'Allegro');
  static const Tempo presto = Tempo(180, marking: 'Presto');
  static const Tempo prestissimo = Tempo(208, marking: 'Prestissimo');

  @override
  String toString() => marking != null ? '$marking (♩=$bpm)' : '♩=$bpm';
}
