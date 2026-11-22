import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/core/state/view_state.dart';
import 'package:kit_app/core/widgets/app_state_view.dart';

void main() {
  test('KIT-T14: each view status maps to one screen status', () {
    expect(const ViewState<int>.idle().screenStatus, ScreenStatus.loading);
    expect(const ViewState<int>.loading().screenStatus, ScreenStatus.loading);
    expect(const ViewState<int>.success(1).screenStatus, ScreenStatus.content);
    expect(const ViewState<int>.empty().screenStatus, ScreenStatus.empty);
    expect(
      const ViewState<int>.failure(ServerFailure(500)).screenStatus,
      ScreenStatus.error,
    );
    expect(
      const ViewState<int>.failure(NoConnection()).screenStatus,
      ScreenStatus.offline,
    );
  });

  test('KIT-T14: data on screen stays while loading and after a failure', () {
    expect(
      const ViewState<int>.loading(previous: 3).screenStatus,
      ScreenStatus.content,
    );
    const failed = ViewState<int>.failure(NoConnection(), previous: 3);
    expect(failed.screenStatus, ScreenStatus.content);
    expect(failed.data, 3);
    expect(failed.failure, const NoConnection());
  });
}
