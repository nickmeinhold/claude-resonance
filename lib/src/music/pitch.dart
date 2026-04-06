/// Pitch — the vertical dimension of music.
///
/// Three levels of abstraction:
/// - [PitchClass] — the abstract note name (C, D♭, F♯), independent of octave
/// - [Pitch]       — a specific pitch in a specific octave (C4, A♭3)
/// - [frequency]   — the acoustic reality in Hz (computed from Pitch)
///
/// Enharmonic equivalents (C♯4 and D♭4) are *distinct* [Pitch] values. This
/// matters: in C major, an augmented second C♯→D♯ and its respelling D♭→E♭
/// are functionally different even though they sound identical on a piano.
/// Spelling carries harmonic intent.
library;

import 'interval.dart';

/// The seven letter names, each carrying its natural (unmodified) position in
/// the chromatic scale measured in semitones above C.
enum PitchClass {
  c(0),
  d(2),
  e(4),
  f(5),
  g(7),
  a(9),
  b(11);

  /// Semitones above C with no accidental applied.
  final int naturalSemitones;

  const PitchClass(this.naturalSemitones);

  /// The next pitch class diatonically (C→D→E→F→G→A→B→C).
  PitchClass get next => PitchClass.values[(index + 1) % 7];

  /// Steps up [n] diatonic steps (can be negative).
  PitchClass step(int n) => PitchClass.values[(index + n) % 7];
}

/// Semitone adjustment applied to a [PitchClass].
enum Accidental {
  doubleFlat(-2, '𝄫'),
  flat(-1, '♭'),
  natural(0, ''),
  sharp(1, '♯'),
  doubleSharp(2, '𝄪');

  final int semitones;
  final String symbol;
  const Accidental(this.semitones, this.symbol);
}

/// A specific pitch: letter name + accidental + octave number.
///
/// Uses scientific pitch notation: octave 4 contains middle C (C4 = 261.63 Hz).
/// Octave numbers increment at C — so B3 is below C4, not above it.
///
/// ```dart
/// const middleC = Pitch(PitchClass.c, 4);
/// const aAbove  = Pitch(PitchClass.a, 4);         // A440
/// const bFlat   = Pitch(PitchClass.b, 4, Accidental.flat);
/// ```
final class Pitch implements Comparable<Pitch> {
  final PitchClass pitchClass;
  final Accidental accidental;
  final int octave;

  const Pitch(this.pitchClass, this.octave,
      [this.accidental = Accidental.natural]);

  // ─── Acoustic ────────────────────────────────────────────────────────────

  /// Semitones above C0 (MIDI-style, but extended to negative values).
  int get semitones =>
      (octave * 12) + pitchClass.naturalSemitones + accidental.semitones;

  /// Concert frequency in Hz. Reference: A4 = 440 Hz, equal temperament.
  ///
  /// For other tuning systems, subclass or wrap this — temperament is a
  /// policy, not a property of the pitch itself.
  double get frequency => 440.0 * _exp2((semitones - _a4Semitones) / 12.0);

  // ─── Relationships ────────────────────────────────────────────────────────

  /// The interval from this pitch up to [other].
  /// If [other] is lower, returns the interval modulo an octave then inverts.
  Interval intervalTo(Pitch other) => Interval.between(this, other);

  /// Transpose up by [interval], preserving diatonic spelling.
  ///
  /// A perfect fifth above D is A (not G𝄪), because interval arithmetic
  /// tracks both semitones *and* diatonic steps.
  Pitch transpose(Interval interval) {
    final targetPitchClass = pitchClass.step(interval.diatonicSteps);
    final targetSemitones = semitones + interval.semitones;
    final naturalTarget = targetPitchClass.naturalSemitones;
    // Infer what accidental is needed to land on the right semitone.
    final targetOctave = (targetSemitones - naturalTarget) ~/ 12;
    final diff = targetSemitones -
        (targetOctave * 12 + targetPitchClass.naturalSemitones);
    final accidental = Accidental.values.firstWhere(
      (a) => a.semitones == diff,
      orElse: () =>
          throw StateError('Cannot spell ${interval} above $this diatonically'),
    );
    return Pitch(targetPitchClass, targetOctave, accidental);
  }

  /// The enharmonic equivalent, if one exists with at most one accidental.
  /// Returns null if this is already natural or if no simpler spelling exists.
  ///
  /// C♯4 → D♭4, B♯4 → C5, etc.
  Pitch? get enharmonicEquivalent {
    // Try each pitch class and each single accidental to find same semitones.
    for (final pc in PitchClass.values) {
      for (final acc in [Accidental.flat, Accidental.natural, Accidental.sharp]) {
        if (pc == pitchClass && acc == accidental) continue;
        final candidate = Pitch(pc, octave, acc);
        if (candidate.semitones == semitones) return candidate;
        // Try adjacent octaves for edge cases (B♯ = C next octave)
        final candidateUp = Pitch(pc, octave + 1, acc);
        if (candidateUp.semitones == semitones) return candidateUp;
      }
    }
    return null;
  }

  // ─── Comparison ──────────────────────────────────────────────────────────

  @override
  int compareTo(Pitch other) => semitones.compareTo(other.semitones);

  bool operator <(Pitch other) => semitones < other.semitones;
  bool operator >(Pitch other) => semitones > other.semitones;
  bool operator <=(Pitch other) => semitones <= other.semitones;
  bool operator >=(Pitch other) => semitones >= other.semitones;

  /// Acoustic equality: C♯4 == D♭4 because they have the same semitone count.
  /// For notational identity (respecting spelling), use [==].
  bool acousticallyEquals(Pitch other) => semitones == other.semitones;

  @override
  bool operator ==(Object other) =>
      other is Pitch &&
      pitchClass == other.pitchClass &&
      accidental == other.accidental &&
      octave == other.octave;

  @override
  int get hashCode => Object.hash(pitchClass, accidental, octave);

  // ─── Named constants ──────────────────────────────────────────────────────

  static const Pitch middleC = Pitch(PitchClass.c, 4);
  static const Pitch a440 = Pitch(PitchClass.a, 4); // A4 = 440 Hz

  @override
  String toString() =>
      '${pitchClass.name.toUpperCase()}${accidental.symbol}$octave';

  static const int _a4Semitones = 4 * 12 + 9; // A4 in semitones above C0
}

double _exp2(double x) => _pow(2.0, x);

double _pow(double base, double exp) {
  // dart:math pow returns num — keep this file self-contained
  if (exp == 0) return 1.0;
  if (exp == 1) return base;
  return _exp(exp * _ln(base));
}

// Taylor series approximations sufficient for audio frequency calculation.
double _ln(double x) {
  assert(x > 0);
  double result = 0;
  double term = (x - 1) / (x + 1);
  double termSq = term * term;
  double current = term;
  for (int i = 0; i < 50; i++) {
    result += current / (2 * i + 1);
    current *= termSq;
  }
  return 2 * result;
}

double _exp(double x) {
  double result = 1;
  double term = 1;
  for (int i = 1; i < 50; i++) {
    term *= x / i;
    result += term;
  }
  return result;
}
