import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Persistence abstraction so tests can run on memory.
abstract class SaveStore {
  Future<void> save(GameState state);
  Future<GameState?> load();
}

class SharedPrefsStore implements SaveStore {
  SharedPrefsStore(this._prefs);

  static const _key = 'blockbreak.save.v1';
  final SharedPreferences _prefs;

  static Future<SharedPrefsStore> open() async =>
      SharedPrefsStore(await SharedPreferences.getInstance());

  @override
  Future<void> save(GameState state) {
    state.savedAt = DateTime.now().millisecondsSinceEpoch;
    return _prefs.setString(_key, jsonEncode(state.toJson()));
  }

  @override
  Future<GameState?> load() async {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    try {
      return GameState.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }
}

class MemoryStore implements SaveStore {
  GameState? stored;

  @override
  Future<void> save(GameState state) async {
    state.savedAt = DateTime.now().millisecondsSinceEpoch;
    stored = GameState.fromJson(
        jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>);
  }

  @override
  Future<GameState?> load() async => stored;
}
