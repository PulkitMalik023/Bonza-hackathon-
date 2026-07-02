import '../data/models/puzzle_chunk.dart';
import 'board_cell_position.dart';
import 'piece_cell.dart';
import 'puzzle_piece_state.dart';

class PuzzlePiece {
  PuzzlePiece({
    required this.id,
    required this.chunkId,
    required this.anchorRow,
    required this.anchorCol,
    required this.spawnAnchorRow,
    required this.spawnAnchorCol,
    required this.cells,
    this.isCompletedWordGroup = false,
    this.completedWordKey,
    this.completedAnswers = const {},
  });

  final String id;
  final String chunkId;
  int anchorRow;
  int anchorCol;
  final int spawnAnchorRow;
  final int spawnAnchorCol;
  final List<PieceCell> cells;
  final bool isCompletedWordGroup;
  final String? completedWordKey;
  final Set<String> completedAnswers;

  List<BoardCellPosition> getOccupiedCells() =>
      getOccupiedCellsAt(anchorRow, anchorCol);

  List<BoardCellPosition> getOccupiedCellsAt(int anchorRow, int anchorCol) =>
      cells
          .map(
            (cell) => BoardCellPosition(
              row: anchorRow + cell.rowOffset,
              col: anchorCol + cell.colOffset,
            ),
          )
          .toList();

  factory PuzzlePiece.fromChunk(
    PuzzleChunk chunk, {
    required int anchorRow,
    required int anchorCol,
  }) {
    final cells = chunk.localCells.entries
        .map(
          (entry) => PieceCell(
            letter: entry.value,
            rowOffset: entry.key.row,
            colOffset: entry.key.col,
          ),
        )
        .toList();

    return PuzzlePiece(
      id: chunk.id,
      chunkId: chunk.id,
      anchorRow: anchorRow,
      anchorCol: anchorCol,
      spawnAnchorRow: anchorRow,
      spawnAnchorCol: anchorCol,
      cells: cells,
    );
  }

  factory PuzzlePiece.fromPieceState(PuzzlePieceState state) {
    return PuzzlePiece(
      id: state.id,
      chunkId: state.id,
      anchorRow: state.anchorRow,
      anchorCol: state.anchorCol,
      spawnAnchorRow: state.spawnAnchorRow,
      spawnAnchorCol: state.spawnAnchorCol,
      cells: state.localCells,
    );
  }

  factory PuzzlePiece.completedWordGroup({
    required String wordKey,
    required int anchorRow,
    required int anchorCol,
    required List<PieceCell> cells,
  }) {
    return PuzzlePiece.completedClusterGroup(
      clusterKey: wordKey,
      anchorRow: anchorRow,
      anchorCol: anchorCol,
      cells: cells,
      completedAnswers: {wordKey},
    );
  }

  factory PuzzlePiece.completedClusterGroup({
    required String clusterKey,
    required int anchorRow,
    required int anchorCol,
    required List<PieceCell> cells,
    required Set<String> completedAnswers,
  }) {
    return PuzzlePiece(
      id: 'completed_$clusterKey',
      chunkId: 'completed_$clusterKey',
      anchorRow: anchorRow,
      anchorCol: anchorCol,
      spawnAnchorRow: anchorRow,
      spawnAnchorCol: anchorCol,
      cells: cells,
      isCompletedWordGroup: true,
      completedWordKey: clusterKey,
      completedAnswers: completedAnswers,
    );
  }
}
