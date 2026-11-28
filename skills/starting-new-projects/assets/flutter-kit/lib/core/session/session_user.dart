import 'package:equatable/equatable.dart';
import 'package:kit_app/core/network/json_read.dart';
import 'package:kit_app/core/session/app_role.dart';

/// The signed-in user as the session needs it. [raw] is the backend's user
/// object as received, so a feature can read any field the kit does not
/// name while the app runs. Only [storedFields] are saved to the device.
class SessionUser extends Equatable {
  const SessionUser({
    required this.raw,
    this.id,
    this.role,
    this.status,
    this.name,
    this.email,
    this.phone,
    this.photo,
  });

  final Map<String, dynamic> raw;
  final int? id;
  final AppRole? role;
  final UserStatus? status;
  final String? name;
  final String? email;
  final String? phone;
  final String? photo;

  /// The user fields kept in SharedPreferences across restarts. Preferences
  /// are not encrypted, so a field the backend adds (an ID number, an
  /// address) stays off the device until someone lists it here on purpose.
  static const storedFields = [
    'id',
    'role',
    'status',
    'name',
    'email',
    'phone',
    'photo',
  ];

  /// The part of [user] that may be saved to the device.
  static Map<String, dynamic> stored(Map<String, dynamic> user) => {
    for (final key in storedFields)
      if (user.containsKey(key)) key: user[key],
  };

  static SessionUser? fromJson(Object? json) {
    final user = JsonRead.map(json);
    if (user == null) return null;
    return SessionUser(
      raw: user,
      id: JsonRead.integer(user['id']),
      role: AppRole.parse(user['role']),
      status: UserStatus.parse(user['status']),
      name: JsonRead.string(user['name']),
      email: JsonRead.string(user['email']),
      phone: JsonRead.string(user['phone']),
      photo: JsonRead.string(user['photo']),
    );
  }

  /// The user object in a response body: `data.user`, or `data` itself when
  /// it has an `id`.
  static Map<String, dynamic>? userIn(Object? body) {
    final data = JsonRead.data(body);
    if (data == null) return null;
    return JsonRead.map(data['user']) ?? (data['id'] != null ? data : null);
  }

  @override
  List<Object?> get props => [raw];
}
