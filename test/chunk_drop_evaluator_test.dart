import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/core/constants/board_constants.dart';
import 'package:jam_pro/features/puzzle/domain/board_cell_position.dart';
import 'package:jam_pro/features/puzzle/domain/board_occupancy.dart';
import 'package:jam_pro/features/puzzle/domain/chunk_drop_evaluator.dart';
import 'package:jam_pro/features/puzzle/domain/piece_cell.dart';
import 'package:jam_pro/features/puzzle/domain/puzzle_piece.dart';

PuzzlePiece _twoCellPiece({
  required String id,
  required int anchorRow,
  required int anchorCol,
  required int spawnRow,
  required int spawnCol,
}) {
  return PuzzlePiece(
    id: id,
    chunkId: 'chunk_$id',
    anchorRow: anchorRow,
    anchorCol: anchorCol,
    spawnAnchorRow: spawnRow,
    spawnAnchorCol: spawnCol,
    cells: const [
      PieceCell(letter: 'A', rowOffset: 0, colOffset: 0),
      PieceCell(letter: 'B', rowOffset: 0, colOffset: 1),
    ],
  );
}

void main() {
  const boardRows = 4;
  const boardCols = 4;
  const tileSize = BoardConstants.kBoardTileSize;

  group('evaluateChunkDrop', () {
    test('snaps multi-cell chunk when overlapping empty board cell', () {
      final piece = _twoCellPiece(
        id: 'p1',
        anchorRow: 6,
        anchorCol: 0,
        spawnRow: 6,
        spawnCol: 0,
      );
      final occupancy = BoardOccupancy();
      final topLeft = Offset(1 * tileSize, 0);

      final result = evaluateChunkDrop(
        droppedTopLeft: topLeft,
        piece: piece,
        occupancy: occupancy,
        boardRows: boardRows,
        boardCols: boardCols,
        tileSize: tileSize,
      );

      expect(result.action, ChunkDropAction.snap);
      expect(result.overlapsBoard, isTrue);
      expect(result.targetAnchor, isNotNull);
      expect(result.occupied, isFalse);
    });

    test('rejects when mapped cells would be out of bounds', () {
      final piece = _twoCellPiece(
        id: 'p1',
        anchorRow: 6,
        anchorCol: 0,
        spawnRow: 6,
        spawnCol: 0,
      );
      final occupancy = BoardOccupancy();
      final topLeft = Offset(3 * tileSize, 0);

      final result = evaluateChunkDrop(
        droppedTopLeft: topLeft,
        piece: piece,
        occupancy: occupancy,
        boardRows: boardRows,
        boardCols: boardCols,
        tileSize: tileSize,
      );

      expect(result.action, ChunkDropAction.returnToOrigin);
      expect(result.insideBoard, isFalse);
    });

    test('rejects when target cells are occupied by another piece', () {
      final pieceA = PuzzlePiece(
        id: 'a',
        chunkId: 'ca',
        anchorRow: 0,
        anchorCol: 0,
        spawnAnchorRow: 6,
        spawnAnchorCol: 0,
        cells: const [PieceCell(letter: 'A', rowOffset: 0, colOffset: 0)],
      );
      final pieceB = _twoCellPiece(
        id: 'b',
        anchorRow: 6,
        anchorCol: 0,
        spawnRow: 6,
        spawnCol: 2,
      );
      final occupancy = BoardOccupancy()
        ..rebuildFromPieces([pieceA], boardRows: boardRows, boardCols: boardCols);

      final result = evaluateChunkDrop(
        droppedTopLeft: Offset.zero,
        piece: pieceB,
        occupancy: occupancy,
        boardRows: boardRows,
        boardCols: boardCols,
        tileSize: tileSize,
      );

      expect(result.action, ChunkDropAction.returnToOrigin);
      expect(result.occupied, isTrue);
    });

    test('rejects when fully in tray with no board overlap', () {
      final piece = _twoCellPiece(
        id: 'p1',
        anchorRow: 6,
        anchorCol: 0,
        spawnRow: 6,
        spawnCol: 0,
      );
      final occupancy = BoardOccupancy();
      final topLeft = Offset(0, boardRows * tileSize + tileSize);

      final result = evaluateChunkDrop(
        droppedTopLeft: topLeft,
        piece: piece,
        occupancy: occupancy,
        boardRows: boardRows,
        boardCols: boardCols,
        tileSize: tileSize,
      );

      expect(result.action, ChunkDropAction.returnToOrigin);
      expect(result.overlapsBoard, isFalse);
      expect(result.targetAnchor, isNull);
    });

    test('snaps full-board piece at origin to anchor (0, 0)', () {
      final cells = <PieceCell>[];
      for (var row = 0; row < boardRows; row++) {
        for (var col = 0; col < boardCols; col++) {
          cells.add(
            PieceCell(
              letter: 'X',
              rowOffset: row,
              colOffset: col,
            ),
          );
        }
      }

      final piece = PuzzlePiece(
        id: 'solved_piece',
        chunkId: 'solved_piece',
        anchorRow: 0,
        anchorCol: 0,
        spawnAnchorRow: 0,
        spawnAnchorCol: 0,
        cells: cells,
      );
      final occupancy = BoardOccupancy();

      final result = evaluateChunkDrop(
        droppedTopLeft: Offset.zero,
        piece: piece,
        occupancy: occupancy,
        boardRows: boardRows,
        boardCols: boardCols,
        tileSize: tileSize,
      );

      expect(result.insideBoard, isTrue);
      expect(result.action, ChunkDropAction.snap);
      expect(result.targetAnchor, const BoardCellPosition(row: 0, col: 0));
    });

    test('accepts drop when tile overlaps board bottom row but center is below board', () {
      final piece = PuzzlePiece(
        id: 'p1',
        chunkId: 'c1',
        anchorRow: 6,
        anchorCol: 0,
        spawnAnchorRow: 6,
        spawnAnchorCol: 0,
        cells: const [PieceCell(letter: 'A', rowOffset: 0, colOffset: 0)],
      );
      final occupancy = BoardOccupancy();
      final topLeft = Offset(
        1 * tileSize,
        (boardRows - 1) * tileSize + tileSize * 0.6,
      );

      final result = evaluateChunkDrop(
        droppedTopLeft: topLeft,
        piece: piece,
        occupancy: occupancy,
        boardRows: boardRows,
        boardCols: boardCols,
        tileSize: tileSize,
      );

      expect(result.overlapsBoard, isTrue);
      expect(result.action, ChunkDropAction.snap);
      expect(
        result.targetAnchor,
        const BoardCellPosition(row: boardRows - 1, col: 1),
      );
    });
  });
}
