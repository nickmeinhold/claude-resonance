/// Score — the top-level document structure.
///
/// A score assembles multiple [Part]s (one per instrument or voice) with
/// shared metadata: tempo, key, time signature, title, etc.
///
/// The relationship between Score and Music:
/// - [Music] is the *algebra* — pure, composable, transformable musical values
/// - [Score] is the *document* — opinionated, named, performer-facing notation
///
/// You can derive a Score from a Music value, or extract Music from a Score.
/// They serve different purposes: Music for computation, Score for notation.
library;

import 'music.dart';
import 'duration.dart';
import 'harmony.dart';
import 'pitch.dart';

// ─── Instrument ───────────────────────────────────────────────────────────────

/// A performing instrument, capturing its range and transposition.
///
/// Transposing instruments (Bb clarinet, horn in F) read in one key but
/// sound in another. Concert pitch is the acoustic reality; written pitch
/// is what the performer reads. A Bb trumpet player reading C sounds Bb.
final class Instrument {
  final String name;
  final String abbreviation;

  /// The lowest pitch this instrument can comfortably produce.
  final Pitch rangeBottom;

  /// The highest pitch this instrument can comfortably produce.
  final Pitch rangeTop;

  /// Transposition interval: how far down the sounding pitch is from written.
  /// A Bb clarinet transposes down a major second: written C sounds Bb.
  /// Concert pitch instruments (piano, flute, violin) have null transposition.
  final Interval? transposition;

  const Instrument({
    required this.name,
    required this.abbreviation,
    required this.rangeBottom,
    required this.rangeTop,
    this.transposition,
  });

  bool get isTransposing => transposition != null;

  // ─── Common instruments ─────────────────────────────────────────────────

  static final Instrument piano = Instrument(
    name: 'Piano',
    abbreviation: 'Pno.',
    rangeBottom: Pitch(PitchClass.a, 0),
    rangeTop: Pitch(PitchClass.c, 8),
  );

  static final Instrument violin = Instrument(
    name: 'Violin',
    abbreviation: 'Vln.',
    rangeBottom: Pitch(PitchClass.g, 3),
    rangeTop: Pitch(PitchClass.a, 7),
  );

  static final Instrument cello = Instrument(
    name: 'Cello',
    abbreviation: 'Vc.',
    rangeBottom: Pitch(PitchClass.c, 2),
    rangeTop: Pitch(PitchClass.b, 5),
  );

  static final Instrument trumpet = Instrument(
    name: 'Trumpet in Bb',
    abbreviation: 'Tpt.',
    rangeBottom: Pitch(PitchClass.e, 3),
    rangeTop: Pitch(PitchClass.b, 5),
    transposition: Interval.majorSecond, // written C sounds Bb (down M2)
  );

  static final Instrument altosax = Instrument(
    name: 'Alto Saxophone',
    abbreviation: 'A.Sx.',
    rangeBottom: Pitch(PitchClass.d, 3),
    rangeTop: Pitch(PitchClass.a, 5),
    transposition: Interval(
      semitones: 9,
      diatonicSteps: 6,
      quality: IntervalQuality.major,
    ), // written C sounds Eb (down M6)
  );

  static final Instrument voice = Instrument(
    name: 'Voice',
    abbreviation: 'Vce.',
    rangeBottom: Pitch(PitchClass.c, 3),
    rangeTop: Pitch(PitchClass.c, 6),
  );

  @override
  String toString() => name;
}

// ─── Clef ─────────────────────────────────────────────────────────────────────

/// The clef specifies which staff line corresponds to which pitch.
/// Purely a notational concern — doesn't affect the music, only its rendering.
enum Clef {
  treble,   // G clef: second line from bottom = G4. Violins, flutes, piano right hand.
  bass,     // F clef: second line from top = F3. Cellos, basses, piano left hand.
  alto,     // C clef: middle line = C4. Violas.
  tenor,    // C clef: second from top = C4. High cello passages.
  soprano,  // C clef: bottom line = C4. Historical vocal notation.
  percussion, // No pitch: for unpitched percussion.
}

// ─── Key Signature ────────────────────────────────────────────────────────────

/// A key signature: how many sharps or flats appear at the start of each staff.
///
/// Negative = flats (C major = 0, F major = -1, Bb major = -2).
/// Positive = sharps (G major = +1, D major = +2, etc.).
///
/// The key signature is a *convenience notation* — it doesn't prevent
/// chromatic notes; it just sets the default. The actual tonality is
/// established by the [Scale] in the [KeyModifier].
final class KeySignature {
  /// Number of sharps (positive) or flats (negative). Range: -7 to +7.
  final int accidentals;

  const KeySignature(this.accidentals)
      : assert(accidentals >= -7 && accidentals <= 7);

  static const KeySignature cMajorAMinor = KeySignature(0);
  static const KeySignature gMajorEMinor = KeySignature(1);
  static const KeySignature dMajorBMinor = KeySignature(2);
  static const KeySignature fMajorDMinor = KeySignature(-1);
  static const KeySignature bbMajorGMinor = KeySignature(-2);

  bool get hasSharps => accidentals > 0;
  bool get hasFlats => accidentals < 0;
  bool get isNatural => accidentals == 0;
  int get sharpCount => accidentals > 0 ? accidentals : 0;
  int get flatCount => accidentals < 0 ? -accidentals : 0;

  @override
  String toString() {
    if (accidentals == 0) return 'C major / A minor';
    if (accidentals > 0) return '$accidentals sharp${accidentals > 1 ? 's' : ''}';
    return '${-accidentals} flat${accidentals < -1 ? 's' : ''}';
  }
}

// ─── Part ────────────────────────────────────────────────────────────────────

/// A single instrumental or vocal line within a score.
///
/// A Part wraps a [Music] value with instrument-specific metadata.
/// The music inside can be arbitrarily complex (polyphonic, with chords,
/// with multiple voices) — the Part just gives it a name and instrument.
final class Part {
  final String name;
  final Instrument instrument;
  final Clef clef;
  final Music music;

  /// Staves count: most instruments have 1; piano, organ, harp have 2 (grand staff).
  final int staveCount;

  const Part({
    required this.name,
    required this.instrument,
    required this.music,
    this.clef = Clef.treble,
    this.staveCount = 1,
  });

  Duration get totalDuration => music.totalDuration;

  @override
  String toString() => '${instrument.abbreviation} (${totalDuration})';
}

// ─── Score ────────────────────────────────────────────────────────────────────

/// A complete musical score: all parts with shared context.
///
/// The score is the *performance specification*: everything a conductor or
/// engraver needs. It layers the abstract Music algebra (in each Part) with
/// the concrete performance context (tempo, key, meter, instrumentation).
///
/// ```dart
/// final score = Score(
///   title: 'Prelude',
///   tempo: Tempo.andante,
///   timeSignature: TimeSignature.commonTime,
///   keySignature: KeySignature.gMajorEMinor,
///   parts: [
///     Part(name: 'Violin I', instrument: Instrument.violin, music: melody),
///     Part(name: 'Cello',    instrument: Instrument.cello,  music: bass),
///   ],
/// );
/// ```
final class Score {
  final String title;
  final String? composer;
  final String? lyricist;

  final Tempo tempo;
  final TimeSignature timeSignature;
  final KeySignature keySignature;

  final List<Part> parts;

  /// Optional program notes or performance instructions.
  final String? notes;

  const Score({
    required this.title,
    required this.parts,
    this.composer,
    this.lyricist,
    this.tempo = Tempo.andante,
    this.timeSignature = TimeSignature.commonTime,
    this.keySignature = KeySignature.cMajorAMinor,
    this.notes,
  });

  /// The total duration of the score (duration of the longest part).
  Duration get totalDuration => parts
      .map((p) => p.totalDuration)
      .reduce((a, b) => a > b ? a : b);

  /// All parts combined into a single parallel Music value.
  Music get asMusic => parts.map((p) => p.music).toList().parallel;

  /// Add a part, returning a new Score.
  Score withPart(Part part) => Score(
        title: title,
        composer: composer,
        lyricist: lyricist,
        tempo: tempo,
        timeSignature: timeSignature,
        keySignature: keySignature,
        parts: [...parts, part],
        notes: notes,
      );

  /// Transpose the entire score by [interval].
  Score transpose(Interval interval) => Score(
        title: title,
        composer: composer,
        lyricist: lyricist,
        tempo: tempo,
        timeSignature: timeSignature,
        keySignature: keySignature,
        parts: parts
            .map((p) => Part(
                  name: p.name,
                  instrument: p.instrument,
                  clef: p.clef,
                  music: p.music.transpose(interval),
                  staveCount: p.staveCount,
                ))
            .toList(),
        notes: notes,
      );

  @override
  String toString() {
    final by = composer != null ? ' by $composer' : '';
    return '"$title"$by — ${parts.length} part${parts.length != 1 ? 's' : ''}, ${totalDuration}';
  }
}
