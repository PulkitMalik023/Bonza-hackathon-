import 'dart:math';

import '../data/models/placed_word.dart';
import '../data/models/puzzle_layout.dart';
import 'board_cell_position.dart';
import 'board_geometry.dart';
import 'piece_cell.dart';
import 'puzzle_piece.dart';

const _colGap = 1;
const _rowGap = 1;

List<PieceCell> cellsForPlacedWord(PlacedWord placed) {
  final word = placed.word.toUpperCase();

  return [
    for (var index = 0; index < word.length; index++)
      switch (placed.direction) {
        WordDirection.horizontal => PieceCell(
            letter: word[index],
            rowOffset: 0,
            colOffset: index,
          ),
        WordDirection.vertical => PieceCell(
            letter: word[index],
            rowOffset: index,
            colOffset: 0,
          ),
      },
  ];
}

List<PuzzlePiece> buildWordPiecesWithoutAnchors(PuzzleLayout layout) {
  final pieces = <PuzzlePiece>[];

  for (var index = 0; index < layout.placedWords.length; index++) {
    final placed = layout.placedWords[index];
    final id = 'word_${index}_${placed.word}';

    pieces.add(
      PuzzlePiece(
        id: id,
        chunkId: id,
        anchorRow: 0,
        anchorCol: 0,
        spawnAnchorRow: 0,
        spawnAnchorCol: 0,
        cells: cellsForPlacedWord(placed),
      ),
    );
  }

  return pieces;
}

List<BoardCellPosition> computeWordSpawnAnchors({
  required List<PuzzlePiece> pieces,
  required int canvasRows,
  required int canvasCols,
}) {
  if (pieces.isEmpty) {
    return const [];
  }

  final anchors = <BoardCellPosition>[];
  var rowStart = canvasRows - 1;
  var colCursor = 0;
  var rowBlockHeight = 1;

  for (final piece in pieces) {
    final size = pieceGridSize(piece);
    final width = size.width.toInt();
    final height = size.height.toInt();

    if (colCursor + width > canvasCols) {
      rowStart -= rowBlockHeight + _rowGap;
      colCursor = 0;
      rowBlockHeight = 1;
    }

    final anchorRow =
        (rowStart - height + 1).clamp(0, max(0, canvasRows - height)).toInt();
    final anchorCol = colCursor.clamp(0, max(0, canvasCols - width)).toInt();

    anchors.add(BoardCellPosition(row: anchorRow, col: anchorCol));

    colCursor += width + _colGap;
    rowBlockHeight = max(rowBlockHeight, height);
  }

  return anchors;
}

List<PuzzlePiece> buildWordPieces({
  required PuzzleLayout layout,
  required int canvasRows,
  required int canvasCols,
}) {
  final pieces = buildWordPiecesWithoutAnchors(layout);
  final anchors = computeWordSpawnAnchors(
    pieces: pieces,
    canvasRows: canvasRows,
    canvasCols: canvasCols,
  );

  final wordPieces = <PuzzlePiece>[];
  for (var index = 0; index < pieces.length; index++) {
    final piece = pieces[index];
    final anchor = anchors[index];

    wordPieces.add(
      PuzzlePiece(
        id: piece.id,
        chunkId: piece.chunkId,
        anchorRow: anchor.row,
        anchorCol: anchor.col,
        spawnAnchorRow: anchor.row,
        spawnAnchorCol: anchor.col,
        cells: piece.cells,
      ),
    );
  }

  return wordPieces;
}

/// Returns true when no two pieces occupy the same board cell at their anchors.
bool wordSpawnAnchorsAreNonOverlapping(List<PuzzlePiece> pieces) {
  final occupied = <BoardCellPosition>{};

  for (final piece in pieces) {
    for (final cell in piece.getOccupiedCells()) {
      if (!occupied.add(cell)) {
        return false;
      }
    }
  }

  return true;
}

/// Returns true when every piece fits fully inside the canvas at its anchor.
bool wordPiecesFitCanvas({
  required List<PuzzlePiece> pieces,
  required int canvasRows,
  required int canvasCols,
}) {
  for (final piece in pieces) {
    for (final cell in piece.getOccupiedCells()) {
      if (cell.row < 0 ||
          cell.row >= canvasRows ||
          cell.col < 0 ||
          cell.col >= canvasCols) {
        return false;
      }
    }
  }

  return true;
}
