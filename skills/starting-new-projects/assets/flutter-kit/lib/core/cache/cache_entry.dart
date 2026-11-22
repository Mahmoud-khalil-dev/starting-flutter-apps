import 'package:equatable/equatable.dart';

/// One cached value: JSON-shaped data and when it was stored.
class CacheEntry extends Equatable {
  const CacheEntry({required this.value, required this.storedAt});

  final Object? value;
  final DateTime storedAt;

  bool isFresh(DateTime now, Duration ttl) => now.difference(storedAt) < ttl;

  Map<String, Object?> toJson() => {
    'v': value,
    't': storedAt.toUtc().millisecondsSinceEpoch,
  };

  /// Null for anything this class did not write.
  static CacheEntry? fromJson(Object? json) {
    if (json is! Map<String, dynamic> || !json.containsKey('v')) return null;
    final stamp = json['t'];
    if (stamp is! int) return null;
    return CacheEntry(
      value: json['v'],
      storedAt: DateTime.fromMillisecondsSinceEpoch(stamp, isUtc: true),
    );
  }

  @override
  List<Object?> get props => [value, storedAt];
}
