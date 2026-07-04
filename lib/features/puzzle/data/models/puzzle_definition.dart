import '../../domain/board_cell_position.dart';
import '../deconstructors/puzzle_deconstructor.dart';
import 'deconstructed_puzzle.dart';
import 'placed_word.dart';
import 'puzzle_layout.dart';

class PuzzleDefinitionCell {
  const PuzzleDefinitionCell({
    required this.row,
    required this.col,
    required this.letter,
  });

  final int row;
  final int col;
  final String letter;

  factory PuzzleDefinitionCell.fromJson(Map<String, dynamic> json) {
    return PuzzleDefinitionCell(
      row: json['row'] as int,
      col: json['col'] as int,
      letter: json['letter'] as String,
    );
  }

  BoardCellPosition get position => BoardCellPosition(row: row, col: col);
}

class PuzzleDefinitionPlacement {
  const PuzzleDefinitionPlacement({
    required this.word,
    required this.row,
    required this.col,
    required this.direction,
  });

  final String word;
  final int row;
  final int col;
  final WordDirection direction;

  factory PuzzleDefinitionPlacement.fromJson(Map<String, dynamic> json) {
    return PuzzleDefinitionPlacement(
      word: (json['word'] as String).toUpperCase(),
      row: json['row'] as int,
      col: json['col'] as int,
      direction: _parseDirection(json['direction'] as String),
    );
  }

  PlacedWord toPlacedWord() {
    return PlacedWord(
      word: word,
      row: row,
      col: col,
      direction: direction,
    );
  }

  static WordDirection _parseDirection(String raw) {
    switch (raw.toLowerCase()) {
      case 'h':
      case 'horizontal':
        return WordDirection.horizontal;
      case 'v':
      case 'vertical':
        return WordDirection.vertical;
      default:
        throw FormatException('Unknown word direction: $raw');
    }
  }
}

class PuzzleDefinitionChunk {
  const PuzzleDefinitionChunk({
    required this.id,
    required this.cells,
  });

  final String id;
  final List<PuzzleDefinitionCell> cells;

  factory PuzzleDefinitionChunk.fromJson(Map<String, dynamic> json) {
    final cellsJson = json['cells'];
    if (cellsJson is! List) {
      throw FormatException('Expected chunk cells list for ${json['id']}');
    }

    return PuzzleDefinitionChunk(
      id: json['id'] as String,
      cells: cellsJson
          .map(
            (entry) =>
                PuzzleDefinitionCell.fromJson(entry as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class PuzzleDefinitionLayout {
  const PuzzleDefinitionLayout({
    required this.placements,
    required this.cells,
  });

  final List<PuzzleDefinitionPlacement> placements;
  final List<PuzzleDefinitionCell> cells;

  factory PuzzleDefinitionLayout.fromJson(Map<String, dynamic> json) {
    final placementsJson = json['placements'];
    final cellsJson = json['cells'];
    if (placementsJson is! List || cellsJson is! List) {
      throw const FormatException('Invalid puzzle definition layout');
    }

    return PuzzleDefinitionLayout(
      placements: placementsJson
          .map(
            (entry) => PuzzleDefinitionPlacement.fromJson(
              entry as Map<String, dynamic>,
            ),
          )
          .toList(),
      cells: cellsJson
          .map(
            (entry) =>
                PuzzleDefinitionCell.fromJson(entry as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  PuzzleLayout toPuzzleLayout() {
    return PuzzleLayout.fromPlacedWords(
      placements.map((placement) => placement.toPlacedWord()).toList(),
    );
  }
}

class PuzzleDefinition {
  const PuzzleDefinition({
    required this.puzzleId,
    required this.layout,
    required this.chunks,
  });

  final int puzzleId;
  final PuzzleDefinitionLayout layout;
  final List<PuzzleDefinitionChunk> chunks;

  factory PuzzleDefinition.fromJson(Map<String, dynamic> json) {
    final puzzleIdRaw = json['puzzleId'];
    final puzzleId = switch (puzzleIdRaw) {
      int value => value,
      String value => int.parse(value),
      _ => throw FormatException('Invalid puzzleId: $puzzleIdRaw'),
    };

    final chunksJson = json['chunks'];
    if (chunksJson is! List) {
      throw FormatException('Expected chunks list for puzzle $puzzleId');
    }

    return PuzzleDefinition(
      puzzleId: puzzleId,
      layout: PuzzleDefinitionLayout.fromJson(
        json['layout'] as Map<String, dynamic>,
      ),
      chunks: chunksJson
          .map(
            (entry) =>
                PuzzleDefinitionChunk.fromJson(entry as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  PuzzleLayout get puzzleLayout => layout.toPuzzleLayout();

  DeconstructedPuzzle toDeconstructedPuzzle() {
    final sourceLayout = puzzleLayout;
    final letterMap = {
      for (final cell in layout.cells)
        cell.position: cell.letter,
    };

    final puzzleChunks = chunks.map((chunk) {
      final chunkCells = chunk.cells.map((cell) => cell.position).toSet();
      return PuzzleDeconstructor.buildChunkFromCells(
        id: chunk.id,
        chunkCells: chunkCells,
        letterMap: letterMap,
      );
    }).toList();

    return DeconstructedPuzzle(
      sourceLayout: sourceLayout,
      chunks: List.unmodifiable(puzzleChunks),
    );
  }
}
