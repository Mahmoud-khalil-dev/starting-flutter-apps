import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/utils/debouncer.dart';

void main() {
  test('KIT-T15: only the last call of a burst runs', () {
    fakeAsync((async) {
      final debouncer = Debouncer(const Duration(milliseconds: 300));
      final ran = <int>[];
      debouncer(() => ran.add(1));
      async.elapse(const Duration(milliseconds: 200));
      debouncer(() => ran.add(2));
      expect(debouncer.pending, isTrue);
      async.elapse(const Duration(milliseconds: 300));
      expect(ran, [2]);
      expect(debouncer.pending, isFalse);
    });
  });

  test('KIT-T15: dispose drops the pending call', () {
    fakeAsync((async) {
      final debouncer = Debouncer(const Duration(milliseconds: 300));
      var ran = false;
      debouncer(() => ran = true);
      debouncer.dispose();
      async.elapse(const Duration(seconds: 1));
      expect(ran, isFalse);
    });
  });

  test('KIT-T15: cancel drops the pending call and allows a new one', () {
    fakeAsync((async) {
      final debouncer = Debouncer(const Duration(milliseconds: 300));
      var ran = 0;
      debouncer(() => ran++);
      debouncer.cancel();
      expect(debouncer.pending, isFalse);
      async.elapse(const Duration(seconds: 1));
      expect(ran, 0);
      debouncer(() => ran++);
      async.elapse(const Duration(seconds: 1));
      expect(ran, 1);
    });
  });

  test('KIT-T15: a call after dispose does nothing', () {
    fakeAsync((async) {
      final debouncer = Debouncer(const Duration(milliseconds: 300))..dispose();
      var ran = false;
      debouncer(() => ran = true);
      expect(debouncer.pending, isFalse);
      async.elapse(const Duration(seconds: 1));
      expect(ran, isFalse);
    });
  });
}
