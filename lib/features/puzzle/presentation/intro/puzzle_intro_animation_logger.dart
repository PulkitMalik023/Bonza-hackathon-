import 'package:flutter/foundation.dart';

abstract final class PuzzleIntroAnimationLogger {
  static const _prefix = '[puzzle_intro_anim]';

  static void introStarted({required int chunkCount}) {
    debugPrint('$_prefix intro started chunkCount=$chunkCount');
  }

  static void chunkStart({
    required int index,
    required String chunkId,
  }) {
    debugPrint('$_prefix chunkStart index=$index chunkId=$chunkId');
  }

  static void ghostStart({required int index}) {
    debugPrint('$_prefix ghostStart index=$index');
  }

  static void realEnterStart({required int index}) {
    debugPrint('$_prefix realEnterStart index=$index');
  }

  static void settleComplete({required int index}) {
    debugPrint('$_prefix settleComplete index=$index');
  }

  static void introComplete({required bool interactionEnabled}) {
    debugPrint(
      '$_prefix intro complete interactionEnabled=$interactionEnabled',
    );
  }
}
