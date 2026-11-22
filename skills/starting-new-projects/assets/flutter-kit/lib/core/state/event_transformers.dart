import 'dart:async';

import 'package:bloc/bloc.dart';

/// The pause after the last keystroke before a search runs.
const searchDebounce = Duration(milliseconds: 300);

/// For a Bloc event such as a search query: only the last event of a burst
/// runs, [wait] after it arrived. Closing the Bloc drops a pending event.
EventTransformer<E> debounce<E>(Duration wait) =>
    (events, mapper) => _debounced(events, wait).asyncExpand(mapper);

/// For a Bloc event such as a refresh pull: the first event runs, the rest
/// inside [window] are dropped.
EventTransformer<E> throttle<E>(Duration window) =>
    (events, mapper) => _throttled(events, window).asyncExpand(mapper);

Stream<E> _debounced<E>(Stream<E> source, Duration wait) {
  Timer? timer;
  return source.transform(
    StreamTransformer<E, E>.fromHandlers(
      handleData: (event, sink) {
        timer?.cancel();
        timer = Timer(wait, () => sink.add(event));
      },
      handleDone: (sink) {
        timer?.cancel();
        sink.close();
      },
    ),
  );
}

Stream<E> _throttled<E>(Stream<E> source, Duration window) {
  Timer? gate;
  StreamSubscription<E>? subscription;
  late final StreamController<E> controller;
  controller = StreamController<E>(
    onListen: () {
      subscription = source.listen(
        (event) {
          if (gate?.isActive ?? false) return;
          gate = Timer(window, () {});
          controller.add(event);
        },
        onError: controller.addError,
        onDone: controller.close,
      );
    },
    onPause: () => subscription?.pause(),
    onResume: () => subscription?.resume(),
    onCancel: () {
      gate?.cancel();
      return subscription?.cancel();
    },
  );
  return controller.stream;
}
