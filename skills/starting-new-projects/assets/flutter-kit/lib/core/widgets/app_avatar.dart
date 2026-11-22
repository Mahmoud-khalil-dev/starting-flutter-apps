import 'package:flutter/material.dart';
import 'package:kit_app/core/theme/app_colors.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/app_text_styles.dart';
import 'package:kit_app/core/theme/motion.dart';

/// A round portrait that holds its square in every state (before the image
/// arrives, after a failure, without one), fades the image in, and shows
/// initials without an image or after a failure. [heroTag] lets a list
/// avatar fly to the profile.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    required this.name,
    this.image,
    this.size = AppDimensions.avatarMd,
    this.heroTag,
    super.key,
  });

  /// Loads [url] with Flutter's own image cache. A project that needs a disk
  /// cache passes its own provider as [image].
  factory AppAvatar.network(
    String? url, {
    required String name,
    double size = AppDimensions.avatarMd,
    Object? heroTag,
    Key? key,
  }) => AppAvatar(
    key: key,
    name: name,
    size: size,
    heroTag: heroTag,
    image: url == null || url.isEmpty ? null : NetworkImage(url),
  );

  final ImageProvider? image;
  final String name;
  final double size;
  final Object? heroTag;

  static String initialsOf(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    return words
        .take(2)
        .map((w) => String.fromCharCode(w.runes.first))
        .join()
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final initials = Center(
      child: Text(
        initialsOf(name),
        // primaryInk, not the brand navy: navy on the dark raised disc would
        // all but vanish. Navy in light, soft blue in dark, both over 4.5:1.
        style: AppTextStyles.weighted(
          context.text.label.copyWith(color: c.primaryInk),
          FontWeight.w600,
        ),
      ),
    );
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final Widget disc = SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: ColoredBox(
          color: c.surfaceRaised,
          child: image == null
              ? initials
              : Image(
                  image: ResizeImage(
                    image!,
                    // Cover keeps the short side at or above the target; a
                    // fit bound of twice the target holds that for
                    // portraits up to 2:1 without decoding them whole.
                    width: (size * dpr).round() * 2,
                    height: (size * dpr).round() * 2,
                    policy: ResizeImagePolicy.fit,
                  ),
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                  frameBuilder: (context, child, frame, sync) => sync
                      ? child
                      : AnimatedOpacity(
                          opacity: frame == null ? 0 : 1,
                          duration: context.motion.fade(Motion.standard),
                          curve: Motion.enter,
                          child: child,
                        ),
                  errorBuilder: (_, _, _) => initials,
                ),
        ),
      ),
    );
    // A parent too tight for [size] scales the avatar down, still square.
    final avatar = Semantics(
      image: true,
      label: name,
      excludeSemantics: true,
      child: FittedBox(fit: BoxFit.scaleDown, child: disc),
    );
    return heroTag == null ? avatar : Hero(tag: heroTag!, child: avatar);
  }
}
