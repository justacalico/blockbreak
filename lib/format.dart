/// Compact number formatting for incremental-game values.
library;

const _suffixes = [
  '',
  'K',
  'M',
  'B',
  'T',
  'Qa',
  'Qi',
  'Sx',
  'Sp',
  'Oc',
  'No',
  'Dc',
];

String fmt(num value) {
  var v = value.toDouble();
  if (v.isNaN || v.isInfinite) return '0';
  if (v < 0) return '-${fmt(-v)}';
  if (v < 1000) {
    return v == v.roundToDouble()
        ? v.toInt().toString()
        : v.toStringAsFixed(1);
  }
  var tier = 0;
  while (v >= 1000 && tier < _suffixes.length - 1) {
    v /= 1000;
    tier++;
  }
  if (v >= 1000) return value.toDouble().toStringAsExponential(1);
  final digits = v >= 100 ? 0 : (v >= 10 ? 1 : 2);
  return '${v.toStringAsFixed(digits)}${_suffixes[tier]}';
}

/// "12.5K picks" style with a unit word.
String fmtPicks(num value) => '${fmt(value)} picks';
