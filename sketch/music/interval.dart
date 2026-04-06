/// Music as code — the conceptual structure, not the audio.
///
/// Foundation: intervals are more fundamental than pitches.
/// A melody's identity survives transposition because it IS its intervals.
library;

/// The quality of an interval — its color independent of size.
enum IntervalQuality {
  diminished,
  minor,
  perfect,
  major,
  augmented;

  /// Invert the quality (major ↔ minor, aug ↔ dim, perfect stays).
  IntervalQuality get inversion => switch (this) {
    diminished => augmented,
    minor => major,
    perfect => perfect,
    major => minor,
    augmented => diminished,
  };
}

/// An interval: the distance and direction between two pitches.
///
/// This is the atomic unit of musical meaning. Not pitch — relationship.
/// A major third means something whether it starts on C or F#.
class Interval implements Comparable<Interval> {
  /// Generic size: unison = 0, second = 1, third = 2, etc.
  /// Negative for descending.
  final int genericSize;

  /// Specific size in semitones. Encodes quality implicitly.
  final int semitones;

  const Interval(this.genericSize, this.semitones);

  // Named constructors for common intervals — because music thinks in names.
  static const unison = Interval(0, 0);
  static const minorSecond = Interval(1, 1);
  static const majorSecond = Interval(1, 2);
  static const minorThird = Interval(2, 3);
  static const majorThird = Interval(2, 4);
  static const perfectFourth = Interval(3, 5);
  static const tritone = Interval(3, 6); // The devil's interval. Also: symmetry axis.
  static const perfectFifth = Interval(4, 7);
  static const minorSixth = Interval(5, 8);
  static const majorSixth = Interval(5, 9);
  static const minorSeventh = Interval(6, 10);
  static const majorSeventh = Interval(6, 11);
  static const octave = Interval(7, 12);

  /// Tendency: does this interval want to expand or contract?
  ///
  /// This is where the *force field* lives. A minor second has enormous
  /// inward pressure. A tritone is unstable in both directions.
  /// A perfect fifth is at rest.
  Tendency get tendency {
    final mod = semitones.abs() % 12;
    return switch (mod) {
      0 || 7 || 5 => Tendency.stable,    // unison, P5, P4 — points of rest
      1 || 11 => Tendency.contract,        // m2, M7 — want to close
      6 => Tendency.ambiguous,             // tritone — could go either way
      _ => Tendency.mild,                  // everything else — gentle pull
    };
  }

  /// The consonance/dissonance spectrum. Not binary — a gradient.
  ///
  /// Helmholtz was wrong that this is purely acoustic. It's learned.
  /// But the ordering is remarkably stable across traditions.
  double get tension {
    final mod = semitones.abs() % 12;
    return switch (mod) {
      0 => 0.0,   // unison
      7 => 0.1,   // P5
      5 => 0.15,  // P4
      4 => 0.2,   // M3
      3 => 0.25,  // m3
      9 => 0.3,   // M6
      8 => 0.35,  // m6
      2 => 0.5,   // M2
      10 => 0.55, // m7
      6 => 0.7,   // tritone
      11 => 0.85, // M7
      1 => 0.9,   // m2
      _ => 0.5,
    };
  }

  /// Stack two intervals: go up by this, then by [other].
  Interval operator +(Interval other) =>
      Interval(genericSize + other.genericSize, semitones + other.semitones);

  /// Invert: the complement within an octave.
  /// M3 up → m6 down. The same two notes, heard the other way.
  Interval get inversion =>
      Interval(7 - genericSize, 12 - semitones);

  /// Descending version of this interval.
  Interval get descending =>
      Interval(-genericSize, -semitones);

  @override
  int compareTo(Interval other) => semitones.compareTo(other.semitones);

  @override
  String toString() => 'Interval($genericSize, ${semitones}st)';

  @override
  bool operator ==(Object other) =>
      other is Interval &&
      genericSize == other.genericSize &&
      semitones == other.semitones;

  @override
  int get hashCode => Object.hash(genericSize, semitones);
}

/// The directional pull of a musical element.
enum Tendency {
  /// At rest. No urge to move. (Tonic, perfect consonance.)
  stable,

  /// Wants to resolve inward. (Leading tone → tonic, m2 → unison.)
  contract,

  /// Gentle directional pull. Present but not urgent.
  mild,

  /// Could go either way. The tritone's special instability.
  ambiguous,

  /// Wants to resolve outward. (Rare in isolation, common in voice leading.)
  expand,
}
