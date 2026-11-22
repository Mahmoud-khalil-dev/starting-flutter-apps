import 'package:equatable/equatable.dart';
import 'package:kit_app/core/network/json_read.dart';
import 'package:kit_app/core/session/session_user.dart';

/// The token and user a sign-in or sign-up answer carries in `data`.
class AuthResult extends Equatable {
  const AuthResult({required this.token, required this.user});

  final String token;
  final Map<String, dynamic> user;

  /// Null when either is missing.
  static AuthResult? fromBody(Object? body) {
    final token = JsonRead.string(JsonRead.data(body)?['token']);
    final user = SessionUser.userIn(body);
    if (token == null || token.isEmpty || user == null) return null;
    return AuthResult(token: token, user: user);
  }

  @override
  List<Object?> get props => [token, user];
}
