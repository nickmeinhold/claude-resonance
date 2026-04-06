/// # Music as Algebra
///
/// The core insight: music has two kinds of composition —
/// **sequential** (this then that) and **parallel** (this with that).
/// Everything else is transformation.
///
/// This makes music a two-dimensional monoid, which is a fancy way of
/// saying exactly what musicians already know: you can stack voices
/// and chain phrases, and both operations are associative with an
/// identity (silence).
library music_algebra;

// ============================================================
// PITCH — the vertical dimension
// ============================================================

/// Pitch class: the note name independent of octave.
/// Using integers mod 12 because enharmonic spelling is a
/// rendering concern, not a structural one.
/// (C=0, C#=1, D=2, ... B=11)
enum PitchClass {
  c(0), cSharp(1), d(2), dSharp(3), e(4), f(5),
  fSharp(6), g(7), gSharp(8), a(9), aSharp(10), b(11);

  final int value;
  const PitchClass(this.value);

  /// Transpose by semitones, wrapping around.
  PitchClass transpose(int semitones) =>
      PitchClass.values[(value + semitones) % 12];
}

/// Absolute pitch = pitch class + octave.
/// Middle C = Pitch(PitchClass.c, 4).
class Pitch implements Comparable<Pitch> {
  final PitchClass pitchClass;
  final int octave;

  const Pitch(this.pitchClass, this.octave);

  /// MIDI note number — useful as a universal ordering.
  int get midi => (octave + 1) * 12 + pitchClass.value;

  /// The real power: transpose by an interval.
  Pitch transpose(Interval interval) {
    final newMidi = midi + interval.semitones;
    return Pitch(
      PitchClass.values[newMidi % 12],
      (newMidi ~/ 12) - 1,
    );
  }

  @override
  int compareTo(Pitch other) => midi.compareTo(other.midi);

  @override
  String toString() => '${pitchClass.name}$octave';
}

// ============================================================
// INTERVALS — the *relationships* between pitches
// ============================================================

/// This is arguably more fundamental than Pitch itself.
/// Musicians think in intervals. A melody IS its intervals.
class Interval {
  final int semitones;

  const Interval(this.semitones);

  // Named constructors read like music theory.
  static const unison = Interval(0);
  static const minorSecond = Interval(1);
  static const majorSecond = Interval(2);
  static const minorThird = Interval(3);
  static const majorThird = Interval(4);
  static const perfectFourth = Interval(5);
  static const tritone = Interval(6);
  static const perfectFifth = Interval(7);
  static const minorSixth = Interval(8);
  static const majorSixth = Interval(9);
  static const minorSeventh = Interval(10);
  static const majorSeventh = Interval(11);
  static const octave = Interval(12);

  /// Intervals compose by addition. They form a group.
  Interval operator +(Interval other) => Interval(semitones + other.semitones);
  Interval get inversion => Interval(-semitones);

  /// Interval class — collapse to within one octave.
  /// This is what determines consonance/dissonance.
  int get intervalClass => semitones.abs() % 12;
}

// ============================================================
// DURATION — the horizontal dimension
// ============================================================

/// Rational duration avoids the curse of floating-point triplets.
/// A quarter note is Duration(1, 4). A triplet eighth is Duration(1, 12).
/// This is how music actually works — durations are ratios.
class Duration implements Comparable<Duration> {
  final int numerator;
  final int denominator;

  const Duration(this.numerator, this.denominator);

  // The familiar names.
  static const whole = Duration(1, 1);
  static const half = Duration(1, 2);
  static const quarter = Duration(1, 4);
  static const eighth = Duration(1, 8);
  static const sixteenth = Duration(1, 16);

  /// Dotted notes: multiply by 3/2.
  Duration get dotted => Duration(numerator * 3, denominator * 2);

  /// Triplets: multiply by 2/3.
  Duration get triplet => Duration(numerator * 2, denominator * 3);

  /// Duration arithmetic — needed for time calculations.
  Duration operator +(Duration other) => Duration(
        numerator * other.denominator + other.numerator * denominator,
        denominator * other.denominator,
      ); // (should reduce, elided for clarity)

  Duration operator *(int factor) => Duration(numerator * factor, denominator);

  double get toDouble => numerator / denominator;

  @override
  int compareTo(Duration other) =>
      (numerator * other.denominator).compareTo(other.numerator * denominator);
}

// ============================================================
// DYNAMICS — the expressive dimension
// ============================================================

/// Dynamics as a first-class concept, not an afterthought.
/// The range 0.0–1.0 maps to ppp–fff.
class Dynamic {
  final double intensity; // 0.0 to 1.0

  const Dynamic(this.intensity);

  static const ppp = Dynamic(0.05);
  static const pp = Dynamic(0.15);
  static const p = Dynamic(0.3);
  static const mp = Dynamic(0.45);
  static const mf = Dynamic(0.55);
  static const f = Dynamic(0.7);
  static const ff = Dynamic(0.85);
  static const fff = Dynamic(0.95);
}

/// Articulation affects how a note occupies its duration.
enum Articulation {
  legato,    // full duration, connected
  tenuto,    // full duration, slightly separated
  normal,    // ~90% of duration
  staccato,  // ~50% of duration
  marcato,   // accented, ~75%
  pizzicato, // plucked, very short
}

// ============================================================
// THE CORE ALGEBRA — Music as a recursive sum type
// ============================================================

/// This is the heart of the design. A [Music] value is one of:
///   - A single note (pitch + duration + expression)
///   - A rest (duration only)
///   - A sequence (this THEN that)
///   - A stack (this WITH that — simultaneous)
///   - A transformation (modify the music inside)
///
/// Everything composes. There is no "top level" — a symphony and a
/// single note are the same type.
sealed class Music {
  const Music();

  // ---- Smart constructors ----

  /// A pitched note with duration and optional expression.
  static Music note(
    Pitch pitch,
    Duration duration, {
    Dynamic dynamic_ = Dynamic.mf,
    Articulation articulation = Articulation.normal,
  }) =>
      Note(pitch, duration, dynamic_, articulation);

  /// Silence that takes up time. Rests are structural, not absence.
  static Music rest(Duration duration) => Rest(duration);

  /// Play music values one after another.
  static Music seq(List<Music> elements) =>
      elements.reduce((a, b) => Sequence(a, b));

  /// Play music values simultaneously (e.g., chord, or multiple voices).
  static Music stack(List<Music> layers) =>
      layers.reduce((a, b) => Stack(a, b));

  // ---- Transformations as methods ----
  // This is where it gets fun. Every transformation returns new Music.

  /// Transpose all pitches by an interval.
  Music transpose(Interval interval) => Transform(this, Transpose(interval));

  /// Time-reverse the music (retrograde).
  Music get retrograde => Transform(this, const Retrograde());

  /// Invert intervals around an axis pitch.
  Music invert(Pitch axis) => Transform(this, Invert(axis));

  /// Scale all durations by a factor (augmentation/diminution).
  Music stretch(int numerator, int denominator) =>
      Transform(this, Stretch(numerator, denominator));

  /// Repeat n times sequentially.
  Music repeat(int times) => Music.seq(List.filled(times, this));

  /// Set dynamics for this entire subtree.
  Music withDynamic(Dynamic d) => Transform(this, SetDynamic(d));

  /// The total duration of this music — computed recursively.
  Duration get totalDuration;
}

// ---- Concrete music types ----

class Note extends Music {
  final Pitch pitch;
  final Duration duration;
  final Dynamic dynamic_;
  final Articulation articulation;

  const Note(this.pitch, this.duration, this.dynamic_, this.articulation);

  @override
  Duration get totalDuration => duration;
}

class Rest extends Music {
  final Duration duration;
  const Rest(this.duration);

  @override
  Duration get totalDuration => duration;
}

/// Sequential composition: a THEN b.
class Sequence extends Music {
  final Music first;
  final Music second;
  const Sequence(this.first, this.second);

  @override
  Duration get totalDuration => first.totalDuration + second.totalDuration;
}

/// Parallel composition: a WITH b.
/// Duration = max of the two (the longer voice determines when it ends).
class Stack extends Music {
  final Music top;
  final Music bottom;
  const Stack(this.top, this.bottom);

  @override
  Duration get totalDuration {
    final a = top.totalDuration;
    final b = bottom.totalDuration;
    return a.compareTo(b) >= 0 ? a : b;
  }
}

/// A transformation wrapping inner music.
class Transform extends Music {
  final Music inner;
  final Transformation transformation;
  const Transform(this.inner, this.transformation);

  @override
  Duration get totalDuration => transformation.transformDuration(inner.totalDuration);
}

// ============================================================
// TRANSFORMATIONS — the operations you can apply
// ============================================================

/// Each transformation knows how to affect pitches, durations, etc.
/// This is the "instruction" — evaluation happens elsewhere.
sealed class Transformation {
  const Transformation();
  Duration transformDuration(Duration d) => d; // default: no change
}

class Transpose extends Transformation {
  final Interval interval;
  const Transpose(this.interval);
}

class Retrograde extends Transformation {
  const Retrograde();
}

class Invert extends Transformation {
  final Pitch axis;
  const Invert(this.axis);
}

class Stretch extends Transformation {
  final int numerator;
  final int denominator;
  const Stretch(this.numerator, this.denominator);

  @override
  Duration transformDuration(Duration d) =>
      Duration(d.numerator * numerator, d.denominator * denominator);
}

class SetDynamic extends Transformation {
  final Dynamic dynamic_;
  const SetDynamic(this.dynamic_);
}

// ============================================================
// HIGHER-LEVEL CONSTRUCTS — built from the algebra
// ============================================================

/// A scale is just a pattern of intervals from a root.
/// Not a special type — it's a function that generates pitches.
class Scale {
  final List<Interval> intervals;
  const Scale(this.intervals);

  static const major = Scale([
    Interval.unison, Interval.majorSecond, Interval.majorThird,
    Interval.perfectFourth, Interval.perfectFifth,
    Interval.majorSixth, Interval.majorSeventh,
  ]);

  static const minor = Scale([
    Interval.unison, Interval.majorSecond, Interval.minorThird,
    Interval.perfectFourth, Interval.perfectFifth,
    Interval.minorSixth, Interval.minorSeventh,
  ]);

  /// Get the nth degree (0-indexed) from a root pitch.
  Pitch degree(Pitch root, int n) {
    final octaveShift = Interval(12 * (n ~/ intervals.length));
    final scaleInterval = intervals[n % intervals.length];
    return root.transpose(scaleInterval + octaveShift);
  }

  /// Build a triad on the nth degree of the scale.
  Music triad(Pitch root, int degree_, Duration duration) {
    return Music.stack([
      Music.note(degree(root, degree_), duration),
      Music.note(degree(root, degree_ + 2), duration),
      Music.note(degree(root, degree_ + 4), duration),
    ]);
  }
}

/// A chord progression as a sequence of scale-degree triads.
/// This captures *harmonic function* — the I-IV-V-I that means
/// something in any key.
class Progression {
  final List<int> degrees; // 0-indexed scale degrees

  const Progression(this.degrees);

  // The classics.
  static const iIVviV = Progression([0, 3, 5, 4]);   // pop
  static const iIVVi = Progression([0, 3, 4, 0]);     // classical cadence
  static const iiViI = Progression([1, 4, 0]);         // jazz turnaround fragment
  static const twelveBarBlues = Progression([
    0, 0, 0, 0, 3, 3, 0, 0, 4, 3, 0, 4,
  ]);

  /// Realize this progression in a specific key and scale.
  Music realize(Pitch root, Scale scale, Duration chordDuration) {
    return Music.seq([
      for (final deg in degrees) scale.triad(root, deg, chordDuration),
    ]);
  }
}

// ============================================================
// EXAMPLE — bringing it all together
// ============================================================

/// Twinkle Twinkle Little Star as music algebra.
Music twinkle() {
  const c4 = Pitch(PitchClass.c, 4);
  const g4 = Pitch(PitchClass.g, 4);
  const a4 = Pitch(PitchClass.a, 4);
  const f4 = Pitch(PitchClass.f, 4);
  const e4 = Pitch(PitchClass.e, 4);
  const d4 = Pitch(PitchClass.d, 4);
  const q = Duration.quarter;
  const h = Duration.half;

  Music n(Pitch p, [Duration d = q]) => Music.note(p, d);

  // "Twinkle twinkle little star"
  final phrase1 = Music.seq([n(c4), n(c4), n(g4), n(g4), n(a4), n(a4), n(g4, h)]);
  // "How I wonder what you are"
  final phrase2 = Music.seq([n(f4), n(f4), n(e4), n(e4), n(d4), n(d4), n(c4, h)]);

  final melody = Music.seq([phrase1, phrase2]);

  // Harmonize with I and V chords underneath.
  final harmony = Progression.iIVVi
      .realize(c4, Scale.major, Duration.whole)
      .withDynamic(Dynamic.mp);

  // Stack melody on top of harmony.
  return Music.stack([
    melody.withDynamic(Dynamic.mf),
    harmony,
  ]);
}

/// Now the fun part — transform it.
Music variations() {
  final theme = twinkle();

  return Music.seq([
    theme,
    // Variation 1: up a fifth (to G major).
    theme.transpose(Interval.perfectFifth),
    // Variation 2: in minor (invert around middle C).
    theme.invert(const Pitch(PitchClass.c, 4)),
    // Variation 3: twice as slow, fortissimo.
    theme.stretch(2, 1).withDynamic(Dynamic.ff),
    // Variation 4: backwards, because why not.
    theme.retrograde,
  ]);
}
