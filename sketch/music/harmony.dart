import 'interval.dart';
import 'pitch.dart';

/// Harmonic function — what a chord DOES, not what notes it contains.
///
/// The same notes can have different functions in different keys.
/// C major is tonic in C, subdominant in G, dominant in F.
/// Function is relational, not intrinsic.
enum HarmonicFunction {
  tonic,         // Home. Rest. Resolution.
  predominant,   // Preparing to leave. (IV, ii, vi)
  dominant,      // Maximum tension toward tonic. (V, vii°)
  applied,       // Temporary dominant of a non-tonic chord.
  prolongation,  // Decorating/extending another function.
  pivot,         // Reinterpretable in two keys simultaneously.
}

/// A chord as a vertical sonority — its abstract shape.
///
/// Separate from voicing (which specific pitches in which octaves)
/// and function (what role it plays in a key).
class ChordQuality {
  /// The intervals above the root that define this chord type.
  final List<Interval> intervals;
  final String name;

  const ChordQuality(this.name, this.intervals);

  static final major = ChordQuality('major', [
    Interval.majorThird,
    Interval.perfectFifth,
  ]);

  static final minor = ChordQuality('minor', [
    Interval.minorThird,
    Interval.perfectFifth,
  ]);

  static final diminished = ChordQuality('diminished', [
    Interval.minorThird,
    Interval(4, 6), // diminished fifth
  ]);

  static final dominant7 = ChordQuality('dominant 7th', [
    Interval.majorThird,
    Interval.perfectFifth,
    Interval.minorSeventh,
  ]);

  static final majorSeventh = ChordQuality('major 7th', [
    Interval.majorThird,
    Interval.perfectFifth,
    Interval.majorSeventh,
  ]);

  static final minorSeventh = ChordQuality('minor 7th', [
    Interval.minorThird,
    Interval.perfectFifth,
    Interval.minorSeventh,
  ]);

  /// The total tension of this sonority — sum of interval tensions.
  /// A dominant 7th is tenser than a major triad. You can feel it.
  double get tension =>
      intervals.fold(0.0, (sum, i) => sum + i.tension) / intervals.length;

  @override
  String toString() => name;
}

/// A chord in context: quality + root + function.
///
/// This is where the magic happens. The same Bb major chord is:
/// - bVII in C major (borrowed, modal, surprising)
/// - IV in F major (subdominant, stable, warm)
/// - V in Eb major (dominant, tense, needs resolution)
///
/// The notes are identical. The MUSIC is completely different.
class HarmonicEvent {
  final PitchSpelling root;
  final ChordQuality quality;
  final HarmonicFunction function;

  /// Where this chord wants to go. The force vector.
  ///
  /// A dominant seventh has a strong tendency toward its tonic.
  /// A tonic triad has no tendency — it's arrived.
  /// This isn't metadata; it's the musical content.
  final Tendency tendency;

  /// How strongly this chord pulls toward resolution.
  /// 0.0 = at rest. 1.0 = desperately needs to resolve.
  final double urgency;

  const HarmonicEvent({
    required this.root,
    required this.quality,
    required this.function,
    this.tendency = Tendency.stable,
    this.urgency = 0.0,
  });
}

/// A voicing: how a chord is distributed across pitch-space.
///
/// Close position, open position, drop-2, rootless — these are
/// different realizations of the same harmony. The voicing determines
/// the *color* and the *voice leading* but not the *function*.
class Voicing {
  final List<Pitch> pitches;

  const Voicing(this.pitches);

  /// The span from lowest to highest note.
  Interval get span => pitches.first.intervalTo(pitches.last);

  /// Voice leading distance to another voicing.
  ///
  /// The sum of semitone movements for each voice. Good voice leading
  /// minimizes this. Bach knew this. Algorithms can find it.
  /// But the *musical* question is: which voices SHOULD move,
  /// and which should stay?
  int voiceLeadingDistance(Voicing other) {
    assert(pitches.length == other.pitches.length);
    var total = 0;
    for (var i = 0; i < pitches.length; i++) {
      total += (pitches[i].midi - other.pitches[i].midi).abs();
    }
    return total;
  }
}

/// A harmonic progression: the backbone of Western tonal music.
///
/// Not a list of chords — a directed graph of tensions and resolutions.
/// The progression I → IV → V → I isn't interesting because of the chords.
/// It's interesting because of the JOURNEY: home → departure → tension → home.
class Progression {
  final List<HarmonicEvent> events;

  const Progression(this.events);

  /// The tension arc: how tension evolves over the progression.
  List<double> get tensionArc =>
      events.map((e) => e.quality.tension + e.urgency).toList();

  /// Does this progression resolve? (Does it end with less tension than its peak?)
  bool get resolves {
    if (events.length < 2) return false;
    final arc = tensionArc;
    final peak = arc.reduce((a, b) => a > b ? a : b);
    return arc.last < peak * 0.5;
  }
}
