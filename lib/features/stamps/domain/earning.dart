/// One payment of **stamp**s, recorded against the event that earned it.
///
/// The key names the event (D-133), and it is the whole of what makes "each
/// event pays once" true: a second **earning** under a key already recorded is
/// the same event arriving twice, and storage keeps the first.
final class Earning {
  const Earning({required this.key, required this.amount});

  final String key;
  final int amount;

  @override
  bool operator ==(Object other) =>
      other is Earning && other.key == key && other.amount == amount;

  @override
  int get hashCode => Object.hash(key, amount);

  @override
  String toString() => 'Earning($key, $amount)';
}
