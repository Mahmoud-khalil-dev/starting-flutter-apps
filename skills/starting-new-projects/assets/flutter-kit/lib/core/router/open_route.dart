import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:kit_app/core/router/route_names.dart';

/// The one way new code navigates. A tab is gone to, which resets its
/// stack; anything else is pushed over the current screen.
void openRoute(BuildContext context, String location, {Object? extra}) {
  final router = GoRouter.of(context);
  if (RouteNames.tabs.contains(Uri.parse(location).path)) {
    router.go(location, extra: extra);
  } else {
    unawaited(router.push<void>(location, extra: extra));
  }
}
