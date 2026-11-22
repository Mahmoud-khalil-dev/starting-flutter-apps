/// The API's `role`. Anything else is null, and the guard denies it.
///
/// Replace with the project's roles, then change `RouteGuard.access`,
/// `destinationsFor` and `AppRole.parse` together.
enum AppRole {
  member,
  admin;

  static AppRole? parse(Object? raw) => switch (raw) {
    'MEMBER' => AppRole.member,
    'ADMIN' => AppRole.admin,
    _ => null,
  };
}

/// The API's user `status`: the account is usable, still to be verified, or
/// blocked. Change the spellings to the API's own.
enum UserStatus {
  active,
  inactive,
  blocked;

  static UserStatus? parse(Object? raw) => switch (raw) {
    'ACTIVE' => UserStatus.active,
    'INACTIVE' => UserStatus.inactive,
    'BLOCKED' => UserStatus.blocked,
    _ => null,
  };
}
