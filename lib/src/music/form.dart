/// Form — the large-scale architecture of a composition.
///
/// If Music is sentences and Phrase is paragraphs, Form is the essay
/// structure: introduction, body, conclusion; or more precisely,
/// exposition, development, recapitulation.
///
/// Musical form has a fascinating property: it's simultaneously
/// **prescriptive** (sonata form has expected sections) and **emergent**
/// (the form arises from how themes are deployed). A sonata isn't a
/// template to fill in — it's a dramatic argument that certain structural
/// habits tend to produce.
///
/// This module models form as a tree of labeled, typed sections that can
/// reference thematic material. The key insight: sections relate to each
/// other through **thematic transformation**. The B section of an ABA
/// form isn't just "different music" — it's music that *contrasts with* A
/// in specific ways (different key, different texture, different character),
/// and the return of A is meaningful *because* B happened.
library;

import 'music.dart';
import 'motif.dart';
import 'harmony.dart';
import 'duration.dart';

// ─── Section: the building block of form ────────────────────────────────────

/// A labeled section of music, potentially containing subsections.
///
/// Sections are the "chapters" of a piece. They can be atomic (a single
/// passage of music) or compound (containing other sections). This
/// recursive structure mirrors how form actually works:
///
///   Sonata Form
///   ├── Exposition
///   │   ├── First Theme Group
///   │   ├── Transition
///   │   └── Second Theme Group
///   ├── Development
///   │   ├── First Episode
///   │   └── Second Episode
///   └── Recapitulation
///       ├── First Theme Group (tonic)
///       └── Second Theme Group (tonic)
///
/// Each section carries its thematic and harmonic content, plus metadata
/// about its structural role.
final class Section {
  /// The label: "A", "B", "exposition", "verse 1", "development", etc.
  final String label;

  /// The structural role this section plays.
  final SectionRole role;

  /// The music content of this section (null if this section is purely
  /// a container for subsections).
  final Music? music;

  /// Ordered subsections, if this is a compound section.
  final List<Section> subsections;

  /// The primary thematic material used in this section.
  /// A section might use the "fate motif" or the "second theme" —
  /// tracking this enables automatic form analysis.
  final List<Motif> themes;

  /// The harmonic area (key center) of this section.
  /// In sonata form, the exposition's second theme group is typically
  /// in the dominant; tracking this is essential for formal analysis.
  final Scale? keyArea;

  /// How this section relates to a previous section, if at all.
  /// "A'" is a varied return of "A"; the development transforms
  /// exposition material; etc.
  final SectionRelation? relation;

  const Section({
    required this.label,
    this.role = SectionRole.body,
    this.music,
    this.subsections = const [],
    this.themes = const [],
    this.keyArea,
    this.relation,
  });

  /// Total duration: either the music's duration or the sum of subsections.
  Duration get totalDuration {
    if (music != null) return music!.totalDuration;
    if (subsections.isEmpty) return Duration.zero;
    return subsections.fold(
        Duration.zero, (sum, s) => sum + s.totalDuration);
  }

  /// Flatten all music content into a single sequential Music value.
  Music get flattenedMusic {
    if (music != null) return music!;
    return subsections.map((s) => s.flattenedMusic).toList().sequential;
  }

  /// Whether this section is a return/reprise of an earlier section.
  bool get isReprise =>
      relation?.type == RelationType.literalReturn ||
      relation?.type == RelationType.variedReturn;

  /// Whether this section is developmental (transforming earlier material).
  bool get isDevelopmental => role == SectionRole.development;

  @override
  String toString() {
    if (subsections.isEmpty) return label;
    return '$label { ${subsections.map((s) => s.label).join(' | ')} }';
  }
}

/// The structural role a section plays within the larger form.
///
/// This goes beyond just labeling — it captures the *function* of the
/// section. An introduction prepares; a transition connects; a coda
/// concludes. The function is what makes formal analysis useful:
/// you can ask "where does the development begin?" regardless of what
/// the composer called it.
enum SectionRole {
  /// Sets the stage — establishes tempo, key, mood before the main material.
  introduction,

  /// Presents thematic material for the first time.
  exposition,

  /// The main body — neither intro nor conclusion.
  body,

  /// Connects two sections, often modulating between key areas.
  transition,

  /// Transforms, fragments, and recombines previously heard material.
  development,

  /// Returns to previously heard material (possibly varied).
  recapitulation,

  /// Concluding material — wraps up, often with finality gestures.
  coda,

  /// A contrasting middle section (as in ABA form).
  contrasting,

  /// A refrain or chorus — material that returns unchanged between verses.
  refrain,
}

/// How one section relates to another — the "because" of form.
///
/// Musical form gets its expressive power from relationships between
/// sections. A return isn't just "playing A again" — it's "playing A
/// in the context of having heard B." The meaning is in the relationship.
final class SectionRelation {
  /// Which earlier section this relates to (by label).
  final String relatedTo;

  /// The type of relationship.
  final RelationType type;

  /// What changed, if this is a varied return.
  final List<Transformation> transformations;

  const SectionRelation({
    required this.relatedTo,
    required this.type,
    this.transformations = const [],
  });
}

enum RelationType {
  /// Exact repetition: the A in ABA. Same notes, same everything.
  literalReturn,

  /// Varied return: A' — recognizably the same material, but altered.
  /// (Reharmonized, re-orchestrated, with added ornamentation, etc.)
  variedReturn,

  /// Developmental: uses material from the related section but transforms
  /// it beyond easy recognition. Fragments, sequences, modulations.
  developmental,

  /// Contrasting: deliberately *different* from the related section.
  /// The B in ABA isn't random — it contrasts with A in specific ways.
  contrasting,

  /// Transitional: bridges from one section to another, potentially
  /// using material from either or both.
  bridging,
}

/// A named transformation applied to thematic material.
///
/// When a section returns in varied form, the transformations describe
/// *how* it changed. This is useful both for analysis ("the recap
/// re-harmonizes the second theme in the tonic") and for generation
/// ("create a varied return by applying these transformations").
enum Transformation {
  /// Moved to a different key.
  transposed,

  /// Re-voiced or re-orchestrated (same notes, different instruments/texture).
  reorchestrated,

  /// Melodic embellishment added (ornaments, passing tones, fills).
  ornamented,

  /// Harmony changed while melody stays recognizable.
  reharmonized,

  /// Rhythmic values altered (augmented, diminished, syncopated).
  rhythmicallyAltered,

  /// Melodic contour inverted.
  inverted,

  /// Played in reverse.
  retrograded,

  /// Only a portion of the original is used.
  fragmented,

  /// The theme appears in a different voice or register.
  registrallyDisplaced,

  /// The texture has changed (homophonic → polyphonic, etc.).
  texturallyAltered,

  /// Dynamic profile changed.
  dynamicallyAltered,
}

// ─── Common formal archetypes ───────────────────────────────────────────────

/// A formal archetype — a template for the large-scale structure of a piece.
///
/// These aren't rigid molds; they're *conventions* that composers use as
/// starting points. The interest in any particular piece comes from how
/// it departs from the archetype, not how faithfully it follows it.
///
/// Using these as templates for generation:
/// ```dart
/// final form = FormArchetype.sonatina;
/// final sections = form.instantiate(
///   themes: [firstTheme, secondTheme],
///   keys: [Scale.cMajor, Scale.gMajor],
/// );
/// ```
final class FormArchetype {
  final String name;
  final List<SectionTemplate> sections;

  const FormArchetype(this.name, this.sections);

  // ─── Binary form: AB ──────────────────────────────────────────────────

  static final binary = FormArchetype('Binary (AB)', [
    SectionTemplate('A', SectionRole.exposition,
        keyRelation: KeyRelation.tonic),
    SectionTemplate('B', SectionRole.contrasting,
        keyRelation: KeyRelation.dominant),
  ]);

  // ─── Ternary form: ABA ────────────────────────────────────────────────

  static final ternary = FormArchetype('Ternary (ABA)', [
    SectionTemplate('A', SectionRole.exposition,
        keyRelation: KeyRelation.tonic),
    SectionTemplate('B', SectionRole.contrasting,
        keyRelation: KeyRelation.relativeMinor),
    SectionTemplate('A\'', SectionRole.recapitulation,
        keyRelation: KeyRelation.tonic,
        relatedTo: 'A',
        relationType: RelationType.variedReturn),
  ]);

  // ─── Rondo: ABACA ────────────────────────────────────────────────────

  static final rondo = FormArchetype('Rondo (ABACA)', [
    SectionTemplate('A', SectionRole.refrain,
        keyRelation: KeyRelation.tonic),
    SectionTemplate('B', SectionRole.contrasting,
        keyRelation: KeyRelation.dominant),
    SectionTemplate('A', SectionRole.refrain,
        keyRelation: KeyRelation.tonic,
        relatedTo: 'A',
        relationType: RelationType.literalReturn),
    SectionTemplate('C', SectionRole.contrasting,
        keyRelation: KeyRelation.subdominant),
    SectionTemplate('A', SectionRole.refrain,
        keyRelation: KeyRelation.tonic,
        relatedTo: 'A',
        relationType: RelationType.literalReturn),
  ]);

  // ─── Sonata form ────────────────────────────────────────────────────

  /// The crown jewel of Western formal architecture. The dramatic arc:
  /// present two contrasting ideas in different keys → develop them
  /// through fragmentation, modulation, and recombination → resolve
  /// the tonal conflict by bringing both ideas into the home key.
  static final sonata = FormArchetype('Sonata', [
    SectionTemplate('Introduction', SectionRole.introduction,
        keyRelation: KeyRelation.tonic),
    SectionTemplate('Exposition: 1st theme', SectionRole.exposition,
        keyRelation: KeyRelation.tonic),
    SectionTemplate('Exposition: transition', SectionRole.transition),
    SectionTemplate('Exposition: 2nd theme', SectionRole.exposition,
        keyRelation: KeyRelation.dominant),
    SectionTemplate('Development', SectionRole.development),
    SectionTemplate('Recap: 1st theme', SectionRole.recapitulation,
        keyRelation: KeyRelation.tonic,
        relatedTo: 'Exposition: 1st theme',
        relationType: RelationType.variedReturn),
    SectionTemplate('Recap: 2nd theme', SectionRole.recapitulation,
        keyRelation: KeyRelation.tonic,  // ← the crucial difference
        relatedTo: 'Exposition: 2nd theme',
        relationType: RelationType.variedReturn),
    SectionTemplate('Coda', SectionRole.coda,
        keyRelation: KeyRelation.tonic),
  ]);

  // ─── 12-bar blues ────────────────────────────────────────────────────

  static final blues12Bar = FormArchetype('12-Bar Blues', [
    SectionTemplate('Bars 1-4: I', SectionRole.exposition,
        keyRelation: KeyRelation.tonic),
    SectionTemplate('Bars 5-6: IV', SectionRole.contrasting,
        keyRelation: KeyRelation.subdominant),
    SectionTemplate('Bars 7-8: I', SectionRole.body,
        keyRelation: KeyRelation.tonic,
        relatedTo: 'Bars 1-4: I',
        relationType: RelationType.variedReturn),
    SectionTemplate('Bars 9-10: V-IV', SectionRole.transition,
        keyRelation: KeyRelation.dominant),
    SectionTemplate('Bars 11-12: I (turnaround)', SectionRole.coda,
        keyRelation: KeyRelation.tonic),
  ]);

  // ─── Verse-chorus (pop) ───────────────────────────────────────────────

  static final verseChorus = FormArchetype('Verse-Chorus', [
    SectionTemplate('Intro', SectionRole.introduction,
        keyRelation: KeyRelation.tonic),
    SectionTemplate('Verse 1', SectionRole.exposition,
        keyRelation: KeyRelation.tonic),
    SectionTemplate('Chorus', SectionRole.refrain,
        keyRelation: KeyRelation.tonic),
    SectionTemplate('Verse 2', SectionRole.body,
        keyRelation: KeyRelation.tonic,
        relatedTo: 'Verse 1',
        relationType: RelationType.variedReturn),
    SectionTemplate('Chorus', SectionRole.refrain,
        keyRelation: KeyRelation.tonic,
        relatedTo: 'Chorus',
        relationType: RelationType.literalReturn),
    SectionTemplate('Bridge', SectionRole.contrasting,
        keyRelation: KeyRelation.subdominant),
    SectionTemplate('Chorus (final)', SectionRole.refrain,
        keyRelation: KeyRelation.tonic,
        relatedTo: 'Chorus',
        relationType: RelationType.variedReturn),
    SectionTemplate('Outro', SectionRole.coda,
        keyRelation: KeyRelation.tonic),
  ]);

  @override
  String toString() => '$name: ${sections.map((s) => s.label).join(' → ')}';
}

/// A template for a section within a formal archetype.
final class SectionTemplate {
  final String label;
  final SectionRole role;
  final KeyRelation? keyRelation;
  final String? relatedTo;
  final RelationType? relationType;

  const SectionTemplate(
    this.label,
    this.role, {
    this.keyRelation,
    this.relatedTo,
    this.relationType,
  });
}

/// How a section's key relates to the home key.
///
/// Tonal music is a drama of keys: departure from and return to tonic.
/// These relationships define the harmonic large-structure.
enum KeyRelation {
  /// The home key — where tension resolves.
  tonic,

  /// A fifth above tonic — the primary contrast key in major-mode pieces.
  dominant,

  /// A fourth above tonic — the "warm" departure.
  subdominant,

  /// The parallel minor or major (C major → C minor).
  parallel,

  /// The relative minor or major (C major → A minor).
  relativeMinor,

  /// A remote key — mediant, flat submediant, tritone away, etc.
  remote,
}

// ─── Form analysis ──────────────────────────────────────────────────────────

/// Analyze a sequence of sections and attempt to identify the formal archetype.
///
/// This is pattern matching at the structural level: given a list of section
/// labels and roles, which formal template does this piece most resemble?
///
/// Returns the best matching archetype and a confidence score (0.0 to 1.0).
/// Low confidence means the piece has an unusual or innovative form — which
/// is not a problem, just a finding.
({FormArchetype archetype, double confidence}) analyzeForm(
    List<Section> sections) {
  final archetypes = [
    FormArchetype.binary,
    FormArchetype.ternary,
    FormArchetype.rondo,
    FormArchetype.sonata,
    FormArchetype.blues12Bar,
    FormArchetype.verseChorus,
  ];

  var bestMatch = archetypes.first;
  var bestScore = 0.0;

  for (final archetype in archetypes) {
    final score = _matchScore(sections, archetype);
    if (score > bestScore) {
      bestScore = score;
      bestMatch = archetype;
    }
  }

  return (archetype: bestMatch, confidence: bestScore);
}

double _matchScore(List<Section> sections, FormArchetype archetype) {
  // Simple heuristic: compare section count, roles, and return patterns.
  var score = 0.0;
  final templateLen = archetype.sections.length;
  final actualLen = sections.length;

  // Penalty for length mismatch.
  if (templateLen == 0) return 0;
  final lengthRatio = actualLen / templateLen;
  score += (1.0 - (lengthRatio - 1.0).abs()).clamp(0.0, 1.0) * 0.3;

  // Role matching: what fraction of roles match?
  var roleMatches = 0;
  final minLen = actualLen < templateLen ? actualLen : templateLen;
  for (var i = 0; i < minLen; i++) {
    if (sections[i].role == archetype.sections[i].role) roleMatches++;
  }
  if (minLen > 0) score += (roleMatches / minLen) * 0.4;

  // Return pattern: do returns match?
  var returnMatches = 0;
  var returnCount = 0;
  for (var i = 0; i < minLen; i++) {
    if (archetype.sections[i].relatedTo != null) {
      returnCount++;
      if (sections[i].isReprise) returnMatches++;
    }
  }
  if (returnCount > 0) score += (returnMatches / returnCount) * 0.3;

  return score;
}
