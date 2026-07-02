import 'package:flutter/material.dart';

import 'demos/connect_tiles_demo.dart';
import 'demos/hint_demo.dart';
import 'demos/make_word_demo.dart';
import 'demos/solved_word_demo.dart';

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
    demoBuilder: MakeWordDemo.new,
  ),
  HowToPlayStep(
    title: 'Solved words move together',
    description:
        'When a valid word is formed, all tiles contributing to it are solved together as one group.',
    demoBuilder: SolvedWordDemo.new,
  ),
  HowToPlayStep(
    title: 'Use hints if stuck',
    description: "Tap Hint to reveal a helpful move when you're stuck.",
    demoBuilder: HintDemo.new,
  ),
];
