import 'package:flutter/services.dart';
import 'package:kit_app/core/logging/app_log.dart';
import 'package:kit_app/core/platform/platform_capabilities.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// [failed]: the platform refused or threw; nothing was shared or copied.
enum ShareOutcome { shared, copied, failed }

/// Opens links and shares text through what the platform has. Only http,
/// https, mailto and tel open; tel only where [PlatformCapabilities.dial].
/// The web has no share sheet, so it copies (the caller shows a snackbar).
/// Plugin errors are caught: [open] gives false, [share] gives
/// [ShareOutcome.failed].
class LinkActions {
  LinkActions({
    required this.capabilities,
    Future<bool> Function(Uri uri)? launch,
    Future<void> Function(String text, {String? subject, Rect? origin})? share,
    Future<void> Function(String text)? copy,
  }) : _launch = launch ?? _launchExternal,
       _share = share ?? _shareSheet,
       _copy = copy ?? _clipboard;

  final PlatformCapabilities capabilities;
  final Future<bool> Function(Uri uri) _launch;
  final Future<void> Function(String text, {String? subject, Rect? origin})
  _share;
  final Future<void> Function(String text) _copy;

  static const _schemes = {'http', 'https', 'mailto', 'tel'};

  bool canOpen(Uri uri) {
    if (!_schemes.contains(uri.scheme)) return false;
    return uri.scheme != 'tel' || capabilities.dial;
  }

  /// False when the link is not allowed, nothing can open it or the platform
  /// throws. Never throws.
  Future<bool> open(Uri uri) async {
    if (!canOpen(uri)) return false;
    try {
      return await _launch(uri);
    } on Object catch (e) {
      AppLog.warn('open link failed: ${e.runtimeType}');
      return false;
    }
  }

  /// [origin] anchors the sheet on a tablet; pass the button's rectangle.
  Future<ShareOutcome> share(
    String text, {
    String? subject,
    Rect? origin,
  }) async {
    try {
      if (!capabilities.shareSheet) {
        await _copy(text);
        return ShareOutcome.copied;
      }
      await _share(text, subject: subject, origin: origin);
      return ShareOutcome.shared;
    } on Object catch (e) {
      AppLog.warn('share failed: ${e.runtimeType}');
      return ShareOutcome.failed;
    }
  }

  static Future<bool> _launchExternal(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  static Future<void> _shareSheet(
    String text, {
    String? subject,
    Rect? origin,
  }) async {
    await SharePlus.instance.share(
      ShareParams(text: text, subject: subject, sharePositionOrigin: origin),
    );
  }

  static Future<void> _clipboard(String text) =>
      Clipboard.setData(ClipboardData(text: text));
}
