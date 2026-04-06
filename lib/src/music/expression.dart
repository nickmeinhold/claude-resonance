/// Expression — dynamics, articulation, and phrasing.
///
/// These are the "how" of music: not what notes, but how they're played.
/// Expression lives at two scales: the note level (articulation, accent) and
/// the phrase level (dynamics, crescendo, slurs).
///
/// A nuance worth capturing: dynamics in classical music are *relative*, not
/// absolute. "forte" in a Beethoven symphony and "forte" in a Chopin nocturne
/// call for very different absolute volumes. The [Dynamic] enum encodes the
/// relationship between loudness levels, not the decibel values.
library;

import 'duration.dart';

// ─── Dynamics ────────────────────────────────────────────────────────────────

/// Standard dynamic levels, from softest to loudest.
///
/// Each step is conventionally about 6dB, but this is a guideline, not a rule.
/// Interpretation always overrides convention.
enum Dynamic {
  ppp('ppp', -3),
  pp('pp', -2),
  p('p', -1),
  mp('mp', 0),
  mf('mf', 1),
  f('f', 2),
  ff('ff', 3),
  fff('fff', 4);

  final String symbol;
  /// Relative loudness step (0 = mezzoforte, negative = softer, positive = louder)
  final int step;
  const Dynamic(this.symbol, this.step);

  Dynamic louder([int steps = 1]) {
    final target = step + steps;
    return values.firstWhere(
      (d) => d.step == target,
      orElse: () => fff,
    );
  }

  Dynamic softer([int steps = 1]) => louder(-steps);

  @override
  String toString() => symbol;
}

/// A continuous change in dynamic over a duration.
///
/// The most common forms: crescendo (getting louder) and diminuendo/decrescendo
/// (getting softer). The shape parameter describes the curve — linear is typical
/// notation, but musical reality is more varied.
final class DynamicGradient {
  final Dynamic from;
  final Dynamic to;
  final Duration duration;
  final GradientShape shape;

  const DynamicGradient({
    required this.from,
    required this.to,
    required this.duration,
    this.shape = GradientShape.linear,
  });

  bool get isCrescendo => to.step > from.step;
  bool get isDiminuendo => to.step < from.step;

  @override
  String toString() =>
      isCrescendo ? 'cresc. ($from→$to)' : 'dim. ($from→$to)';
}

enum GradientShape {
  linear,    // steady change — how it's notated
  convex,    // sudden at the start, tapers off — typical for diminuendo
  concave,   // slow at first, rushes at the end — typical for crescendo
  hairpin,   // swell and return — like a single-note messa di voce
}

// ─── Articulation ────────────────────────────────────────────────────────────

/// How a single note is attacked, sustained, and released.
///
/// Articulation lives at the intersection of duration (how much of the
/// notated duration is actually sounded) and accent (how the attack is shaped).
/// A staccato quarter note sounds for roughly 1/2 its notated duration;
/// a tenuto extends to the full value and then some.
enum Articulation {
  /// Play the full written duration — smooth, connected. The default.
  legato,

  /// Detach: play approximately half the written duration, light attack.
  staccato,

  /// Very short and light — extreme detachment, almost a flick.
  staccatissimo,

  /// Full duration with slight emphasis — hold for the full value.
  tenuto,

  /// Emphasized attack — louder at the onset than the body of the note.
  accent,

  /// Strong, full-value emphasis — both tenuto and accent combined.
  marcato,

  /// Multiple tonguing/bowing strokes within a single note value (strings/winds).
  tremolo,
}

/// A slur connects multiple notes into a single phrase arc.
///
/// Unlike legato (an articulation on a single note), a slur is a *spanning*
/// directive — it says "play these N notes as one connected phrase" and implies
/// that only the first note gets a fresh attack. Used in both bowing (strings)
/// and breath grouping (winds/voice).
final class Slur {
  /// How many notes the slur spans from its starting point.
  final int noteCount;

  const Slur(this.noteCount);
}

// ─── Accent patterns ────────────────────────────────────────────────────────

/// Beat stress within a measure — the difference between rhythmic meter and
/// rhythmic feel.
///
/// In 4/4, the metric stress is [strong, weak, medium, weak], but syncopation
/// and phrasing constantly work against this expectation. Modeling both the
/// expected and the actual stress is how you represent tension.
enum BeatStress {
  /// Metrically strong — the downbeat, or an accented upbeat.
  strong,

  /// Metrically medium — the third beat in 4/4.
  medium,

  /// Metrically weak — offbeats, upbeats.
  weak,

  /// An attack that deliberately lands off the expected metric stress.
  /// (The offbeat in syncopation that *feels* strong because of emphasis.)
  syncopated,
}

// ─── Ornaments ────────────────────────────────────────────────────────────────

/// Ornaments: rapid decorative flourishes around a main note.
///
/// These are notoriously period- and style-dependent: a Baroque trill starts
/// on the upper neighbor; a Classical trill often starts on the main note.
/// The [style] parameter captures this — ornaments are instructions to perform,
/// not exact pitches, which is why they live in expression rather than melody.
sealed class Ornament {
  const Ornament();
}

/// A rapid alternation between the main note and its upper neighbor.
final class Trill extends Ornament {
  /// Whether the trill starts on the main note (Classical/Romantic) or
  /// upper neighbor (Baroque). Ambiguous if null — performer decides.
  final bool? startOnMainNote;

  /// How many repetitions. Null = as many as the duration allows.
  final int? repetitions;

  const Trill({this.startOnMainNote, this.repetitions});
}

/// A rapid three-note figure: upper neighbor → main → lower neighbor (or reverse).
final class Turn extends Ornament {
  final bool inverted; // lower first instead of upper first
  const Turn({this.inverted = false});
}

/// A very fast single-note ornament to/from a neighbor — a "flick."
final class Mordent extends Ornament {
  final bool upper; // upper mordent (main→upper→main) vs lower (main→lower→main)
  const Mordent({this.upper = false});
}

/// An approach note (or notes) leading into the main pitch.
/// The duration of the appoggiatura is borrowed from the main note.
final class Appoggiatura extends Ornament {
  /// True = acciaccatura (grace note, played as quickly as possible, duration stolen
  /// from the start of the main note). False = appoggiatura (takes half the main
  /// note's value, or two-thirds if the main note is dotted).
  final bool isAcciaccatura;
  const Appoggiatura({this.isAcciaccatura = false});
}
