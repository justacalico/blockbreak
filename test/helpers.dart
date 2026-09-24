import 'dart:collection';
import 'dart:math';

/// Random with scripted outputs so tests are fully deterministic.
/// [nextDouble] always returns [doubleValue]; [nextInt] drains [intResults]
/// (mod max) then falls back to 0.
class ScriptedRandom implements Random {
  ScriptedRandom({this.doubleValue = 0.99, List<int>? ints})
      : intResults = Queue.of(ints ?? const []);

  double doubleValue;
  final Queue<int> intResults;
  int lastMax = 0;

  @override
  int nextInt(int max) {
    lastMax = max;
    if (intResults.isNotEmpty) return intResults.removeFirst() % max;
    return 0;
  }

  @override
  double nextDouble() => doubleValue;

  @override
  bool nextBool() => doubleValue < 0.5;
}
