/// Voice Leading — how chords connect, the deep grammar of Western harmony.
///
/// Voice leading is arguably the most important concept that's *not* about
/// individual notes or individual chords. It's about the *motion between*
/// chords — how each voice (soprano, alto, tenor, bass) moves from one
/// chord to the next.
///
/// Why does a V7→I cadence sound "right"? Because:
/// - The leading tone (7th scale degree) resolves up by half step to tonic
/// - The chordal 7th resolves down by step
/// - The other voices move as little as possible
/// - No two voices move in parallel fifths or octaves
///
/// These aren't arbitrary rules. They're emergent properties of how the ear
/// tracks independent melodic lines within a harmonic texture. Parallel fifths
/// "fuse" — the ear stops hearing two voices and hears one. The rules exist
/// to maintain voice independence.
///
/// This module models voice leading as a *constraint satisfaction* problem:
/// given a current voicing and a target chord symbol, find the voicing of the
/// target chord that best satisfies a ranked set of voice-leading preferences.
///
/// The analogy to code: voice leading is like type inference. You have
/// constraints (chord tones, voice ranges, forbidden parallels) and you need
/// to find an assignment that satisfies all of them. Sometimes there's one
/// clear answer; sometimes there are trade-offs.
library;

import 'pitch.dart';
import 'interval.dart';
import 'harmony.dart';
import 'duration.dart';
import 'music.dart';

// ─── Voicing: a chord symbol realized as specific pitches ───────────────────

/// A specific arrangement of a chord's pitch classes across registers.
///
/// The same Cmaj7 chord can be voiced dozens of ways:
/// - Close position: C4 E4 G4 B4 (compact, bright)
/// - Open/drop-2:   C3 G3 B3 E4 (spacious, warm)
/// - Root position:  C3 E3 G3 B3 (grounded)
/// - First inversion: E3 G3 B3 C4 (lighter, forward-moving)
///
/// Each voicing has a different color, weight, and set of voice-leading
/// implications. The [Voicing] type captures one specific arrangement.
final class Voicing {
  /// The chord symbol this voicing realizes.
  final ChordSymbol symbol;

  /// Pitches from lowest to highest. Typically 3-6 voices.
  final List<Pitch> pitches;

  const Voicing({required this.symbol, required this.pitches});

  int get voiceCount => pitches.length;

  Pitch get bass => pitches.first;
  Pitch get soprano => pitches.last;

  /// The semitone spread between bass and soprano — a measure of "openness."
  /// Wider spacing = more orchestral, grander. Tighter = more intimate.
  int get spread => soprano.semitones - bass.semitones;

  /// Which inversion is this? 0 = root position, 1 = first inversion, etc.
  /// Determined by which chord tone is in the bass.
  int get inversion {
    final chordPitchClasses = symbol.pitchClasses;
    final bassClass = bass.pitchClass;
    final idx = chordPitchClasses.indexOf(bassClass);
    return idx == -1 ? 0 : idx; // -1 shouldn't happen for a valid voicing
  }

  /// Whether this voicing is in close position (all voices within an octave)
  /// or open position (wider than an octave between adjacent upper voices).
  bool get isClosePosition {
    for (var i = 1; i < pitches.length - 1; i++) {
      if (pitches[i + 1].semitones - pitches[i].semitones > 12) return false;
    }
    return true;
  }

  @override
  String toString() => '$symbol: [${pitches.join(', ')}]';
}

// ─── Voice motion types ─────────────────────────────────────────────────────

/// How two voices move relative to each other between two chords.
///
/// This is the fundamental vocabulary of counterpoint. Every pair of voices
/// exhibits one of these four motion types, and the mix determines the
/// texture's quality:
///
/// - Too much parallel motion → voices fuse, independence is lost
/// - Too much contrary motion → restless, no sense of harmonic direction
/// - A good mix (mostly oblique + contrary, some similar) → clear, balanced
enum MotionType {
  /// Both voices move in the same direction by the same interval.
  /// (Parallel thirds are lovely; parallel fifths are forbidden.)
  parallel,

  /// Both voices move in the same direction by different intervals.
  /// Safe but less interesting than contrary.
  similar,

  /// Voices move in opposite directions. The strongest tool for
  /// maintaining independence.
  contrary,

  /// One voice stays on the same pitch while the other moves.
  /// Common and useful — the stationary voice acts as an anchor.
  oblique,
}

/// Classify the motion between two voice pairs.
MotionType classifyMotion(Pitch from1, Pitch to1, Pitch from2, Pitch to2) {
  final motion1 = to1.semitones - from1.semitones;
  final motion2 = to2.semitones - from2.semitones;

  if (motion1 == 0 || motion2 == 0) return MotionType.oblique;
  if (motion1 == motion2) return MotionType.parallel;
  if ((motion1 > 0) != (motion2 > 0)) return MotionType.contrary;
  return MotionType.similar;
}

// ─── Voice-leading errors ───────────────────────────────────────────────────

/// A specific voice-leading problem detected between two voicings.
///
/// These aren't "errors" in an absolute sense — composers break every one
/// of these rules intentionally. But violating them *unintentionally*
/// usually sounds wrong, so the system flags them and lets the user
/// (or an algorithm) decide which to accept.
sealed class VoiceLeadingIssue {
  const VoiceLeadingIssue();

  /// How severe is this issue? Higher = more audibly wrong.
  double get severity;
}

/// Two voices moving in parallel perfect fifths or octaves.
///
/// The cardinal sin of classical voice leading. Parallel fifths (or octaves)
/// cause two independent voices to momentarily fuse into one sound. In
/// orchestral writing you hear it as a sudden thinning of texture.
///
/// Exception: parallel fifths are *idiomatic* in certain styles:
/// organum, power chords, Debussy, film scoring. Context matters.
final class ParallelFifthsOrOctaves extends VoiceLeadingIssue {
  final int voice1;
  final int voice2;
  final bool isOctaves; // true = octaves, false = fifths

  const ParallelFifthsOrOctaves({
    required this.voice1,
    required this.voice2,
    required this.isOctaves,
  });

  @override
  double get severity => 0.9;

  @override
  String toString() =>
      'Parallel ${isOctaves ? 'octaves' : 'fifths'} between voices $voice1 and $voice2';
}

/// A tendency tone (leading tone or chordal 7th) that doesn't resolve
/// in its expected direction.
///
/// The leading tone (e.g., B in C major) "wants" to resolve up to the tonic.
/// The chordal 7th (e.g., F in G7) "wants" to resolve down by step.
/// When they don't, the listener feels cheated — like a sentence
/// that stops before the
final class UnresolvedTendencyTone extends VoiceLeadingIssue {
  final int voice;
  final Pitch tone;
  final Pitch expectedResolution;
  final Pitch actualResolution;

  const UnresolvedTendencyTone({
    required this.voice,
    required this.tone,
    required this.expectedResolution,
    required this.actualResolution,
  });

  @override
  double get severity => 0.7;

  @override
  String toString() =>
      'Voice $voice: $tone should resolve to $expectedResolution, went to $actualResolution';
}

/// A voice leaps by more than an octave, or leaps without subsequent
/// step-wise contrary motion to "recover."
///
/// Large leaps create energy — they demand attention. The convention is
/// that a leap should be followed by stepwise motion in the opposite
/// direction, like a rubber band snapping back. An unrecovered leap
/// feels like a sentence shouted into a void.
final class UnrecoveredLeap extends VoiceLeadingIssue {
  final int voice;
  final Interval leap;

  const UnrecoveredLeap({required this.voice, required this.leap});

  @override
  double get severity => leap.semitones.abs() > 12 ? 0.6 : 0.3;

  @override
  String toString() => 'Voice $voice: unrecovered leap of $leap';
}

/// Voices cross: a lower voice goes higher than an upper voice.
///
/// Not always wrong (Bach does it), but it obscures the independence
/// of each voice because the listener's ear tracks register, not timbre.
final class VoiceCrossing extends VoiceLeadingIssue {
  final int voice1;
  final int voice2;

  const VoiceCrossing({required this.voice1, required this.voice2});

  @override
  double get severity => 0.4;

  @override
  String toString() => 'Voice crossing between voices $voice1 and $voice2';
}

// ─── Voice-leading analysis ─────────────────────────────────────────────────

/// Analyze the voice leading between two successive voicings.
///
/// Returns all detected issues. An empty list means the voice leading
/// follows all classical conventions — which doesn't mean it's *good*,
/// only that it's *correct*. Good voice leading also needs musical
/// intelligence that no rule set fully captures.
List<VoiceLeadingIssue> analyzeVoiceLeading(Voicing from, Voicing to) {
  assert(from.voiceCount == to.voiceCount,
      'Voice counts must match: ${from.voiceCount} vs ${to.voiceCount}');

  final issues = <VoiceLeadingIssue>[];
  final n = from.voiceCount;

  // Check all pairs of voices for parallel fifths/octaves.
  for (var i = 0; i < n; i++) {
    for (var j = i + 1; j < n; j++) {
      final fromInterval =
          (from.pitches[j].semitones - from.pitches[i].semitones).abs() % 12;
      final toInterval =
          (to.pitches[j].semitones - to.pitches[i].semitones).abs() % 12;

      // Both are fifths (7 semitones) or both are octaves (0 semitones)
      // AND both voices actually moved (not oblique motion)
      final bothMoved = from.pitches[i] != to.pitches[i] &&
          from.pitches[j] != to.pitches[j];

      if (bothMoved && fromInterval == toInterval) {
        if (fromInterval == 7) {
          issues.add(ParallelFifthsOrOctaves(
              voice1: i, voice2: j, isOctaves: false));
        } else if (fromInterval == 0) {
          issues.add(ParallelFifthsOrOctaves(
              voice1: i, voice2: j, isOctaves: true));
        }
      }
    }
  }

  // Check for voice crossing.
  for (var i = 0; i < n - 1; i++) {
    if (to.pitches[i].semitones > to.pitches[i + 1].semitones) {
      issues.add(VoiceCrossing(voice1: i, voice2: i + 1));
    }
  }

  // Check for unrecovered leaps (simplified: just flag large leaps).
  for (var i = 0; i < n; i++) {
    final leap = to.pitches[i].semitones - from.pitches[i].semitones;
    if (leap.abs() > 7) {
      // A leap larger than a fifth — should be recovered
      issues.add(UnrecoveredLeap(
        voice: i,
        leap: Interval(
          semitones: leap.abs(),
          diatonicSteps: (leap.abs() / 2).ceil(), // approximate
          quality: IntervalQuality.perfect, // approximate
        ),
      ));
    }
  }

  return issues;
}

// ─── Voice-leading engine ───────────────────────────────────────────────────

/// Configuration for the voice-leading algorithm.
///
/// These weights control how aggressively the algorithm avoids various
/// voice-leading issues. Setting a weight to 0 disables that constraint.
///
/// The defaults model classical common-practice harmony. For jazz,
/// you'd lower [parallelPenalty] (parallel motion is fine) and raise
/// [smoothnessPriority] (minimal movement is paramount). For modal/
/// film scoring, nearly everything can be relaxed.
final class VoiceLeadingStyle {
  /// How much to penalize total voice movement (semitones summed across voices).
  /// Higher = voices move less (smoother, more connected).
  final double smoothnessPriority;

  /// Penalty for parallel fifths/octaves.
  final double parallelPenalty;

  /// Penalty for unresolved tendency tones.
  final double tendencyTonePenalty;

  /// Penalty for voice crossing.
  final double crossingPenalty;

  /// Penalty for large leaps.
  final double leapPenalty;

  /// Prefer common tones (voices that can stay on the same pitch should).
  final double commonToneBonus;

  const VoiceLeadingStyle({
    this.smoothnessPriority = 1.0,
    this.parallelPenalty = 10.0,
    this.tendencyTonePenalty = 5.0,
    this.crossingPenalty = 3.0,
    this.leapPenalty = 2.0,
    this.commonToneBonus = 1.5,
  });

  /// Classical common-practice style: strict avoidance of parallels,
  /// strong tendency-tone resolution, minimal motion.
  static const classical = VoiceLeadingStyle();

  /// Jazz voicing style: parallels are fine, smoothness is king,
  /// extensions are welcome.
  static const jazz = VoiceLeadingStyle(
    smoothnessPriority: 2.0,
    parallelPenalty: 1.0,
    tendencyTonePenalty: 2.0,
    crossingPenalty: 1.0,
    leapPenalty: 3.0,
    commonToneBonus: 2.0,
  );

  /// Choral/SATB style: voices must stay in range, no crossing,
  /// classical rules apply strictly.
  static const choral = VoiceLeadingStyle(
    smoothnessPriority: 1.5,
    parallelPenalty: 15.0,
    tendencyTonePenalty: 8.0,
    crossingPenalty: 10.0,
    leapPenalty: 3.0,
    commonToneBonus: 2.0,
  );
}

/// Voice ranges for SATB (soprano, alto, tenor, bass) writing.
///
/// These are the "lanes" that voices must stay in. The ranges overlap
/// slightly — which is exactly where voice crossing becomes tempting
/// and dangerous.
final class VoiceRange {
  final Pitch low;
  final Pitch high;

  const VoiceRange(this.low, this.high);

  bool contains(Pitch p) =>
      p.semitones >= low.semitones && p.semitones <= high.semitones;

  static final soprano = VoiceRange(
    Pitch(PitchClass.c, 4),
    Pitch(PitchClass.g, 5),
  );
  static final alto = VoiceRange(
    Pitch(PitchClass.f, 3),
    Pitch(PitchClass.d, 5),
  );
  static final tenor = VoiceRange(
    Pitch(PitchClass.c, 3),
    Pitch(PitchClass.a, 4),
  );
  static final bass = VoiceRange(
    Pitch(PitchClass.e, 2),
    Pitch(PitchClass.e, 4),
  );

  static final satb = [soprano, alto, tenor, bass];
}

/// Given a current voicing and a target chord, find the smoothest voicing
/// of the target chord according to the given [style].
///
/// This is the core algorithm. It generates candidate voicings of [target]
/// that fit within [ranges], scores each candidate against [style], and
/// returns the best one.
///
/// The approach is brute-force over a constrained search space: for each
/// voice, enumerate the chord tones within that voice's range, then score
/// every combination. For 4 voices × ~4 chord tones × ~2 octaves, that's
/// around 4^4 × 2^4 = ~4096 candidates, which is tiny.
///
/// A production system would use branch-and-bound or dynamic programming,
/// but the brute-force approach is correct and fast enough for real-time
/// composition assistance.
Voicing? leadTo({
  required Voicing current,
  required ChordSymbol target,
  required List<VoiceRange> ranges,
  VoiceLeadingStyle style = VoiceLeadingStyle.classical,
}) {
  assert(ranges.length == current.voiceCount,
      'Need one range per voice: ${ranges.length} vs ${current.voiceCount}');

  final targetPitchClasses = target.pitchClasses;
  final n = current.voiceCount;

  // Generate all candidate pitches for each voice.
  final candidatesPerVoice = <List<Pitch>>[];
  for (var i = 0; i < n; i++) {
    final voiceCandidates = <Pitch>[];
    for (final pc in targetPitchClasses) {
      // Try every octave that falls within this voice's range.
      for (var oct = ranges[i].low.octave - 1;
          oct <= ranges[i].high.octave + 1;
          oct++) {
        final candidate = Pitch(pc, oct);
        if (ranges[i].contains(candidate)) {
          voiceCandidates.add(candidate);
        }
      }
    }
    if (voiceCandidates.isEmpty) return null; // can't voice this chord here
    candidatesPerVoice.add(voiceCandidates);
  }

  // Score every combination. (Cartesian product of voice candidates.)
  Voicing? best;
  var bestScore = double.infinity;

  void search(int voice, List<Pitch> partial) {
    if (voice == n) {
      // Score this complete voicing.
      final candidate = Voicing(symbol: target, pitches: List.of(partial));
      final score = _scoreVoicing(current, candidate, style);
      if (score < bestScore) {
        bestScore = score;
        best = candidate;
      }
      return;
    }
    for (final pitch in candidatesPerVoice[voice]) {
      partial.add(pitch);
      search(voice + 1, partial);
      partial.removeLast();
    }
  }

  search(0, []);
  return best;
}

/// Score a candidate voicing (lower is better).
double _scoreVoicing(
    Voicing from, Voicing to, VoiceLeadingStyle style) {
  var score = 0.0;
  final n = from.voiceCount;

  // 1. Smoothness: total voice movement.
  var totalMovement = 0;
  for (var i = 0; i < n; i++) {
    totalMovement +=
        (to.pitches[i].semitones - from.pitches[i].semitones).abs();
  }
  score += totalMovement * style.smoothnessPriority;

  // 2. Common tone bonus (reduce score for shared pitches).
  for (var i = 0; i < n; i++) {
    if (from.pitches[i].semitones == to.pitches[i].semitones) {
      score -= style.commonToneBonus;
    }
  }

  // 3. Voice-leading issues.
  final issues = analyzeVoiceLeading(from, to);
  for (final issue in issues) {
    final penalty = switch (issue) {
      ParallelFifthsOrOctaves() => style.parallelPenalty,
      UnresolvedTendencyTone() => style.tendencyTonePenalty,
      UnrecoveredLeap() => style.leapPenalty,
      VoiceCrossing() => style.crossingPenalty,
    };
    score += penalty;
  }

  // 4. Ordering: voices should not cross (lower index = lower pitch).
  for (var i = 0; i < n - 1; i++) {
    if (to.pitches[i].semitones > to.pitches[i + 1].semitones) {
      score += 100; // hard penalty — this isn't a voicing, it's a mess
    }
  }

  // 5. All chord tones should be represented (no doublings that omit a tone).
  final representedPCs =
      to.pitches.map((p) => p.pitchClass).toSet();
  final requiredPCs = to.symbol.pitchClasses.toSet();
  final missing = requiredPCs.difference(representedPCs).length;
  score += missing * 5.0; // penalty for missing chord tones

  return score;
}

// ─── Realizing a full progression ───────────────────────────────────────────

/// Voice-lead an entire harmonic progression, producing a sequence of voicings.
///
/// Starting from [initialVoicing], each chord in [progression] is voiced
/// by finding the smoothest connection from the previous voicing.
///
/// Returns the list of voicings and any issues detected. The issues list
/// is useful for both automated refinement and pedagogical feedback
/// ("here's why your part-writing lost a mark").
({List<Voicing> voicings, List<(int, VoiceLeadingIssue)> issues})
    realizeProgression({
  required Voicing initialVoicing,
  required List<ChordSymbol> progression,
  required List<VoiceRange> ranges,
  VoiceLeadingStyle style = VoiceLeadingStyle.classical,
}) {
  final voicings = <Voicing>[initialVoicing];
  final allIssues = <(int, VoiceLeadingIssue)>[];

  for (var i = 0; i < progression.length; i++) {
    final next = leadTo(
      current: voicings.last,
      target: progression[i],
      ranges: ranges,
      style: style,
    );

    if (next == null) {
      // Can't voice this chord — use the previous voicing as fallback
      // (a real system would try respacing or voice exchange)
      voicings.add(voicings.last);
      continue;
    }

    // Record issues for this transition.
    final issues = analyzeVoiceLeading(voicings.last, next);
    for (final issue in issues) {
      allIssues.add((i, issue));
    }

    voicings.add(next);
  }

  return (voicings: voicings, issues: allIssues);
}

/// Convert a realized progression of voicings into Music values.
///
/// Each voicing becomes a Chord in the music algebra. The chords are
/// arranged sequentially with the given [chordDuration].
///
/// This is the bridge from the voice-leading engine back to the
/// general Music algebra — once you have Music, you can layer melodies
/// on top, transpose the whole thing, etc.
Music voicingsToMusic(List<Voicing> voicings, Duration chordDuration) {
  return voicings
      .map((v) => Chord(
            pitches: v.pitches,
            duration: chordDuration,
          ).asMusic)
      .toList()
      .sequential;
}
