import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:kit_app/core/theme/app_colors.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/motion.dart';
import 'package:kit_app/core/utils/context_extensions.dart';
import 'package:kit_app/core/widgets/app_shimmer.dart';

/// A network image, cached on the device, with a shimmer while it loads and
/// a quiet icon when it cannot, which a tap tries again. It is decoded at
/// the size of its slot, not at the size of the file. The fade follows the
/// motion tokens and shortens under reduce motion. Pass [semanticLabel] when
/// the image says something; without one a screen reader skips it.
class AppNetworkImage extends StatefulWidget {
  const AppNetworkImage({
    required this.url,
    this.width,
    this.height,
    this.radius = AppDimensions.radiusMd,
    this.fit = BoxFit.cover,
    this.cacheManager,
    this.semanticLabel,
    super.key,
  });

  final String url;
  final double? width;
  final double? height;
  final double radius;
  final BoxFit fit;

  /// The disk cache. Null uses the plugin's default (the browser's on the
  /// web). A test passes a double.
  final BaseCacheManager? cacheManager;
  final String? semanticLabel;

  @override
  State<AppNetworkImage> createState() => _AppNetworkImageState();
}

class _AppNetworkImageState extends State<AppNetworkImage> {
  // A new key makes the image load afresh after a retry.
  var _attempt = 0;

  Future<void> _retry() async {
    try {
      await CachedNetworkImage.evictFromCache(
        widget.url,
        cacheManager: widget.cacheManager,
      );
    } on Object {
      // A cache that cannot forget the failure still loads again.
    }
    if (mounted) setState(() => _attempt++);
  }

  Widget _unavailable(BuildContext context, {required bool retry}) {
    final l10n = context.l10n;
    final box = SizedBox(
      width: widget.width,
      height: widget.height,
      child: ColoredBox(
        color: context.colors.surfaceRaised,
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: AppDimensions.iconLg,
            color: context.colors.hint,
            semanticLabel: l10n.mediaImageUnavailable,
          ),
        ),
      ),
    );
    if (!retry) return box;
    return Semantics(
      button: true,
      hint: l10n.kitRetry,
      child: InkWell(onTap: _retry, child: box),
    );
  }

  int? _pixels(double? logical, double ratio) =>
      logical == null || !logical.isFinite || logical <= 0
      ? null
      : (logical * ratio).round();

  @override
  Widget build(BuildContext context) {
    final ratio = MediaQuery.devicePixelRatioOf(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      // No address (a user without a photo): the quiet state, no request.
      child: widget.url.isEmpty
          ? _unavailable(context, retry: false)
          : Semantics(
              image: true,
              label: widget.semanticLabel,
              child: CachedNetworkImage(
                key: ValueKey(_attempt),
                imageUrl: widget.url,
                cacheManager: widget.cacheManager,
                width: widget.width,
                height: widget.height,
                memCacheWidth: _pixels(widget.width, ratio),
                memCacheHeight: _pixels(widget.height, ratio),
                fit: widget.fit,
                fadeInDuration: context.motion.fade(Motion.standard),
                fadeOutDuration: context.motion.fade(Motion.quick),
                // A list of images is one loading region, not one
                // announcement each.
                placeholder: (context, url) => AppShimmer(
                  announce: false,
                  child: AppSkeleton(
                    height: widget.height ?? AppDimensions.avatarLg,
                    width: widget.width,
                    radius: widget.radius,
                  ),
                ),
                errorWidget: (context, url, error) =>
                    _unavailable(context, retry: true),
              ),
            ),
    );
  }
}
