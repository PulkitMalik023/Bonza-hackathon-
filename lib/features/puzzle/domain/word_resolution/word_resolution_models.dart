import '../board_cell_position.dart';
import '../puzzle_piece.dart';

enum WordOrientation { horizontal, vertical }

extension WordOrientationCode on WordOrientation {
  String get code => this == WordOrientation.horizontal ? 'H' : 'V';
}

enum AssignmentType { strictFinal, flexibleIndependent, latentInventory }

class FinalLayoutWord {
  const FinalLayoutWord({
    required this.wordId,
    required this.text,
    required this.cellIds,
    required this.orientation,
  });

  final String wordId;
  final String text;
  final List<String> cellIds;
  final WordOrientation orientation;
}

class FinalLayoutCell {
  const FinalLayoutCell({
    required this.id,
    required this.row,
    required this.col,
    required this.letter,
    required this.wordIds,
  });

  final String id;
  final int row;
  final int col;
  final String letter;
  final List<String> wordIds;
}

class ChunkCoverageEntry {
  const ChunkCoverageEntry({
    required this.chunkId,
    required this.cellIdsForThisWord,
  });

  final String chunkId;
  final List<String> cellIdsForThisWord;
}

class OrderedBoardCell {
  const OrderedBoardCell({
    required this.finalCellId,
    required this.boardRow,
    required this.boardCol,
    required this.chunkId,
    required this.componentId,
    required this.letter,
  });

  final String finalCellId;
  final int boardRow;
  final int boardCol;
  final String chunkId;
  final String componentId;
  final String letter;
}

class CandidateWordInstance {
  const CandidateWordInstance({
    required this.text,
    required this.orientation,
    required this.orderedBoardCells,
    required this.finalCellIds,
    required this.chunkIds,
    required this.componentIds,
  });

  final String text;
  final String orientation;
  final List<OrderedBoardCell> orderedBoardCells;
  final List<String> finalCellIds;
  final List<String> chunkIds;
  final List<String> componentIds;

  String get dedupeKey => '$orientation:${finalCellIds.join(',')}';
}

class PlacedRuntimeCell {
  const PlacedRuntimeCell({
    required this.finalCellId,
    required this.letter,
    required this.boardRow,
    required this.boardCol,
    required this.chunkId,
    required this.componentId,
  });

  final String finalCellId;
  final String letter;
  final int boardRow;
  final int boardCol;
  final String chunkId;
  final String componentId;
}

class RuntimeComponent {
  const RuntimeComponent({
    required this.componentId,
    required this.finalCellIds,
    required this.chunkIds,
  });

  final String componentId;
  final List<String> finalCellIds;
  final List<String> chunkIds;
}

class BoardCellEntry {
  const BoardCellEntry({
    required this.finalCellId,
    required this.letter,
    required this.chunkId,
    required this.componentId,
  });

  final String finalCellId;
  final String letter;
  final String chunkId;
  final String componentId;
}

class SolvedAssignment {
  const SolvedAssignment({
    required this.wordId,
    required this.assignedCellIds,
    this.moveComponentId,
  });

  final String wordId;
  final Set<String> assignedCellIds;
  final String? moveComponentId;
}

class WordAssignmentOption {
  const WordAssignmentOption({
    required this.wordId,
    required this.reservedFinalCellIds,
    required this.contributingFinalCellIds,
    required this.contributingChunkIds,
    required this.contributingComponentIds,
    required this.assignmentType,
    required this.debugReason,
    this.groupedBoardCells,
  });

  final String wordId;
  final List<String> reservedFinalCellIds;
  final List<String> contributingFinalCellIds;
  final List<String> contributingChunkIds;
  final List<String> contributingComponentIds;
  final AssignmentType assignmentType;
  final String debugReason;
  final List<OrderedBoardCell>? groupedBoardCells;
}

class WordResolutionOptions {
  const WordResolutionOptions({
    this.candidateWordInstances = const [],
    this.affectedComponentIds = const {},
    this.flexibleEnabled = true,
  });

  final List<CandidateWordInstance> candidateWordInstances;
  final Set<String> affectedComponentIds;
  final bool flexibleEnabled;
}

class MoveCluster {
  const MoveCluster({
    required this.moveComponentId,
    required this.assignmentWordIds,
    required this.reservedCellIds,
    required this.contributingComponentIds,
    required this.contributingChunkIds,
  });

  final String moveComponentId;
  final List<String> assignmentWordIds;
  final Set<String> reservedCellIds;
  final Set<String> contributingComponentIds;
  final Set<String> contributingChunkIds;
}

class WordResolutionResult {
  const WordResolutionResult({
    required this.pieces,
    required this.solvedWordIds,
    required this.reservedCellIds,
    required this.solvedAssignments,
    required this.newlySolvedWordIds,
    required this.puzzleComplete,
    required this.completedAnswers,
  });

  final List<PuzzlePiece> pieces;
  final Set<String> solvedWordIds;
  final Set<String> reservedCellIds;
  final Map<String, SolvedAssignment> solvedAssignments;
  final Set<String> newlySolvedWordIds;
  final bool puzzleComplete;
  final Set<String> completedAnswers;

  bool get hasChanges => newlySolvedWordIds.isNotEmpty;
}

String finalCellIdForLayout(int row, int col) => 'final_${row}_$col';

List<BoardCellPosition> boardPositionsFromFinalCellIds(
  Iterable<String> cellIds,
  Map<String, FinalLayoutCell> finalCellById,
) {
  return [
    for (final id in cellIds)
      if (finalCellById.containsKey(id))
        BoardCellPosition(
          row: finalCellById[id]!.row,
          col: finalCellById[id]!.col,
        ),
  ];
}
