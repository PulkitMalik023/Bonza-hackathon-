import '../data/models/placed_word.dart';
import 'board_cell_position.dart';

typedef WordBoardSlot = ({BoardCellPosition position, String letter});

List<WordBoardSlot> boardSlotsForPlacedWord(PlacedWord word) {
  final letters = word.word.toUpperCase();

  return [
    for (var index = 0; index < letters.length; index++)
      (
        position: _cellForLetter(word, index),
        letter: letters[index],
      ),
  ];
}

Set<BoardCellPosition> boardPositionsForPlacedWord(PlacedWord word) {
  return boardSlotsForPlacedWord(word).map((slot) => slot.position).toSet();
}

BoardCellPosition _cellForLetter(PlacedWord placed, int letterIndex) {
  switch (placed.direction) {
    case WordDirection.horizontal:
      return BoardCellPosition(row: placed.row, col: placed.col + letterIndex);
    case WordDirection.vertical:
      return BoardCellPosition(row: placed.row + letterIndex, col: placed.col);
  }
}

String? formedWordForPlacedWord(
  PlacedWord word,
  Map<BoardCellPosition, String> board,
) {
  final slots = boardSlotsForPlacedWord(word);
  final buffer = StringBuffer();

  for (final slot in slots) {
    final letter = board[slot.position];
    if (letter == null) {
      return null;
    }
    buffer.write(letter);
  }

  return buffer.toString();
}

typedef WordSlotStatus = ({
  BoardCellPosition position,
  String expected,
  String? actual,
});

class WordCompletionStatus {
  const WordCompletionStatus({
    required this.isComplete,
    required this.formed,
    required this.alreadyCompleted,
    required this.slots,
    required this.missingSlots,
    required this.wrongSlots,
  });

  final bool isComplete;
  final String? formed;
  final bool alreadyCompleted;
  final List<WordSlotStatus> slots;
  final List<WordBoardSlot> missingSlots;
  final List<({WordBoardSlot slot, String actual})> wrongSlots;
}

WordCompletionStatus evaluateWordCompletion({
  required PlacedWord word,
  required Map<BoardCellPosition, String> board,
  required Set<String> alreadyCompleted,
  required String key,
}) {
  if (alreadyCompleted.contains(key)) {
    final wordSlots = boardSlotsForPlacedWord(word);
    final slotStatuses = [
      for (final slot in wordSlots)
        (
          position: slot.position,
          expected: slot.letter,
          actual: board[slot.position],
        ),
    ];

    return WordCompletionStatus(
      isComplete: false,
      formed: formedWordForPlacedWord(word, board),
      alreadyCompleted: true,
      slots: slotStatuses,
      missingSlots: const [],
      wrongSlots: const [],
    );
  }

  final expected = word.word.toUpperCase();
  final wordSlots = boardSlotsForPlacedWord(word);
  final slotStatuses = <WordSlotStatus>[];
  final missingSlots = <WordBoardSlot>[];
  final wrongSlots = <({WordBoardSlot slot, String actual})>[];

  for (final slot in wordSlots) {
    final actual = board[slot.position];
    slotStatuses.add(
      (
        position: slot.position,
        expected: slot.letter,
        actual: actual,
      ),
    );

    if (actual == null) {
      missingSlots.add(slot);
      continue;
    }

    if (actual != slot.letter) {
      wrongSlots.add((slot: slot, actual: actual));
    }
  }

  final formed = missingSlots.isEmpty
      ? slotStatuses.map((slot) => slot.actual!).join()
      : null;

  return WordCompletionStatus(
    isComplete: formed == expected,
    formed: formed,
    alreadyCompleted: false,
    slots: slotStatuses,
    missingSlots: missingSlots,
    wrongSlots: wrongSlots,
  );
}

bool isWordCompleted({
  required PlacedWord word,
  required Map<BoardCellPosition, String> board,
  required Set<String> alreadyCompleted,
  required String key,
}) {
  return evaluateWordCompletion(
    word: word,
    board: board,
    alreadyCompleted: alreadyCompleted,
    key: key,
  ).isComplete;
}
