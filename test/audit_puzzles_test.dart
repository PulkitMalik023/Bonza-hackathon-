import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/data/deconstructors/puzzle_feasibility_auditor.dart';
import 'package:jam_pro/features/puzzle/data/models/puzzle_content.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('audit puzzles.json and update enabled flags', () {
    const puzzlesPath = 'assets/data/puzzles.json';
    final file = File(puzzlesPath);
    expect(file.existsSync(), isTrue, reason: 'Missing $puzzlesPath');

    final decoded = jsonDecode(file.readAsStringSync());
    expect(decoded, isA<List>());

    final puzzles = (decoded as List)
        .map((entry) => PuzzleContent.fromJson(entry as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    final auditor = PuzzleFeasibilityAuditor();
    final reports = auditor.auditAll(puzzles);

    var passCount = 0;
    var failCount = 0;

    for (final report in reports) {
      if (report.isPlayable) {
        passCount++;
        // ignore: avoid_print
        print(
          'PASS Puzzle ${report.id} ${report.category}: '
          '${report.validLayoutCount}/${report.layoutCount} valid layouts',
        );
      } else {
        failCount++;
        // ignore: avoid_print
        print(
          'FAIL Puzzle ${report.id} ${report.category}: '
          '${report.failureReason ?? 'Unknown failure'}',
        );
      }
    }

    final updated = puzzles
        .map((puzzle) {
          final report = reports.firstWhere((entry) => entry.id == puzzle.id);
          return puzzle.copyWith(enabled: report.isPlayable);
        })
        .map((puzzle) => puzzle.toJson())
        .toList();

    const encoder = JsonEncoder.withIndent('  ');
    file.writeAsStringSync('${encoder.convert(updated)}\n');

    // ignore: avoid_print
    print('Pass: $passCount  Fail: $failCount');
    // ignore: avoid_print
    print('Updated $puzzlesPath');

    expect(passCount, greaterThan(0));
  });
}
