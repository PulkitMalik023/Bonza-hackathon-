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
