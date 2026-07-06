import '../generators/puzzle_layout_generator.dart';
import '../models/puzzle_content.dart';
import '../models/deconstructed_puzzle.dart';
import '../models/puzzle_layout.dart';
import 'deconstruction_quality_validator.dart';
import 'puzzle_deconstructor.dart';
import 'puzzle_layout_selector.dart';
import 'puzzle_solvability_auditor.dart';

class PuzzleFeasibilityReport {
  const PuzzleFeasibilityReport({
    required this.id,
    required this.category,
    required this.words,
    required this.canGenerateLayout,
    required this.canDeconstruct,
    required this.canSolve,
    required this.layoutCount,
    required this.validLayoutCount,
    this.failureReason,
  });

  final int id;
  final String category;
  final List<String> words;
  final bool canGenerateLayout;
  final bool canDeconstruct;
  final bool canSolve;
  final String? failureReason;
  final int layoutCount;
  final int validLayoutCount;

  bool get isPlayable => canGenerateLayout && canDeconstruct && canSolve;
}

class PuzzleFeasibilityAuditor {
  PuzzleFeasibilityAuditor({
    PuzzleLayoutGenerator? layoutGenerator,
    PuzzleDeconstructor? deconstructor,
    PuzzleLayoutSelector? layoutSelector,
    DeconstructionQualityValidator? validator,
    PuzzleSolvabilityAuditor? solvabilityAuditor,
  })  : _layoutGenerator = layoutGenerator ?? PuzzleLayoutGenerator(),
        _deconstructor = deconstructor ?? PuzzleDeconstructor(),
        _layoutSelector = layoutSelector ?? PuzzleLayoutSelector(),
        _validator = validator ?? const DeconstructionQualityValidator(),
        _solvabilityAuditor =
            solvabilityAuditor ?? const PuzzleSolvabilityAuditor();

  final PuzzleLayoutGenerator _layoutGenerator;
  final PuzzleDeconstructor _deconstructor;
  final PuzzleLayoutSelector _layoutSelector;
  final DeconstructionQualityValidator _validator;
  final PuzzleSolvabilityAuditor _solvabilityAuditor;

  List<PuzzleFeasibilityReport> auditAll(List<PuzzleContent> puzzles) {
    return puzzles.map(audit).toList();
  }

  PuzzleFeasibilityReport audit(PuzzleContent puzzle) {
    final layouts = _layoutGenerator.generateAllLayouts(puzzle.words);
    if (layouts.isEmpty) {
      return PuzzleFeasibilityReport(
        id: puzzle.id,
        category: puzzle.category,
        words: puzzle.words,
        canGenerateLayout: false,
        canDeconstruct: false,
        canSolve: false,
        failureReason: 'No crossword layout can be generated from these words',
        layoutCount: 0,
        validLayoutCount: 0,
      );
    }

    var validLayoutCount = 0;
    String? failureReason;

    for (final layout in layouts) {
      final deconstructed = _deconstructor.tryBuild(layout);
      if (deconstructed == null) {
        failureReason ??=
            'No deconstruction satisfies minimum chunk size and unique sub-parts';
        continue;
      }

      if (!_validator.isValid(layout: layout, deconstructed: deconstructed)) {
        failureReason ??= _describeValidationFailure(
          layout: layout,
          deconstructed: deconstructed,
        );
        continue;
      }

      final solvability = _solvabilityAuditor.audit(
        layout: layout,
        deconstructed: deconstructed,
      );
      if (!solvability.isSolvable) {
        failureReason ??= _describeSolvabilityFailure(solvability);
        continue;
      }

      validLayoutCount++;
    }

    final validLayouts = _prioritizeSolvableLayouts(layouts);

    return PuzzleFeasibilityReport(
      id: puzzle.id,
      category: puzzle.category,
      words: puzzle.words,
      canGenerateLayout: true,
      canDeconstruct: validLayoutCount > 0,
      canSolve: validLayoutCount > 0,
      failureReason: validLayoutCount > 0 ? null : failureReason,
      layoutCount: layouts.length,
      validLayoutCount: validLayouts.length,
    );
  }

  List<PuzzleLayout> _prioritizeSolvableLayouts(List<PuzzleLayout> layouts) {
    final valid = <PuzzleLayout>[];

    for (final layout in layouts) {
      final deconstructed = _deconstructor.tryBuild(layout);
      if (deconstructed == null) {
        continue;
      }
      if (!_validator.isValid(layout: layout, deconstructed: deconstructed)) {
        continue;
      }
      final solvability = _solvabilityAuditor.audit(
        layout: layout,
        deconstructed: deconstructed,
      );
      if (solvability.isSolvable) {
        valid.add(layout);
      }
    }

    return valid;
  }

  String _describeValidationFailure({
    required PuzzleLayout layout,
    required DeconstructedPuzzle deconstructed,
  }) {
    if (_validator.hasSingletonChunks(deconstructed)) {
      return 'Deconstruction contains single-letter chunks';
    }
    if (_validator.hasDuplicateChunkSignatures(deconstructed)) {
      return 'Deconstruction contains duplicate sub-parts';
    }
    if (_validator.hasSingletonAndMultiCellLetterConflict(deconstructed)) {
      return 'Deconstruction has ambiguous single-letter chunks';
    }
    if (_validator.hasCrossingCellsInSingletonChunks(layout, deconstructed)) {
      return 'Crossing cells appear in single-letter chunks';
    }
    return 'Deconstruction failed quality validation';
  }

  String _describeSolvabilityFailure(PuzzleSolvabilityReport report) {
    switch (report.failedCheck) {
      case SolvabilityCheckKind.fullLayoutCompletes:
        return report.failureReason ?? 'Full layout does not complete all words';
      case SolvabilityCheckKind.allOrdersSolvable:
        return report.failureReason ?? 'No solvable completion order';
      case SolvabilityCheckKind.noPrematureCompletions:
        return report.failureReason ?? 'Premature word completion detected';
      case null:
        return report.failureReason ?? 'Solvability validation failed';
    }
  }
}
