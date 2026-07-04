import 'dart:math';

import '../../domain/board_cell_position.dart';
import '../models/deconstructed_puzzle.dart';
import '../models/puzzle_chunk.dart';
import '../models/puzzle_layout.dart';

/// Deconstructs a solved [PuzzleLayout] into connected draggable chunks.
class PuzzleDeconstructor {
  static const _maxChunkSize = 3;

  DeconstructedPuzzle build(PuzzleLayout layout) {
    final letterMap = _buildLetterMap(layout);
    final remainingCells = letterMap.keys.toSet();
    final chunks = <PuzzleChunk>[];
    final signature = PuzzleLayout.signature(layout);
    final random = Random(signature.hashCode);

    var chunkIndex = 0;
    while (remainingCells.isNotEmpty) {
      final seed = _pickSeedCell(remainingCells);
      final targetSize = _pickTargetSize(
        remainingCells.length,
        random,
      );

      final candidate = _growChunkCandidate(
        seed: seed,
        remainingCells: remainingCells,
        targetSize: targetSize,
        random: random,
      );

      if (candidate != null && isValidChunkCandidate(
        candidate: candidate,
        remainingCells: remainingCells,
      )) {
        chunks.add(
          buildChunkFromCells(
            id: 'chunk_$chunkIndex',
            chunkCells: candidate,
            letterMap: letterMap,
          ),
        );
        remainingCells.removeAll(candidate);
        chunkIndex++;
        continue;
      }

      final fallback = _findValidFallbackChunk(
        remainingCells: remainingCells,
        random: random,
      );

      if (fallback == null) {
        throw StateError(
          'Failed to deconstruct layout: ${PuzzleLayout.signature(layout)}',
        );
      }

      chunks.add(
        buildChunkFromCells(
          id: 'chunk_$chunkIndex',
          chunkCells: fallback,
          letterMap: letterMap,
        ),
      );
      remainingCells.removeAll(fallback);
      chunkIndex++;
    }

    return DeconstructedPuzzle(
      sourceLayout: layout,
      chunks: List.unmodifiable(chunks),
    );
  }

  DeconstructedPuzzle? tryBuild(PuzzleLayout layout) {
    try {
      return build(layout);
    } on StateError {
      return null;
    }
  }

  Map<BoardCellPosition, String> _buildLetterMap(PuzzleLayout layout) {
    final letterMap = <BoardCellPosition, String>{};
    for (final cell in layout.occupiedCells) {
      letterMap[BoardCellPosition(row: cell.row, col: cell.col)] = cell.letter;
    }
    return letterMap;
  }

  BoardCellPosition _pickSeedCell(Set<BoardCellPosition> cells) {
    final sorted = cells.toList()
      ..sort((a, b) {
        final rowCompare = a.row.compareTo(b.row);
        if (rowCompare != 0) {
          return rowCompare;
        }
        return a.col.compareTo(b.col);
      });
    return sorted.first;
  }

  int _pickTargetSize(int remainingCount, Random random) {
    if (remainingCount <= 1) {
      return 1;
    }
    if (remainingCount == 2) {
      return 2;
    }
    return 2 + random.nextInt(2);
  }

  Set<BoardCellPosition>? _growChunkCandidate({
    required BoardCellPosition seed,
    required Set<BoardCellPosition> remainingCells,
    required int targetSize,
    required Random random,
  }) {
    if (!remainingCells.contains(seed)) {
      return null;
    }

    final candidate = <BoardCellPosition>{seed};
    final frontier = <BoardCellPosition>[seed];

    while (candidate.length < targetSize && frontier.isNotEmpty) {
      final neighbors = <BoardCellPosition>[];
      for (final cell in frontier) {
        for (final adjacent in getAdjacentCells(cell)) {
          if (remainingCells.contains(adjacent) &&
              !candidate.contains(adjacent)) {
            neighbors.add(adjacent);
          }
        }
      }

      if (neighbors.isEmpty) {
        break;
      }

      neighbors.sort((a, b) {
        final rowCompare = a.row.compareTo(b.row);
        if (rowCompare != 0) {
          return rowCompare;
        }
        return a.col.compareTo(b.col);
      });

      final pickIndex = random.nextInt(neighbors.length);
      final next = neighbors[pickIndex];
      candidate.add(next);
      frontier.add(next);
    }

    if (candidate.length == 1 && remainingCells.length > 1) {
      return null;
    }

    return candidate;
  }

  Set<BoardCellPosition>? _findValidFallbackChunk({
    required Set<BoardCellPosition> remainingCells,
    required Random random,
  }) {
    final sortedSeeds = remainingCells.toList()
      ..sort((a, b) {
        final rowCompare = a.row.compareTo(b.row);
        if (rowCompare != 0) {
          return rowCompare;
        }
        return a.col.compareTo(b.col);
      });

    for (final seed in sortedSeeds) {
      for (var size = _maxChunkSize; size >= 1; size--) {
        final candidate = _growChunkCandidate(
          seed: seed,
          remainingCells: remainingCells,
          targetSize: size,
          random: random,
        );
        if (candidate != null &&
            isValidChunkCandidate(
              candidate: candidate,
              remainingCells: remainingCells,
            )) {
          return candidate;
        }
      }
    }

    return null;
  }

  static List<BoardCellPosition> getAdjacentCells(BoardCellPosition cell) {
    return [
      BoardCellPosition(row: cell.row - 1, col: cell.col),
      BoardCellPosition(row: cell.row + 1, col: cell.col),
      BoardCellPosition(row: cell.row, col: cell.col - 1),
      BoardCellPosition(row: cell.row, col: cell.col + 1),
    ];
  }

  static bool isConnectedCellSet(Set<BoardCellPosition> cells) {
    if (cells.isEmpty) {
      return true;
    }
    if (cells.length == 1) {
      return true;
    }

    final visited = <BoardCellPosition>{cells.first};
    final queue = <BoardCellPosition>[cells.first];

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      for (final neighbor in getAdjacentCells(current)) {
        if (cells.contains(neighbor) && visited.add(neighbor)) {
          queue.add(neighbor);
        }
      }
    }

    return visited.length == cells.length;
  }

  static bool isValidChunkCandidate({
    required Set<BoardCellPosition> candidate,
    required Set<BoardCellPosition> remainingCells,
  }) {
    if (candidate.isEmpty || !remainingCells.containsAll(candidate)) {
      return false;
    }

    if (!isConnectedCellSet(candidate)) {
      return false;
    }

    final remainder = remainingCells.difference(candidate);
    if (remainder.isEmpty) {
      return true;
    }

    return isConnectedCellSet(remainder);
  }

  static PuzzleChunk buildChunkFromCells({
    required String id,
    required Set<BoardCellPosition> chunkCells,
    required Map<BoardCellPosition, String> letterMap,
  }) {
    var minRow = chunkCells.first.row;
    var maxRow = chunkCells.first.row;
    var minCol = chunkCells.first.col;
    var maxCol = chunkCells.first.col;

    final solvedCells = <BoardCellPosition, String>{};
    for (final cell in chunkCells) {
      solvedCells[cell] = letterMap[cell]!;
      minRow = min(minRow, cell.row);
      maxRow = max(maxRow, cell.row);
      minCol = min(minCol, cell.col);
      maxCol = max(maxCol, cell.col);
    }

    final localCells = <BoardCellPosition, String>{};
    for (final entry in solvedCells.entries) {
      localCells[BoardCellPosition(
        row: entry.key.row - minRow,
        col: entry.key.col - minCol,
      )] = entry.value;
    }

    return PuzzleChunk(
      id: id,
      solvedCells: Map.unmodifiable(solvedCells),
      localCells: Map.unmodifiable(localCells),
      solvedMinRow: minRow,
      solvedMinCol: minCol,
      solvedMaxRow: maxRow,
      solvedMaxCol: maxCol,
      width: maxCol - minCol + 1,
      height: maxRow - minRow + 1,
    );
  }
}
