/// Harmony — vertical relationships between pitches, and their functional meaning.
///
/// Harmony is the most layered concept in Western music theory. This file
/// separates three distinct layers:
///
/// 1. **Scale** — the pitch vocabulary of a key center
/// 2. **Chord** — a specific set of simultaneously-sounding pitches (the *spelling*)
/// 3. **ChordSymbol** — the harmonic label and function (C7, Am, G♯dim, etc.)
///
/// These are not the same thing. A "C major chord" can be voiced dozens of ways
/// (C-E-G, E-G-C, G-C-E, C-E-G-C...). The ChordSymbol captures the identity;
/// the voiced chord captures a specific realization. Keeping them separate
/// makes it possible to analyze harmony without fixing a voicing, and to
/// generate voicings algorithmically from symbols.
library;

import 'pitch.dart';
import 'interval.dart';

// ─── Scales ───────────────────────────────────────────────────────────────────

/// A scale type: the pattern of intervals that defines a mode or scale.
///
/// Defined as successive intervals (steps), not intervals from root, so that
/// exotic scales and modes can be defined uniformly. The steps must sum to
/// a perfect octave (12 semitones, 8 diatonic steps for 7-note scales).
final class ScaleType {
  final String name;

  /// The intervals between successive scale degrees (not from root).
  /// For major: [W, W, H, W, W, W, H] = [M2, M2, m2, M2, M2, M2, m2].
  final List<Interval> steps;

  const ScaleType(this.name, this.steps);

  // ─── Common scales ───────────────────────────────────────────────────────

  static final ScaleType major = ScaleType('Major', [
    Interval.majorSecond, Interval.majorSecond, Interval.minorSecond,
    Interval.majorSecond, Interval.majorSecond, Interval.majorSecond,
    Interval.minorSecond,
  ]);

  static final ScaleType naturalMinor = ScaleType('Natural Minor', [
    Interval.majorSecond, Interval.minorSecond, Interval.majorSecond,
    Interval.majorSecond, Interval.minorSecond, Interval.majorSecond,
    Interval.majorSecond,
  ]);

  static final ScaleType harmonicMinor = ScaleType('Harmonic Minor', [
    Interval.majorSecond, Interval.minorSecond, Interval.majorSecond,
    Interval.majorSecond, Interval.minorSecond,
    Interval(semitones: 3, diatonicSteps: 2, quality: IntervalQuality.augmented), // aug 2nd
    Interval.minorSecond,
  ]);

  static final ScaleType dorian = ScaleType('Dorian', [
    Interval.majorSecond, Interval.minorSecond, Interval.majorSecond,
    Interval.majorSecond, Interval.majorSecond, Interval.minorSecond,
    Interval.majorSecond,
  ]);

  static final ScaleType phrygian = ScaleType('Phrygian', [
    Interval.minorSecond, Interval.majorSecond, Interval.majorSecond,
    Interval.majorSecond, Interval.minorSecond, Interval.majorSecond,
    Interval.majorSecond,
  ]);

  static final ScaleType lydian = ScaleType('Lydian', [
    Interval.majorSecond, Interval.majorSecond, Interval.majorSecond,
    Interval.minorSecond, Interval.majorSecond, Interval.majorSecond,
    Interval.minorSecond,
  ]);

  static final ScaleType mixolydian = ScaleType('Mixolydian', [
    Interval.majorSecond, Interval.majorSecond, Interval.minorSecond,
    Interval.majorSecond, Interval.majorSecond, Interval.minorSecond,
    Interval.majorSecond,
  ]);

  // Pentatonic — 5 notes, no half-steps, hence the "universal" quality
  static final ScaleType majorPentatonic = ScaleType('Major Pentatonic', [
    Interval.majorSecond, Interval.majorSecond, Interval.minorThird,
    Interval.majorSecond, Interval.minorThird,
  ]);

  static final ScaleType blues = ScaleType('Blues', [
    Interval.minorThird, Interval.majorSecond, Interval.minorSecond,
    Interval.minorSecond, Interval.minorThird, Interval.majorSecond,
  ]);

  @override
  String toString() => name;
}

/// A scale rooted at a specific [PitchClass], spanning one or more octaves.
///
/// The scale is the tonal *vocabulary* of a passage — it defines which notes
/// are "in" and which are chromatic alterations, which chords are diatonic,
/// and which scale degree (I, II, III...) each pitch represents.
final class Scale {
  final PitchClass root;
  final ScaleType type;

  const Scale(this.root, this.type);

  // ─── Common keys ─────────────────────────────────────────────────────────

  static final Scale cMajor = Scale(PitchClass.c, ScaleType.major);
  static final Scale aMinor = Scale(PitchClass.a, ScaleType.naturalMinor);
  static final Scale gMajor = Scale(PitchClass.g, ScaleType.major);
  static final Scale dDorian = Scale(PitchClass.d, ScaleType.dorian);

  /// The pitch classes in this scale, in ascending order from root.
  List<PitchClass> get pitchClasses {
    final classes = <PitchClass>[root];
    var current = Pitch(root, 4); // octave doesn't matter for pitch class
    for (final step in type.steps.take(type.steps.length - 1)) {
      current = current.transpose(step);
      classes.add(current.pitchClass);
    }
    return classes;
  }

  /// Ascending pitches from root in the given [startOctave].
  List<Pitch> pitches({int startOctave = 4, int octaves = 1}) {
    final result = <Pitch>[];
    var current = Pitch(root, startOctave);
    result.add(current);
    final allSteps = List.generate(
      type.steps.length * octaves,
      (i) => type.steps[i % type.steps.length],
    );
    for (final step in allSteps) {
      current = current.transpose(step);
      result.add(current);
    }
    return result;
  }

  /// Whether this [pitchClass] is diatonic in this scale.
  bool contains(PitchClass pitchClass) => pitchClasses.contains(pitchClass);

  /// The scale degree of [pitchClass] (1-indexed: 1=tonic, 5=dominant).
  /// Returns null if the pitch class is not in the scale.
  int? degreeOf(PitchClass pitchClass) {
    final idx = pitchClasses.indexOf(pitchClass);
    return idx == -1 ? null : idx + 1;
  }

  /// Build a diatonic triad on [degree] (1=tonic, 4=subdominant, 5=dominant).
  ChordSymbol triadOnDegree(int degree) {
    assert(degree >= 1 && degree <= pitchClasses.length);
    final classes = pitchClasses;
    final root = classes[(degree - 1) % classes.length];
    final third = classes[(degree + 1) % classes.length];
    final fifth = classes[(degree + 3) % classes.length];
    return ChordSymbol._analyze(root, third, fifth);
  }

  @override
  String toString() => '${root.name.toUpperCase()} ${type.name}';
}

// ─── Chord Symbols ────────────────────────────────────────────────────────────

/// The quality (character) of a chord.
enum ChordQuality {
  major,
  minor,
  diminished,
  augmented,
  dominant7,      // major triad + minor 7th — the "tension chord" par excellence
  major7,         // major triad + major 7th — jazzy, dreamy
  minor7,         // minor triad + minor 7th
  halfDiminished, // diminished triad + minor 7th (ø)
  diminished7,    // diminished triad + diminished 7th — dense dissonance
  suspended2,
  suspended4,
}

/// An optional chord extension or alteration (9th, 11th, 13th, ♭9, ♯11, etc.)
final class Extension {
  final int degree;      // 9, 11, 13
  final Accidental alteration;

  const Extension(this.degree, [this.alteration = Accidental.natural]);

  static const Extension ninth = Extension(9);
  static const Extension flatNinth = Extension(9, Accidental.flat);
  static const Extension sharpNinth = Extension(9, Accidental.sharp);
  static const Extension eleventh = Extension(11);
  static const Extension sharpEleventh = Extension(11, Accidental.sharp);
  static const Extension thirteenth = Extension(13);
  static const Extension flatThirteenth = Extension(13, Accidental.flat);

  @override
  String toString() => '${alteration.symbol}$degree';
}

/// A harmonic label: root + quality + extensions + optional bass note.
///
/// This is the "name tag" on a chord — what you'd write in a lead sheet.
/// C7, Am7, G♯dim, Fmaj7/A, B♭13(♯11) are all valid ChordSymbols.
///
/// Crucially, a ChordSymbol doesn't specify:
/// - Which octave the root is in
/// - How the notes are spaced (voicing)
/// - Which notes are doubled
///
/// Those details live in the voiced [ChordVoicing]. This separation makes
/// harmonic analysis possible: you can ask "what is this chord?" without
/// knowing "how exactly is it laid out?"
final class ChordSymbol {
  final PitchClass root;
  final ChordQuality quality;
  final List<Extension> extensions;

  /// If non-null, the lowest note (slash chord): C/E = C major with E in the bass.
  final PitchClass? bassNote;

  const ChordSymbol({
    required this.root,
    required this.quality,
    this.extensions = const [],
    this.bassNote,
  });

  // ─── Factories ───────────────────────────────────────────────────────────

  factory ChordSymbol.major(PitchClass root, {List<Extension> extensions = const []}) =>
      ChordSymbol(root: root, quality: ChordQuality.major, extensions: extensions);

  factory ChordSymbol.minor(PitchClass root, {List<Extension> extensions = const []}) =>
      ChordSymbol(root: root, quality: ChordQuality.minor, extensions: extensions);

  factory ChordSymbol.dominant7(PitchClass root, {List<Extension> extensions = const []}) =>
      ChordSymbol(root: root, quality: ChordQuality.dominant7, extensions: extensions);

  factory ChordSymbol.diminished(PitchClass root) =>
      ChordSymbol(root: root, quality: ChordQuality.diminished);

  // ─── Analysis ────────────────────────────────────────────────────────────

  /// Infer a chord symbol from the root, third, and fifth pitch classes.
  /// (Internal helper for Scale.triadOnDegree.)
  ///
  /// Determines quality by measuring the intervals between root→third and
  /// root→fifth in semitones. The four triad types:
  /// - Major: M3 + P5 (4 + 7)
  /// - Minor: m3 + P5 (3 + 7)
  /// - Diminished: m3 + d5 (3 + 6)
  /// - Augmented: M3 + A5 (4 + 8)
  static ChordSymbol _analyze(PitchClass root, PitchClass third, PitchClass fifth) {
    final rootSemitones = Pitch(root, 4).semitones;
    final thirdInterval = (Pitch(third, 4).semitones - rootSemitones) % 12;
    final fifthInterval = (Pitch(fifth, 4).semitones - rootSemitones) % 12;

    final quality = switch ((thirdInterval, fifthInterval)) {
      (4, 7) => ChordQuality.major,
      (3, 7) => ChordQuality.minor,
      (3, 6) => ChordQuality.diminished,
      (4, 8) => ChordQuality.augmented,
      _ => ChordQuality.major, // fallback for unrecognized voicings
    };
    return ChordSymbol(root: root, quality: quality);
  }

  // ─── Realization ─────────────────────────────────────────────────────────

  /// The pitch classes in this chord (root position, no extensions).
  List<PitchClass> get pitchClasses {
    final rootSemitones = Pitch(root, 4).semitones;
    return _intervalSemitones.map((semitones) {
      final target = rootSemitones + semitones;
      // Find the pitch class at this semitone offset
      for (final pc in PitchClass.values) {
        for (final acc in Accidental.values) {
          final candidate = Pitch(pc, 4, acc);
          if ((candidate.semitones - rootSemitones) % 12 == semitones % 12) {
            return pc;
          }
        }
      }
      return root; // fallback
    }).toList();
  }

  List<int> get _intervalSemitones => switch (quality) {
        ChordQuality.major => [0, 4, 7],
        ChordQuality.minor => [0, 3, 7],
        ChordQuality.diminished => [0, 3, 6],
        ChordQuality.augmented => [0, 4, 8],
        ChordQuality.dominant7 => [0, 4, 7, 10],
        ChordQuality.major7 => [0, 4, 7, 11],
        ChordQuality.minor7 => [0, 3, 7, 10],
        ChordQuality.halfDiminished => [0, 3, 6, 10],
        ChordQuality.diminished7 => [0, 3, 6, 9],
        ChordQuality.suspended2 => [0, 2, 7],
        ChordQuality.suspended4 => [0, 5, 7],
      };

  @override
  String toString() {
    final ext = extensions.map((e) => e.toString()).join('');
    final bass = bassNote != null ? '/${bassNote!.name.toUpperCase()}' : '';
    final qualityStr = switch (quality) {
      ChordQuality.major => '',
      ChordQuality.minor => 'm',
      ChordQuality.diminished => 'dim',
      ChordQuality.augmented => 'aug',
      ChordQuality.dominant7 => '7',
      ChordQuality.major7 => 'maj7',
      ChordQuality.minor7 => 'm7',
      ChordQuality.halfDiminished => 'ø7',
      ChordQuality.diminished7 => 'dim7',
      ChordQuality.suspended2 => 'sus2',
      ChordQuality.suspended4 => 'sus4',
    };
    return '${root.name.toUpperCase()}$qualityStr$ext$bass';
  }
}

// ─── Harmonic Progressions ────────────────────────────────────────────────────

/// A scale degree in Roman numeral notation.
///
/// The power of Roman numeral analysis: you can say "this piece goes I-IV-V-I"
/// and mean it in *any* key. The function (tonic→subdominant→dominant→tonic)
/// is preserved regardless of transposition.
enum ScaleDegree {
  i(1), ii(2), iii(3), iv(4), v(5), vi(6), vii(7);

  final int number;
  const ScaleDegree(this.number);

  String get romanNumeral => switch (this) {
        ScaleDegree.i => 'I',
        ScaleDegree.ii => 'II',
        ScaleDegree.iii => 'III',
        ScaleDegree.iv => 'IV',
        ScaleDegree.v => 'V',
        ScaleDegree.vi => 'VI',
        ScaleDegree.vii => 'VII',
      };
}

/// A functional harmonic step: a scale degree + optional quality override + duration.
///
/// In C major, [ScaleDegree.v] with [ChordQuality.dominant7] = G7.
/// The scale handles the spelling; the degree and quality define the function.
final class HarmonicStep {
  final ScaleDegree degree;

  /// Null = use the diatonic quality from the scale. Non-null = override
  /// (e.g., raise the V to a dominant 7th even in minor, add a borrowed chord).
  final ChordQuality? quality;

  /// Optional bass note (for inversions in the progression).
  final PitchClass? bassNote;

  final duration.Duration harmonicDuration;

  const HarmonicStep(
    this.degree,
    this.harmonicDuration, {
    this.quality,
    this.bassNote,
  });

  @override
  String toString() {
    final q = quality != null ? '(${quality!.name})' : '';
    return '${degree.romanNumeral}$q';
  }
}

/// A harmonic progression: the chord-to-chord motion that defines tonal direction.
///
/// Progressions are abstract (key-independent) until realized in a specific [Scale].
/// The classic ii-V-I of jazz is the same functional motion in every key.
final class HarmonicProgression {
  final List<HarmonicStep> steps;

  const HarmonicProgression(this.steps);

  // ─── Common progressions ─────────────────────────────────────────────────

  static HarmonicProgression get iviVI => HarmonicProgression([
        HarmonicStep(ScaleDegree.i, duration.Duration.whole),
        HarmonicStep(ScaleDegree.v, duration.Duration.whole),
        HarmonicStep(ScaleDegree.vi, duration.Duration.whole),
        HarmonicStep(ScaleDegree.i, duration.Duration.whole),
      ]);

  static HarmonicProgression get iiVI => HarmonicProgression([
        HarmonicStep(ScaleDegree.ii, duration.Duration.half,
            quality: ChordQuality.minor7),
        HarmonicStep(ScaleDegree.v, duration.Duration.half,
            quality: ChordQuality.dominant7),
        HarmonicStep(ScaleDegree.i, duration.Duration.whole,
            quality: ChordQuality.major7),
      ]);

  static HarmonicProgression get blues => HarmonicProgression([
        HarmonicStep(ScaleDegree.i, duration.Duration(4, 4), quality: ChordQuality.dominant7),
        HarmonicStep(ScaleDegree.i, duration.Duration(4, 4), quality: ChordQuality.dominant7),
        HarmonicStep(ScaleDegree.i, duration.Duration(4, 4), quality: ChordQuality.dominant7),
        HarmonicStep(ScaleDegree.i, duration.Duration(4, 4), quality: ChordQuality.dominant7),
        HarmonicStep(ScaleDegree.iv, duration.Duration(4, 4), quality: ChordQuality.dominant7),
        HarmonicStep(ScaleDegree.iv, duration.Duration(4, 4), quality: ChordQuality.dominant7),
        HarmonicStep(ScaleDegree.i, duration.Duration(4, 4), quality: ChordQuality.dominant7),
        HarmonicStep(ScaleDegree.i, duration.Duration(4, 4), quality: ChordQuality.dominant7),
        HarmonicStep(ScaleDegree.v, duration.Duration(4, 4), quality: ChordQuality.dominant7),
        HarmonicStep(ScaleDegree.iv, duration.Duration(4, 4), quality: ChordQuality.dominant7),
        HarmonicStep(ScaleDegree.i, duration.Duration(4, 4), quality: ChordQuality.dominant7),
        HarmonicStep(ScaleDegree.v, duration.Duration(4, 4), quality: ChordQuality.dominant7),
      ]);

  /// Realize this progression in [scale], returning concrete chord symbols.
  List<ChordSymbol> realize(Scale scale) {
    return steps.map((step) {
      final degree = step.degree.number;
      final diatonicChord = scale.triadOnDegree(degree);
      if (step.quality != null) {
        return ChordSymbol(
          root: diatonicChord.root,
          quality: step.quality!,
          bassNote: step.bassNote,
        );
      }
      return ChordSymbol(
        root: diatonicChord.root,
        quality: diatonicChord.quality,
        bassNote: step.bassNote,
      );
    }).toList();
  }

  @override
  String toString() => steps.map((s) => s.toString()).join(' – ');
}

// Import alias to avoid naming conflict with Duration in this file
import 'duration.dart' as duration;
