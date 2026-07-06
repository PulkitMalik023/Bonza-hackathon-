import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/data/deconstructors/puzzle_feasibility_auditor.dart';
import 'package:jam_pro/features/puzzle/data/deconstructors/puzzle_solvability_auditor.dart';
import 'package:jam_pro/features/puzzle/data/models/deconstructed_puzzle.dart';
import 'package:jam_pro/features/puzzle/data/models/puzzle_content.dart';
import 'package:jam_pro/features/puzzle/data/models/puzzle_definition.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/puzzle_layout_metadata.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/word_resolution_service.dart';

import 'word_resolution/word_resolution_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const solvabilityAuditor = PuzzleSolvabilityAuditor();
  final feasibilityAuditor = PuzzleFeasibilityAuditor();

  test('Fruit Salad passes all solvability checks', () async {
    final jsonString = await rootBundle.loadString(
      'assets/data/puzzle_definitions.json',
    );
    final decoded = jsonDecode(jsonString) as List<dynamic>;
    final definition = decoded
        .map(
          (entry) => PuzzleDefinition.fromJson(entry as Map<String, dynamic>),
        )
        .firstWhere((entry) => entry.puzzleId == 1);

    final report = solvabilityAuditor.audit(
      layout: definition.puzzleLayout,
      deconstructed: definition.toDeconstructedPuzzle(),
    );

    expect(report.isSolvable, isTrue, reason: report.failureReason);
  });

  test('Planets partial board does not pass full-layout completion', () async {
    final jsonString = await rootBundle.loadString(
      'assets/data/puzzle_definitions.json',
    );
    final decoded = jsonDecode(jsonString) as List<dynamic>;
    final definition = decoded
        .map(
          (entry) => PuzzleDefinition.fromJson(entry as Map<String, dynamic>),
        )
        .firstWhere((entry) => entry.puzzleId == 4);
    final metadata = PuzzleLayoutMetadata.fromLayoutAndDeconstruction(
      layout: definition.puzzleLayout,
      deconstructed: definition.toDeconstructedPuzzle(),
    );

    final pieces = piecesForChunkIds(metadata, ['chunk_1', 'chunk_3', 'chunk_4']);
    final result = handlePuzzleStateAfterReconnect(
      pieces: pieces,
      metadata: metadata,
      movedChunkIds: const ['chunk_4'],
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    expect(result.completedAnswers, isNot(contains('MARS')));
  });

  test('solvability auditor rejects partial planets layout as incomplete', () async {
    final jsonString = await rootBundle.loadString(
      'assets/data/puzzle_definitions.json',
    );
    final decoded = jsonDecode(jsonString) as List<dynamic>;
    final definition = decoded
        .map(
          (entry) => PuzzleDefinition.fromJson(entry as Map<String, dynamic>),
        )
        .firstWhere((entry) => entry.puzzleId == 4);

    final deconstructed = definition.toDeconstructedPuzzle();
    final partialChunks = deconstructed.chunks
        .where((chunk) => chunk.id != 'chunk_0' && chunk.id != 'chunk_2')
        .toList();

    final report = solvabilityAuditor.audit(
      layout: definition.puzzleLayout,
      deconstructed: DeconstructedPuzzle(
        sourceLayout: definition.puzzleLayout,
        chunks: partialChunks,
      ),
    );

    expect(report.isSolvable, isFalse);
    expect(report.failedCheck, SolvabilityCheckKind.fullLayoutCompletes);
  });

  test('PINK SINK word set passes extended feasibility audit', () {
    final report = feasibilityAuditor.audit(
      const PuzzleContent(
        id: 99,
        category: 'Test',
        words: ['PINK', 'SINK'],
      ),
    );

    expect(report.canGenerateLayout, isTrue);
    expect(report.canDeconstruct, isTrue);
    expect(report.canSolve, isTrue);
    expect(report.isPlayable, isTrue);
  });

  test('GOLF POLO RUGBY fails before solvability due to singleton chunks', () {
    final report = feasibilityAuditor.audit(
      const PuzzleContent(
        id: 99,
        category: 'Test',
        words: ['GOLF', 'POLO', 'RUGBY'],
      ),
    );

    expect(report.canGenerateLayout, isTrue);
    expect(report.isPlayable, isFalse);
    expect(
      report.failureReason,
      contains('single-letter'),
    );
  });

  test('content candidates are playable under extended audit', () {
    final candidatesFile = File('tool/examples/content_candidates.json');
    final decoded = jsonDecode(candidatesFile.readAsStringSync()) as List;
    final failures = <String>[];

    for (final entry in decoded) {
      final map = entry as Map<String, dynamic>;
      final category = map['category'] as String;
      final words = (map['words'] as List).cast<String>();
      final report = feasibilityAuditor.audit(
        PuzzleContent(id: 0, category: category, words: words),
      );
      if (!report.isPlayable) {
        failures.add('$category: ${report.failureReason}');
      }
    }

    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}
