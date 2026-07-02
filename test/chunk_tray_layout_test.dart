import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
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
    test('fits all chunks within computed canvas bounds', () {
      final layout = generator.generateAllLayouts(['NORTH', 'SOUTH', 'EAST', 'WEST']).first;
      final deconstructed = deconstructor.build(layout);
      final boardRows = layout.maxRow - layout.minRow + 1;
      final boardCols = layout.maxCol - layout.minCol + 1;

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

      expect(result.canvasCols, greaterThanOrEqualTo(boardCols));
      expect(
        allPiecesFitCanvas(
          pieces: pieces,
          canvasRows: result.canvasRows,
          canvasCols: result.canvasCols,
        ),
        isTrue,
      );

      for (var index = 0; index < pieces.length; index++) {
        expect(pieces[index].anchorRow, greaterThanOrEqualTo(boardRows + 1));
      }
    });

    test('spawn positions do not overlap for directions puzzle', () {
      final layout = generator.generateAllLayouts(['NORTH', 'SOUTH', 'EAST', 'WEST']).first;
      final deconstructed = deconstructor.build(layout);
      final boardRows = layout.maxRow - layout.minRow + 1;
      final boardCols = layout.maxCol - layout.minCol + 1;

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

    test('planets layout uses expanded canvas width', () {
      final layout = generator
          .generateAllLayouts(['VENUS', 'NEPTUNE', 'MARS', 'SATURN', 'JUPITER'])
          .first;
      final deconstructed = deconstructor.build(layout);
      final boardRows = layout.maxRow - layout.minRow + 1;
      final boardCols = layout.maxCol - layout.minCol + 1;

      final result = trayService.compute(
        boardRows: boardRows,
        boardCols: boardCols,
        chunks: deconstructed.chunks,
        tileSize: 48,
      );

      expect(result.canvasCols, greaterThanOrEqualTo(boardCols));
      expect(result.anchors, hasLength(deconstructed.chunks.length));
    });

    test('respects viewport by preferring compact layout when constrained', () {
      final layout = generator
          .generateAllLayouts(['VENUS', 'NEPTUNE', 'MARS', 'SATURN', 'JUPITER'])
          .first;
      final deconstructed = deconstructor.build(layout);
      final boardRows = layout.maxRow - layout.minRow + 1;
      final boardCols = layout.maxCol - layout.minCol + 1;

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

      final unconstrainedArea = unconstrained.canvasRows * unconstrained.canvasCols;
      final constrainedArea = constrained.canvasRows * constrained.canvasCols;
      expect(constrainedArea, lessThanOrEqualTo(unconstrainedArea));
    });

    test('all chunks visible in viewport after centering for directions puzzle', () {
      final layout = generator.generateAllLayouts(['NORTH', 'SOUTH', 'EAST', 'WEST']).first;
      final deconstructed = deconstructor.build(layout);
      final boardRows = layout.maxRow - layout.minRow + 1;
      final boardCols = layout.maxCol - layout.minCol + 1;
      const tileSize = 48.0;
      const viewportSize = Size(400, 700);

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
      final boardRows = layout.maxRow - layout.minRow + 1;
      final boardCols = layout.maxCol - layout.minCol + 1;
      const tileSize = 48.0;

      final wide = trayService.compute(
        boardRows: boardRows,
        boardCols: boardCols,
        chunks: deconstructed.chunks,
        tileSize: tileSize,
        viewportSize: const Size(500, 900),
      );

      final narrow = trayService.compute(
        boardRows: boardRows,
        boardCols: boardCols,
        chunks: deconstructed.chunks,
        tileSize: tileSize,
        viewportSize: const Size(360, 900),
      );

      expect(narrow.canvasCols * tileSize, lessThanOrEqualTo(360));
      expect(
        allChunksVisibleAfterCentering(
          chunks: deconstructed.chunks,
          anchors: narrow.anchors,
          canvasRows: narrow.canvasRows,
          canvasCols: narrow.canvasCols,
          tileSize: tileSize,
          viewportSize: const Size(360, 900),
        ),
        isTrue,
      );
      expect(
        narrow.canvasCols * narrow.canvasRows,
        lessThanOrEqualTo(wide.canvasCols * wide.canvasRows),
      );
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
