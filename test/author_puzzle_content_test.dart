import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/data/deconstructors/puzzle_feasibility_auditor.dart';
import 'package:jam_pro/features/puzzle/data/models/puzzle_content.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('author content candidates from tool/examples/content_candidates.json', () {
    const candidatesPath = 'tool/examples/content_candidates.json';
    final file = File(candidatesPath);
    expect(file.existsSync(), isTrue, reason: 'Missing $candidatesPath');

    final decoded = jsonDecode(file.readAsStringSync());
    expect(decoded, isA<List>());

    final candidates = decoded as List;
    final auditor = PuzzleFeasibilityAuditor();
    final failures = <String>[];
    var nextId = 13;

    for (final entry in candidates) {
      final map = entry as Map<String, dynamic>;
      final category = map['category'] as String;
      final words = (map['words'] as List).cast<String>();

      final report = auditor.audit(
        PuzzleContent(
          id: nextId,
          category: category,
          words: words,
        ),
      );

      if (report.isPlayable) {
        // ignore: avoid_print
        print(
          'PASS $category (id $nextId): '
          '${report.validLayoutCount}/${report.layoutCount} solvable layouts',
        );
        // ignore: avoid_print
        print(
          '  puzzles.json entry: '
          '{"id": $nextId, "category": "$category", '
          '"words": ${jsonEncode(words)}, "enabled": true}',
        );
        nextId++;
      } else {
        final message =
            'FAIL $category: ${report.failureReason ?? 'Unknown failure'}';
        failures.add(message);
        // ignore: avoid_print
        print(message);
      }
    }

    expect(
      failures,
      isEmpty,
      reason: failures.join('\n'),
    );
  });
}
