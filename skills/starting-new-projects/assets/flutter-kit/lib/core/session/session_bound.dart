/// A long-lived Cubit that holds user data. Its module registers it, and
/// the end of a session resets every registered one.
abstract interface class SessionBound {
  void reset();
}

class SessionBoundRegistry {
  final _resolvers = <SessionBound Function()>[];

  void add(SessionBound Function() resolve) => _resolvers.add(resolve);

  /// Resets every registered Cubit, even after one fails, then rethrows the
  /// first failure: one broken reset must not leave another user's data in
  /// the next Cubit.
  void resetAll() {
    Object? firstError;
    StackTrace? firstStack;
    for (final resolve in _resolvers) {
      try {
        resolve().reset();
      } on Object catch (error, stack) {
        if (firstError == null) {
          firstError = error;
          firstStack = stack;
        }
      }
    }
    if (firstError != null) Error.throwWithStackTrace(firstError, firstStack!);
  }
}
