import '../models/puzzle_layout.dart';
import 'deconstruction_quality_validator.dart';
import 'puzzle_deconstructor.dart';

/// Picks puzzle layouts whose deconstruction passes quality rules.
class PuzzleLayoutSelector {
  PuzzleLayoutSelector({
    DeconstructionQualityValidator validator = const DeconstructionQualityValidator(),
    PuzzleDeconstructor? deconstructor,
  })  : _validator = validator,
        _deconstructor = deconstructor ?? PuzzleDeconstructor();

  final DeconstructionQualityValidator _validator;
  final PuzzleDeconstructor _deconstructor;

  List<PuzzleLayout> prioritizeValidDeconstructionLayouts(
    List<PuzzleLayout> layouts,
  ) {
    if (layouts.isEmpty) {
      return layouts;
    }

    final valid = <PuzzleLayout>[];
    final invalid = <PuzzleLayout>[];

    for (final layout in layouts) {
      final deconstructed = _deconstructor.tryBuild(layout);
      if (deconstructed != null &&
          _validator.isValid(layout: layout, deconstructed: deconstructed)) {
        valid.add(layout);
      } else {
        invalid.add(layout);
      }
    }

    if (valid.isEmpty) {
      return layouts;
    }

    return [...valid, ...invalid];
  }

  bool hasValidDeconstruction(PuzzleLayout layout) {
    final deconstructed = _deconstructor.tryBuild(layout);
    if (deconstructed == null) {
      return false;
    }

    return _validator.isValid(layout: layout, deconstructed: deconstructed);
  }
}
