import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tour_board/core/money/split.dart';

void main() {
  group('splitEqual', () {
    test('divisible amounts split evenly', () {
      expect(splitEqual(300, ['a', 'b', 'c']), {'a': 100, 'b': 100, 'c': 100});
    });

    test('remainder goes to first participants in uid order', () {
      expect(splitEqual(100, ['c', 'a', 'b']), {'a': 34, 'b': 33, 'c': 33});
      expect(splitEqual(101, ['a', 'b', 'c']), {'a': 34, 'b': 34, 'c': 33});
    });

    test('is independent of input order', () {
      expect(
        splitEqual(1001, ['x', 'y', 'z']),
        splitEqual(1001, ['z', 'x', 'y']),
      );
    });

    test('very small totals still sum exactly', () {
      expect(splitEqual(1, ['a', 'b', 'c']), {'a': 1, 'b': 0, 'c': 0});
    });

    test('duplicate uids are collapsed', () {
      expect(splitEqual(100, ['a', 'a', 'b']), {'a': 50, 'b': 50});
    });

    test('rejects invalid input', () {
      expect(() => splitEqual(0, ['a']), throwsA(isA<SplitException>()));
      expect(() => splitEqual(-5, ['a']), throwsA(isA<SplitException>()));
      expect(() => splitEqual(100, []), throwsA(isA<SplitException>()));
      expect(
        () => splitEqual(100, List.generate(31, (i) => 'u$i')),
        throwsA(isA<SplitException>()),
      );
    });
  });

  group('splitByWeights', () {
    test('2:1 shares', () {
      expect(splitByWeights(300, {'a': 2, 'b': 1}), {'a': 200, 'b': 100});
    });

    test('largest remainder allocation is deterministic', () {
      // 100 * 1/3 = 33.33 each -> one leftover unit to the uid-first tie.
      expect(splitByWeights(100, {'b': 1, 'a': 1, 'c': 1}), {
        'a': 34,
        'b': 33,
        'c': 33,
      });
      // 1000 split 1:1:1:2 -> 200, 200, 200, 400.
      expect(splitByWeights(1000, {'a': 1, 'b': 1, 'c': 1, 'd': 2}), {
        'a': 200,
        'b': 200,
        'c': 200,
        'd': 400,
      });
      // 10 split 3:3:1 -> 4.28, 4.28, 1.43 -> 4,4,2? remainders .28,.28,.43
      expect(splitByWeights(10, {'a': 3, 'b': 3, 'c': 1}), {
        'a': 4,
        'b': 4,
        'c': 2,
      });
    });

    test('rejects zero/negative weights', () {
      expect(
        () => splitByWeights(100, {'a': 0, 'b': 1}),
        throwsA(isA<SplitException>()),
      );
      expect(
        () => splitByWeights(100, {'a': -1}),
        throwsA(isA<SplitException>()),
      );
      expect(
        () => splitByWeights(100, {'a': 1001}),
        throwsA(isA<SplitException>()),
      );
    });
  });

  group('validateCustomSplit', () {
    test('accepts exact sums and strips zero shares', () {
      expect(validateCustomSplit(500, {'a': 300, 'b': 200, 'c': 0}), {
        'a': 300,
        'b': 200,
      });
    });

    test('rejects mismatched sums and negative shares', () {
      expect(
        () => validateCustomSplit(500, {'a': 300, 'b': 199}),
        throwsA(
          isA<SplitException>().having(
            (e) => e.reason,
            'reason',
            SplitError.sumMismatch,
          ),
        ),
      );
      expect(
        () => validateCustomSplit(100, {'a': 150, 'b': -50}),
        throwsA(
          isA<SplitException>().having(
            (e) => e.reason,
            'reason',
            SplitError.negativeShare,
          ),
        ),
      );
      expect(
        () => validateCustomSplit(100, {'a': 0}),
        throwsA(isA<SplitException>()),
      );
    });
  });

  test('randomised: every split sums exactly to the total', () {
    final random = Random(42);
    for (var i = 0; i < 2000; i++) {
      final total = i.isEven
          ? 1 + random.nextInt(1000)
          : 1 + random.nextInt(1 << 30) * 931; // up to ~1e12
      final count = 1 + random.nextInt(maxSplitParticipants);
      final uids = List.generate(count, (j) => 'uid$j');
      final equal = splitEqual(total, uids);
      expect(sumShares(equal), total);
      expect(equal.values.every((v) => v >= 0), isTrue);
      final maxShare = equal.values.reduce(max);
      final minShare = equal.values.reduce(min);
      expect(maxShare - minShare, lessThanOrEqualTo(1));

      final weights = {for (final u in uids) u: 1 + random.nextInt(10)};
      final weighted = splitByWeights(total, weights);
      expect(sumShares(weighted), total);
      expect(weighted.values.every((v) => v >= 0), isTrue);
    }
  });
}
