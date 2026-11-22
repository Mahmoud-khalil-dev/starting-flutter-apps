import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/core/state/paged_list_cubit.dart';
import 'package:kit_app/core/state/view_state.dart';
import 'package:kit_app/core/widgets/app_state_view.dart';

class _Pages {
  final answers =
      <int, Future<Either<Failure, PageResult<String>>> Function()>{};
  final asked = <int>[];

  Future<Either<Failure, PageResult<String>>> call(int page) {
    asked.add(page);
    return answers[page]!();
  }

  void set(int page, List<String> items, {bool hasMore = false}) =>
      answers[page] = () async =>
          Right(PageResult(items: items, hasMore: hasMore));
}

void main() {
  late _Pages pages;
  late PagedListCubit<String> cubit;

  setUp(() {
    pages = _Pages();
    cubit = PagedListCubit<String>(pages.call);
  });
  tearDown(() => cubit.close());

  test('KIT-T14: refresh loads the first page', () async {
    pages.set(1, ['a', 'b'], hasMore: true);
    await cubit.refresh();
    expect(cubit.state.items, ['a', 'b']);
    expect(cubit.state.status, ViewStatus.success);
    expect(cubit.state.page, 1);
    expect(cubit.state.hasMore, isTrue);
    expect(cubit.state.screenStatus, ScreenStatus.content);
  });

  test('KIT-T14: load more appends and stops at the end', () async {
    pages
      ..set(1, ['a', 'b'], hasMore: true)
      ..set(2, ['c']);
    await cubit.refresh();
    await cubit.loadMore();
    await cubit.loadMore();
    expect(cubit.state.items, ['a', 'b', 'c']);
    expect(cubit.state.hasMore, isFalse);
    expect(pages.asked, [1, 2]);
  });

  test('KIT-T14: a failed page keeps the list and can be retried', () async {
    pages
      ..set(1, ['a'], hasMore: true)
      ..answers[2] = () async => const Left(NoConnection());
    await cubit.refresh();
    await cubit.loadMore();
    expect(cubit.state.items, ['a']);
    expect(cubit.state.moreFailure, const NoConnection());
    expect(cubit.state.loadingMore, isFalse);
    pages.set(2, ['b']);
    await cubit.retryMore();
    expect(cubit.state.items, ['a', 'b']);
    expect(cubit.state.moreFailure, isNull);
  });

  test('KIT-T14: an empty first page is the empty state', () async {
    pages.set(1, []);
    await cubit.refresh();
    expect(cubit.state.status, ViewStatus.empty);
    expect(cubit.state.screenStatus, ScreenStatus.empty);
  });

  test('KIT-T14: a first page offline is the offline state', () async {
    pages.answers[1] = () async => const Left(NoConnection());
    await cubit.refresh();
    expect(cubit.state.screenStatus, ScreenStatus.offline);
  });

  test('KIT-T14: a page that answers after a refresh is dropped', () async {
    final slow = Completer<Either<Failure, PageResult<String>>>();
    pages
      ..set(1, ['a', 'b'], hasMore: true)
      ..answers[2] = () => slow.future;
    await cubit.refresh();
    final more = cubit.loadMore();
    pages.set(1, ['x'], hasMore: true);
    await cubit.refresh();
    slow.complete(const Right(PageResult(items: ['c'], hasMore: false)));
    await more;
    expect(cubit.state.items, ['x']);
  });

  test('KIT-T14: load more is ignored while one is running', () async {
    final slow = Completer<Either<Failure, PageResult<String>>>();
    pages
      ..set(1, ['a'], hasMore: true)
      ..answers[2] = () => slow.future;
    await cubit.refresh();
    final first = cubit.loadMore();
    await cubit.loadMore();
    slow.complete(const Right(PageResult(items: ['b'], hasMore: false)));
    await first;
    expect(pages.asked, [1, 2]);
  });

  test(
    'KIT-T14: a first page that answers after a newer refresh is dropped',
    () async {
      final slow = Completer<Either<Failure, PageResult<String>>>();
      pages.answers[1] = () => slow.future;
      final first = cubit.refresh();
      pages.set(1, ['new']);
      await cubit.refresh();
      slow.complete(const Right(PageResult(items: ['old'], hasMore: false)));
      await first;
      expect(cubit.state.items, ['new']);
    },
  );
}
