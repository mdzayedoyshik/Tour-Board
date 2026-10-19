/// Deterministic split allocation in integer minor units.
///
/// Every function here guarantees that the returned shares sum exactly to the
/// total. Participant order is normalised (sorted by uid) before remainders are
/// handed out, so two devices always compute identical shares.
library;

enum SplitMethod { equal, custom, shares }

SplitMethod splitMethodFromName(String? name) => SplitMethod.values.firstWhere(
  (m) => m.name == name,
  orElse: () => SplitMethod.equal,
);

class SplitException implements Exception {
  const SplitException(this.reason);
  final SplitError reason;
  @override
  String toString() => 'SplitException($reason)';
}

enum SplitError {
  noParticipants,
  nonPositiveTotal,
  negativeShare,
  invalidWeight,
  sumMismatch,
  tooManyParticipants,
}

/// Mirrors `maxParticipants()` in firestore.rules.
const int maxSplitParticipants = 30;

/// Splits [totalMinor] equally between [uids].
///
/// Remainder minor units go one each to the first participants in sorted uid
/// order, e.g. 100 / 3 -> 34, 33, 33.
Map<String, int> splitEqual(int totalMinor, Iterable<String> uids) {
  final ordered = _normalise(uids);
  _checkTotal(totalMinor);
  final base = totalMinor ~/ ordered.length;
  var remainder = totalMinor - base * ordered.length;
  final result = <String, int>{};
  for (final uid in ordered) {
    final extra = remainder > 0 ? 1 : 0;
    remainder -= extra;
    result[uid] = base + extra;
  }
  return result;
}

/// Splits [totalMinor] proportionally to integer [weights] using the
/// largest-remainder method. Ties are broken by sorted uid order.
Map<String, int> splitByWeights(int totalMinor, Map<String, int> weights) {
  final ordered = _normalise(weights.keys);
  _checkTotal(totalMinor);
  var weightSum = 0;
  for (final uid in ordered) {
    final w = weights[uid]!;
    if (w <= 0 || w > 1000) {
      throw const SplitException(SplitError.invalidWeight);
    }
    weightSum += w;
  }

  // floor(total * w / sum) for each participant; products stay < 2^63 since
  // total <= ~1e12 and weightSum <= 30 * 1000.
  final result = <String, int>{};
  final remainders = <String, int>{};
  var allocated = 0;
  for (final uid in ordered) {
    final product = totalMinor * weights[uid]!;
    result[uid] = product ~/ weightSum;
    remainders[uid] = product % weightSum;
    allocated += result[uid]!;
  }

  // Hand out leftover units to the largest remainders first.
  var leftover = totalMinor - allocated;
  final byRemainder = [...ordered]
    ..sort((a, b) {
      final cmp = remainders[b]!.compareTo(remainders[a]!);
      return cmp != 0 ? cmp : a.compareTo(b);
    });
  for (final uid in byRemainder) {
    if (leftover == 0) break;
    result[uid] = result[uid]! + 1;
    leftover--;
  }
  return result;
}

/// Validates explicit custom shares; they must be non-negative and sum
/// exactly to [totalMinor]. Returns a copy with zero entries removed.
Map<String, int> validateCustomSplit(int totalMinor, Map<String, int> shares) {
  _checkTotal(totalMinor);
  final cleaned = <String, int>{};
  var sum = 0;
  for (final entry in shares.entries) {
    if (entry.value < 0) throw const SplitException(SplitError.negativeShare);
    if (entry.value == 0) continue;
    cleaned[entry.key] = entry.value;
    sum += entry.value;
  }
  // Report the mismatch first: "nothing entered yet" is a sum problem.
  if (sum != totalMinor) throw const SplitException(SplitError.sumMismatch);
  _normalise(cleaned.keys);
  return cleaned;
}

/// Sum of all values; used for validation and previews.
int sumShares(Map<String, int> shares) =>
    shares.values.fold(0, (sum, value) => sum + value);

List<String> _normalise(Iterable<String> uids) {
  final ordered = uids.toSet().toList()..sort();
  if (ordered.isEmpty) throw const SplitException(SplitError.noParticipants);
  if (ordered.length > maxSplitParticipants) {
    throw const SplitException(SplitError.tooManyParticipants);
  }
  return ordered;
}

void _checkTotal(int totalMinor) {
  if (totalMinor <= 0) throw const SplitException(SplitError.nonPositiveTotal);
}
