import 'package:flutter/material.dart';

import 'game/controller.dart';
import 'theme.dart';
import 'ui/game_screen.dart';

class BlockBreakApp extends StatelessWidget {
  const BlockBreakApp({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BlockBreak',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: GameScreen(controller: controller),
    );
  }
}
