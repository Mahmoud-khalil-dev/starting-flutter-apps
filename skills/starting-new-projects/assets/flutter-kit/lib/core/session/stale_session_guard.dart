/// For a Cubit whose fetches and actions answer after the session may have
/// ended: take `sessionGeneration()` before the request, and drop the late
/// state, navigation or disk write when [isStale] says the session moved on.
/// The request itself is never cancelled or resent.
mixin StaleSessionGuard {
  int Function() get sessionGeneration;

  bool isStale(int generation) => sessionGeneration() != generation;
}
