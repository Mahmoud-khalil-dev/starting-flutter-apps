import 'package:equatable/equatable.dart';
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/core/widgets/app_state_view.dart';

enum ViewStatus { idle, loading, success, empty, failure }

/// What a screen shows for one load: nothing yet, loading, the data, an
/// empty answer, or a failure. Loading and failure keep the data already
/// on screen ([data]), so a refresh never blanks the screen.
class ViewState<T> extends Equatable {
  const ViewState.idle() : this._(ViewStatus.idle);

  const ViewState.loading({T? previous})
    : this._(ViewStatus.loading, data: previous);

  const ViewState.success(T data) : this._(ViewStatus.success, data: data);

  const ViewState.empty() : this._(ViewStatus.empty);

  const ViewState.failure(Failure failure, {T? previous})
    : this._(ViewStatus.failure, data: previous, failure: failure);

  const ViewState._(this.status, {this.data, this.failure});

  final ViewStatus status;
  final T? data;
  final Failure? failure;

  bool get isLoading => status == ViewStatus.loading;

  /// The state `AppStateView` shows. Data on screen wins over loading and
  /// over a failure; the failure then shows as a snackbar or inline error.
  ScreenStatus get screenStatus => switch (status) {
    ViewStatus.idle || ViewStatus.loading =>
      data != null ? ScreenStatus.content : ScreenStatus.loading,
    ViewStatus.success => ScreenStatus.content,
    ViewStatus.empty => ScreenStatus.empty,
    ViewStatus.failure =>
      data != null
          ? ScreenStatus.content
          : failure is NoConnection
          ? ScreenStatus.offline
          : ScreenStatus.error,
  };

  @override
  List<Object?> get props => [status, data, failure];
}
