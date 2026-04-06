import 'interval.dart';
import 'pitch.dart';
import 'time.dart' as music;

/// A melody: a contour through pitch-time space.
///
/// The deepest insight about melody: it's not a sequence of notes.
/// It's a SHAPE — a contour — that exists independently of its
/// specific pitches or rhythms. "Happy Birthday" is recognizable
/// hummed at any speed in any key. Its identity is its contour.
class Melody {
  final List<MelodicEvent> events;

  const Melody(this.events);

  /// The interval sequence — the melody's DNA.
  ///
  /// This is what survives transposition. Two melodies with the same
  /// interval sequence are "the same melody" in a meaningful sense.
  List<Interval> get intervals => [
    for (var i = 0; i < events.length - 1; i++)
      events[i].pitch.intervalTo(events[i + 1].pitch),
  ];

  /// The contour: just the direction of each move (up/down/same).
  ///
  /// Even more abstract than intervals. A coarser equivalence class.
  /// Useful for finding melodic similarity across styles.
  List<ContourDirection> get contour => intervals.map((i) {
    if (i.semitones > 0) return ContourDirection.up;
    if (i.semitones < 0) return ContourDirection.down;
    return ContourDirection.same;
  }).toList();

  /// Transpose: shift every pitch by the same interval.
  /// The fundamental symmetry operation. The melody IS what's
  /// invariant under this transform.
  Melody transpose(Interval interval) => Melody([
    for (final event in events)
      MelodicEvent(
        pitch: event.pitch + interval,
        duration: event.duration,
        dynamic: event.dynamic,
        articulation: event.articulation,
      ),
  ]);

  /// Invert: flip every interval. Up becomes down, down becomes up.
  /// The contour is mirrored around the first note.
  ///
  /// Bach used this constantly. Webern built an entire aesthetic on it.
  /// It works because the SHAPE is recognizable even upside down —
  /// the way you recognize a face in a mirror.
  Melody invert() {
    if (events.isEmpty) return this;
    final anchor = events.first.pitch;
    final newEvents = [events.first];
    for (var i = 1; i < events.length; i++) {
      final originalInterval = anchor.intervalTo(events[i].pitch);
      final invertedInterval = originalInterval.descending;
      newEvents.add(MelodicEvent(
        pitch: anchor + invertedInterval,
        duration: events[i].duration,
        dynamic: events[i].dynamic,
        articulation: events[i].articulation,
      ));
    }
    return Melody(newEvents);
  }

  /// Retrograde: reverse the time ordering.
  /// The melody played backwards. Palindromic melodies are their
  /// own retrogrades — a rare and beautiful symmetry.
  Melody retrograde() => Melody(events.reversed.toList());

  /// Augmentation: stretch every duration by a factor.
  /// The melody in slow motion. Same pitches, more spacious.
  Melody augment(int factor) => Melody([
    for (final event in events)
      MelodicEvent(
        pitch: event.pitch,
        duration: music.Duration(event.duration.fraction * music.Rational(factor)),
        dynamic: event.dynamic,
        articulation: event.articulation,
      ),
  ]);

  /// Diminution: compress every duration.
  /// The melody sped up. Same pitches, more urgent.
  Melody diminish(int factor) => Melody([
    for (final event in events)
      MelodicEvent(
        pitch: event.pitch,
        duration: music.Duration(event.duration.fraction * music.Rational(1, factor)),
        dynamic: event.dynamic,
        articulation: event.articulation,
      ),
  ]);

  /// The range: distance from lowest to highest pitch.
  Interval get range {
    final sorted = events.map((e) => e.pitch).toList()
      ..sort((a, b) => a.compareTo(b));
    return sorted.first.intervalTo(sorted.last);
  }

  /// Tension profile: how each note relates to the prevailing harmony.
  /// (Requires harmonic context — a melody alone is ambiguous.)
  ///
  /// This is left as a method that takes context, not a property,
  /// because the same melody means different things over different chords.
  /// "Blue notes" only exist in relation to the expected harmony.
}

/// A single melodic event: pitch + duration + expression.
class MelodicEvent {
  final Pitch pitch;
  final music.Duration duration;
  final Dynamic dynamic;
  final Articulation articulation;

  const MelodicEvent({
    required this.pitch,
    required this.duration,
    this.dynamic = Dynamic.mf,
    this.articulation = Articulation.normal,
  });
}

enum ContourDirection { up, down, same }

/// Dynamics: not just volume — ENERGY.
///
/// Piano isn't "quiet." It's intimate, conspiratorial, fragile.
/// Forte isn't "loud." It's assertive, public, powerful.
/// The standard Italian terms are pointers to these energies.
enum Dynamic implements Comparable<Dynamic> {
  ppp(0.1, 'barely there'),
  pp(0.2, 'whispering'),
  p(0.35, 'intimate'),
  mp(0.5, 'conversational'),
  mf(0.65, 'present'),
  f(0.8, 'assertive'),
  ff(0.9, 'powerful'),
  fff(1.0, 'overwhelming');

  final double intensity;
  final String character;
  const Dynamic(this.intensity, this.character);

  @override
  int compareTo(Dynamic other) => intensity.compareTo(other.intensity);
}

/// Articulation: how a note BEGINS and ENDS.
///
/// Staccato isn't "short" — it's detached. Legato isn't "long" — it's connected.
/// The space between notes is as musical as the notes themselves.
enum Articulation {
  staccato,   // Detached. Each note a separate event.
  normal,     // Default. Neither connected nor detached.
  legato,     // Connected. Notes flow into each other.
  tenuto,     // Held to full value. Weighted.
  marcato,    // Accented attack. Emphatic.
  accent,     // Stressed beginning.
}
