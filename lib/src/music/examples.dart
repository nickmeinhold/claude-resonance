/// Examples — showing how the music algebra composes in practice.
///
/// These aren't runnable yet (the implementations need filling in), but they
/// demonstrate the *interface* — what it feels like to build music with this
/// system, and what's expressible at each level.
library;

import 'pitch.dart';
import 'duration.dart';
import 'interval.dart';
import 'harmony.dart';
import 'music.dart';
import 'score.dart';
import 'expression.dart';
import 'motif.dart';

// ─── Example 1: A simple Bach-style chorale phrase ───────────────────────────

/// "Jesu, Joy of Man's Desiring" opening — soprano voice, simplified.
///
/// This shows the note-level API: each pitch gets a duration, articulation
/// is implicit (legato), and the phrase is built as a Sequential.
Music joyOpening() {
  // Building blocks: name the notes we'll use.
  final b4  = Pitch(PitchClass.b, 4);
  final d5  = Pitch(PitchClass.d, 5);
  final e5  = Pitch(PitchClass.e, 5);
  final g5  = Pitch(PitchClass.g, 5);
  final a5  = Pitch(PitchClass.a, 5);
  final fS5 = Pitch(PitchClass.f, 5, Accidental.sharp);

  // The melody as a list of note-values using the PitchToNote extension.
  final soprano = [
    b4.eighth,   // the pickup — rhythmically interesting, starts on beat 3
    d5.eighth,
    e5.eighth,
    fS5.eighth,
    g5.quarter,  // arrival: the phrase breathes here
    e5.quarter,
    g5.eighth,
    a5.eighth,
  ].map((n) => n.asMusic).toList().sequential;

  return soprano;
}

// ─── Example 2: A jazz ii-V-I in C, with chord symbols ───────────────────────

/// Demonstrates harmonic progression realization — abstract function to
/// concrete chord names.
List<ChordSymbol> jazzTurnaround() {
  final cMajor = Scale.cMajor;
  final iiVI = HarmonicProgression.iiVI;
  return iiVI.realize(cMajor);
  // Returns: [Dm7, G7, Cmaj7]
}

// ─── Example 3: Canon by inversion ───────────────────────────────────────────

/// A short canon where Voice 2 enters after one measure with the inverted melody.
///
/// This is the algebraic power: [Music.invert] and [Music.delayed] work on
/// *any* Music value without knowing the specific notes inside.
Music canticleOfInversion() {
  final theme = [
    Pitch(PitchClass.c, 5).quarter,
    Pitch(PitchClass.e, 5).quarter,
    Pitch(PitchClass.g, 5).half,
  ].map((n) => n.asMusic).toList().sequential;

  final voice1 = theme.repeat(2);

  // Voice 2 is the inversion of the theme, entering one measure late.
  // The melody C→E→G becomes C→A→F (mirror around C5).
  final voice2 = theme
      .invert(Pitch.middleC.transpose(Interval.perfectOctave))
      .delayed(Duration.whole) // enter after 4 quarter notes
      .repeat(2);

  return voice1 | voice2;
}

// ─── Example 4: Rhythm + melody separated ────────────────────────────────────

/// The bossa nova clave rhythm, applied to two different melodic ideas.
///
/// This demonstrates that rhythm is a first-class concept: you define the
/// rhythmic skeleton once, then realize it with different pitches.
Music bossaNovaPhrase() {
  // The tresillo feel: 3+3+2 over 8 eighth notes
  final clave = RhythmPattern.tresillo;

  final phraseA = clave.realize([
    Pitch(PitchClass.a, 4),
    Pitch(PitchClass.b, 4),
    Pitch(PitchClass.c, 5),
  ]);

  final phraseB = clave.realize([
    Pitch(PitchClass.f, 4, Accidental.sharp),
    Pitch(PitchClass.a, 4),
    Pitch(PitchClass.e, 4),
  ]);

  // Alternate the two phrases over four repetitions
  return (phraseA + phraseB).repeat(2);
}

// ─── Example 5: Full score assembly ──────────────────────────────────────────

/// A two-voice invention sketch in G major.
///
/// Shows how parts combine into a Score, and how the Score carries
/// all the performance context while the Music values stay pure.
Score twoVoiceInvention() {
  final gMajor = Scale(PitchClass.g, ScaleType.major);

  // Subject: a rising scalewise figure
  final subject = gMajor.pitches(startOctave: 4)
      .take(5)
      .map((p) => p.eighth.asMusic)
      .toList()
      .sequential;

  // Answer: the subject transposed up a fifth (dominant key area)
  final answer = subject.transpose(Interval.perfectFifth);

  // Voice 1: subject, then answer
  final voice1Music = subject + answer.delayed(Duration.whole);

  // Voice 2: answer enters while voice 1 continues (stretto!)
  final voice2Music = answer.delayed(Duration.half);

  return Score(
    title: 'Invention No. 1 (sketch)',
    composer: 'Example',
    tempo: Tempo.allegro,
    timeSignature: TimeSignature.commonTime,
    keySignature: KeySignature.gMajorEMinor,
    parts: [
      Part(
        name: 'Voice I',
        instrument: Instrument.piano,
        clef: Clef.treble,
        music: voice1Music,
      ),
      Part(
        name: 'Voice II',
        instrument: Instrument.piano,
        clef: Clef.bass,
        music: voice2Music,
      ),
    ],
    notes: 'Voices enter in stretto at the half measure.',
  );
}

// ─── Example 6: Serial operations ────────────────────────────────────────────

/// The tone row from Schoenberg's Op. 25, and its four classical transforms.
///
/// Retrograde, inversion, and retrograde-inversion are all one-liners
/// because Music.retrograde and Music.invert are structural operations,
/// not manual rewrites.
({Music p, Music r, Music i, Music ri}) schoenbergRow() {
  // Simplified — a real tone row would have all 12 pitch classes
  final row = [
    Pitch(PitchClass.e, 4),
    Pitch(PitchClass.f, 4),
    Pitch(PitchClass.g, 4),
    Pitch(PitchClass.d, 4, Accidental.flat),
    Pitch(PitchClass.g, 4, Accidental.flat),
    Pitch(PitchClass.e, 4, Accidental.flat),
    Pitch(PitchClass.a, 3, Accidental.flat),
    Pitch(PitchClass.d, 4),
    Pitch(PitchClass.b, 3),
    Pitch(PitchClass.c, 4),
    Pitch(PitchClass.a, 3),
    Pitch(PitchClass.b, 3, Accidental.flat),
  ].map((p) => p.sixteenth.asMusic).toList().sequential;

  return (
    p: row,
    r: row.retrograde,
    i: row.invert(Pitch(PitchClass.e, 4)),
    ri: row.invert(Pitch(PitchClass.e, 4)).retrograde,
  );
}

// ─── Example 7: Motivic development ──────────────────────────────────────────

/// The "fate" motif from Beethoven's Fifth, developed through classical
/// compositional techniques.
///
/// This demonstrates the Motif type — musical ideas defined by their
/// interval + rhythm pattern, independent of key or register. Every
/// transformation produces a new Motif that can be further developed,
/// and realized at any starting pitch.
Music beethovenDevelopment() {
  final fate = WellKnownMotifs.fate;

  // 1. State the theme in C minor
  final statement = fate.realize(Pitch(PitchClass.g, 5));

  // 2. Repeat it a step lower (Beethoven's actual second phrase)
  final echo = fate.realize(Pitch(PitchClass.f, 5));

  // 3. Fragment: just the repeated-note "knock" — the first 3 notes
  final knock = fate.fragment(0, 3);
  final knockSequence = knock.sequence(
    Interval(semitones: -1, diatonicSteps: -1, quality: IntervalQuality.minor),
    times: 4,
  )(Pitch(PitchClass.e, 5, Accidental.flat));

  // 4. Invert the motif — what fell now rises
  final inverted = fate.invert().realize(Pitch(PitchClass.c, 4));

  // 5. Augment: the same shape, twice as slow (majestic, inevitable)
  final augmented = fate.augment(2).realize(Pitch(PitchClass.g, 3));

  // Assemble: statement, echo, fragmented development, then inversion
  // over augmented bass
  final development = statement + echo + knockSequence + inverted;
  final bass = augmented;

  return development | bass;
}

// ─── Example 8: Motivic analysis ─────────────────────────────────────────────

/// Demonstrates finding a motif within a larger piece — pattern matching
/// on musical content.
List<Pitch> findFateInMusic(Music piece) {
  return findMotifOccurrences(
    WellKnownMotifs.fate,
    piece,
    matchInversions: true,
    matchRetrogrades: true,
  );
}

/// Show that the BACH motif and the Dies Irae have different interval
/// class vectors — different "color fingerprints" — even though they're
/// both 4-note motifs built from seconds and thirds.
({List<int> bach, List<int> diesIrae, double similarity}) motifFingerprints() {
  final bach = WellKnownMotifs.bach;
  final dies = WellKnownMotifs.diesIrae;
  return (
    bach: bach.intervalClassVector,
    diesIrae: dies.intervalClassVector,
    similarity: bach.similarityTo(dies),
  );
}
