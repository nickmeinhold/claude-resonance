import 'melody.dart';
import 'harmony.dart';
import 'texture.dart';

/// Musical form: the large-scale architecture of time.
///
/// A piece isn't a stream of notes with a start and end.
/// It's a NARRATIVE — with exposition, development, recapitulation,
/// with expectation and surprise, with memory and anticipation.
///
/// The representation here uses a recursive tree, because musical
/// form is fractal: a 4-bar phrase has the same tension-resolution
/// shape as a 40-minute symphony movement.
sealed class Form {
  /// Human-readable label for this section.
  String get label;

  /// The tension arc: how tension evolves across this section's duration.
  /// Normalized to [0.0, 1.0] over the section's timespan.
  TensionArc get tensionArc;
}

/// A leaf section: actual musical content.
class Section extends Form {
  @override
  final String label;
  final Texture texture;
  final Progression harmony;

  Section({required this.label, required this.texture, required this.harmony});

  @override
  TensionArc get tensionArc => TensionArc(harmony.tensionArc);
}

/// A compound form: sections related by transformation.
///
/// The key insight: sections don't just follow each other.
/// They RELATE to each other. A recapitulation isn't just "A again" —
/// it's A heard through the lens of everything that happened since.
/// The relationship IS the form.
class CompoundForm extends Form {
  @override
  final String label;
  final List<(Form section, SectionRelation relation)> sections;

  CompoundForm({required this.label, required this.sections});

  @override
  TensionArc get tensionArc => TensionArc(
    sections.expand((s) => s.$1.tensionArc.values).toList(),
  );
}

/// How a section relates to what came before.
enum SectionRelation {
  /// First statement. No prior context.
  exposition,

  /// Exact or near-exact repetition. Comfort, familiarity.
  repetition,

  /// Recognizable transformation of earlier material.
  /// The heart of musical development: taking an idea and showing
  /// it from a different angle.
  variation,

  /// Contrasting material. Departure, newness.
  /// The tension of the unfamiliar.
  contrast,

  /// Fragmentation, recombination, modulation of earlier material.
  /// Sonata development sections. Where ideas are stress-tested.
  development,

  /// Return of earlier material after departure.
  /// The most powerful structural event in tonal music.
  /// It works because you can't go home without having left.
  recapitulation,

  /// Wrapping up. Coda. The story is over; this is the epilogue.
  closing,
}

/// A tension arc: the shape of tension over time.
///
/// This might be the most fundamental musical concept in this entire
/// model. A piece IS its tension arc. Everything else — the notes,
/// the chords, the rhythms — is in service of this shape.
///
/// The classic shapes:
/// - Rising to cadence: /\ (antecedent-consequent phrase)
/// - Gradual build: / (crescendo, Ravel's Bolero)
/// - Arch: ∩ (most song forms, sonata movements)
/// - Rondo: /\/\/\ (recurring home base with departures)
class TensionArc {
  final List<double> values;

  const TensionArc(this.values);

  double get peak => values.fold(0.0, (a, b) => a > b ? a : b);
  double get valley => values.fold(1.0, (a, b) => a < b ? a : b);

  /// Where the climax falls, as a fraction of total duration.
  /// Most Western music places it around 0.6-0.8 (golden ratio territory).
  double get climaxPosition {
    var maxIdx = 0;
    for (var i = 1; i < values.length; i++) {
      if (values[i] > values[maxIdx]) maxIdx = i;
    }
    return maxIdx / values.length;
  }

  /// Does this arc resolve? (End lower than peak.)
  bool get resolves => values.isNotEmpty && values.last < peak * 0.5;

  /// Surprise metric: how much the arc deviates from a smooth curve.
  /// High surprise = interesting. Zero surprise = predictable = boring.
  double get surprise {
    if (values.length < 3) return 0.0;
    var totalDeviation = 0.0;
    for (var i = 1; i < values.length - 1; i++) {
      final expected = (values[i - 1] + values[i + 1]) / 2;
      totalDeviation += (values[i] - expected).abs();
    }
    return totalDeviation / (values.length - 2);
  }
}
