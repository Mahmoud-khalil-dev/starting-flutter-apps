import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:kit_app/app/kit_gallery/kit_gallery_screen.dart';
import 'package:kit_app/app/router/app_route.dart';
import 'package:kit_app/core/router/route_names.dart';

/// The gallery route. Empty in a release build: the const [kDebugMode]
/// folds the branch away, so the screen is tree-shaken whatever the
/// router is asked.
List<RouteBase> kitGalleryRoutes() => kDebugMode
    ? [
        appRoute(
          path: RouteNames.kitGallery,
          builder: (context, state) => const KitGalleryScreen(),
        ),
      ]
    : const [];
