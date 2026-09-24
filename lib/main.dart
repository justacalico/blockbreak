import 'package:flutter/material.dart';

import 'app.dart';
import 'game/controller.dart';
import 'game/save.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await SharedPrefsStore.open();
  final controller = await loadGame(store);
  runApp(BlockBreakApp(controller: controller));
}
