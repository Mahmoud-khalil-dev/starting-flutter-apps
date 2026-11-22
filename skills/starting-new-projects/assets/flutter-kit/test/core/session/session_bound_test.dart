import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/session/session_bound.dart';

class _Bound implements SessionBound {
  _Bound({this.error});

  final StateError? error;
  int resets = 0;

  @override
  void reset() {
    resets++;
    if (error != null) throw error!;
  }
}

void main() {
  // Characterization: the reset-all-then-rethrow fix landed with KIT-T10, so
  // this passes on its first run.
  test(
    'KIT-T10: one failing reset does not stop the next, and the first error is rethrown',
    () {
      final first = _Bound(error: StateError('first'));
      final second = _Bound();
      final third = _Bound(error: StateError('third'));
      final registry = SessionBoundRegistry()
        ..add(() => first)
        ..add(() => second)
        ..add(() => third);
      expect(
        registry.resetAll,
        throwsA(isA<StateError>().having((e) => e.message, 'message', 'first')),
      );
      expect([first.resets, second.resets, third.resets], [1, 1, 1]);
    },
  );
}
