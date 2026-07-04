import '../../domain/board_cell_position.dart';
import '../deconstructors/chunk_signature.dart';
import '../deconstructors/deconstruction_quality_validator.dart';
import '../deconstructors/puzzle_deconstructor.dart';
import '../models/puzzle_definition.dart';

class PuzzleDefinitionValidationResult {
  const PuzzleDefinitionValidationResult({
    required this.isValid,
    this.reason,
  });

  final bool isValid;
  final String? reason;
}

class PuzzleDefinitionValidator {
  const PuzzleDefinitionValidator({
    DeconstructionQualityValidator qualityValidator =
        const DeconstructionQualityValidator(),
  }) : _qualityValidator = qualityValidator;

  final DeconstructionQualityValidator _qualityValidator;

  PuzzleDefinitionValidationResult validate(PuzzleDefinition definition) {
    final layout = definition.puzzleLayout;
    final deconstructed = definition.toDeconstructedPuzzle();

    final layoutCells = {
      for (final cell in layout.occupiedCells)
        BoardCellPosition(row: cell.row, col: cell.col): cell.letter,
    };

    final chunkCells = <BoardCellPosition, String>{};
    for (final chunk in deconstructed.chunks) {
      for (final entry in chunk.solvedCells.entries) {
        if (chunkCells.containsKey(entry.key)) {
          return PuzzleDefinitionValidationResult(
            isValid: false,
            reason: 'Duplicate cell ${entry.key} in chunks',
          );
        }
        chunkCells[entry.key] = entry.value;
      }
    }

    if (chunkCells.length != layoutCells.length) {
      return PuzzleDefinitionValidationResult(
        isValid: false,
        reason:
            'Chunk coverage mismatch: ${chunkCells.length} vs ${layoutCells.length}',
      );
    }

    for (final entry in layoutCells.entries) {
      if (chunkCells[entry.key]?.toUpperCase() != entry.value.toUpperCase()) {
        return PuzzleDefinitionValidationResult(
          isValid: false,
          reason: 'Letter mismatch at ${entry.key}',
        );
      }
    }

    for (final chunk in deconstructed.chunks) {
      if (!PuzzleDeconstructor.isConnectedCellSet(
        chunk.solvedCells.keys.toSet(),
      )) {
        return PuzzleDefinitionValidationResult(
          isValid: false,
          reason: 'Chunk ${chunk.id} is disconnected',
        );
      }
    }

    final signatures = deconstructed.chunks
        .map(signatureFromChunk)
        .toList();
    if (signatures.toSet().length != signatures.length) {
      return PuzzleDefinitionValidationResult(
        isValid: false,
        reason: 'Duplicate chunk signatures',
      );
    }

    if (!_qualityValidator.isValid(
      layout: layout,
      deconstructed: deconstructed,
    )) {
      return PuzzleDefinitionValidationResult(
        isValid: false,
        reason: 'Failed deconstruction quality validation',
      );
    }

    return const PuzzleDefinitionValidationResult(isValid: true);
  }
}
