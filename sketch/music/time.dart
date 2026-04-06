/// Musical time — multiple simultaneous clocks.
///
/// The key insight: music doesn't have ONE notion of time.
/// Meter, harmonic rhythm, phrase structure, and hypermeter
/// are independent clocks that can agree, disagree, or deliberately
/// conflict. Syncopation IS a disagreement between clocks.
library;

/// A position in metric time.
///
/// Not a duration in seconds — a position in the metric hierarchy.
/// Beat 1 of measure 3 means something different from beat 3 of measure 1,
/// even if they're the same number of seconds from the start.
class MetricPosition {
  final int measure;
  final Rational beat; // Rational because triplets exist.

  const MetricPosition(this.measure, this.beat);

  /// The metric weight of this position.
  ///
  /// Beat 1 > beat 3 > beats 2,4 > offbeats > sub-offbeats.
  /// This hierarchy is what makes syncopation *feel* like something —
  /// an accent on a weak beat borrows energy from the expected strong beat.
  double weight(Meter meter) {
    if (beat == Rational.zero) return 1.0; // Downbeat: maximum weight.
    if (beat.toDouble() == meter.beatsPerMeasure / 2) return 0.7; // Half-bar.
    if (beat.denominator == 1) return 0.4; // On a main beat.
    return 0.1; // Everything else.
  }
}

/// A duration in musical time.
///
/// Expressed as a fraction of a whole note, because musical durations
/// ARE fractions. A dotted quarter = 3/8. A triplet eighth = 1/6.
/// Floating point would be a lie about what these are.
class Duration {
  final Rational fraction;

  const Duration(this.fraction);

  static final whole = Duration(Rational(1, 1));
  static final half = Duration(Rational(1, 2));
  static final quarter = Duration(Rational(1, 4));
  static final eighth = Duration(Rational(1, 8));
  static final sixteenth = Duration(Rational(1, 16));
  static final dottedQuarter = Duration(Rational(3, 8));
  static final tripletEighth = Duration(Rational(1, 6));

  /// Dot the duration: multiply by 3/2.
  Duration get dotted => Duration(fraction * Rational(3, 2));

  /// Tie two durations together.
  Duration operator +(Duration other) => Duration(fraction + other.fraction);

  @override
  String toString() => 'Duration($fraction)';
}

/// Meter: how pulses group.
///
/// Not just "4/4" — a meter is a HIERARCHY of accent patterns.
/// 6/8 and 3/4 have the same number of eighth notes but completely
/// different grouping. That grouping is the meter.
class Meter {
  final int beatsPerMeasure;
  final int beatUnit; // 4 = quarter note gets one beat, 8 = eighth note, etc.

  const Meter(this.beatsPerMeasure, this.beatUnit);

  static const commonTime = Meter(4, 4);
  static const waltzTime = Meter(3, 4);
  static const sixEight = Meter(6, 8); // Compound duple, not simple sextuple.

  /// Is this a compound meter? (Beats subdivide into 3, not 2.)
  bool get isCompound => beatsPerMeasure % 3 == 0 && beatsPerMeasure > 3;

  /// The "big beats" — the primary pulse level.
  /// In 6/8 this is 2 (dotted quarters), not 6.
  int get primaryPulses => isCompound ? beatsPerMeasure ~/ 3 : beatsPerMeasure;
}

/// Groove: systematic micro-deviations from the grid.
///
/// Swing isn't random. It's a *function* from grid position to time offset.
/// A laid-back drummer isn't late — they're operating on a slightly delayed
/// clock. This is where feel lives, and it's completely absent from MIDI.
class Groove {
  /// Micro-timing offset as a function of metric position.
  /// Returns a fraction of a beat (-0.5 to 0.5).
  /// Zero = perfectly on grid.
  final double Function(MetricPosition position) offset;

  /// Velocity (loudness) accent pattern as a function of position.
  /// Returns a multiplier (0.0 to 1.0).
  final double Function(MetricPosition position) accent;

  const Groove({required this.offset, required this.accent});

  /// Straight feel: no deviation from grid.
  static final straight = Groove(
    offset: (_) => 0.0,
    accent: (pos) => pos.weight(Meter.commonTime),
  );

  /// Swing: offbeats are pushed late. The defining groove of jazz.
  /// [amount] ranges from 0.0 (straight) to 1.0 (full triplet swing).
  static Groove swing({double amount = 0.67}) => Groove(
    offset: (pos) {
      // Push offbeats late by [amount] of a triplet displacement.
      final beatFraction = pos.beat.toDouble() % 1.0;
      if (beatFraction > 0.4 && beatFraction < 0.6) {
        return amount * 0.33; // Swing the "and" of each beat.
      }
      return 0.0;
    },
    accent: (pos) => pos.weight(Meter.commonTime),
  );
}

/// Exact rational numbers. Because music IS fractions.
class Rational implements Comparable<Rational> {
  final int numerator;
  final int denominator;

  const Rational(this.numerator, [this.denominator = 1])
      : assert(denominator != 0);

  static const zero = Rational(0);
  static const one = Rational(1);

  double toDouble() => numerator / denominator;

  Rational operator +(Rational other) => Rational(
    numerator * other.denominator + other.numerator * denominator,
    denominator * other.denominator,
  )._reduced;

  Rational operator *(Rational other) => Rational(
    numerator * other.numerator,
    denominator * other.denominator,
  )._reduced;

  Rational get _reduced {
    final g = numerator.gcd(denominator);
    return Rational(numerator ~/ g, denominator ~/ g);
  }

  @override
  int compareTo(Rational other) =>
      (numerator * other.denominator).compareTo(other.numerator * denominator);

  @override
  bool operator ==(Object other) =>
      other is Rational && compareTo(other) == 0;

  @override
  int get hashCode {
    final r = _reduced;
    return Object.hash(r.numerator, r.denominator);
  }

  @override
  String toString() =>
      denominator == 1 ? '$numerator' : '$numerator/$denominator';
}
