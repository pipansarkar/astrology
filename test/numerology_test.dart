import 'package:astrology/numerology/numerology.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Mulank, Bhagyank and name number', () {
    final dob = DateTime(1995, 8, 15);
    expect(mulank(dob), 6); // 1+5
    expect(bhagyank(dob), 2); // 1+5+8+1+9+9+5 = 38 -> 11 -> 2
    expect(mulank(DateTime(2000, 1, 29)), 2); // 29 -> 11 -> 2
    expect(nameNumber('Asha'), 1); // a1 s3 h5 a1 = 10 -> 1
  });

  test('reduce', () {
    expect(reduce(38), 2);
    expect(reduce(9), 9);
    expect(reduce(18), 9);
    expect(nameNumber('!!!'), isNull);
  });
}
