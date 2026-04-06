/// Example: encoding the opening of Bach's C Major Prelude (BWV 846)
/// to show how these concepts compose.
///
/// What makes this piece perfect for demonstration:
/// - The texture is arpeggiated homophony (broken chords)
/// - The harmony is the entire point — the melody IS the harmony
/// - The tension arc is exquisitely shaped across 35 bars
/// - Bach wrote it as a teaching piece, so the structure is transparent
library;

import 'interval.dart';
import 'pitch.dart';
import 'harmony.dart';
import 'melody.dart';
import 'texture.dart';
import 'time.dart' as music;
import 'form.dart';

/// Build the harmonic progression of the first 4 bars.
Progression bachPreludeOpening() {
  return Progression([
    // Bar 1: C major. Home. Tonic. Everything begins here.
    HarmonicEvent(
      root: PitchSpelling.c,
      quality: ChordQuality.major,
      function: HarmonicFunction.tonic,
      tendency: Tendency.stable,
      urgency: 0.0,
    ),
    // Bar 2: Dm7. A gentle departure. Predominant.
    // The ii chord — not tense, but no longer at rest.
    HarmonicEvent(
      root: PitchSpelling.d,
      quality: ChordQuality.minorSeventh,
      function: HarmonicFunction.predominant,
      tendency: Tendency.mild,
      urgency: 0.2,
    ),
    // Bar 3: G7. Dominant. The coiled spring.
    // Every note in this chord wants to go somewhere specific.
    HarmonicEvent(
      root: PitchSpelling.g,
      quality: ChordQuality.dominant7,
      function: HarmonicFunction.dominant,
      tendency: Tendency.contract,
      urgency: 0.7,
    ),
    // Bar 4: C major. Resolution. Exhale.
    // But Bach doesn't stop here — this resolution becomes
    // the launching pad for the next departure. Elision.
    HarmonicEvent(
      root: PitchSpelling.c,
      quality: ChordQuality.major,
      function: HarmonicFunction.tonic,
      tendency: Tendency.stable,
      urgency: 0.0,
    ),
  ]);
}

/// The full piece as a form.
///
/// The Prelude is a single compound form with no contrasting sections.
/// Its drama comes entirely from the harmonic journey —
/// a slow migration from C major through increasing tension
/// to a dominant pedal, then home.
///
/// This is music with almost no melody, no counterpoint, no rhythmic
/// variety. It proves that harmony alone — the tension field —
/// can sustain an entire piece.
Form bachPreludeForm() {
  final opening = bachPreludeOpening();

  return CompoundForm(
    label: 'Prelude in C Major, BWV 846',
    sections: [
      (
        Section(
          label: 'Opening: tonic establishment',
          texture: Homophony(
            melody: _arpeggioMelody(), // The "melody" IS the arpeggiation
            harmony: opening,
            pattern: AccompanimentPattern.arpeggiated,
          ),
          harmony: opening,
        ),
        SectionRelation.exposition,
      ),
      // ... middle section would show modulation to V ...
      // ... dominant pedal section would show maximum tension ...
      // ... final cadence would show resolution ...
    ],
  );
}

/// Even the "melody" here is really just arpeggiated harmony.
/// This is a placeholder — in a full implementation, the arpeggiation
/// pattern would be generated from the harmonic events.
Melody _arpeggioMelody() {
  return Melody([
    MelodicEvent(
      pitch: Pitch(PitchSpelling.c, 4),
      duration: music.Duration.eighth,
    ),
    MelodicEvent(
      pitch: Pitch(PitchSpelling.e, 4),
      duration: music.Duration.eighth,
    ),
    MelodicEvent(
      pitch: Pitch(PitchSpelling.g, 4),
      duration: music.Duration.eighth,
    ),
    MelodicEvent(
      pitch: Pitch(PitchSpelling.c, 5),
      duration: music.Duration.eighth,
    ),
    MelodicEvent(
      pitch: Pitch(PitchSpelling.e, 5),
      duration: music.Duration.eighth,
    ),
  ]);
}

// ─── What this design makes POSSIBLE ───────────────────────────────

/// Find the moment of maximum tension in a piece.
/// This is a musically meaningful query that most representations can't express.
double peakTension(Form form) => form.tensionArc.peak;

/// Ask: does this piece resolve? Not "does it end on the tonic" —
/// does the tension arc close?
bool doesItResolve(Form form) => form.tensionArc.resolves;

/// Where does the climax fall? Music with the climax at 0.75
/// feels different from music with the climax at 0.3.
double climaxPlacement(Form form) => form.tensionArc.climaxPosition;

/// Transform a melody through the four serial operations.
/// A fugue subject exists as the ORBIT of these transformations,
/// not as any single instance.
List<Melody> serialOrbit(Melody subject) => [
  subject,                    // Prime (P)
  subject.invert(),           // Inversion (I)
  subject.retrograde(),       // Retrograde (R)
  subject.invert().retrograde(), // Retrograde Inversion (RI)
];

/// The same melody at different speeds — augmentation canon.
/// Nancarrow wrote entire pieces exploring this idea.
List<Melody> temporalOrbit(Melody subject) => [
  subject,
  subject.augment(2),     // Half speed
  subject.diminish(2),    // Double speed
  subject.augment(3),     // Third speed — now they drift apart
];
