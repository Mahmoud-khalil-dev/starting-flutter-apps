import 'package:bloc/bloc.dart';

/// A Cubit that drops a state arriving after close instead of throwing. An
/// answer that lands after the user left the screen is no error.
abstract class SafeCubit<S> extends Cubit<S> {
  SafeCubit(super.initialState);

  @override
  void emit(S state) {
    if (isClosed) return;
    super.emit(state);
  }
}
