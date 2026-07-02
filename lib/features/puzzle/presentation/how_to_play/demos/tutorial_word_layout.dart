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
  return [
    for (var index = 0; index < word.length; index++)
      TutorialCell(
        letter: word[index],
        col: index,
        row: 0,
      ),
  ];
}

Offset tutorialWordOrigin({
  required int wordLength,
  double rowY = 69,
}) {
  final wordWidth = wordLength * kTutorialTileSize;
  final x = (kTutorialDemoWidth - wordWidth) / 2;
  return Offset(x, rowY);
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

Offset chunkHandPosition(Offset chunkOrigin, {double tileSize = kTutorialTileSize}) {
  return Offset(chunkOrigin.dx + 8, chunkOrigin.dy + 8);
}
