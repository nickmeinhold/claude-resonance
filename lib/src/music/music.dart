/// Music — the algebraic core of the system.
///
/// The central insight here comes from Haskell's Euterpea: music has exactly
/// two fundamental ways to combine:
///   - **Sequential** (+): one thing, then another
///   - **Parallel** (|): two things simultaneously
///
/// Everything else — phrases, movements, scores — is built from these two
/// operations, plus atomic events (notes, rests) and modifiers (tempo, key).
///
/// This gives you a *Music algebra*: you can transform, analyze, and combine
/// pieces of music as first-class values without ever thinking about the
/// specific notes inside them.
///
/// ```dart
/// final melody = [noteC, noteE, noteG].sequential;
/// final harmony = [chordC, chordF, chordG].sequential;
/// final piece = melody | harmony; // they play simultaneously
///
/// final transposed = piece.transpose(Interval.perfectFifth);
/// final inverted = piece.invert(Pitch.middleC);
/// final canon = piece + piece.delayed(Duration.half);
/// ```
library;

import 'pitch.dart';
import 'duration.dart';
import 'expression.dart';
import 'interval.dart';
import 'harmony.dart';

// ─── Atomic events ────────────────────────────────────────────────────────────

/// A single pitched note.
///
/// The [dynamic] and [articulation] here are note-level overrides. If null,
/// the note inherits the dynamic context from its enclosing [Modified] or
/// the score default. This models how sheet music actually works: you mark
/// the start of a piano passage, not every individual note.
final class Note {
  final Pitch pitch;
  final Duration duration;
  final Articulation articulation;
  final Dynamic? dynamic; // null = inherit from context

  /// Optional ornament (trill, turn, mordent, grace note).
  final Ornament? ornament;

  /// Ties this note to the next. The two notes sound as one sustained pitch.
  /// Distinct from a slur — a tie requires the same pitch; a slur connects
  /// different pitches into a phrase.
  final bool tied;

  const Note({
    required this.pitch,
    required this.duration,
    this.articulation = Articulation.legato,
    this.dynamic,
    this.ornament,
    this.tied = false,
  });

  Note withDuration(Duration d) => Note(
        pitch: pitch,
        duration: d,
        articulation: articulation,
        dynamic: dynamic,
        ornament: ornament,
        tied: tied,
      );

  @override
  String toString() => '$pitch (${duration})';
}

/// A silent note — a pause in the music.
///
/// Rests are as important as notes. The silent beat before a cadence, the
/// space in a jazz melody, the fermata — silence has musical weight.
final class Rest {
  final Duration duration;
  const Rest(this.duration);

  @override
  String toString() => 'rest (${duration})';
}

/// Multiple pitches sounding simultaneously, treated as a single rhythmic unit.
///
/// This is the *notational* chord — pitches that share a stem in traditional
/// notation. Distinct from harmony (which is about function) and from
/// parallel [Music] voices (which can have different rhythms).
final class Chord {
  /// Pitches from bottom to top. Convention: lowest pitch first.
  final List<Pitch> pitches;
  final Duration duration;
  final Articulation articulation;
  final Dynamic? dynamic;

  const Chord({
    required this.pitches,
    required this.duration,
    this.articulation = Articulation.legato,
    this.dynamic,
  });

  /// The lowest (bass) note.
  Pitch get bass => pitches.first;

  /// The highest note.
  Pitch get soprano => pitches.last;

  /// Attempt to identify this chord as a symbol (e.g., "C major", "G7").
  /// Returns null if the pitches don't match any recognizable chord type.
  ChordSymbol? get symbol => _analyzeChord(pitches.map((p) => p.pitchClass).toList());

  @override
  String toString() => '[${pitches.join(', ')}] (${duration})';
}

ChordSymbol? _analyzeChord(List<PitchClass> classes) {
  // Simplified chord recognition — a full implementation would
  // try all inversions and match against known interval patterns.
  return null;
}

// ─── The Music algebra ────────────────────────────────────────────────────────

/// A musical value — the algebraic type that all music is made of.
///
/// The sealed hierarchy:
/// - [MusicNote]     — a single note
/// - [MusicRest]     — a single rest
/// - [MusicChord]    — simultaneous notes (same rhythm)
/// - [Sequential]    — a + b: play a, then b
/// - [Parallel]      — a | b: play a and b simultaneously
/// - [Modified]      — m[a]: play a with modifier m (tempo, key, dynamic)
///
/// Two operations define composition:
/// - `a + b`  → Sequential([a, b])   "a then b"
/// - `a | b`  → Parallel([a, b])     "a and b together"
///
/// These operations are associative: (a + b) + c == a + (b + c).
/// (| is also commutative for duration purposes, though voice order may matter.)
sealed class Music {
  const Music();

  /// Total duration of this musical value.
  Duration get totalDuration;

  // ─── Composition operators ─────────────────────────────────────────────

  /// Sequential composition: play [this], then [other].
  Music operator +(Music other) {
    // Flatten nested Sequentials for efficiency.
    final parts = [
      if (this case Sequential(:final parts)) ...parts else this,
      if (other case Sequential(:final parts)) ...parts else other,
    ];
    return Sequential(parts);
  }

  /// Parallel composition: play [this] and [other] simultaneously.
  Music operator |(Music other) {
    final voices = [
      if (this case Parallel(:final voices)) ...voices else this,
      if (other case Parallel(:final voices)) ...voices else other,
    ];
    return Parallel(voices);
  }

  // ─── Transformations ──────────────────────────────────────────────────

  /// Transpose every pitch by [interval].
  Music transpose(Interval interval);

  /// Reverse the time order of events (retrograde).
  /// A classic serial technique; also appears in Bach's crab canons.
  Music get retrograde;

  /// Invert pitches around [axis]: every interval above the axis becomes
  /// the same interval below, and vice versa. The pitch contour flips.
  Music invert(Pitch axis);

  /// Augment: multiply all durations by [factor]. Double the factor = twice as slow.
  Music augment(int factor);

  /// Diminish: divide all durations by [factor]. Speeds up rhythmic values.
  Music diminish(int factor);

  /// Add a [duration] of silence before this music begins.
  Music delayed(Duration duration) => Rest(duration).asMusic + this;

  /// Apply a [modifier] to this music (tempo change, dynamic, key center).
  Music withModifier(Modifier modifier) => Modified(this, [modifier]);

  // ─── Convenience ──────────────────────────────────────────────────────

  /// Repeat this music [times] times.
  Music repeat(int times) {
    assert(times > 0);
    Music result = this;
    for (int i = 1; i < times; i++) {
      result = result + this;
    }
    return result;
  }

  /// Play this music over a harmonic progression, grouping by chord duration.
  /// (Thin wrapper — real voice leading belongs in a separate module.)
  Music over(HarmonicProgression progression, Scale scale) =>
      Modified(this, [HarmonicContext(progression, scale)]);
}

// ─── Concrete Music types ─────────────────────────────────────────────────────

/// A single note wrapped as a Music value.
final class MusicNote extends Music {
  final Note note;
  const MusicNote(this.note);

  @override
  Duration get totalDuration => note.duration;

  @override
  Music transpose(Interval interval) =>
      MusicNote(Note(
        pitch: note.pitch.transpose(interval),
        duration: note.duration,
        articulation: note.articulation,
        dynamic: note.dynamic,
        ornament: note.ornament,
        tied: note.tied,
      ));

  @override
  Music get retrograde => this; // a single note is its own retrograde

  @override
  Music invert(Pitch axis) {
    // True pitch-axis inversion: reflect around the axis.
    // If note is N semitones above the axis, inverted note is N semitones below.
    final diff = note.pitch.semitones - axis.semitones;
    final invertedSemitones = axis.semitones - diff;
    // Reconstruct pitch from absolute semitones.
    final invertedOctave = invertedSemitones ~/ 12;
    final invertedPcSemitones = invertedSemitones % 12;
    // Find the pitch class — try natural first, then sharps.
    final invertedPc = PitchClass.values.firstWhere(
      (pc) => pc.naturalSemitones == invertedPcSemitones,
      orElse: () => PitchClass.values.firstWhere(
        (pc) => pc.naturalSemitones == invertedPcSemitones - 1,
      ),
    );
    final needsSharp = invertedPc.naturalSemitones != invertedPcSemitones;
    final inverted = Pitch(
      invertedPc,
      invertedOctave,
      needsSharp ? Accidental.sharp : Accidental.natural,
    );
    return MusicNote(Note(
      pitch: inverted,
      duration: note.duration,
      articulation: note.articulation,
      dynamic: note.dynamic,
      ornament: note.ornament,
      tied: note.tied,
    ));
  }

  @override
  Music augment(int factor) =>
      MusicNote(note.withDuration(note.duration * factor));

  @override
  Music diminish(int factor) =>
      MusicNote(note.withDuration(note.duration ~/ factor));

  @override
  String toString() => note.toString();
}

/// A rest wrapped as a Music value.
final class MusicRest extends Music {
  final Rest rest;
  const MusicRest(this.rest);

  @override
  Duration get totalDuration => rest.duration;

  @override
  Music transpose(Interval interval) => this; // rests have no pitch to transpose

  @override
  Music get retrograde => this;

  @override
  Music invert(Pitch axis) => this;

  @override
  Music augment(int factor) => MusicRest(Rest(rest.duration * factor));

  @override
  Music diminish(int factor) => MusicRest(Rest(rest.duration ~/ factor));

  @override
  String toString() => rest.toString();
}

/// A chord wrapped as a Music value.
final class MusicChord extends Music {
  final Chord chord;
  const MusicChord(this.chord);

  @override
  Duration get totalDuration => chord.duration;

  @override
  Music transpose(Interval interval) => MusicChord(Chord(
        pitches: chord.pitches.map((p) => p.transpose(interval)).toList(),
        duration: chord.duration,
        articulation: chord.articulation,
        dynamic: chord.dynamic,
      ));

  @override
  Music get retrograde => this; // a chord is its own retrograde

  @override
  Music invert(Pitch axis) => MusicChord(Chord(
        pitches: chord.pitches.map((p) {
          final diff = p.semitones - axis.semitones;
          final invertedSemitones = axis.semitones - diff;
          final oct = invertedSemitones ~/ 12;
          final pcSemi = invertedSemitones % 12;
          final pc = PitchClass.values.firstWhere(
            (pc) => pc.naturalSemitones == pcSemi,
            orElse: () => PitchClass.values.firstWhere(
              (pc) => pc.naturalSemitones == pcSemi - 1,
            ),
          );
          final needsSharp = pc.naturalSemitones != pcSemi;
          return Pitch(pc, oct, needsSharp ? Accidental.sharp : Accidental.natural);
        }).toList(),
        duration: chord.duration,
        articulation: chord.articulation,
        dynamic: chord.dynamic,
      ));

  @override
  Music augment(int factor) => MusicChord(Chord(
        pitches: chord.pitches,
        duration: chord.duration * factor,
        articulation: chord.articulation,
        dynamic: chord.dynamic,
      ));

  @override
  Music diminish(int factor) => MusicChord(Chord(
        pitches: chord.pitches,
        duration: chord.duration ~/ factor,
        articulation: chord.articulation,
        dynamic: chord.dynamic,
      ));

  @override
  String toString() => chord.toString();
}

/// Play a list of [Music] values one after another.
final class Sequential extends Music {
  final List<Music> parts;

  const Sequential(this.parts) : assert(parts.length > 0);

  @override
  Duration get totalDuration =>
      parts.fold(Duration.zero, (sum, m) => sum + m.totalDuration);

  @override
  Music transpose(Interval interval) =>
      Sequential(parts.map((m) => m.transpose(interval)).toList());

  @override
  Music get retrograde =>
      Sequential(parts.reversed.map((m) => m.retrograde).toList());

  @override
  Music invert(Pitch axis) =>
      Sequential(parts.map((m) => m.invert(axis)).toList());

  @override
  Music augment(int factor) =>
      Sequential(parts.map((m) => m.augment(factor)).toList());

  @override
  Music diminish(int factor) =>
      Sequential(parts.map((m) => m.diminish(factor)).toList());

  @override
  String toString() => parts.join(' → ');
}

/// Play a list of [Music] values simultaneously (different voices/layers).
///
/// The total duration is the *longest* voice — shorter voices are padded
/// with silence. This is the natural behavior for polyphony.
final class Parallel extends Music {
  final List<Music> voices;

  const Parallel(this.voices) : assert(voices.length > 0);

  @override
  Duration get totalDuration => voices
      .map((v) => v.totalDuration)
      .reduce((a, b) => a > b ? a : b);

  @override
  Music transpose(Interval interval) =>
      Parallel(voices.map((m) => m.transpose(interval)).toList());

  @override
  Music get retrograde =>
      Parallel(voices.map((m) => m.retrograde).toList());

  @override
  Music invert(Pitch axis) =>
      Parallel(voices.map((m) => m.invert(axis)).toList());

  @override
  Music augment(int factor) =>
      Parallel(voices.map((m) => m.augment(factor)).toList());

  @override
  Music diminish(int factor) =>
      Parallel(voices.map((m) => m.diminish(factor)).toList());

  @override
  String toString() => '(${voices.join(' ‖ ')})';
}

/// Music with a contextual modifier applied (tempo, dynamic, key).
final class Modified extends Music {
  final Music music;
  final List<Modifier> modifiers;

  const Modified(this.music, this.modifiers);

  @override
  Duration get totalDuration => music.totalDuration;

  @override
  Music transpose(Interval interval) =>
      Modified(music.transpose(interval), modifiers);

  @override
  Music get retrograde => Modified(music.retrograde, modifiers);

  @override
  Music invert(Pitch axis) => Modified(music.invert(axis), modifiers);

  @override
  Music augment(int factor) => Modified(music.augment(factor), modifiers);

  @override
  Music diminish(int factor) => Modified(music.diminish(factor), modifiers);
}

// ─── Modifiers ────────────────────────────────────────────────────────────────

/// A contextual marking that modifies how enclosed music is interpreted.
///
/// Modifiers don't change *what* the notes are, only *how* they're performed.
/// They accumulate: you can have a tempo change inside a key change inside a
/// dynamic change. The innermost modifier of each type wins.
sealed class Modifier {
  const Modifier();
}

final class TempoModifier extends Modifier {
  final Tempo tempo;
  const TempoModifier(this.tempo);
}

final class DynamicModifier extends Modifier {
  final Dynamic dynamic;
  const DynamicModifier(this.dynamic);
}

final class KeyModifier extends Modifier {
  final Scale scale;
  const KeyModifier(this.scale);
}

final class HarmonicContext extends Modifier {
  final HarmonicProgression progression;
  final Scale scale;
  const HarmonicContext(this.progression, this.scale);
}

// ─── Rhythm patterns ──────────────────────────────────────────────────────────

/// A pure rhythmic pattern: durations and stresses, with no pitches.
///
/// This models the insight that rhythm is independent of pitch. The same
/// rhythmic cell can be "filled in" with different melodies, just as a
/// jazz standard's melody can be played over its rhythm changes.
///
/// ```dart
/// final bossaNova = RhythmPattern([
///   RhythmCell(Duration.eighth, BeatStress.strong),
///   RhythmCell(Duration.eighth, BeatStress.weak),
///   RhythmCell(Duration.eighth, BeatStress.syncopated),
///   // ...
/// ]);
///
/// final melody = bossaNova.realize([c4, e4, g4, a4, ...]);
/// ```
final class RhythmPattern {
  final List<RhythmCell> cells;

  const RhythmPattern(this.cells);

  Duration get totalDuration =>
      cells.fold(Duration.zero, (sum, c) => sum + c.duration);

  /// Realize this rhythm by pairing cells with [pitches].
  /// Pitches cycle if there are fewer pitches than cells.
  /// Rest cells (stress == null) produce rests regardless of pitch.
  Music realize(List<Pitch> pitches) {
    final events = <Music>[];
    var pitchIndex = 0;
    for (final cell in cells) {
      if (cell.stress == null) {
        events.add(MusicRest(Rest(cell.duration)));
      } else {
        final pitch = pitches[pitchIndex % pitches.length];
        events.add(MusicNote(Note(
          pitch: pitch,
          duration: cell.duration,
          // Map beat stress to articulation as a simple default.
          articulation: cell.stress == BeatStress.strong
              ? Articulation.accent
              : Articulation.legato,
        )));
        pitchIndex++;
      }
    }
    return Sequential(events);
  }

  // ─── Common rhythm patterns ─────────────────────────────────────────────

  static RhythmPattern get straight4 => RhythmPattern(List.generate(
      4, (_) => RhythmCell(Duration.quarter, BeatStress.weak)));

  /// A swing "long-short" eighth-note pattern (♩♪ feel).
  static RhythmPattern get swingEighths => RhythmPattern([
        RhythmCell(Duration.eighth.dotted, BeatStress.strong),
        RhythmCell(Duration.sixteenth, BeatStress.weak),
        RhythmCell(Duration.eighth.dotted, BeatStress.medium),
        RhythmCell(Duration.sixteenth, BeatStress.weak),
      ]);

  /// A tresillo: the 3-3-2 subdivision ubiquitous in Afro-Cuban music.
  static RhythmPattern get tresillo => RhythmPattern([
        RhythmCell(Duration(3, 8), BeatStress.strong),
        RhythmCell(Duration(3, 8), BeatStress.syncopated),
        RhythmCell(Duration(2, 8), BeatStress.medium),
      ]);
}

/// A single cell in a rhythm pattern.
final class RhythmCell {
  final Duration duration;
  /// Null = this cell is a rest.
  final BeatStress? stress;

  const RhythmCell(this.duration, [this.stress]);
}

// ─── Phrase — the missing middle layer ────────────────────────────────────────

/// A musical phrase: a sequence of notes with directional *intent*.
///
/// The phrase is the unit of musical *meaning*. Two identical note sequences
/// can be different phrases (the breath falls differently, the climax lands
/// on a different note). A phrase has:
///
/// - A **contour**: the shape of its pitch trajectory (rising, falling, arch, valley)
/// - A **climax**: the point of maximum intensity (often the highest pitch)
/// - A **cadence**: how it resolves at the end
///
/// Phrases compose into periods (antecedent + consequent = question + answer),
/// and periods compose into sections. This recursive structure mirrors how
/// musicians actually think about form.
///
/// ```dart
/// final question = Phrase(notes, cadence: Cadence.halfCadence);
/// final answer   = Phrase(otherNotes, cadence: Cadence.authenticCadence);
/// final period   = Period(antecedent: question, consequent: answer);
/// ```
final class Phrase {
  final Music music;

  /// How this phrase ends — open (half cadence), closed (authentic), etc.
  final Cadence cadence;

  /// Optional label for analysis ("A", "bridge", "development").
  final String? label;

  const Phrase(this.music, {this.cadence = Cadence.none, this.label});

  Duration get totalDuration => music.totalDuration;

  /// Analyze the melodic contour of this phrase by extracting all pitches
  /// and classifying the overall shape.
  Contour get contour => _analyzeContour(music);

  /// The phrase transposed.
  Phrase transpose(Interval interval) => Phrase(
        music.transpose(interval),
        cadence: cadence,
        label: label,
      );
}

/// How a phrase ends — its point of (non-)resolution.
///
/// Cadences are the punctuation of music. An authentic cadence (V→I) is a
/// period. A half cadence (→V) is a comma. A deceptive cadence (V→vi) is
/// an em dash — you expected resolution and got a surprise.
enum Cadence {
  /// No specific cadential pattern (mid-phrase, or analysis not applied).
  none,

  /// V→I in root position — the strongest resolution, a full stop.
  perfectAuthentic,

  /// V→I with the melody *not* on the tonic — slightly weaker closure.
  imperfectAuthentic,

  /// Phrase ends on V — an open question, demanding continuation.
  half,

  /// IV→I — softer, more contemplative resolution (the "Amen" cadence).
  plagal,

  /// V→vi (or other unexpected chord) — the musical plot twist.
  deceptive,
}

/// The directional shape of a melody — its pitch trajectory over time.
///
/// Contour is how we recognize melodies even when transposed, rhythmically
/// altered, or heard in a different timbre. It's the most abstract level
/// of melodic identity — more fundamental than specific intervals.
enum Contour {
  /// Generally ascending: the phrase moves upward overall.
  ascending,

  /// Generally descending: the phrase moves downward.
  descending,

  /// Arch: rises then falls (the most common melodic shape).
  arch,

  /// Valley: descends then rises (inverted arch).
  valley,

  /// Stays roughly at one pitch level — reciting-tone or pedal figure.
  stationary,

  /// Complex or multi-directional — doesn't fit a simple category.
  complex,
}

/// A period: two phrases in an antecedent/consequent (question/answer) pair.
///
/// The antecedent typically ends with a half cadence (open, unresolved)
/// and the consequent answers with an authentic cadence (closed, resolved).
/// This is the most fundamental unit of musical form above the phrase.
final class Period {
  final Phrase antecedent;
  final Phrase consequent;

  const Period({required this.antecedent, required this.consequent});

  /// The complete music of both phrases in sequence.
  Music get music => antecedent.music + consequent.music;

  Duration get totalDuration =>
      antecedent.totalDuration + consequent.totalDuration;

  /// Transpose the entire period.
  Period transpose(Interval interval) => Period(
        antecedent: antecedent.transpose(interval),
        consequent: consequent.transpose(interval),
      );
}

/// Extract all pitches from a Music value (flattening structure).
List<Pitch> _extractPitches(Music music) => switch (music) {
      MusicNote(:final note) => [note.pitch],
      MusicRest() => [],
      MusicChord(:final chord) => [chord.soprano], // use top voice for contour
      Sequential(:final parts) => parts.expand(_extractPitches).toList(),
      Parallel(:final voices) =>
        // Take the first (top) voice for contour analysis
        voices.isNotEmpty ? _extractPitches(voices.first) : [],
      Modified(:final music) => _extractPitches(music),
    };

/// Classify the overall contour of a Music value.
Contour _analyzeContour(Music music) {
  final pitches = _extractPitches(music);
  if (pitches.length < 2) return Contour.stationary;

  final semitones = pitches.map((p) => p.semitones).toList();
  final first = semitones.first;
  final last = semitones.last;
  final highIndex = semitones.indexOf(semitones.reduce((a, b) => a > b ? a : b));
  final lowIndex = semitones.indexOf(semitones.reduce((a, b) => a < b ? a : b));
  final mid = semitones.length ~/ 2;

  // Stationary: range of less than a major second
  final range = semitones.reduce((a, b) => a > b ? a : b) -
      semitones.reduce((a, b) => a < b ? a : b);
  if (range <= 2) return Contour.stationary;

  // Arch: high point near the middle
  if (highIndex > 0 && highIndex < semitones.length - 1 &&
      (highIndex - mid).abs() <= semitones.length ~/ 3) {
    return Contour.arch;
  }

  // Valley: low point near the middle
  if (lowIndex > 0 && lowIndex < semitones.length - 1 &&
      (lowIndex - mid).abs() <= semitones.length ~/ 3) {
    return Contour.valley;
  }

  // Ascending: last is higher than first by at least a third of range
  if (last - first > range ~/ 3) return Contour.ascending;

  // Descending: first is higher than last by at least a third of range
  if (first - last > range ~/ 3) return Contour.descending;

  return Contour.complex;
}

// ─── Convenience extensions ───────────────────────────────────────────────────

extension NoteAsMusic on Note {
  Music get asMusic => MusicNote(this);
}

extension RestAsMusic on Rest {
  Music get asMusic => MusicRest(this);
}

extension ChordAsMusic on Chord {
  Music get asMusic => MusicChord(this);
}

extension MusicListExtensions on List<Music> {
  /// Combine all elements sequentially (one after another).
  Music get sequential => Sequential(this);

  /// Combine all elements in parallel (all at once).
  Music get parallel => Parallel(this);
}

extension PitchToNote on Pitch {
  /// Quick note construction: `Pitch.middleC.quarter`.
  Note withDuration(Duration d) => Note(pitch: this, duration: d);

  Note get whole => Note(pitch: this, duration: Duration.whole);
  Note get half => Note(pitch: this, duration: Duration.half);
  Note get quarter => Note(pitch: this, duration: Duration.quarter);
  Note get eighth => Note(pitch: this, duration: Duration.eighth);
  Note get sixteenth => Note(pitch: this, duration: Duration.sixteenth);
}
