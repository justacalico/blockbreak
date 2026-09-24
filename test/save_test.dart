import 'package:blockbreak/game/models.dart';
import 'package:blockbreak/game/save.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('SharedPrefsStore round trips a state', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await SharedPrefsStore.open();
    expect(await store.load(), isNull);

    final s = GameState()..picks = 42;
    await store.save(s);
    expect(s.savedAt, greaterThan(0));

    final loaded = await store.load();
    expect(loaded, isNotNull);
    expect(loaded!.picks, 42);
    expect(loaded.savedAt, s.savedAt);
  });

  test('SharedPrefsStore returns null on corrupt data', () async {
    SharedPreferences.setMockInitialValues(
        {'blockbreak.save.v1': '{not json'});
    final store = await SharedPrefsStore.open();
    expect(await store.load(), isNull);
  });

  test('MemoryStore stores a deep copy', () async {
    final store = MemoryStore();
    expect(await store.load(), isNull);
    final s = GameState()..picks = 7;
    await store.save(s);
    s.picks = 999;
    final loaded = await store.load();
    expect(loaded!.picks, 7);
  });
}
