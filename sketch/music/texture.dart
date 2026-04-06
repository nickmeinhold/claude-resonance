import 'melody.dart';
import 'harmony.dart';
import 'time.dart';

/// Musical texture: how simultaneous musical lines relate.
///
/// This is the layer most representations miss entirely.
/// A Bach fugue and a Chopin nocturne might use the same notes
/// and chords, but they have completely different textures —
/// and texture is load-bearing for what the music *means*.
sealed class Texture {
  const Texture();

  /// How many independent voices are active?
  int get voiceCount;

  /// The independence of voices (0.0 = homophonic, 1.0 = fully independent).
  double get independence;
}

/// Monophony: a single unaccompanied line.
///
/// The oldest texture. Gregorian chant. A solo violin partita.
/// All the musical meaning compressed into one dimension.
/// When it works, it's because the melody implies its own harmony.
class Monophony extends Texture {
  final Melody voice;

  const Monophony(this.voice);

  @override
  int get voiceCount => 1;

  @override
  double get independence => 1.0; // Trivially independent — nothing to agree with.
}

/// Homophony: melody + accompaniment.
///
/// The dominant texture of Western music since ~1750.
/// One voice leads; others support harmonically.
/// The hierarchy is explicit: melody matters more.
class Homophony extends Texture {
  final Melody melody;
  final Progression harmony;
  final AccompanimentPattern pattern;

  const Homophony({
    required this.melody,
    required this.harmony,
    required this.pattern,
  });

  @override
  int get voiceCount => 1 + pattern.voices;

  @override
  double get independence => 0.2; // Accompaniment follows the melody's lead.
}

/// Polyphony: multiple independent melodies sounding simultaneously.
///
/// The miracle of counterpoint. Each voice is a complete melody.
/// The harmony EMERGES from the intersection of lines, rather than
/// being imposed on them. This is music as an emergent system.
class Polyphony extends Texture {
  final List<Melody> voices;

  /// The contrapuntal rules these voices follow (species, free, etc.).
  final CounterpointType type;

  const Polyphony(this.voices, {this.type = CounterpointType.free});

  @override
  int get voiceCount => voices.length;

  @override
  double get independence => 0.9; // Voices are independent but coordinated.
}

/// Heterophony: the same melody played simultaneously in different versions.
///
/// Common in non-Western traditions. Rare in classical Western music.
/// Each performer plays "the same tune" but with different ornaments,
/// timing, octaves. The result is a shimmering cloud of near-unisons.
class Heterophony extends Texture {
  final Melody base;
  final List<Melody Function(Melody)> variations;

  const Heterophony(this.base, this.variations);

  @override
  int get voiceCount => 1 + variations.length;

  @override
  double get independence => 0.4; // Same melody, different realizations.
}

enum AccompanimentPattern {
  blockChords(1),       // Hymn style. Vertical.
  arpeggiated(1),       // Alberti bass, broken chords. Rolling.
  waltz(2),             // Boom-chick-chick.
  strummed(1),          // Guitar style.
  ostinato(1),          // Repeating pattern.
  figuration(2);        // Keyboard figuration — Chopin, Liszt.

  final int voices;
  const AccompanimentPattern(this.voices);
}

enum CounterpointType {
  species,    // Strict rules. Pedagogical. Fux.
  free,       // Bach. Rules internalized and transcended.
  imitative,  // Voices enter with the same material (fugue, canon).
  invertible, // Voices can swap positions and still work.
}

/// A musical moment: the full vertical slice plus its temporal context.
///
/// This is where everything comes together. A moment has:
/// - A texture (how the voices relate)
/// - A metric position (where we are in the measure)
/// - A place in the phrase (beginning, middle, cadence)
/// - A dynamic level
/// - A tension value (the sum of all forces at this instant)
///
/// The piece is NOT a sequence of these moments — it's the
/// trajectory through the space they define.
class MusicalMoment {
  final Texture texture;
  final MetricPosition position;
  final PhrasePosition phrasePosition;
  final Dynamic dynamic;

  const MusicalMoment({
    required this.texture,
    required this.position,
    required this.phrasePosition,
    required this.dynamic,
  });

  /// The total tension at this moment.
  /// Computed from: harmonic tension + metric tension + phrase tension.
  /// Three independent force fields overlaid.
  // double get tension => ...
}

/// Where we are in a phrase — the breathing rhythm of music.
enum PhrasePosition {
  /// Opening: establishing the idea. Low tension.
  opening,

  /// Continuation: developing the idea. Rising tension.
  continuation,

  /// Climax: peak tension. The point everything has been building toward.
  climax,

  /// Cadence: resolution. Exhaling.
  cadence,

  /// Elision: the end of one phrase is the beginning of the next.
  /// This is where the most interesting things happen — the overlap
  /// creates urgency because you never fully resolve before restarting.
  elision,
}
