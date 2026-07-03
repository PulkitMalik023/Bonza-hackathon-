import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/core/constants/board_constants.dart';
import 'package:jam_pro/features/puzzle/data/deconstructors/puzzle_deconstructor.dart';
import 'package:jam_pro/features/puzzle/data/generators/puzzle_layout_generator.dart';
import 'package:jam_pro/features/puzzle/domain/grid_layout.dart';
import 'package:jam_pro/features/puzzle/domain/chunk_drop_evaluator.dart';
import 'package:jam_pro/features/puzzle/domain/piece_cell.dart';
import 'package:jam_pro/features/puzzle/domain/puzzle_piece.dart';
import 'package:jam_pro/features/puzzle/presentation/puzzle_tray_layout.dart';

void main() {
  final generator = PuzzleLayoutGenerator();
  final deconstructor = PuzzleDeconstructor();
  final trayService = ChunkTrayLayoutService();

  group('ChunkTrayLayoutService', () {
    test('fits all chunks within fixed board canvas bounds', () {
      final layout = generator.generateAllLayouts(['NORTH', 'SOUTH', 'EAST', 'WEST']).first;
      final deconstructed = deconstructor.build(layout);
      const boardRows = BoardConstants.kPlayGridRows;
      const boardCols = BoardConstants.kPlayGridCols;

      final result = trayService.compute(
        boardRows: boardRows,
        boardCols: boardCols,
        chunks: deconstructed.chunks,
        tileSize: 48,
      );
      final pieces = trayService.buildPieces(
        chunks: deconstructed.chunks,
        layout: result,
      );

      expect(result.canvasRows, boardRows);
      expect(result.canvasCols, boardCols);
      expect(result.fitsInBoard, isTrue);
      expect(
        allPiecesFitCanvas(
          pieces: pieces,
          canvasRows: result.canvasRows,
          canvasCols: result.canvasCols,
        ),
        isTrue,
      );

      for (final piece in pieces) {
        expect(piece.anchorRow, greaterThanOrEqualTo(0));
        expect(piece.anchorRow, lessThan(boardRows));
        expect(piece.anchorCol, greaterThanOrEqualTo(0));
        expect(piece.anchorCol, lessThan(boardCols));
      }
    });

    test('spawn positions do not overlap for directions puzzle', () {
      final layout = generator.generateAllLayouts(['NORTH', 'SOUTH', 'EAST', 'WEST']).first;
      final deconstructed = deconstructor.build(layout);
      const boardRows = BoardConstants.kPlayGridRows;
      const boardCols = BoardConstants.kPlayGridCols;

      final result = trayService.compute(
        boardRows: boardRows,
        boardCols: boardCols,
        chunks: deconstructed.chunks,
        tileSize: 48,
      );
      final pieces = trayService.buildPieces(
        chunks: deconstructed.chunks,
        layout: result,
      );

      for (var i = 0; i < pieces.length; i++) {
        for (var j = i + 1; j < pieces.length; j++) {
          expect(
            piecesOverlapAtSpawn(pieces[i], pieces[j]),
            isFalse,
            reason: 'Pieces $i and $j overlap at spawn',
          );
        }
      }
    });

    test('planets layout keeps canvas equal to board dimensions', () {
      final layout = generator
          .generateAllLayouts(['VENUS', 'NEPTUNE', 'MARS', 'SATURN', 'JUPITER'])
          .first;
      final deconstructed = deconstructor.build(layout);
      const boardRows = BoardConstants.kPlayGridRows;
      const boardCols = BoardConstants.kPlayGridCols;

      final result = trayService.compute(
        boardRows: boardRows,
        boardCols: boardCols,
        chunks: deconstructed.chunks,
        tileSize: 48,
      );

      expect(result.canvasRows, boardRows);
      expect(result.canvasCols, boardCols);
      expect(result.anchors, hasLength(deconstructed.chunks.length));
    });

    test('respects viewport by preferring compact layout when constrained', () {
      final layout = generator
          .generateAllLayouts(['VENUS', 'NEPTUNE', 'MARS', 'SATURN', 'JUPITER'])
          .first;
      final deconstructed = deconstructor.build(layout);
      const boardRows = BoardConstants.kPlayGridRows;
      const boardCols = BoardConstants.kPlayGridCols;

      final unconstrained = trayService.compute(
        boardRows: boardRows,
        boardCols: boardCols,
        chunks: deconstructed.chunks,
        tileSize: 48,
      );

      final constrained = trayService.compute(
        boardRows: boardRows,
        boardCols: boardCols,
        chunks: deconstructed.chunks,
        tileSize: 48,
        viewportSize: const Size(400, 900),
      );

      expect(unconstrained.canvasRows, boardRows);
      expect(constrained.canvasRows, boardRows);
      expect(constrained.fitsInBoard, isTrue);
    });

    test('all chunks visible in viewport after centering for directions puzzle', () {
      final layout = generator.generateAllLayouts(['NORTH', 'SOUTH', 'EAST', 'WEST']).first;
      final deconstructed = deconstructor.build(layout);
      const boardRows = BoardConstants.kPlayGridRows;
      const boardCols = BoardConstants.kPlayGridCols;
      const viewportSize = Size(400, 700);
      final tileSize = min(
        viewportSize.width / boardCols,
        viewportSize.height / boardRows,
      );

      final result = trayService.compute(
        boardRows: boardRows,
        boardCols: boardCols,
        chunks: deconstructed.chunks,
        tileSize: tileSize,
        viewportSize: viewportSize,
      );

      expect(result.canvasCols * tileSize, lessThanOrEqualTo(viewportSize.width));
      expect(result.canvasRows * tileSize, lessThanOrEqualTo(viewportSize.height));
      expect(
        allChunksVisibleAfterCentering(
          chunks: deconstructed.chunks,
          anchors: result.anchors,
          canvasRows: result.canvasRows,
          canvasCols: result.canvasCols,
          tileSize: tileSize,
          viewportSize: viewportSize,
        ),
        isTrue,
      );
    });

    test('prefers fewer chunks per row for narrow viewport when possible', () {
      final layout = generator.generateAllLayouts(['NORTH', 'SOUTH', 'EAST', 'WEST']).first;
      final deconstructed = deconstructor.build(layout);
      const boardRows = BoardConstants.kPlayGridRows;
      const boardCols = BoardConstants.kPlayGridCols;
      const wideViewport = Size(500, 900);
      const narrowViewport = Size(360, 900);
      final wideTileSize = min(
        wideViewport.width / boardCols,
        wideViewport.height / boardRows,
      );
      final narrowTileSize = min(
        narrowViewport.width / boardCols,
        narrowViewport.height / boardRows,
      );

      final wide = trayService.compute(
        boardRows: boardRows,
        boardCols: boardCols,
        chunks: deconstructed.chunks,
        tileSize: wideTileSize,
        viewportSize: wideViewport,
      );

      final narrow = trayService.compute(
        boardRows: boardRows,
        boardCols: boardCols,
        chunks: deconstructed.chunks,
        tileSize: narrowTileSize,
        viewportSize: narrowViewport,
      );

      expect(narrow.canvasCols * narrowTileSize, lessThanOrEqualTo(narrowViewport.width));
      expect(narrow.canvasRows, boardRows);
      expect(narrow.canvasCols, boardCols);
      expect(
        allChunksVisibleAfterCentering(
          chunks: deconstructed.chunks,
          anchors: narrow.anchors,
          canvasRows: narrow.canvasRows,
          canvasCols: narrow.canvasCols,
          tileSize: narrowTileSize,
          viewportSize: narrowViewport,
        ),
        isTrue,
      );
      expect(wide.fitsInBoard, isTrue);
      expect(narrow.fitsInBoard, isTrue);
    });
  });

  group('canPlaceOnBoard', () {
    test('rejects placements outside board bounds', () {
      final piece = PuzzlePiece(
        id: 'p1',
        chunkId: 'c1',
        anchorRow: 0,
        anchorCol: 0,
        spawnAnchorRow: 5,
        spawnAnchorCol: 0,
        cells: const [
          PieceCell(letter: 'A', rowOffset: 0, colOffset: 0),
          PieceCell(letter: 'B', rowOffset: 0, colOffset: 1),
        ],
      );

      expect(
        canPlaceOnBoard(
          movingPiece: piece,
          targetAnchorRow: 0,
          targetAnchorCol: 4,
          boardRows: 4,
          boardCols: 4,
          pieces: [piece],
        ),
        isFalse,
      );
    });

    test('rejects overlapping board placements', () {
      final pieceA = PuzzlePiece(
        id: 'a',
        chunkId: 'ca',
        anchorRow: 0,
        anchorCol: 0,
        spawnAnchorRow: 5,
        spawnAnchorCol: 0,
        cells: const [PieceCell(letter: 'A', rowOffset: 0, colOffset: 0)],
      );
      final pieceB = PuzzlePiece(
        id: 'b',
        chunkId: 'cb',
        anchorRow: 0,
        anchorCol: 0,
        spawnAnchorRow: 5,
        spawnAnchorCol: 2,
        cells: const [PieceCell(letter: 'B', rowOffset: 0, colOffset: 0)],
      );

      expect(
        canPlaceOnBoard(
          movingPiece: pieceB,
          targetAnchorRow: 0,
          targetAnchorCol: 0,
          boardRows: 4,
          boardCols: 4,
          pieces: [pieceA, pieceB],
        ),
        isFalse,
      );
    });
  });

  group('GridLayout snap', () {
    test('snapCellFromTopLeft clamps to canvas grid', () {
      final grid = GridLayout.fromBoardSize(
        boardSize: const Size(480, 480),
        tileSize: 48,
      );

      final snapped = grid.snapCellFromTopLeft(const Offset(500, 500));
      expect(snapped.row, 9);
      expect(snapped.col, 9);
    });
  });
}
