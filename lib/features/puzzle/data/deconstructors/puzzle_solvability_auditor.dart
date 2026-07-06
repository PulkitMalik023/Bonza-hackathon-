import '../../domain/puzzle_piece.dart';
import '../../domain/word_resolution/puzzle_layout_metadata.dart';
import '../../domain/word_resolution/puzzle_runtime_state.dart';
import '../../domain/word_resolution/puzzle_solvability_solver.dart';
import '../../domain/word_resolution/word_assignment.dart';
import '../../domain/word_resolution/word_resolution_service.dart';
import '../models/deconstructed_puzzle.dart';
import '../models/puzzle_layout.dart';

enum SolvabilityCheckKind {
  fullLayoutCompletes,
  allOrdersSolvable,
  noPrematureCompletions,
}

class PuzzleSolvabilityReport {
  const PuzzleSolvabilityReport({
    required this.isSolvable,
    this.failureReason,
    this.failedCheck,
    this.blockedWordIds = const [],
    this.prematureWordText,
  });

  final bool isSolvable;
  final String? failureReason;
  final SolvabilityCheckKind? failedCheck;
  final List<String> blockedWordIds;
  final String? prematureWordText;
}

class PuzzleSolvabilityAuditor {
  const PuzzleSolvabilityAuditor();

  PuzzleSolvabilityReport audit({
    required PuzzleLayout layout,
    required DeconstructedPuzzle deconstructed,
  }) {
    final metadata = PuzzleLayoutMetadata.fromLayoutAndDeconstruction(
      layout: layout,
      deconstructed: deconstructed,
    );

    final fullLayoutResult = _checkFullLayoutCompletes(metadata);
    if (fullLayoutResult != null) {
      return fullLayoutResult;
    }

    final ordersResult = _checkAllOrdersSolvable(metadata);
    if (ordersResult != null) {
      return ordersResult;
    }

    final prematureResult = _checkNoPrematureCompletions(metadata);
    if (prematureResult != null) {
      return prematureResult;
    }

    return const PuzzleSolvabilityReport(isSolvable: true);
  }

  PuzzleSolvabilityReport? _checkFullLayoutCompletes(
    PuzzleLayoutMetadata metadata,
  ) {
    final pieces = _piecesAtLayoutPositions(metadata);
    final result = handlePuzzleStateAfterReconnect(
      pieces: pieces,
      metadata: metadata,
      movedChunkIds: metadata.chunkById.keys.take(1),
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    final expected = metadata.allTargetTexts;
    if (!expected.every(result.completedAnswers.contains)) {
      final missing = expected.difference(result.completedAnswers);
      return PuzzleSolvabilityReport(
        isSolvable: false,
        failedCheck: SolvabilityCheckKind.fullLayoutCompletes,
        failureReason:
            'Full layout does not complete all words; missing: ${missing.join(', ')}',
      );
    }

    if (!result.puzzleComplete) {
      return const PuzzleSolvabilityReport(
        isSolvable: false,
        failedCheck: SolvabilityCheckKind.fullLayoutCompletes,
        failureReason: 'Full layout does not mark puzzle complete',
      );
    }

    return null;
  }

  PuzzleSolvabilityReport? _checkAllOrdersSolvable(
    PuzzleLayoutMetadata metadata,
  ) {
    final pieces = _piecesAtLayoutPositions(metadata);
    final baseState = rebuildRuntimeBoardState(
      pieces: pieces,
      metadata: metadata,
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    for (final order in _permutations(metadata.targetWordIds)) {
      var state = baseState.clone();

      for (var index = 0; index < order.length; index++) {
        final wordId = order[index];
        final assignments = getPossibleAssignmentsForWord_Strict(
          wordId: wordId,
          state: state,
          metadata: metadata,
        );

        if (assignments.isEmpty) {
          final text = metadata.textForWordId(wordId) ?? wordId;
          return PuzzleSolvabilityReport(
            isSolvable: false,
            failedCheck: SolvabilityCheckKind.allOrdersSolvable,
            failureReason:
                'Word $text has no strict assignment in order ${order.map(metadata.textForWordId).join(' -> ')}',
            blockedWordIds: [wordId],
          );
        }

        state = applyWordAssignmentToSolverState(
          state: state,
          assignment: assignments.first,
          metadata: metadata,
        );

        if (index < order.length - 1 &&
            !canRemainingPuzzleBeSolved(state: state, metadata: metadata)) {
          final text = metadata.textForWordId(wordId) ?? wordId;
          final blocked = getBlockedUnsolvedWordIds(
            state: state,
            metadata: metadata,
          );
          return PuzzleSolvabilityReport(
            isSolvable: false,
            failedCheck: SolvabilityCheckKind.allOrdersSolvable,
            failureReason:
                'Completing $text blocks remaining words in order ${order.map(metadata.textForWordId).join(' -> ')}',
            blockedWordIds: blocked,
          );
        }
      }
    }

    return null;
  }

  PuzzleSolvabilityReport? _checkNoPrematureCompletions(
    PuzzleLayoutMetadata metadata,
  ) {
    for (final wordId in metadata.targetWordIds) {
      final wordText = metadata.textForWordId(wordId);
      if (wordText == null) {
        continue;
      }

      final coveringChunks = _chunkIdsCoveringWord(metadata, wordId);
      final otherChunkIds = metadata.chunkById.keys
          .where((chunkId) => !coveringChunks.contains(chunkId))
          .toList();

      if (otherChunkIds.isEmpty) {
        continue;
      }

      final pieces = _piecesForChunkIds(metadata, otherChunkIds);
      final result = handlePuzzleStateAfterReconnect(
        pieces: pieces,
        metadata: metadata,
        movedChunkIds: otherChunkIds.take(1),
        solvedWordIds: const {},
        reservedCellIds: const {},
        solvedAssignments: const {},
      );

      if (result.completedAnswers.contains(wordText)) {
        return PuzzleSolvabilityReport(
          isSolvable: false,
          failedCheck: SolvabilityCheckKind.noPrematureCompletions,
          failureReason:
              'Word $wordText completes without its own chunks on the board',
          prematureWordText: wordText,
          blockedWordIds: [wordId],
        );
      }
    }

    return null;
  }

  List<PuzzlePiece> _piecesAtLayoutPositions(PuzzleLayoutMetadata metadata) {
    return _piecesForChunkIds(metadata, metadata.chunkById.keys);
  }

  List<PuzzlePiece> _piecesForChunkIds(
    PuzzleLayoutMetadata metadata,
    Iterable<String> chunkIds,
  ) {
    return [
      for (final chunkId in chunkIds)
        if (metadata.chunkById[chunkId] != null)
          PuzzlePiece.fromChunk(
            metadata.chunkById[chunkId]!.chunk,
            anchorRow: metadata.chunkById[chunkId]!.chunk.solvedMinRow,
            anchorCol: metadata.chunkById[chunkId]!.chunk.solvedMinCol,
          ),
    ];
  }

  List<String> _chunkIdsCoveringWord(
    PuzzleLayoutMetadata metadata,
    String wordId,
  ) {
    return metadata.wordToChunkCoverage[wordId]
            ?.map((entry) => entry.chunkId)
            .toSet()
            .toList() ??
        const [];
  }

  List<List<T>> _permutations<T>(List<T> items) {
    if (items.length <= 1) {
      return [items];
    }

    final result = <List<T>>[];
    for (var index = 0; index < items.length; index++) {
      final current = items[index];
      final rest = [
        ...items.sublist(0, index),
        ...items.sublist(index + 1),
      ];
      for (final permutation in _permutations(rest)) {
        result.add([current, ...permutation]);
      }
    }
    return result;
  }
}
