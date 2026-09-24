import 'package:blockbreak/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats small numbers', () {
    expect(fmt(0), '0');
    expect(fmt(42), '42');
    expect(fmt(999), '999');
    expect(fmt(1.5), '1.5');
    expect(fmt(-5), '-5');
    expect(fmt(double.nan), '0');
    expect(fmt(double.infinity), '0');
  });

  test('formats suffixed numbers', () {
    expect(fmt(1000), '1.00K');
    expect(fmt(1500), '1.50K');
    expect(fmt(12345), '12.3K');
    expect(fmt(999999), '1.00M');
    expect(fmt(2.5e6), '2.50M');
    expect(fmt(1.2e9), '1.20B');
    expect(fmt(7e12), '7.00T');
    expect(fmt(3e15), '3.00Qa');
    expect(fmt(3e18), '3.00Qi');
    expect(fmt(3e21), '3.00Sx');
    expect(fmt(3e24), '3.00Sp');
    expect(fmt(3e27), '3.00Oc');
    expect(fmt(3e30), '3.00No');
    expect(fmt(3e33), '3.00Dc');
  });

  test('falls back to exponential past Dc', () {
    expect(fmt(1e37), '1.0e+37');
  });

  test('fmtPicks appends the unit', () {
    expect(fmtPicks(1200), '1.20K picks');
  });
}
