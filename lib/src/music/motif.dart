/// Motif — the atom of musical identity.
///
/// A motif is a short musical idea defined by its **interval content** and
/// **rhythmic shape**, independent of absolute pitch, octave, or key. This
/// is how musicians actually think: "the opening of Beethoven's 5th" is
/// three repeated notes stepping down a minor third, in the rhythm ♩♩♩𝅗𝅥.
/// That identity persists through every transposition, inversion,
/// augmentation, and development in the movement.
///
/// A motif is to music what a regex is to text: a pattern that matches
/// regardless of where it appears.
///
/// ```dart
/// // Beethoven's Fifth — the "fate" motif
/// final fate = Motif(
///   intervals: [Interval.perfectUnison, Interval.perfectUnison, -Interval.minorThird],
///   rhythm: [Duration.eighth, Duration.eighth, Duration.eighth, Duration.half],
/// );
///
/// // Realize it starting on G5
/// final opening = fate.realize(Pitch(PitchClass.g, 5));
///
/// // Develop it: invert, augment, sequence upward
/// final development = fate
///     .invert()
///     .augment(2)
///     .sequence(Interval.majorSecond, times: 3);
/// ```
library;

import 'pitch.dart';
import 'interval.dart';
import 'duration.dart';
import 'expression.dart';
import 'music.dart';

/// A motif: the irreducible kernel of a musical idea.
///
/// Defined by:
/// - [intervals] — the directed pitch motion between successive notes
///   (ascending = positive semitones, descending = negative). Length = N-1
///   for an N-note motif.
/// - [rhythm] — the durations of each note. Length = N.
///
/// Because the motif stores intervals (not pitches) and durations (not
/// absolute time), it's inherently key-independent and tempo-independent.
/// You can recognize it in any context.
///
/// The motif is immutable. Every transformation returns a new Motif,
/// enabling a fluent development chain:
/// ```dart
/// motif.invert().fragment(0, 3).sequence(Interval.majorSecond, times: 4)
/// ```
final class Motif {
  /// Directed intervals between successive notes.
  ///
  /// An interval with positive semitones = ascending; negative = descending.
  /// Length is always `rhythm.length - 1` (N notes → N-1 intervals).
  final List<Interval> intervals;

  /// Duration of each note in the motif.
  final List<Duration> rhythm;

  /// Optional articulation pattern (cycles if shorter than rhythm).
  final List<Articulation> articulations;

  /// Optional label for analysis ("fate", "BACH", "second theme").
  final String? label;

  Motif({
    required this.intervals,
    required this.rhythm,
    this.articulations = const [Articulation.legato],
    this.label,
  })  : assert(
          intervals.length == rhythm.length - 1,
          'intervals.length (${intervals.length}) must be rhythm.length - 1 '
          '(${rhythm.length - 1}): N notes have N-1 intervals between them.',
        ),
        assert(rhythm.isNotEmpty, 'A motif must have at least one note.');

  /// Number of notes in the motif.
  int get noteCount => rhythm.length;

  /// Total duration of the motif.
  Duration get totalDuration =>
      rhythm.fold(Duration.zero, (sum, d) => sum + d);

  /// The overall interval span from first note to last.
  Interval get span => intervals.fold(
        Interval.perfectUnison,
        (sum, i) => Interval(
          semitones: sum.semitones + i.semitones,
          diatonicSteps: sum.diatonicSteps + i.diatonicSteps,
          quality: IntervalQuality.perfect, // quality is approximate here
        ),
      );

  // ─── Realization: from abstract pattern to concrete music ─────────────────

  /// Realize this motif starting on [startPitch], producing concrete [Music].
  ///
  /// This is the bridge between the abstract pattern world and the concrete
  /// Music algebra. Once realized, you get all the Music operations
  /// (transpose, parallel composition, etc.) for free.
  Music realize(Pitch startPitch) {
    final notes = <Music>[];
    var currentPitch = startPitch;
    for (var i = 0; i < noteCount; i++) {
      final art = articulations[i % articulations.length];
      notes.add(MusicNote(Note(
        pitch: currentPitch,
        duration: rhythm[i],
        articulation: art,
      )));
      if (i < intervals.length) {
        currentPitch = currentPitch.transpose(intervals[i]);
      }
    }
    return Sequential(notes);
  }

  // ─── Classical development operations ─────────────────────────────────────
  //
  // These are the composer's toolkit — the operations that transform a motif
  // while preserving (or systematically destroying) its identity. Each one
  // corresponds to a technique taught in every composition class, but rarely
  // modeled as a first-class function.

  /// **Inversion**: flip every interval direction.
  ///
  /// What went up now goes down, and vice versa. The rhythmic shape is
  /// preserved. This is the most fundamental transformation after
  /// transposition — Bach uses it constantly, and it's a pillar of
  /// twelve-tone technique.
  Motif invert() => Motif(
        intervals: intervals
            .map((i) => Interval(
                  semitones: -i.semitones,
                  diatonicSteps: -i.diatonicSteps,
                  quality: i.quality,
                ))
            .toList(),
        rhythm: rhythm,
        articulations: articulations,
        label: label != null ? '${label!} (inv)' : null,
      );

  /// **Retrograde**: reverse the time order of notes.
  ///
  /// The last note becomes the first; intervals reverse and flip direction.
  /// Combined with inversion, gives the four classical row forms of
  /// twelve-tone music: P, R, I, RI.
  Motif retrograde() => Motif(
        intervals: intervals.reversed
            .map((i) => Interval(
                  semitones: -i.semitones,
                  diatonicSteps: -i.diatonicSteps,
                  quality: i.quality,
                ))
            .toList(),
        rhythm: rhythm.reversed.toList(),
        articulations: articulations,
        label: label != null ? '${label!} (ret)' : null,
      );

  /// **Retrograde-inversion**: reverse and flip. A compound transformation.
  Motif retrogradeInversion() => retrograde().invert();

  /// **Augmentation**: stretch all durations by [factor].
  ///
  /// Makes the motif slower and grander. A common technique in fugal
  /// stretto and development sections — the subject enters in augmentation
  /// while other voices continue at normal speed.
  Motif augment(int factor) => Motif(
        intervals: intervals,
        rhythm: rhythm.map((d) => d * factor).toList(),
        articulations: articulations,
        label: label != null ? '${label!} (aug×$factor)' : null,
      );

  /// **Diminution**: compress all durations by [factor].
  ///
  /// Makes the motif faster and more urgent. The inverse of augmentation.
  Motif diminish(int factor) => Motif(
        intervals: intervals,
        rhythm: rhythm.map((d) => d ~/ factor).toList(),
        articulations: articulations,
        label: label != null ? '${label!} (dim÷$factor)' : null,
      );

  /// **Fragment**: extract a portion of the motif.
  ///
  /// Takes notes from index [start] to [end] (exclusive). This is how
  /// Beethoven develops — he takes a 4-note motif and hammers on just
  /// the first 2 notes, or the last 3. The fragment is itself a Motif,
  /// so it can be further developed.
  Motif fragment(int start, int end) {
    assert(start >= 0 && end <= noteCount && start < end);
    return Motif(
      intervals: intervals.sublist(start, end - 1),
      rhythm: rhythm.sublist(start, end),
      articulations: articulations,
      label: label != null ? '${label!} [$start:$end]' : null,
    );
  }

  /// **Sequence**: repeat the motif at successively higher (or lower) pitch levels.
  ///
  /// Each repetition starts [step] higher than the previous one. This is
  /// one of the most common development techniques — the "Rosalia" pattern
  /// that drives countless Classical-era development sections and Baroque
  /// sequences (Vivaldi's entire output, basically).
  ///
  /// Returns a function that realizes the sequence at a given starting pitch,
  /// since the motif itself is pitch-independent.
  Music Function(Pitch startPitch) sequence(Interval step, {required int times}) {
    return (Pitch startPitch) {
      final parts = <Music>[];
      var currentStart = startPitch;
      for (var i = 0; i < times; i++) {
        parts.add(realize(currentStart));
        currentStart = currentStart.transpose(step);
      }
      return Sequential(parts);
    };
  }

  /// **Extension**: add notes to the end of the motif.
  ///
  /// Appends [extraIntervals] and [extraRhythm] to create a longer motif.
  /// This models the compositional technique of spinning out a short idea
  /// into a longer melody.
  Motif extend({
    required List<Interval> extraIntervals,
    required List<Duration> extraRhythm,
  }) {
    assert(extraIntervals.length == extraRhythm.length,
        'Extension needs equal intervals and durations');
    return Motif(
      intervals: [...intervals, ...extraIntervals],
      rhythm: [...rhythm, ...extraRhythm],
      articulations: articulations,
      label: label != null ? '${label!} (ext)' : null,
    );
  }

  /// **Truncation**: remove notes from the end.
  ///
  /// The opposite of extension — shorten the motif to [length] notes.
  /// Useful for "liquidation," Schoenberg's term for the gradual
  /// dismantling of a theme in development sections.
  Motif truncate(int length) => fragment(0, length);

  /// **Intervallic expansion**: multiply all intervals by [factor].
  ///
  /// A major second becomes a major third (×1.5 semitones, roughly).
  /// This widens the melodic contour while preserving rhythm and direction.
  /// Distinct from transposition, which shifts everything uniformly.
  Motif expandIntervals(double factor) => Motif(
        intervals: intervals
            .map((i) => Interval(
                  semitones: (i.semitones * factor).round(),
                  diatonicSteps: (i.diatonicSteps * factor).round(),
                  quality: i.quality,
                ))
            .toList(),
        rhythm: rhythm,
        articulations: articulations,
        label: label != null ? '${label!} (×${factor}int)' : null,
      );

  /// **Intervallic compression**: the inverse of expansion.
  Motif compressIntervals(double factor) => expandIntervals(1.0 / factor);

  /// **Rhythmic displacement**: shift all durations forward by [offset],
  /// inserting a rest at the beginning.
  ///
  /// The motif starts the same way but lands on different beats.
  /// This is a powerful source of rhythmic variety — the same melody
  /// feels completely different when it starts on beat 2 instead of beat 1.
  (Duration rest, Motif motif) displace(Duration offset) => (offset, this);

  // ─── Analysis ─────────────────────────────────────────────────────────────

  /// Whether this motif is a transposition of [other].
  ///
  /// Two motifs are transpositionally equivalent if they have the same
  /// interval and rhythm content — they differ only in starting pitch.
  bool isTranspositionOf(Motif other) =>
      _listEquals(intervals, other.intervals) &&
      _listEquals(rhythm, other.rhythm);

  /// Whether this motif is an inversion of [other].
  bool isInversionOf(Motif other) => isTranspositionOf(other.invert());

  /// Whether this motif is a retrograde of [other].
  bool isRetrogradeOf(Motif other) => isTranspositionOf(other.retrograde());

  /// The **interval-class vector**: a fingerprint of the motif's interval content.
  ///
  /// Counts how many of each interval class (0-6 semitones) appear.
  /// Two motifs with the same vector have similar "color" even if they
  /// differ in order — like anagrams share letter frequencies.
  List<int> get intervalClassVector {
    final vector = List.filled(7, 0); // ic 0 through 6
    for (final interval in intervals) {
      final ic = interval.semitones.abs() % 12;
      final normalizedIc = ic > 6 ? 12 - ic : ic;
      vector[normalizedIc]++;
    }
    return vector;
  }

  /// Degree of similarity to [other], from 0.0 (nothing in common) to
  /// 1.0 (identical).
  ///
  /// Compares both interval-class vectors (pitch shape) and rhythmic
  /// proportions (time shape). This is a simplified version of what music
  /// theorists call "motivic similarity" — useful for automated analysis
  /// of thematic relationships in a piece.
  double similarityTo(Motif other) {
    // Interval similarity: cosine similarity of interval-class vectors
    final v1 = intervalClassVector;
    final v2 = other.intervalClassVector;
    final dot = List.generate(7, (i) => v1[i] * v2[i]).fold(0, (a, b) => a + b);
    final mag1 = List.generate(7, (i) => v1[i] * v1[i]).fold(0, (a, b) => a + b);
    final mag2 = List.generate(7, (i) => v2[i] * v2[i]).fold(0, (a, b) => a + b);
    final intervalSim = (mag1 == 0 || mag2 == 0)
        ? 0.0
        : dot / (_sqrt(mag1.toDouble()) * _sqrt(mag2.toDouble()));

    // Rhythm similarity: compare duration ratios
    final r1 = _normalizeRhythm(rhythm);
    final r2 = _normalizeRhythm(other.rhythm);
    final minLen = r1.length < r2.length ? r1.length : r2.length;
    final maxLen = r1.length > r2.length ? r1.length : r2.length;
    var rhythmSim = 0.0;
    if (maxLen > 0) {
      var matchSum = 0.0;
      for (var i = 0; i < minLen; i++) {
        final diff = (r1[i] - r2[i]).abs();
        matchSum += 1.0 - diff; // proportional values are 0-1, so diff ≤ 1
      }
      rhythmSim = matchSum / maxLen;
    }

    // Weight: intervals matter slightly more than rhythm for identity
    return intervalSim * 0.6 + rhythmSim * 0.4;
  }

  @override
  String toString() {
    final l = label != null ? '"$label" ' : '';
    final ints = intervals.map((i) =>
        '${i.semitones > 0 ? '+' : ''}${i.semitones}').join(' ');
    return '${l}Motif[$ints] (${rhythm.join(' ')})';
  }
}

// ─── Well-known motifs ──────────────────────────────────────────────────────

/// A small library of famous motifs, demonstrating how the representation
/// captures musical ideas that anyone would recognize.
abstract final class WellKnownMotifs {
  /// Beethoven's Fifth, opening: ♩♩♩ 𝅗𝅥  (G G G E♭ — three repeated, step down m3)
  static final fate = Motif(
    intervals: [
      Interval.perfectUnison,
      Interval.perfectUnison,
      Interval(semitones: -3, diatonicSteps: -2, quality: IntervalQuality.minor),
    ],
    rhythm: [Duration.eighth, Duration.eighth, Duration.eighth, Duration.half],
    label: 'fate',
  );

  /// "Happy Birthday" opening: two pickup notes, then a rising step.
  /// ♩♩ ♩. — G G A G C B
  static final happyBirthday = Motif(
    intervals: [
      Interval.perfectUnison,            // same note repeated
      Interval.majorSecond,              // up a step
      Interval(semitones: -2, diatonicSteps: -1, quality: IntervalQuality.major), // back down
      Interval(semitones: 5, diatonicSteps: 3, quality: IntervalQuality.perfect), // up to 4th
      Interval(semitones: -1, diatonicSteps: -1, quality: IntervalQuality.minor), // half step down
    ],
    rhythm: [
      Duration.eighth, Duration.eighth,
      Duration.quarter, Duration.quarter,
      Duration.quarter, Duration.quarter,
    ],
    label: 'happy birthday',
  );

  /// BACH motif: B♭ A C B♮ — the composer's musical signature.
  /// Intervals: -m2, +m3, -m2 (chromatic-diatonic zigzag).
  static final bach = Motif(
    intervals: [
      Interval(semitones: -1, diatonicSteps: -1, quality: IntervalQuality.minor),
      Interval(semitones: 3, diatonicSteps: 2, quality: IntervalQuality.minor),
      Interval(semitones: -1, diatonicSteps: -1, quality: IntervalQuality.minor),
    ],
    rhythm: [
      Duration.quarter, Duration.quarter, Duration.quarter, Duration.quarter,
    ],
    label: 'BACH',
  );

  /// Dies Irae — the medieval chant of death, endlessly quoted.
  /// The first 7 notes: D E D D C D E — neighbor-tone oscillation.
  static final diesIrae = Motif(
    intervals: [
      Interval.majorSecond,               // D→E
      Interval(semitones: -2, diatonicSteps: -1, quality: IntervalQuality.major), // E→D
      Interval.perfectUnison,             // D→D
      Interval(semitones: -2, diatonicSteps: -1, quality: IntervalQuality.major), // D→C
      Interval.majorSecond,               // C→D
      Interval.majorSecond,               // D→E
    ],
    rhythm: [
      Duration.quarter, Duration.quarter, Duration.quarter, Duration.quarter,
      Duration.quarter, Duration.quarter, Duration.half,
    ],
    label: 'dies irae',
  );
}

// ─── Motif extraction: finding motifs in existing music ─────────────────────

/// Extract a motif from a [Music] value by reading its intervals and rhythm.
///
/// This is the inverse of [Motif.realize]: given concrete music, derive
/// the abstract pattern. Useful for analyzing existing compositions —
/// "what motif is the first four notes of this melody?"
///
/// Only extracts from the top voice of parallel music, and ignores rests
/// (they break the motif boundary).
Motif? extractMotif(Music music, {String? label}) {
  final events = _extractNoteEvents(music);
  if (events.length < 2) return null;

  final intervals = <Interval>[];
  for (var i = 0; i < events.length - 1; i++) {
    intervals.add(events[i].pitch.intervalTo(events[i + 1].pitch));
  }

  return Motif(
    intervals: intervals,
    rhythm: events.map((e) => e.duration).toList(),
    articulations: events.map((e) => e.articulation).toList(),
    label: label,
  );
}

/// Find all occurrences of [motif] within [music], returning the starting
/// pitches where the motif appears.
///
/// This is pattern matching: "where does this motif occur in this piece?"
/// Matches transpositions automatically (same intervals, any starting pitch).
/// Use [matchInversions] to also find inverted forms.
List<Pitch> findMotifOccurrences(
  Motif motif,
  Music music, {
  bool matchInversions = false,
  bool matchRetrogrades = false,
}) {
  final events = _extractNoteEvents(music);
  if (events.length < motif.noteCount) return [];

  final candidates = [motif];
  if (matchInversions) candidates.add(motif.invert());
  if (matchRetrogrades) candidates.add(motif.retrograde());
  if (matchInversions && matchRetrogrades) {
    candidates.add(motif.retrogradeInversion());
  }

  final matches = <Pitch>[];

  for (var i = 0; i <= events.length - motif.noteCount; i++) {
    for (final candidate in candidates) {
      if (_matchesAt(events, i, candidate)) {
        matches.add(events[i].pitch);
        break; // don't double-count
      }
    }
  }

  return matches;
}

// ─── Internal helpers ───────────────────────────────────────────────────────

bool _matchesAt(List<Note> events, int start, Motif motif) {
  // Check intervals match
  for (var j = 0; j < motif.intervals.length; j++) {
    final actual = events[start + j].pitch.intervalTo(events[start + j + 1].pitch);
    if (actual.semitones != motif.intervals[j].semitones) return false;
  }
  // Check rhythm matches
  for (var j = 0; j < motif.rhythm.length; j++) {
    if (events[start + j].duration != motif.rhythm[j]) return false;
  }
  return true;
}

List<Note> _extractNoteEvents(Music music) => switch (music) {
      MusicNote(:final note) => [note],
      MusicRest() => [],
      MusicChord(:final chord) => [
          // Use the soprano (top) voice of the chord
          Note(pitch: chord.soprano, duration: chord.duration),
        ],
      Sequential(:final parts) => parts.expand(_extractNoteEvents).toList(),
      Parallel(:final voices) =>
        voices.isNotEmpty ? _extractNoteEvents(voices.first) : [],
      Modified(:final music) => _extractNoteEvents(music),
    };

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

List<double> _normalizeRhythm(List<Duration> rhythm) {
  final total = rhythm.fold(Duration.zero, (sum, d) => sum + d);
  if (total == Duration.zero) return [];
  final totalValue = total.numerator / total.denominator;
  return rhythm.map((d) => (d.numerator / d.denominator) / totalValue).toList();
}

double _sqrt(double x) {
  if (x <= 0) return 0;
  var guess = x / 2;
  for (var i = 0; i < 20; i++) {
    guess = (guess + x / guess) / 2;
  }
  return guess;
}
