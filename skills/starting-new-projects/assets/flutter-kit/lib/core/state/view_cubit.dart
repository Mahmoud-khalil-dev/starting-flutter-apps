import 'package:dartz/dartz.dart';
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/core/state/safe_cubit.dart';
import 'package:kit_app/core/state/view_state.dart';

/// One load at a time, through a repository call. Only the latest call's
/// answer lands: an older one that arrives late is dropped.
class ViewCubit<T> extends SafeCubit<ViewState<T>> {
  ViewCubit() : super(ViewState<T>.idle());

  int _run = 0;

  Future<void> run(
    Future<Either<Failure, T>> Function() fetch, {
    bool Function(T data)? isEmpty,
  }) async {
    final ticket = ++_run;
    emit(ViewState<T>.loading(previous: state.data));
    final result = await fetch();
    if (ticket != _run) return;
    emit(
      result.fold(
        (failure) => ViewState<T>.failure(failure, previous: state.data),
        (data) => (isEmpty?.call(data) ?? false)
            ? ViewState<T>.empty()
            : ViewState<T>.success(data),
      ),
    );
  }
}
