import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/core/state/safe_cubit.dart';
import 'package:kit_app/core/state/view_state.dart';
import 'package:kit_app/core/widgets/app_state_view.dart';

/// One page from the API: its items and whether another follows.
class PageResult<T> extends Equatable {
  const PageResult({required this.items, required this.hasMore});

  final List<T> items;
  final bool hasMore;

  @override
  List<Object?> get props => [items, hasMore];
}

typedef PageFetch<T> =
    Future<Either<Failure, PageResult<T>>> Function(int page);

/// A paged list: the first page's status, the items so far, and the state
/// of the next page. Feeds `AppPagedList` (itemCount, hasMore, loadingMore,
/// loadMoreError from [moreFailure]).
class PagedListState<T> extends Equatable {
  const PagedListState({
    this.items = const [],
    this.status = ViewStatus.idle,
    this.page = 0,
    this.hasMore = false,
    this.loadingMore = false,
    this.failure,
    this.moreFailure,
  });

  final List<T> items;
  final ViewStatus status;
  final int page;
  final bool hasMore;
  final bool loadingMore;

  /// The first page failed.
  final Failure? failure;

  /// A later page failed; the items stay.
  final Failure? moreFailure;

  ScreenStatus get screenStatus {
    if (items.isNotEmpty) return ScreenStatus.content;
    return switch (status) {
      ViewStatus.idle || ViewStatus.loading => ScreenStatus.loading,
      ViewStatus.success => ScreenStatus.content,
      ViewStatus.empty => ScreenStatus.empty,
      ViewStatus.failure =>
        failure is NoConnection ? ScreenStatus.offline : ScreenStatus.error,
    };
  }

  /// A null-returning function clears a failure; omitting it keeps it.
  PagedListState<T> copyWith({
    List<T>? items,
    ViewStatus? status,
    int? page,
    bool? hasMore,
    bool? loadingMore,
    Failure? Function()? failure,
    Failure? Function()? moreFailure,
  }) => PagedListState<T>(
    items: items ?? this.items,
    status: status ?? this.status,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    failure: failure == null ? this.failure : failure(),
    moreFailure: moreFailure == null ? this.moreFailure : moreFailure(),
  );

  @override
  List<Object?> get props => [
    items,
    status,
    page,
    hasMore,
    loadingMore,
    failure,
    moreFailure,
  ];
}

/// Loads page after page. A refresh starts over and drops any page still
/// on its way; one next-page request runs at a time.
class PagedListCubit<T> extends SafeCubit<PagedListState<T>> {
  PagedListCubit(this._fetch, {this.firstPage = 1})
    : super(PagedListState<T>());

  final PageFetch<T> _fetch;
  final int firstPage;
  int _generation = 0;

  Future<void> refresh() async {
    final ticket = ++_generation;
    emit(
      state.copyWith(
        status: ViewStatus.loading,
        loadingMore: false,
        failure: () => null,
        moreFailure: () => null,
      ),
    );
    final result = await _fetch(firstPage);
    if (ticket != _generation) return;
    emit(
      result.fold(
        (failure) =>
            state.copyWith(status: ViewStatus.failure, failure: () => failure),
        (page) => PagedListState<T>(
          items: page.items,
          status: page.items.isEmpty ? ViewStatus.empty : ViewStatus.success,
          page: firstPage,
          hasMore: page.hasMore,
        ),
      ),
    );
  }

  Future<void> loadMore() async {
    if (state.status != ViewStatus.success ||
        !state.hasMore ||
        state.loadingMore) {
      return;
    }
    final ticket = _generation;
    final next = state.page + 1;
    emit(state.copyWith(loadingMore: true, moreFailure: () => null));
    final result = await _fetch(next);
    if (ticket != _generation) return;
    emit(
      result.fold(
        (failure) =>
            state.copyWith(loadingMore: false, moreFailure: () => failure),
        (page) => state.copyWith(
          items: [...state.items, ...page.items],
          page: next,
          hasMore: page.hasMore,
          loadingMore: false,
        ),
      ),
    );
  }

  Future<void> retryMore() => loadMore();
}
