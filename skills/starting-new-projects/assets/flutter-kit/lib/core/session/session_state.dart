import 'package:equatable/equatable.dart';
import 'package:kit_app/core/session/app_role.dart';
import 'package:kit_app/core/session/session_user.dart';

enum SessionStatus { unknown, unauthenticated, authenticated }

class SessionState extends Equatable {
  const SessionState.unknown()
    : status = SessionStatus.unknown,
      role = null,
      userStatus = null,
      user = null,
      savedOnly = false;

  const SessionState.unauthenticated()
    : status = SessionStatus.unauthenticated,
      role = null,
      userStatus = null,
      user = null,
      savedOnly = false;

  const SessionState.authenticated({
    required this.role,
    required this.userStatus,
    this.user,
    this.savedOnly = false,
  }) : status = SessionStatus.authenticated;

  final SessionStatus status;
  final AppRole? role;
  final UserStatus? userStatus;
  final SessionUser? user;

  /// Restored from the cache; the profile refresh has not answered, or the
  /// device is offline (stale while revalidate).
  final bool savedOnly;

  @override
  List<Object?> get props => [status, role, userStatus, user, savedOnly];
}
