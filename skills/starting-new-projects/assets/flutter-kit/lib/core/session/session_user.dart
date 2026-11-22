import 'package:equatable/equatable.dart';
import 'package:kit_app/core/network/json_read.dart';
import 'package:kit_app/core/session/app_role.dart';

/// The signed-in user as the session needs it. [raw] is the backend's user
/// object as received, kept and saved unchanged, so a feature can read any
/// field the kit does not name.
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
