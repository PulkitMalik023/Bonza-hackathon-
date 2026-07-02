import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/domain/board_cell_position.dart';
import 'package:jam_pro/features/puzzle/domain/completion_scan_service.dart';
import 'package:jam_pro/features/puzzle/domain/piece_cell.dart';
import 'package:jam_pro/features/puzzle/domain/puzzle_board_state.dart';
import 'package:jam_pro/features/puzzle/domain/puzzle_piece.dart';

PuzzlePiece _boardPiece({
  required String id,
  required int anchorRow,
  required int anchorCol,
  required List<String> letters,
  int rowOffset = 0,
  int spawnRow = 99,
  int spawnCol = 99,
}) {
  return PuzzlePiece(
    id: id,
    chunkId: id,
    anchorRow: anchorRow,
    anchorCol: anchorCol,
    spawnAnchorRow: spawnRow,
    spawnAnchorCol: spawnCol,
    cells: [
      for (var index = 0; index < letters.length; index++)
        PieceCell(
          letter: letters[index],
          rowOffset: rowOffset,
          colOffset: index,
        ),
    ],
  );
}

PuzzlePiece _boardCell({
  required String id,
  required int row,
  required int col,
  required String letter,
  int spawnRow = 99,
  int spawnCol = 99,
}) {
  return PuzzlePiece(
    id: id,
    chunkId: id,
    anchorRow: row,
    anchorCol: col,
    spawnAnchorRow: spawnRow,
    spawnAnchorCol: spawnCol,
    cells: [PieceCell(letter: letter, rowOffset: 0, colOffset: 0)],
  );
}

void main() {
  test('init scan detects pre-placed completed word on board', () {
    final pieces = [
      _boardPiece(
        id: 'red',
        anchorRow: 2,
        anchorCol: 0,
        letters: ['R', 'E', 'D'],
      ),
    ];

    final result = runCompletionScan(
      pieces: pieces,
      scanScopeCells: getAllPlayAreaCells(buildPlayAreaLetterMap(pieces)),
      targetWords: const ['RED', 'BLUE'],
      completedAnswers: const {},
      source: CompletionScanSource.initialization,
    );

    expect(result.newlyCompletedAnswers, {'RED'});
    expect(result.completedAnswers, {'RED'});
    expect(
      result.pieces.where((piece) => piece.isCompletedWordGroup),
      hasLength(1),
    );
  });

  test('connected expansion detects word away from move seed in same component', () {
    final pieces = [
      _boardPiece(
        id: 'red',
        anchorRow: 0,
        anchorCol: 0,
        letters: ['R', 'E', 'D'],
      ),
      _boardCell(id: 'bridge', row: 1, col: 2, letter: 'B'),
      _boardCell(id: 'tail', row: 2, col: 2, letter: 'T'),
    ];

    final playAreaBoard = buildPlayAreaLetterMap(pieces);
    final scanScope = getConnectedPlayAreaCells(
      seedCells: {const BoardCellPosition(row: 2, col: 2)},
      playAreaBoard: playAreaBoard,
    );

    final result = runCompletionScan(
      pieces: pieces,
      scanScopeCells: scanScope,
      targetWords: const ['RED'],
      completedAnswers: const {},
    );

    expect(result.newlyCompletedAnswers, {'RED'});
  });

  test('Rule A excludes unrelated letters on a different row', () {
    final pieces = [
      _boardPiece(
        id: 'apple',
        anchorRow: 0,
        anchorCol: 0,
        letters: ['A', 'P', 'P', 'L', 'E'],
      ),
      _boardPiece(
        id: 'xyz',
        anchorRow: 1,
        anchorCol: 3,
        letters: ['X', 'Y', 'Z'],
      ),
    ];

    final playAreaBoard = buildPlayAreaLetterMap(pieces);
    final result = runCompletionScan(
      pieces: pieces,
      scanScopeCells: getAllPlayAreaCells(playAreaBoard),
      targetWords: const ['APPLE'],
      completedAnswers: const {},
    );

    expect(result.newlyCompletedAnswers, {'APPLE'});

    final group = result.pieces.singleWhere((piece) => piece.isCompletedWordGroup);
    expect(group.cells.length, 5);
    expect(group.cells.map((cell) => cell.letter).join(), 'APPLE');

    final xyzPiece = result.pieces.where((piece) => !piece.isCompletedWordGroup);
    expect(xyzPiece, hasLength(1));
    expect(xyzPiece.first.cells.map((cell) => cell.letter).join(), 'XYZ');
  });

  test('Rule B keeps disjoint completed words in separate groups', () {
    final pieces = [
      _boardPiece(
        id: 'apple',
        anchorRow: 0,
        anchorCol: 0,
        letters: ['A', 'P', 'P', 'L', 'E'],
      ),
      _boardPiece(
        id: 'dog',
        anchorRow: 2,
        anchorCol: 0,
        letters: ['D', 'O', 'G'],
      ),
    ];

    final playAreaBoard = buildPlayAreaLetterMap(pieces);
    final result = runCompletionScan(
      pieces: pieces,
      scanScopeCells: getAllPlayAreaCells(playAreaBoard),
      targetWords: const ['APPLE', 'DOG'],
      completedAnswers: const {},
    );

    expect(result.newlyCompletedAnswers, {'APPLE', 'DOG'});
    expect(
      result.pieces.where((piece) => piece.isCompletedWordGroup),
      hasLength(2),
    );
  });

  test('Rule C merges overlapping completed words into one group', () {
    final pieces = [
      _boardCell(id: 'c', row: 0, col: 0, letter: 'C'),
      _boardCell(id: 'a_h', row: 0, col: 1, letter: 'A'),
      _boardCell(id: 't', row: 0, col: 2, letter: 'T'),
      _boardCell(id: 'a_v', row: 1, col: 0, letter: 'A'),
      _boardCell(id: 'r', row: 2, col: 0, letter: 'R'),
    ];

    final playAreaBoard = buildPlayAreaLetterMap(pieces);
    final result = runCompletionScan(
      pieces: pieces,
      scanScopeCells: getAllPlayAreaCells(playAreaBoard),
      targetWords: const ['CAT', 'CAR'],
      completedAnswers: const {},
    );

    expect(result.newlyCompletedAnswers, {'CAT', 'CAR'});
    expect(
      result.pieces.where((piece) => piece.isCompletedWordGroup),
      hasLength(1),
    );

    final group = result.pieces.singleWhere((piece) => piece.isCompletedWordGroup);
    expect(group.completedAnswers, {'CAT', 'CAR'});
    expect(group.cells.length, 5);
  });

  test('dedup prevents duplicate completion for same segment', () {
    final pieces = [
      _boardPiece(
        id: 'red',
        anchorRow: 0,
        anchorCol: 0,
        letters: ['R', 'E', 'D'],
      ),
    ];

    final playAreaBoard = buildPlayAreaLetterMap(pieces);
    final scope = getAllPlayAreaCells(playAreaBoard);

    final first = runCompletionScan(
      pieces: pieces,
      scanScopeCells: scope,
      targetWords: const ['RED'],
      completedAnswers: const {},
    );

    final second = runCompletionScan(
      pieces: first.pieces,
      scanScopeCells: scope,
      targetWords: const ['RED'],
      completedAnswers: first.completedAnswers,
    );

    expect(first.newlyCompletedAnswers, {'RED'});
    expect(second.newlyCompletedAnswers, isEmpty);
  });

  test('marks puzzle complete when all target answers are found', () {
    final pieces = [
      _boardPiece(
        id: 'red',
        anchorRow: 0,
        anchorCol: 0,
        letters: ['R', 'E', 'D'],
      ),
      _boardPiece(
        id: 'blue',
        anchorRow: 2,
        anchorCol: 0,
        letters: ['B', 'L', 'U', 'E'],
      ),
    ];

    final playAreaBoard = buildPlayAreaLetterMap(pieces);
    final result = runCompletionScan(
      pieces: pieces,
      scanScopeCells: getAllPlayAreaCells(playAreaBoard),
      targetWords: const ['RED', 'BLUE'],
      completedAnswers: const {},
    );

    expect(result.allAnswersCompleted, isTrue);
    expect(result.completedAnswers, {'RED', 'BLUE'});
  });

  test('FORK reconnect scan detects full word from RK seeds only', () {
    final pieces = [
      _boardCell(id: 'f', row: 0, col: 0, letter: 'F'),
      _boardCell(id: 'o', row: 0, col: 1, letter: 'O'),
      _boardPiece(
        id: 'rk',
        anchorRow: 0,
        anchorCol: 2,
        letters: ['R', 'K'],
      ),
    ];

    final playAreaBoard = buildPlayAreaLetterMap(pieces);
    final scanScope = buildBoardChangeScanScope(
      affectedCells: {
        const BoardCellPosition(row: 0, col: 2),
        const BoardCellPosition(row: 0, col: 3),
      },
      playAreaBoard: playAreaBoard,
    );

    final result = runCompletionScan(
      pieces: pieces,
      scanScopeCells: scanScope,
      targetWords: const ['FORK'],
      completedAnswers: const {},
    );

    expect(result.newlyCompletedAnswers, {'FORK'});
  });

  test('FORK contributing components move F O and RK pieces together', () {
    final pieces = [
      _boardCell(id: 'f', row: 0, col: 0, letter: 'F'),
      _boardCell(id: 'o', row: 0, col: 1, letter: 'O'),
      _boardPiece(
        id: 'rk',
        anchorRow: 0,
        anchorCol: 2,
        letters: ['R', 'K'],
      ),
    ];

    final playAreaBoard = buildPlayAreaLetterMap(pieces);
    final result = runCompletionScan(
      pieces: pieces,
      scanScopeCells: buildInitializationScanScope(playAreaBoard),
      targetWords: const ['FORK'],
      completedAnswers: const {},
    );

    expect(result.newlyCompletedAnswers, {'FORK'});
    expect(
      result.pieces.where((piece) => piece.isCompletedWordGroup),
      hasLength(1),
    );
    expect(
      result.pieces.where((piece) => !piece.isCompletedWordGroup),
      isEmpty,
    );

    final group = result.pieces.singleWhere((piece) => piece.isCompletedWordGroup);
    expect(group.cells.length, 4);
    expect(group.cells.map((cell) => cell.letter).join(), 'FORK');
  });

  test('contributing component expansion includes full multi-cell chunk', () {
    final pieces = [
      _boardCell(id: 'f', row: 0, col: 0, letter: 'F'),
      PuzzlePiece(
        id: 'ork_extra',
        chunkId: 'ork_extra',
        anchorRow: 0,
        anchorCol: 1,
        spawnAnchorRow: 99,
        spawnAnchorCol: 99,
        cells: const [
          PieceCell(letter: 'O', rowOffset: 0, colOffset: 0),
          PieceCell(letter: 'R', rowOffset: 0, colOffset: 1),
          PieceCell(letter: 'K', rowOffset: 0, colOffset: 2),
          PieceCell(letter: 'Z', rowOffset: 1, colOffset: 0),
        ],
      ),
    ];

    final playAreaBoard = buildPlayAreaLetterMap(pieces);
    final result = runCompletionScan(
      pieces: pieces,
      scanScopeCells: buildInitializationScanScope(playAreaBoard),
      targetWords: const ['FORK'],
      completedAnswers: const {},
    );

    expect(result.newlyCompletedAnswers, {'FORK'});

    final group = result.pieces.singleWhere((piece) => piece.isCompletedWordGroup);
    expect(group.cells.length, 5);
    expect(
      group.cells.map((cell) => cell.letter).toSet(),
      {'F', 'O', 'R', 'K', 'Z'},
    );
  });

  test('crossword contributing components merge into one group', () {
    final pieces = [
      _boardCell(id: 'c', row: 0, col: 0, letter: 'C'),
      _boardCell(id: 'a_h', row: 0, col: 1, letter: 'A'),
      _boardCell(id: 't', row: 0, col: 2, letter: 'T'),
      _boardCell(id: 'a_v', row: 1, col: 0, letter: 'A'),
      _boardCell(id: 'r', row: 2, col: 0, letter: 'R'),
    ];

    final playAreaBoard = buildPlayAreaLetterMap(pieces);
    final result = runCompletionScan(
      pieces: pieces,
      scanScopeCells: buildInitializationScanScope(playAreaBoard),
      targetWords: const ['CAT', 'CAR'],
      completedAnswers: const {},
    );

    expect(result.newlyCompletedAnswers, {'CAT', 'CAR'});
    expect(
      result.pieces.where((piece) => piece.isCompletedWordGroup),
      hasLength(1),
    );
    expect(
      result.pieces.where((piece) => !piece.isCompletedWordGroup),
      isEmpty,
    );
  });
}
