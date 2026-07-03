import 'dart:ui';

import 'tutorial_chunk_group.dart';

const kTutorialTileSize = 36.0;
const kTutorialDemoWidth = 328.0;

List<TutorialCell> horizontalWord(String word) {
  return [
    for (var index = 0; index < word.length; index++)
      TutorialCell(
        letter: word[index],
        col: index,
        row: 0,
      ),
  ];
}

List<TutorialCell> horizontalChunk(String word) {
  return horizontalWord(word);
}

List<TutorialCell> verticalWord(String word) {
  return [
    for (var index = 0; index < word.length; index++)
      TutorialCell(
        letter: word[index],
        col: 0,
        row: index,
      ),
  ];
}

List<TutorialCell> verticalChunk(String word) {
  return verticalWord(word);
}

List<TutorialCell> horizontalWordAt({
  required int startCol,
  required int startRow,
  required String word,
}) {
  return [
    for (var index = 0; index < word.length; index++)
      TutorialCell(
        letter: word[index],
        col: index,
        row: 0,
      ),
  ];
}

List<TutorialCell> verticalWordAt({
  required int startCol,
  required int startRow,
  required String word,
}) {
  return [
    for (var index = 0; index < word.length; index++)
      TutorialCell(
        letter: word[index],
        col: 0,
        row: index,
      ),
  ];
}

Offset tutorialWordOrigin({
  required int wordLength,
  double rowY = 69,
  bool vertical = false,
}) {
  if (vertical) {
    final wordHeight = wordLength * kTutorialTileSize;
    final y = (kTutorialDemoWidth - wordHeight) / 2;
    final x = kTutorialDemoWidth / 2 - kTutorialTileSize / 2;
    return Offset(x, y);
  }

  final wordWidth = wordLength * kTutorialTileSize;
  final x = (kTutorialDemoWidth - wordWidth) / 2;
  return Offset(x, rowY);
}

Offset tutorialGridOrigin({
  required int cols,
  required int rows,
  double topPadding = 24,
}) {
  final gridWidth = cols * kTutorialTileSize;
  final x = (kTutorialDemoWidth - gridWidth) / 2;
  return Offset(x, topPadding);
}

Offset cellOrigin({
  required Offset gridOrigin,
  required int col,
  required int row,
  double tileSize = kTutorialTileSize,
}) {
  return Offset(
    gridOrigin.dx + col * tileSize,
    gridOrigin.dy + row * tileSize,
  );
}

Offset attachRight({
  required Offset leftOrigin,
  required int leftTileCount,
  double tileSize = kTutorialTileSize,
}) {
  return Offset(
    leftOrigin.dx + leftTileCount * tileSize,
    leftOrigin.dy,
  );
}

Offset attachLeft({
  required Offset rightOrigin,
  required int movingTileCount,
  double tileSize = kTutorialTileSize,
}) {
  return Offset(
    rightOrigin.dx - movingTileCount * tileSize,
    rightOrigin.dy,
  );
}

Offset attachBelow({
  required Offset topOrigin,
  required int topTileCount,
  double tileSize = kTutorialTileSize,
}) {
  return Offset(
    topOrigin.dx,
    topOrigin.dy + topTileCount * tileSize,
  );
}

Offset attachBetween({
  required Offset leftCompletedOrigin,
  required int leftCompletedTileCount,
  required int movingTileCount,
  double tileSize = kTutorialTileSize,
  double gapRows = 0,
}) {
  return Offset(
    leftCompletedOrigin.dx + leftCompletedTileCount * tileSize,
    leftCompletedOrigin.dy + gapRows * tileSize,
  );
}

Offset chunkHandPosition(Offset chunkOrigin, {double tileSize = kTutorialTileSize}) {
  return Offset(chunkOrigin.dx + 8, chunkOrigin.dy + 8);
}
