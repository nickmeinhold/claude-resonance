import 'interval.dart';

/// A pitch class: the note name, independent of octave.
///
/// Why spelling matters: C# and Db are the same frequency but different
/// musical meanings. C# is a leading tone pulling up to D. Db is a
/// flattened third settling down from D. The spelling encodes the
/// *history* — where this note came from and where it wants to go.
enum PitchSpelling {
  c, dFlat, cSharp, d, eFlat, dSharp, e, f,
  gFlat, fSharp, g, aFlat, gSharp, a, bFlat, aSharp, b;

  /// The pitch class as an integer (0-11, C=0).
  int get pitchClass => switch (this) {
    c => 0,
    cSharp || dFlat => 1,
    d => 2,
    dSharp || eFlat => 3,
    e => 4,
    f => 5,
    fSharp || gFlat => 6,
    g => 7,
    gSharp || aFlat => 8,
    a => 9,
    aSharp || bFlat => 10,
    b => 11,
  };
}

/// A specific pitch: spelling + octave.
///
/// Pitches are coordinates in pitch-space. Useful for realization,
/// but remember: the music lives in the intervals between them.
class Pitch implements Comparable<Pitch> {
  final PitchSpelling spelling;
  final int octave;

  const Pitch(this.spelling, this.octave);

  /// Middle C.
  static const middleC = Pitch(PitchSpelling.c, 4);

  /// Concert A.
  static const a440 = Pitch(PitchSpelling.a, 4);

  /// MIDI note number. The universal coordinate system.
  int get midi => spelling.pitchClass + (octave + 1) * 12;

  /// The interval from this pitch to [other].
  Interval intervalTo(Pitch other) {
    final semitones = other.midi - midi;
    // Generic interval computation would need full enharmonic spelling logic.
    // Simplified here — a real implementation would track diatonic steps.
    final generic = (semitones.abs() * 7 / 12).round();
    return Interval(
      semitones >= 0 ? generic : -generic,
      semitones,
    );
  }

  /// Apply an interval to get a new pitch.
  Pitch operator +(Interval interval) {
    final newMidi = midi + interval.semitones;
    final newOctave = newMidi ~/ 12 - 1;
    // Simplified: loses enharmonic spelling. A real implementation
    // would propagate spelling through the interval's generic size.
    final pc = newMidi % 12;
    final spelling = PitchSpelling.values.firstWhere(
      (s) => s.pitchClass == pc,
    );
    return Pitch(spelling, newOctave);
  }

  @override
  int compareTo(Pitch other) => midi.compareTo(other.midi);

  @override
  String toString() => '${spelling.name}$octave';

  @override
  bool operator ==(Object other) =>
      other is Pitch && spelling == other.spelling && octave == other.octave;

  @override
  int get hashCode => Object.hash(spelling, octave);
}
