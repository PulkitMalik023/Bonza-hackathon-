import 'package:flutter/material.dart';

import 'demos/between_solved_words_demo.dart';
import 'demos/connect_tiles_demo.dart';
import 'demos/hint_demo.dart';
import 'demos/make_vertical_word_demo.dart';

class HowToPlayStep {
  const HowToPlayStep({
    required this.title,
    required this.description,
    required this.demoBuilder,
  });

  final String title;
  final String description;
  final Widget Function({required bool isActive}) demoBuilder;
}

const howToPlaySteps = <HowToPlayStep>[
  HowToPlayStep(
    title: 'Drag tiles to connect',
    description:
        'Drag a tile or chunk near another one to connect them on the board.',
    demoBuilder: ConnectTilesDemo.new,
  ),
  HowToPlayStep(
    title: 'Make complete words',
    description:
        'Connect letters so they form a full target word horizontally or vertically.',
    demoBuilder: MakeVerticalWordDemo.new,
  ),
  HowToPlayStep(
    title: 'Connect through shared letters',
    description:
        'Solved words can share letters. Drag ES to form TEST vertically between EAST and SOUTH.',
    demoBuilder: BetweenSolvedWordsDemo.new,
  ),
  HowToPlayStep(
    title: 'Use hints if stuck',
    description:
        'Tap Hint for a helpful move, or Full Grid to see the solved puzzle reference.',
    demoBuilder: HintDemo.new,
  ),
];
