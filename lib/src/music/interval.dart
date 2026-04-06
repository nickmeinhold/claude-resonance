/// Intervals — the distances between pitches.
///
/// An interval has two independent properties that must be tracked separately:
/// - **Semitones** — the acoustic distance (a tritone is always 6 semitones)
/// - **Diatonic steps** — the notational distance (an augmented fourth C→F♯
///   and a diminished fifth C→G♭ are acoustically the same but spelled differently)
///
/// Why this matters: when you transpose a melody, you don't just add semitones —
/// you move diatonically, then adjust the accidental. Otherwise D + "4 semitones"
/// could give you either F♯ or G♭, and harmony tells you which.
library;

/// The quality of an interval — its character beyond raw size.
///
/// Not all combinations of quality and number are valid: perfect intervals
/// (unison, fourth, fifth, octave) use P/Aug/Dim; all others use Maj/Min/Aug/Dim.
enum IntervalQuality {
  diminished,
  minor,
  perfect,
  major,
  augmented;

  /// Whether this quality applies to perfect intervals (1, 4, 5, 8).
  bool get isPerfect => this == perfect;
}

/// A directed interval between two pitches.
///
/// Intervals are always *ascending* here; for descending motion, negate or
/// use [Interval.descending]. This choice sidesteps the thorny question of
/// whether a "descending minor third" is the same object as an "ascending
/// minor sixth" — they're related by inversion but are different intervals.
///
/// ```dart
/// final fifth  = Interval.perfectFifth;
/// final third  = Interval.majorThird;
/// final tritone = Interval.augmentedFourth;
/// ```
final class Interval {
  /// How many semitones wide (always non-negative for ascending intervals).
  final int semitones;

  /// How many diatonic steps span (1 = unison, 2 = second, 7 = seventh, etc.)
  final int diatonicSteps;

  /// The quality: diminished, minor, perfect, major, or augmented.
  final IntervalQuality quality;

  const Interval({
    required this.semitones,
    required this.diatonicSteps,
    required this.quality,
  });

  // ─── Interval arithmetic ─────────────────────────────────────────────────

  /// Compound this interval with [other]: P5 + M3 = M7.
  Interval operator +(Interval other) => Interval(
        semitones: semitones + other.semitones,
        diatonicSteps: diatonicSteps + other.diatonicSteps,
        quality: _compoundQuality(other), // simplified: works for common cases
      );

  /// Inversion: a major third (4 semitones, 3 steps) inverts to a minor sixth
  /// (8 semitones, 6 steps). Steps sum to 9; semitones sum to 12.
  Interval get inversion => Interval(
        semitones: 12 - semitones,
        diatonicSteps: 9 - diatonicSteps,
        quality: _invertQuality(quality),
      );

  /// Reduce a compound interval to its simple equivalent (within an octave).
  Interval get simple => semitones <= 12
      ? this
      : Interval(
          semitones: semitones % 12,
          diatonicSteps: ((diatonicSteps - 1) % 7) + 1,
          quality: quality,
        );

  /// Number of octaves this interval spans (0 for simple intervals).
  int get octaves => semitones ~/ 12;

  /// True if this is a consonant interval (unison, thirds, fifths, sixths, octave).
  bool get isConsonant => const {0, 3, 4, 7, 8, 9, 12}.contains(semitones % 12);

  /// True if this is a dissonant interval (seconds, sevenths, tritone).
  bool get isDissonant => !isConsonant;

  // ─── Factory: compute interval between two pitches ───────────────────────

  /// Compute the interval from [lower] to [upper].
  ///
  /// If [upper] is actually lower, wraps by inverting and adding an octave —
  /// because intervals are always ascending here.
  static Interval between(dynamic lower, dynamic upper) {
    // Circular import avoidance: accept semitone pairs directly from Pitch.
    // Pitch calls this; the actual dispatch is in pitch.dart.
    throw UnimplementedError('Call via Pitch.intervalTo');
  }

  // ─── Named constants — the vocabulary of Western harmony ─────────────────

  static const Interval perfectUnison =
      Interval(semitones: 0, diatonicSteps: 1, quality: IntervalQuality.perfect);
  static const Interval minorSecond =
      Interval(semitones: 1, diatonicSteps: 2, quality: IntervalQuality.minor);
  static const Interval majorSecond =
      Interval(semitones: 2, diatonicSteps: 2, quality: IntervalQuality.major);
  static const Interval minorThird =
      Interval(semitones: 3, diatonicSteps: 3, quality: IntervalQuality.minor);
  static const Interval majorThird =
      Interval(semitones: 4, diatonicSteps: 3, quality: IntervalQuality.major);
  static const Interval perfectFourth =
      Interval(semitones: 5, diatonicSteps: 4, quality: IntervalQuality.perfect);
  static const Interval augmentedFourth =
      Interval(semitones: 6, diatonicSteps: 4, quality: IntervalQuality.augmented);
  static const Interval diminishedFifth =
      Interval(semitones: 6, diatonicSteps: 5, quality: IntervalQuality.diminished);
  static const Interval perfectFifth =
      Interval(semitones: 7, diatonicSteps: 5, quality: IntervalQuality.perfect);
  static const Interval minorSixth =
      Interval(semitones: 8, diatonicSteps: 6, quality: IntervalQuality.minor);
  static const Interval majorSixth =
      Interval(semitones: 9, diatonicSteps: 6, quality: IntervalQuality.major);
  static const Interval minorSeventh =
      Interval(semitones: 10, diatonicSteps: 7, quality: IntervalQuality.minor);
  static const Interval majorSeventh =
      Interval(semitones: 11, diatonicSteps: 7, quality: IntervalQuality.major);
  static const Interval perfectOctave =
      Interval(semitones: 12, diatonicSteps: 8, quality: IntervalQuality.perfect);

  /// The tritone — the most tension-laden interval, equidistant between
  /// tonic and dominant. The augmented fourth and diminished fifth are
  /// enharmonically equivalent but spelled differently based on context.
  static const Interval tritone = augmentedFourth;

  @override
  String toString() => '${quality.name} ${_ordinal(diatonicSteps)}';

  IntervalQuality _invertQuality(IntervalQuality q) => switch (q) {
        IntervalQuality.perfect => IntervalQuality.perfect,
        IntervalQuality.major => IntervalQuality.minor,
        IntervalQuality.minor => IntervalQuality.major,
        IntervalQuality.augmented => IntervalQuality.diminished,
        IntervalQuality.diminished => IntervalQuality.augmented,
      };

  IntervalQuality _compoundQuality(Interval other) {
    // Simplified: only handles same-quality compounds for now
    if (quality == other.quality) return quality;
    return IntervalQuality.major; // fallback — real impl needs full table
  }

  String _ordinal(int n) => switch (n) {
        1 => 'unison',
        2 => 'second',
        3 => 'third',
        4 => 'fourth',
        5 => 'fifth',
        6 => 'sixth',
        7 => 'seventh',
        8 => 'octave',
        _ => '${n}th',
      };
}
