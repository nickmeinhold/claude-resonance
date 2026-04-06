/// Music as code — modeling musical *concepts*, not notation.
///
/// Design principles:
///   1. Relationships over atoms (intervals > absolute pitches)
///   2. Two combinators: sequential (melody) and parallel (harmony)
///   3. Dynamics/articulation as separable layers, not note properties
///   4. Relative by default, absolute only when grounded
library;

// ---------------------------------------------------------------------------
// PITCH: The vertical dimension
// ---------------------------------------------------------------------------

/// Pitch is either absolute or relative. Most musical thinking is relative:
/// "a step up," "the fifth of the chord," "the leading tone."
/// Absolute pitch only matters when you finally render to sound.
sealed class Pitch {
  const Pitch();
}

/// Concert pitch — the physicist's view. Rarely what musicians think in.
class Frequency extends Pitch {
  final double hz;
  const Frequency(this.hz);
}

/// Named pitch — the performer's view. C4, Bb3, F#5.
class NamedPitch extends Pitch {
  final PitchClass pitchClass;
  final int octave;
  const NamedPitch(this.pitchClass, this.octave);
}

/// Scale degree — the composer's view. "The third," "the leading tone."
/// This is where musical *meaning* lives. The third of a major scale
/// and the third of a minor scale are different organisms in different
/// ecosystems, even if they're the same frequency.
class ScaleDegree extends Pitch {
  final int degree; // 1-7
  final Alteration alteration;
  const ScaleDegree(this.degree, [this.alteration = Alteration.natural]);
}

/// Interval — the relationship itself, divorced from any starting point.
/// Arguably the most fundamental pitch concept. A melody IS its intervals.
/// Transpose a melody and it's "the same melody" because intervals are preserved.
class Interval extends Pitch {
  final int semitones;
  const Interval(this.semitones);

  // Named constructors for readability
  static const unison = Interval(0);
  static const minorSecond = Interval(1);
  static const majorSecond = Interval(2);
  static const minorThird = Interval(3);
  static const majorThird = Interval(4);
  static const perfectFourth = Interval(5);
  static const tritone = Interval(6);
  static const perfectFifth = Interval(7);
  static const octave = Interval(12);
}

enum PitchClass { c, cSharp, d, dSharp, e, f, fSharp, g, gSharp, a, aSharp, b }
enum Alteration { flat, natural, sharp }

// ---------------------------------------------------------------------------
// TIME: The horizontal dimension
// ---------------------------------------------------------------------------

/// Duration is relative by default. A "quarter note" has no absolute length
/// until you specify a tempo. This matters: the same rhythm feels completely
/// different at 60bpm vs 180bpm, but it's structurally identical.
sealed class Duration {
  const Duration();
}

/// Relative duration — proportional to the beat.
class RelativeDuration extends Duration {
  /// Fraction of a whole note. quarter = 1/4, eighth = 1/8, etc.
  final double fraction;
  const RelativeDuration(this.fraction);

  static const whole = RelativeDuration(1.0);
  static const half = RelativeDuration(0.5);
  static const quarter = RelativeDuration(0.25);
  static const eighth = RelativeDuration(0.125);
  static const sixteenth = RelativeDuration(0.0625);

  /// Dotted: duration * 1.5
  RelativeDuration get dotted => RelativeDuration(fraction * 1.5);
}

/// Absolute duration — for when you need real time.
class AbsoluteDuration extends Duration {
  final double milliseconds;
  const AbsoluteDuration(this.milliseconds);
}

/// Silence is not the absence of music. It's music that isn't sounding.
/// John Cage knew this. A rest has duration, weight, tension.
class Rest extends Duration {
  final Duration length;
  const Rest(this.length);
}

// ---------------------------------------------------------------------------
// THE CORE: Musical expressions as a recursive tree
// ---------------------------------------------------------------------------

/// This is where the programming-language analogy pays off.
/// A musical expression is either a primitive (a note, a rest)
/// or a combinator (sequential, parallel, transformed).
///
/// Think of it like an AST for music.
sealed class Music {
  const Music();

  // --- Combinators as operators ---

  /// Sequential composition: this THEN that. Melody.
  Music operator +(Music other) => Seq([this, other]);

  /// Parallel composition: this WITH that. Harmony.
  Music operator |(Music other) => Par([this, other]);

  /// Apply a transformation.
  Music transform(Transform t) => Transformed(this, t);
}

/// A single sounding event. The atom.
/// Note: dynamics and articulation are NOT here. They're separate layers.
/// A note doesn't "have" a dynamic — a dynamic is applied to a passage.
class Note extends Music {
  final Pitch pitch;
  final Duration duration;
  const Note(this.pitch, this.duration);
}

/// Silence with shape.
class Silence extends Music {
  final Duration duration;
  const Silence(this.duration);
}

/// Sequential composition — events in time order. This IS melody.
class Seq extends Music {
  final List<Music> children;
  const Seq(this.children);
}

/// Parallel composition — simultaneous events. This IS harmony/polyphony.
/// The ecology: multiple organisms coexisting in the same temporal niche.
class Par extends Music {
  final List<Music> children;
  const Par(this.children);
}

/// A transformation applied to music. This is where it gets interesting.
/// Music is deeply self-similar — themes return transposed, inverted,
/// augmented. A fugue is literally "the same music, transformed."
class Transformed extends Music {
  final Music source;
  final Transform transform;
  const Transformed(this.source, this.transform);
}

/// Repetition with optional variation. Not just "play it again" —
/// repetition with variation is arguably the fundamental operation of music.
/// Theme and variations. Verse and chorus. Ostinato.
class Repeated extends Music {
  final Music source;
  final int times;
  final Transform? variation; // null = exact repetition
  const Repeated(this.source, this.times, [this.variation]);
}

// ---------------------------------------------------------------------------
// TRANSFORMS: How music refers to itself
// ---------------------------------------------------------------------------

/// Transforms are first-class. They can compose, chain, and apply to
/// any level of the musical tree. This mirrors how composers actually think:
/// "take the theme, invert it, augment the rhythm, start on the dominant."
sealed class Transform {
  const Transform();

  /// Compose two transforms: apply this, then other.
  Transform then(Transform other) => Chained([this, other]);
}

class Transpose extends Transform {
  final Interval interval;
  const Transpose(this.interval);
}

/// Melodic inversion — flip intervals. What went up now goes down.
/// The musical mirror.
class Invert extends Transform {
  final Pitch axis; // pitch around which to invert
  const Invert(this.axis);
}

/// Retrograde — play it backwards. Time reversal.
class Retrograde extends Transform {
  const Retrograde();
}

/// Augmentation/diminution — stretch or compress time.
class ScaleTime extends Transform {
  final double factor; // 2.0 = augmentation (twice as slow), 0.5 = diminution
  const ScaleTime(this.factor);
}

/// Change the tonal context. Same melody, different ecosystem.
/// This is the ecological analogy at its strongest: transplant an organism
/// to a new environment and its role changes entirely.
class Recontextualize extends Transform {
  final TonalContext newContext;
  const Recontextualize(this.newContext);
}

class Chained extends Transform {
  final List<Transform> transforms;
  const Chained(this.transforms);
}

// ---------------------------------------------------------------------------
// LAYERS: Things that are ABOUT music, not music itself
// ---------------------------------------------------------------------------

/// Dynamics are not properties of notes. They're a separate expressive
/// layer painted over a musical structure. The same melody can be played
/// pp or ff — it's the same melody. This is the crucial modeling insight.
///
/// Analogy: dynamics are like weather in the ecology. They affect everything,
/// but they're not part of any organism's DNA.
sealed class Dynamic {
  const Dynamic();
}

class ConstantDynamic extends Dynamic {
  final double level; // 0.0 (silence) to 1.0 (fff)
  const ConstantDynamic(this.level);

  static const ppp = ConstantDynamic(0.1);
  static const pp = ConstantDynamic(0.2);
  static const p = ConstantDynamic(0.35);
  static const mp = ConstantDynamic(0.5);
  static const mf = ConstantDynamic(0.6);
  static const f = ConstantDynamic(0.75);
  static const ff = ConstantDynamic(0.88);
  static const fff = ConstantDynamic(1.0);
}

/// A dynamic shape over time. Crescendo, decrescendo, sforzando.
class DynamicContour extends Dynamic {
  final Dynamic from;
  final Dynamic to;
  final Duration over;
  const DynamicContour(this.from, this.to, this.over);
}

/// Articulation: how a note begins, sustains, and ends.
/// Staccato, legato, marcato, tenuto. These are about *gesture*, not pitch.
enum Articulation { legato, staccato, marcato, tenuto, accent, slurred }

/// A layer binds expression to a musical passage.
class Expressive extends Music {
  final Music music;
  final Dynamic? dynamic;
  final Articulation? articulation;
  final double? tempo; // bpm, if grounding to absolute time
  const Expressive(this.music, {this.dynamic, this.articulation, this.tempo});
}

// ---------------------------------------------------------------------------
// TONAL CONTEXT: The ecosystem that gives notes meaning
// ---------------------------------------------------------------------------

/// A tonal context is like an ecosystem — it defines the roles available
/// to organisms (pitches). In C major, the note E is the warm major third.
/// In C minor, Eb is the dark minor third. Same spatial region, different niche.
class TonalContext {
  final PitchClass root;
  final Mode mode;
  const TonalContext(this.root, this.mode);
}

/// Modes aren't just scales — they're *moods*, entire ecosystems of tension
/// and resolution. Ionian (major) and Aeolian (minor) are just the two
/// everyone knows. Dorian, Mixolydian, Lydian each have distinct gravitational fields.
enum Mode { ionian, dorian, phrygian, lydian, mixolydian, aeolian, locrian }

/// Harmonic function — what role a chord plays in the tonal ecosystem.
/// This is the deepest layer of tonal meaning. A V chord "wants" to resolve
/// to I not because of physics, but because of learned expectation.
/// (Where the ecology analogy breaks: ecological niches aren't teleological.
/// Harmonic functions ARE — they point somewhere.)
enum HarmonicFunction { tonic, supertonic, mediant, subdominant, dominant, submediant, leadingTone }

/// A chord is a vertical slice of the ecology — which organisms coexist.
class Chord {
  final ScaleDegree root;
  final ChordQuality quality;
  final List<Interval> extensions; // 7ths, 9ths, etc.
  final HarmonicFunction? function;
  const Chord(this.root, this.quality, {this.extensions = const [], this.function});
}

enum ChordQuality { major, minor, diminished, augmented, dominant7, major7, minor7 }

// ---------------------------------------------------------------------------
// EXAMPLE: Bach meets Dart
// ---------------------------------------------------------------------------

/// Here's what composing looks like with this structure.
/// A simple melody, harmonized, with expression.
Music examplePhrase() {
  const ctx = TonalContext(PitchClass.c, Mode.ionian);

  // Melody as scale degrees — portable across keys
  const melody = Seq([
    Note(ScaleDegree(1), RelativeDuration.quarter),
    Note(ScaleDegree(3), RelativeDuration.quarter),
    Note(ScaleDegree(5), RelativeDuration.quarter),
    Note(ScaleDegree(8), RelativeDuration.half),
  ]);

  // The same melody, inverted and in the dominant — a fugal answer
  const answer = Transformed(
    melody,
    Chained([
      Invert(ScaleDegree(5)),
      Transpose(Interval.perfectFifth),
    ]),
  );

  // Harmony: melody WITH its answer, simultaneous
  const polyphony = Par([melody, answer]);

  // Add expression as a layer
  const phrase = Expressive(
    polyphony,
    dynamic: DynamicContour(
      ConstantDynamic.mp,
      ConstantDynamic.f,
      RelativeDuration.whole,
    ),
    articulation: Articulation.legato,
    tempo: 120,
  );

  return phrase;
}

// A chord progression as harmonic ecology
Music exampleProgression() {
  const q = RelativeDuration.whole;
  const progression = Seq([
    // I → vi → IV → V : the most common niche structure in pop ecology
    Note(ScaleDegree(1), q),  // home
    Note(ScaleDegree(6), q),  // relative minor — the shadow
    Note(ScaleDegree(4), q),  // subdominant — departure
    Note(ScaleDegree(5), q),  // dominant — tension, pointing home
  ]);

  // Theme and variations: the fundamental musical operation
  const piece = Repeated(progression, 4, ScaleTime(0.75)); // each time, slightly faster

  return piece;
}
