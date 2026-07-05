import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/domain/piece_cell.dart';
import 'package:jam_pro/features/puzzle/domain/piece_spawn_layout.dart';
import 'package:jam_pro/features/puzzle/domain/puzzle_piece.dart';

void main() {
  group('computeRandomScatter', () {
    test('places pieces without overlap for seeded layout', () {
      final pieces = [
        PuzzlePiece(
          id: 'a',
          chunkId: 'a',
          anchorRow: 0,
          anchorCol: 0,
          spawnAnchorRow: 0,
          spawnAnchorCol: 0,
          cells: const [
            PieceCell(letter: 'A', rowOffset: 0, colOffset: 0),
            PieceCell(letter: 'B', rowOffset: 0, colOffset: 1),
          ],
        ),
        PuzzlePiece(
          id: 'b',
          chunkId: 'b',
          anchorRow: 0,
          anchorCol: 0,
          spawnAnchorRow: 0,
          spawnAnchorCol: 0,
          cells: const [
            PieceCell(letter: 'C', rowOffset: 0, colOffset: 0),
          ],
        ),
      ];

      final result = computeRandomScatter(
        pieces: pieces,
        canvasRows: 8,
        canvasCols: 8,
        random: Random(99),
      );

      expect(result.mode, ScatterPlacementMode.random);
      expect(result.anchors.length, 2);

      final placed = applySpawnAnchors(pieces, result.anchors);
      expect(pieceSpawnAnchorsAreNonOverlapping(placed), isTrue);
      expect(
        piecesFitCanvas(
          pieces: placed,
          canvasRows: 8,
          canvasCols: 8,
        ),
        isTrue,
      );
      expect(
        piecesHaveSpawnSeparation(pieces: placed),
        isTrue,
      );
    });

    test('keeps at least one empty cell between chunk tiles', () {
      final pieces = [
        PuzzlePiece(
          id: 'gr',
          chunkId: 'gr',
          anchorRow: 0,
          anchorCol: 0,
          spawnAnchorRow: 0,
          spawnAnchorCol: 0,
          cells: const [
            PieceCell(letter: 'G', rowOffset: 0, colOffset: 0),
            PieceCell(letter: 'R', rowOffset: 1, colOffset: 0),
          ],
        ),
        PuzzlePiece(
          id: 'n',
          chunkId: 'n',
          anchorRow: 0,
          anchorCol: 0,
          spawnAnchorRow: 0,
          spawnAnchorCol: 0,
          cells: const [
            PieceCell(letter: 'N', rowOffset: 0, colOffset: 0),
          ],
        ),
        PuzzlePiece(
          id: 'ue',
          chunkId: 'ue',
          anchorRow: 0,
          anchorCol: 0,
          spawnAnchorRow: 0,
          spawnAnchorCol: 0,
          cells: const [
            PieceCell(letter: 'U', rowOffset: 0, colOffset: 0),
            PieceCell(letter: 'E', rowOffset: 0, colOffset: 1),
          ],
        ),
      ];

      final result = computeRandomScatter(
        pieces: pieces,
        canvasRows: 10,
        canvasCols: 10,
        random: Random(7),
      );

      expect(result.mode, ScatterPlacementMode.random);
      final placed = applySpawnAnchors(pieces, result.anchors);
      expect(piecesHaveSpawnSeparation(pieces: placed), isTrue);
    });

    test('Spectrum-scale scatter places 12 pieces on 16x12 grid', () {
      final pieces = [
        PuzzlePiece(
          id: 'yebl',
          chunkId: 'yebl',
          anchorRow: 0,
          anchorCol: 0,
          spawnAnchorRow: 0,
          spawnAnchorCol: 0,
          cells: const [
            PieceCell(letter: 'Y', rowOffset: 0, colOffset: 1),
            PieceCell(letter: 'E', rowOffset: 1, colOffset: 1),
            PieceCell(letter: 'B', rowOffset: 2, colOffset: 0),
            PieceCell(letter: 'L', rowOffset: 2, colOffset: 1),
          ],
        ),
        PuzzlePiece(
          id: 'n',
          chunkId: 'n',
          anchorRow: 0,
          anchorCol: 0,
          spawnAnchorRow: 0,
          spawnAnchorCol: 0,
          cells: const [PieceCell(letter: 'N', rowOffset: 0, colOffset: 0)],
        ),
        PuzzlePiece(
          id: 'ian',
          chunkId: 'ian',
          anchorRow: 0,
          anchorCol: 0,
          spawnAnchorRow: 0,
          spawnAnchorCol: 0,
          cells: const [
            PieceCell(letter: 'I', rowOffset: 0, colOffset: 1),
            PieceCell(letter: 'A', rowOffset: 1, colOffset: 0),
            PieceCell(letter: 'N', rowOffset: 1, colOffset: 1),
          ],
        ),
        PuzzlePiece(
          id: 'et',
          chunkId: 'et',
          anchorRow: 0,
          anchorCol: 0,
          spawnAnchorRow: 0,
          spawnAnchorCol: 0,
          cells: const [
            PieceCell(letter: 'E', rowOffset: 0, colOffset: 0),
            PieceCell(letter: 'T', rowOffset: 0, colOffset: 1),
          ],
        ),
        PuzzlePiece(
          id: 'gee',
          chunkId: 'gee',
          anchorRow: 0,
          anchorCol: 0,
          spawnAnchorRow: 0,
          spawnAnchorCol: 0,
          cells: const [
            PieceCell(letter: 'G', rowOffset: 0, colOffset: 0),
            PieceCell(letter: 'E', rowOffset: 0, colOffset: 1),
            PieceCell(letter: 'E', rowOffset: 1, colOffset: 1),
          ],
        ),
        PuzzlePiece(
          id: 'vi',
          chunkId: 'vi',
          anchorRow: 0,
          anchorCol: 0,
          spawnAnchorRow: 0,
          spawnAnchorCol: 0,
          cells: const [
            PieceCell(letter: 'V', rowOffset: 0, colOffset: 0),
            PieceCell(letter: 'I', rowOffset: 0, colOffset: 1),
          ],
        ),
        PuzzlePiece(
          id: 'ue',
          chunkId: 'ue',
          anchorRow: 0,
          anchorCol: 0,
          spawnAnchorRow: 0,
          spawnAnchorCol: 0,
          cells: const [
            PieceCell(letter: 'U', rowOffset: 0, colOffset: 0),
            PieceCell(letter: 'E', rowOffset: 0, colOffset: 1),
          ],
        ),
        PuzzlePiece(
          id: 'gr',
          chunkId: 'gr',
          anchorRow: 0,
          anchorCol: 0,
          spawnAnchorRow: 0,
          spawnAnchorCol: 0,
          cells: const [
            PieceCell(letter: 'G', rowOffset: 0, colOffset: 0),
            PieceCell(letter: 'R', rowOffset: 1, colOffset: 0),
          ],
        ),
        PuzzlePiece(
          id: 'ed',
          chunkId: 'ed',
          anchorRow: 0,
          anchorCol: 0,
          spawnAnchorRow: 0,
          spawnAnchorCol: 0,
          cells: const [
            PieceCell(letter: 'E', rowOffset: 0, colOffset: 0),
            PieceCell(letter: 'D', rowOffset: 0, colOffset: 1),
          ],
        ),
        PuzzlePiece(
          id: 'di',
          chunkId: 'di',
          anchorRow: 0,
          anchorCol: 0,
          spawnAnchorRow: 0,
          spawnAnchorCol: 0,
          cells: const [
            PieceCell(letter: 'D', rowOffset: 0, colOffset: 0),
            PieceCell(letter: 'I', rowOffset: 1, colOffset: 0),
          ],
        ),
        PuzzlePiece(
          id: 'lorw',
          chunkId: 'lorw',
          anchorRow: 0,
          anchorCol: 0,
          spawnAnchorRow: 0,
          spawnAnchorCol: 0,
          cells: const [
            PieceCell(letter: 'L', rowOffset: 0, colOffset: 0),
            PieceCell(letter: 'O', rowOffset: 1, colOffset: 0),
            PieceCell(letter: 'R', rowOffset: 1, colOffset: 1),
            PieceCell(letter: 'W', rowOffset: 2, colOffset: 0),
          ],
        ),
        PuzzlePiece(
          id: 'gol',
          chunkId: 'gol',
          anchorRow: 0,
          anchorCol: 0,
          spawnAnchorRow: 0,
          spawnAnchorCol: 0,
          cells: const [
            PieceCell(letter: 'G', rowOffset: 0, colOffset: 0),
            PieceCell(letter: 'O', rowOffset: 1, colOffset: 0),
            PieceCell(letter: 'L', rowOffset: 1, colOffset: 1),
          ],
        ),
      ];

      final result = computeRandomScatter(
        pieces: pieces,
        canvasRows: 16,
        canvasCols: 12,
        random: Random(42),
      );

      expect(result.anchors.length, pieces.length);
      final placed = applySpawnAnchors(pieces, result.anchors);
      expect(pieceSpawnAnchorsAreNonOverlapping(placed), isTrue);
      expect(
        piecesFitCanvas(
          pieces: placed,
          canvasRows: 16,
          canvasCols: 12,
        ),
        isTrue,
      );

      if (result.mode == ScatterPlacementMode.random) {
        expect(piecesHaveSpawnSeparation(pieces: placed), isTrue);
      }
    });

    test('falls back to tray when random scatter cannot place all pieces', () {
      final pieces = [
        for (var i = 0; i < 6; i++)
          PuzzlePiece(
            id: 'piece_$i',
            chunkId: 'piece_$i',
            anchorRow: 0,
            anchorCol: 0,
            spawnAnchorRow: 0,
            spawnAnchorCol: 0,
            cells: const [
              PieceCell(letter: 'X', rowOffset: 0, colOffset: 0),
              PieceCell(letter: 'Y', rowOffset: 0, colOffset: 1),
              PieceCell(letter: 'Z', rowOffset: 0, colOffset: 2),
            ],
          ),
      ];

      final result = computeRandomScatter(
        pieces: pieces,
        canvasRows: 4,
        canvasCols: 4,
        random: Random(1),
      );

      expect(result.mode, ScatterPlacementMode.trayFallback);
      expect(result.anchors.length, pieces.length);
    });
  });
}
