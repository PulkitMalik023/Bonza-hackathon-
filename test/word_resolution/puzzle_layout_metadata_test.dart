import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/data/deconstructors/puzzle_deconstructor.dart';
import 'package:jam_pro/features/puzzle/data/models/placed_word.dart';
import 'package:jam_pro/features/puzzle/data/models/puzzle_layout.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/puzzle_layout_metadata.dart';

void main() {
  test('builds word and final cell metadata from layout and deconstruction', () {
    final layout = PuzzleLayout.fromPlacedWords(const [
      PlacedWord(
        word: 'FORK',
        row: 0,
        col: 0,
        direction: WordDirection.horizontal,
      ),
    ]);
    final deconstructed = PuzzleDeconstructor().build(layout);
    final metadata = PuzzleLayoutMetadata.fromLayoutAndDeconstruction(
      layout: layout,
      deconstructed: deconstructed,
    );

    expect(metadata.targetWordIds, hasLength(1));
    expect(metadata.wordById.values.first.text, 'FORK');
    expect(metadata.finalCellById.length, 4);
    expect(metadata.chunkById.length, greaterThan(0));
    expect(
      getTargetWordIdsMatchingText('FORK', metadata),
      [metadata.targetWordIds.first],
    );
  });
}
