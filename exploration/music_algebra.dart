/// # Music Algebra
///
/// A compositional data structure for musical concepts.
///
/// Design philosophy: Music has two fundamental axes —
///   **horizontal** (time: melody, rhythm) and
///   **vertical** (simultaneity: harmony, texture).
///
/// With just four primitives (Note, Rest, Seq, Par) plus a Modify wrapper,
/// we can represent any musical structure. This mirrors how chemistry builds
/// infinite molecular diversity from ~118 elements — except music's "bonds"
/// are temporal, not spatial.
///
/// The analogy to chemistry breaks at **order-dependence**: a water molecule
/// doesn't care which hydrogen you look at first, but a V→I cadence is
/// fundamentally different from I→V. This is why [Seq] is not commutative
/// while [Par] largely is (voicing aside).

// ============================================================
// § 1. Pitch — The Periodic Table of Music
// ============================================================

/// The 12 pitch classes, independent of octave.
///
/// Like chemical elements, these are the irreducible alphabet.
/// Unlike elements, they're cyclical — C repeats every 12 semitones,
/// the way carbon doesn't repeat anywhere on the periodic table.
enum PitchClass {
  c,
  cSharp,
  d,
  dSharp,
  e,
  f,
  fSharp,
  g,
  gSharp,
  a,
  aSharp,
  b;

  /// Semitones above C.
  int get semitone => index;

  /// Transpose by [semitones], wrapping around the octave.
  PitchClass transpose(int semitones) =>
      PitchClass.values[(index + semitones) % 12];

  /// The interval (in semitones) from this pitch class to [other],
  /// always measured upward.
  int distanceTo(PitchClass other) => (other.index - index) % 12;

  /// Enharmonic display names — a pragmatic concession.
  /// Real music theory distinguishes C♯ from D♭; we don't (yet).
  String get display => const {
        0: 'C',
        1: 'C♯',
        2: 'D',
        3: 'E♭',
        4: 'E',
        5: 'F',
        6: 'F♯',
        7: 'G',
        8: 'A♭',
        9: 'A',
        10: 'B♭',
        11: 'B',
      }[index]!;
}

/// A pitch with a specific octave — the full "isotope" to PitchClass's "element".
///
/// Middle C = Pitch(PitchClass.c, 4), concert A = Pitch(PitchClass.a, 4).
class Pitch implements Comparable<Pitch> {
  final PitchClass pitchClass;
  final int octave;

  const Pitch(this.pitchClass, [this.octave = 4]);

  /// MIDI note number (Middle C = 60). Useful as a universal pitch coordinate.
  int get midi => (octave + 1) * 12 + pitchClass.semitone;

  /// Construct from MIDI note number.
  factory Pitch.fromMidi(int midi) => Pitch(
        PitchClass.values[midi % 12],
        (midi ~/ 12) - 1,
      );

  /// Transpose by [semitones] (positive = up, negative = down).
  Pitch transpose(int semitones) => Pitch.fromMidi(midi + semitones);

  /// Interval in semitones to another pitch (signed).
  int distanceTo(Pitch other) => other.midi - midi;

  @override
  int compareTo(Pitch other) => midi.compareTo(other.midi);

  @override
  bool operator ==(Object other) => other is Pitch && other.midi == midi;

  @override
  int get hashCode => midi.hashCode;

  @override
  String toString() => '${pitchClass.display}$octave';
}

// ============================================================
// § 2. Intervals — The Bonds Between Atoms
// ============================================================

/// Named intervals — the relationships that give pitch sequences meaning.
///
/// In chemistry, a bond's character (ionic, covalent, hydrogen) determines
/// molecular behavior. In music, an interval's character (consonant, dissonant,
/// perfect, tritone) determines emotional trajectory.
///
/// The most interesting parallel: both are *relative*, not absolute. A perfect
/// fifth sounds like a perfect fifth whether it starts on C or F♯.
enum IntervalQuality { perfect, major, minor, augmented, diminished }

class Interval {
  final int semitones;
  final String name;
  final IntervalQuality quality;

  const Interval._(this.semitones, this.name, this.quality);

  // The fundamental intervals — music's bond types
  static const unison = Interval._(0, 'P1', IntervalQuality.perfect);
  static const minorSecond = Interval._(1, 'm2', IntervalQuality.minor);
  static const majorSecond = Interval._(2, 'M2', IntervalQuality.major);
  static const minorThird = Interval._(3, 'm3', IntervalQuality.minor);
  static const majorThird = Interval._(4, 'M3', IntervalQuality.major);
  static const perfectFourth = Interval._(5, 'P4', IntervalQuality.perfect);
  static const tritone = Interval._(6, 'TT', IntervalQuality.augmented);
  static const perfectFifth = Interval._(7, 'P5', IntervalQuality.perfect);
  static const minorSixth = Interval._(8, 'm6', IntervalQuality.minor);
  static const majorSixth = Interval._(9, 'M6', IntervalQuality.major);
  static const minorSeventh = Interval._(10, 'm7', IntervalQuality.minor);
  static const majorSeventh = Interval._(11, 'M7', IntervalQuality.major);
  static const octave = Interval._(12, 'P8', IntervalQuality.perfect);

  /// Consonance score (0.0 = maximally dissonant, 1.0 = maximally consonant).
  /// Follows the harmonic series — simpler frequency ratios feel more stable.
  double get consonance => const {
        0: 1.0, // unison
        7: 0.95, // P5
        5: 0.9, // P4
        4: 0.8, // M3
        3: 0.75, // m3
        9: 0.7, // M6
        8: 0.65, // m6
        2: 0.5, // M2
        10: 0.45, // m7
        11: 0.3, // M7
        1: 0.2, // m2
        6: 0.1, // tritone — the "devil's interval"
      }[semitones % 12]!;

  /// The inversion of this interval (what you get flipping it upside down).
  /// P5 ↔ P4, M3 ↔ m6, etc. — musical chirality.
  Interval get inversion => Interval._(
        12 - semitones,
        _invertName(name),
        _invertQuality(quality),
      );

  static String _invertName(String n) => n; // simplified
  static IntervalQuality _invertQuality(IntervalQuality q) => switch (q) {
        IntervalQuality.major => IntervalQuality.minor,
        IntervalQuality.minor => IntervalQuality.major,
        IntervalQuality.augmented => IntervalQuality.diminished,
        IntervalQuality.diminished => IntervalQuality.augmented,
        IntervalQuality.perfect => IntervalQuality.perfect,
      };

  @override
  String toString() => name;
}

// ============================================================
// § 3. Duration — The Dimension Chemistry Doesn't Have
// ============================================================

/// Rhythmic duration as a fraction of a whole note.
///
/// This is where the chemistry analogy breaks hardest. Molecules don't have
/// "duration" — they exist or they don't. But in music, a C held for 4 beats
/// is a fundamentally different experience than a C held for a sixteenth.
/// Time is not just a container; it's a *parameter* of the sound itself.
class Duration implements Comparable<Duration> {
  /// Number of beats (quarter notes) this duration spans.
  final double beats;

  const Duration(this.beats);

  // Standard durations
  static const whole = Duration(4.0);
  static const dottedHalf = Duration(3.0);
  static const half = Duration(2.0);
  static const dottedQuarter = Duration(1.5);
  static const quarter = Duration(1.0);
  static const eighth = Duration(0.5);
  static const sixteenth = Duration(0.25);
  static const tripletEighth = Duration(1.0 / 3.0);

  /// Dotted version (1.5× duration).
  Duration get dotted => Duration(beats * 1.5);

  /// Tuplet scaling — triplets, quintuplets, etc.
  Duration tuplet(int n, int inSpaceOf) =>
      Duration(beats * inSpaceOf / n);

  Duration operator +(Duration other) => Duration(beats + other.beats);
  Duration operator *(double factor) => Duration(beats * factor);

  @override
  int compareTo(Duration other) => beats.compareTo(other.beats);

  @override
  String toString() => '${beats}q'; // "1.0q" = one quarter note
}

// ============================================================
// § 4. The Music Tree — Four Primitives, Infinite Structure
// ============================================================

/// The core algebraic type. Every musical structure is a [Music].
///
/// This is the heart of the design. Like an AST for a programming language,
/// or a molecular graph in chemistry, this tree can represent anything from
/// a single note to a full orchestral score.
///
/// The key operators:
///   - [Seq]: horizontal composition (time flows left to right)
///   - [Par]: vertical composition (sounds stack simultaneously)
///   - [Modify]: wraps any music with expression/dynamics
///
/// These satisfy useful algebraic laws:
///   - Seq is associative: (a >> b) >> c  ≡  a >> (b >> c)
///   - Par is associative: (a | b) | c  ≡  a | (b | c)
///   - Rest is identity for Seq: rest(0) >> m  ≡  m
///   - Par is *nearly* commutative: a | b  ≈  b | a
///     (breaks for voicing/spatialization, holds for pitch content)
sealed class Music {
  const Music();

  /// Total duration in beats.
  double get totalBeats;

  // -- Compositional operators --

  /// Sequential composition: play this, then [other].
  Music operator >>(Music other) => Seq([this, other]);

  /// Parallel composition: play this simultaneously with [other].
  Music operator |(Music other) => Par([this, other]);

  /// Wrap with a dynamic marking.
  Music withDynamic(Dynamic d) => Modify(this, dynamic_: d);

  /// Wrap with an articulation.
  Music withArticulation(Articulation a) => Modify(this, articulation: a);

  /// Wrap with a tempo marking.
  Music atTempo(int bpm) => Modify(this, tempo: bpm);

  // -- Transformations (music's "chemical reactions") --

  /// Transpose every pitch by [semitones].
  Music transpose(int semitones) => switch (this) {
        NoteEvent n => NoteEvent(n.pitch.transpose(semitones), n.duration),
        RestEvent r => r,
        Seq s => Seq(s.children.map((m) => m.transpose(semitones)).toList()),
        Par p => Par(p.children.map((m) => m.transpose(semitones)).toList()),
        Modify m => Modify(
            m.child.transpose(semitones),
            dynamic_: m.dynamic_,
            articulation: m.articulation,
            tempo: m.tempo,
          ),
      };

  /// Retrograde: reverse the order of events (time-reversal symmetry).
  /// Like reading a polymer chain backwards.
  Music get retrograde => switch (this) {
        NoteEvent _ => this,
        RestEvent _ => this,
        Seq s => Seq(s.children.reversed.map((m) => m.retrograde).toList()),
        Par p => Par(p.children.map((m) => m.retrograde).toList()),
        Modify m => Modify(
            m.child.retrograde,
            dynamic_: m.dynamic_,
            articulation: m.articulation,
            tempo: m.tempo,
          ),
      };

  /// Inversion: flip intervals (up becomes down, down becomes up).
  /// Musical chirality — the mirror-image molecule.
  /// [axis] is the MIDI note number around which to reflect.
  Music invert([int axis = 60]) => switch (this) {
        NoteEvent n =>
          NoteEvent(Pitch.fromMidi(2 * axis - n.pitch.midi), n.duration),
        RestEvent _ => this,
        Seq s => Seq(s.children.map((m) => m.invert(axis)).toList()),
        Par p => Par(p.children.map((m) => m.invert(axis)).toList()),
        Modify m => Modify(
            m.child.invert(axis),
            dynamic_: m.dynamic_,
            articulation: m.articulation,
            tempo: m.tempo,
          ),
      };

  /// Augmentation: stretch all durations by [factor].
  Music augment(double factor) => switch (this) {
        NoteEvent n => NoteEvent(n.pitch, n.duration * factor),
        RestEvent r => RestEvent(r.duration * factor),
        Seq s => Seq(s.children.map((m) => m.augment(factor)).toList()),
        Par p => Par(p.children.map((m) => m.augment(factor)).toList()),
        Modify m => Modify(
            m.child.augment(factor),
            dynamic_: m.dynamic_,
            articulation: m.articulation,
            tempo: m.tempo,
          ),
      };

  /// Diminution: compress durations by [factor]. Sugar for augment(1/factor).
  Music diminish(double factor) => augment(1.0 / factor);
}

/// A single pitched sound — the atom.
class NoteEvent extends Music {
  final Pitch pitch;
  final Duration duration;

  const NoteEvent(this.pitch, this.duration);

  @override
  double get totalBeats => duration.beats;

  @override
  String toString() => '${pitch}(${duration})';
}

/// Silence — not absence, but *structured* absence.
///
/// In chemistry, a vacuum is nothing. In music, a rest is something.
/// John Cage's 4'33" is all rests — and it's a composition.
class RestEvent extends Music {
  final Duration duration;

  const RestEvent(this.duration);

  @override
  double get totalBeats => duration.beats;

  @override
  String toString() => 'rest(${duration})';
}

/// Sequential composition — play children one after another.
///
/// This is the "polymer chain" — monomers bonded in sequence.
/// Unlike a real polymer, the order is *everything*.
class Seq extends Music {
  final List<Music> children;

  const Seq(this.children);

  @override
  double get totalBeats =>
      children.fold(0.0, (sum, m) => sum + m.totalBeats);

  @override
  String toString() => children.join(' >> ');
}

/// Parallel composition — play children simultaneously.
///
/// This is the "crystal lattice" — but only in one extra dimension.
/// Duration is the longest child (they all start together).
class Par extends Music {
  final List<Music> children;

  const Par(this.children);

  @override
  double get totalBeats => children.fold(
      0.0, (max, m) => m.totalBeats > max ? m.totalBeats : max);

  @override
  String toString() => '(${children.join(' | ')})';
}

/// Expression wrapper — dynamics, articulation, tempo.
///
/// Like a catalyst that changes how a reaction proceeds without changing
/// the reactants: Modify doesn't alter pitches or durations, but changes
/// how the music *feels*.
class Modify extends Music {
  final Music child;
  final Dynamic? dynamic_;
  final Articulation? articulation;
  final int? tempo; // BPM

  const Modify(
    this.child, {
    this.dynamic_,
    this.articulation,
    this.tempo,
  });

  @override
  double get totalBeats => child.totalBeats;
}

// ============================================================
// § 5. Expression Vocabulary
// ============================================================

/// Dynamic markings — how loud or soft.
enum Dynamic {
  ppp,
  pp,
  p,
  mp,
  mf,
  f,
  ff,
  fff;

  /// Approximate MIDI velocity (0-127).
  int get velocity => (index + 1) * 16 - 1;
}

/// Articulation — how each note is attacked and released.
enum Articulation {
  legato, // smooth, connected
  staccato, // short, detached
  accent, // emphasized attack
  tenuto, // held full duration
  marcato, // strongly accented
  pizzicato, // plucked (strings)
  fermata, // held beyond written duration
}

// ============================================================
// § 6. Scales & Chords — Molecular Templates
// ============================================================

/// A scale is a *recipe* — a pattern of intervals from which melodies
/// and chords crystallize. Like a molecular formula vs. a structural formula:
/// the scale tells you the ingredients, not the arrangement.
class Scale {
  final PitchClass root;
  final List<int> pattern; // intervals in semitones from root
  final String name;

  const Scale(this.root, this.pattern, this.name);

  // Common scale patterns
  static Scale major(PitchClass root) =>
      Scale(root, const [0, 2, 4, 5, 7, 9, 11], 'major');

  static Scale minor(PitchClass root) =>
      Scale(root, const [0, 2, 3, 5, 7, 8, 10], 'natural minor');

  static Scale harmonicMinor(PitchClass root) =>
      Scale(root, const [0, 2, 3, 5, 7, 8, 11], 'harmonic minor');

  static Scale pentatonic(PitchClass root) =>
      Scale(root, const [0, 2, 4, 7, 9], 'pentatonic');

  static Scale blues(PitchClass root) =>
      Scale(root, const [0, 3, 5, 6, 7, 10], 'blues');

  static Scale chromatic(PitchClass root) =>
      Scale(root, const [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], 'chromatic');

  /// All pitches in this scale at a given octave.
  List<Pitch> pitchesAt(int octave) =>
      pattern.map((s) => Pitch(root, octave).transpose(s)).toList();

  /// The nth degree of the scale (1-indexed, like music theory).
  Pitch degree(int n, [int octave = 4]) {
    final idx = (n - 1) % pattern.length;
    final octaveShift = (n - 1) ~/ pattern.length;
    return Pitch(root, octave + octaveShift).transpose(pattern[idx]);
  }

  /// Build a triad on the nth degree.
  Chord triad(int degree) {
    final d = degree - 1;
    return Chord(
      [
        root.transpose(pattern[d % pattern.length]),
        root.transpose(pattern[(d + 2) % pattern.length]),
        root.transpose(pattern[(d + 4) % pattern.length]),
      ],
      _triadQuality(d),
    );
  }

  ChordQuality _triadQuality(int d) {
    final root2third = (pattern[(d + 2) % pattern.length] -
            pattern[d % pattern.length] + 12) % 12;
    final third2fifth = (pattern[(d + 4) % pattern.length] -
            pattern[(d + 2) % pattern.length] + 12) % 12;
    if (root2third == 4 && third2fifth == 3) return ChordQuality.major;
    if (root2third == 3 && third2fifth == 4) return ChordQuality.minor;
    if (root2third == 3 && third2fifth == 3) return ChordQuality.diminished;
    if (root2third == 4 && third2fifth == 4) return ChordQuality.augmented;
    return ChordQuality.major; // fallback
  }

  @override
  String toString() => '${root.display} $name';
}

enum ChordQuality { major, minor, diminished, augmented, dominant7, major7, minor7 }

/// A chord — a vertical "molecule" of pitch classes.
class Chord {
  final List<PitchClass> pitchClasses;
  final ChordQuality quality;

  const Chord(this.pitchClasses, this.quality);

  // Common chord constructors
  static Chord majorTriad(PitchClass root) => Chord(
        [root, root.transpose(4), root.transpose(7)],
        ChordQuality.major,
      );

  static Chord minorTriad(PitchClass root) => Chord(
        [root, root.transpose(3), root.transpose(7)],
        ChordQuality.minor,
      );

  static Chord dominant7th(PitchClass root) => Chord(
        [root, root.transpose(4), root.transpose(7), root.transpose(10)],
        ChordQuality.dominant7,
      );

  /// Realize this chord as a [Par] of notes at a given octave and duration.
  Music realize(int octave, Duration duration) => Par(
        pitchClasses
            .map((pc) => NoteEvent(Pitch(pc, octave), duration) as Music)
            .toList(),
      );

  /// All intervals present in this chord (the "bond graph").
  List<int> get intervalVector {
    final intervals = <int>[];
    for (int i = 0; i < pitchClasses.length; i++) {
      for (int j = i + 1; j < pitchClasses.length; j++) {
        intervals.add(pitchClasses[i].distanceTo(pitchClasses[j]));
      }
    }
    return intervals..sort();
  }

  @override
  String toString() {
    final root = pitchClasses.first.display;
    final suffix = switch (quality) {
      ChordQuality.major => '',
      ChordQuality.minor => 'm',
      ChordQuality.diminished => '°',
      ChordQuality.augmented => '+',
      ChordQuality.dominant7 => '7',
      ChordQuality.major7 => 'maj7',
      ChordQuality.minor7 => 'm7',
    };
    return '$root$suffix';
  }
}

// ============================================================
// § 7. Convenience — Making the Algebra Ergonomic
// ============================================================

// Shorthand constructors — because music should read like music.

NoteEvent note(PitchClass pc, int octave, Duration dur) =>
    NoteEvent(Pitch(pc, octave), dur);

RestEvent rest(Duration dur) => RestEvent(dur);

/// Build a melodic line from pitch-duration pairs.
Music melody(List<(PitchClass, int, Duration)> notes) =>
    Seq(notes.map((n) => NoteEvent(Pitch(n.$1, n.$2), n.$3)).toList());

/// Repeat a musical phrase [times] times.
Music repeat(Music phrase, int times) =>
    Seq(List.generate(times, (_) => phrase));

// ============================================================
// § 8. Analysis — Asking Questions of the Structure
// ============================================================

extension MusicAnalysis on Music {
  /// Extract all pitches in temporal order (flattening parallel voices).
  List<Pitch> get allPitches => switch (this) {
        NoteEvent n => [n.pitch],
        RestEvent _ => [],
        Seq s => s.children.expand((m) => m.allPitches).toList(),
        Par p => p.children.expand((m) => m.allPitches).toList(),
        Modify m => m.child.allPitches,
      };

  /// The melodic contour — sequence of interval directions.
  /// Returns +1 (ascending), 0 (repeated), -1 (descending).
  List<int> get contour {
    final pitches = allPitches;
    if (pitches.length < 2) return [];
    return List.generate(pitches.length - 1, (i) {
      final diff = pitches[i + 1].midi - pitches[i].midi;
      return diff > 0 ? 1 : (diff < 0 ? -1 : 0);
    });
  }

  /// Pitch range (ambitus) in semitones.
  int get ambitus {
    final pitches = allPitches;
    if (pitches.isEmpty) return 0;
    final sorted = pitches.toList()..sort();
    return sorted.last.midi - sorted.first.midi;
  }

  /// Count of distinct pitch classes used.
  int get pitchClassDiversity =>
      allPitches.map((p) => p.pitchClass).toSet().length;
}

// ============================================================
// § 9. Example — Bach Would Approve (Probably)
// ============================================================

void main() {
  // -- A simple melody: first phrase of "Ode to Joy" --
  final odeToJoy = melody([
    (PitchClass.e, 4, Duration.quarter),
    (PitchClass.e, 4, Duration.quarter),
    (PitchClass.f, 4, Duration.quarter),
    (PitchClass.g, 4, Duration.quarter),
    (PitchClass.g, 4, Duration.quarter),
    (PitchClass.f, 4, Duration.quarter),
    (PitchClass.e, 4, Duration.quarter),
    (PitchClass.d, 4, Duration.quarter),
  ]);

  // -- Harmonize with a simple chord progression --
  final chords = Seq([
    Chord.majorTriad(PitchClass.c).realize(3, Duration.half),
    Chord.majorTriad(PitchClass.g).realize(3, Duration.half),
    Chord.majorTriad(PitchClass.c).realize(3, Duration.half),
    Chord.majorTriad(PitchClass.g).realize(3, Duration.half),
  ]);

  // -- Combine: melody OVER chords (parallel composition) --
  final harmonized = odeToJoy | chords;

  // -- Add expression --
  final expressive = harmonized
      .withDynamic(Dynamic.mf)
      .atTempo(120);

  // -- Apply transformations --
  final retrograde = odeToJoy.retrograde;
  final inverted = odeToJoy.invert(Pitch(PitchClass.e, 4).midi);
  final transposedUp = odeToJoy.transpose(5); // up a P4

  // -- Analysis --
  print('Ode to Joy:');
  print('  Total beats: ${odeToJoy.totalBeats}');
  print('  Contour: ${odeToJoy.contour}');
  print('  Ambitus: ${odeToJoy.ambitus} semitones');
  print('  Pitch classes used: ${odeToJoy.pitchClassDiversity}');
  print('');

  // -- Demonstrate the algebra --
  print('Retrograde: $retrograde');
  print('Inverted:   $inverted');
  print('Transposed: $transposedUp');
  print('');

  // -- Scale exploration --
  final cMajor = Scale.major(PitchClass.c);
  print('$cMajor scale degrees:');
  for (var i = 1; i <= 7; i++) {
    final triad = cMajor.triad(i);
    print('  $i: $triad (intervals: ${triad.intervalVector})');
  }

  // -- The "Amen cadence" (IV → I) vs "Perfect cadence" (V → I) --
  // Order matters! This is where the chemistry analogy breaks.
  final amen = Seq([
    Chord.majorTriad(PitchClass.f).realize(3, Duration.half),
    Chord.majorTriad(PitchClass.c).realize(3, Duration.whole),
  ]);
  final perfect = Seq([
    Chord.dominant7th(PitchClass.g).realize(3, Duration.half),
    Chord.majorTriad(PitchClass.c).realize(3, Duration.whole),
  ]);
  print('');
  print('Amen cadence (IV→I): ${amen.totalBeats} beats');
  print('Perfect cadence (V7→I): ${perfect.totalBeats} beats');
  print('Same destination, different journey — order is semantic.');
}
