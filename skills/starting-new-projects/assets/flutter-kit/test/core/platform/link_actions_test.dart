import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/platform/link_actions.dart';
import 'package:kit_app/core/platform/platform_capabilities.dart';

const _phone = PlatformCapabilities(isWeb: false, platform: TargetPlatform.iOS);
const _web = PlatformCapabilities(
  isWeb: true,
  platform: TargetPlatform.android,
);

void main() {
  late List<Uri> launched;
  late List<String> shared;
  late List<String> copied;

  LinkActions actions(PlatformCapabilities capabilities) => LinkActions(
    capabilities: capabilities,
    launch: (uri) async {
      launched.add(uri);
      return true;
    },
    share: (text, {subject, origin}) async => shared.add(text),
    copy: (text) async => copied.add(text),
  );

  setUp(() {
    launched = [];
    shared = [];
    copied = [];
  });

  test('KIT-T15: only web, mail and phone links open', () async {
    final links = actions(_phone);
    expect(await links.open(Uri.parse('https://example.com/a')), isTrue);
    expect(await links.open(Uri.parse('mailto:hello@example.com')), isTrue);
    expect(await links.open(Uri.parse('tel:+15550100')), isTrue);
    expect(await links.open(Uri.parse('javascript:alert(1)')), isFalse);
    expect(await links.open(Uri.parse('file:///etc/hosts')), isFalse);
    expect(launched, hasLength(3));
  });

  test('KIT-T15: the web build never tries to dial', () async {
    final links = actions(_web);
    expect(links.canOpen(Uri.parse('tel:+15550100')), isFalse);
    expect(await links.open(Uri.parse('tel:+15550100')), isFalse);
    expect(launched, isEmpty);
  });

  test('KIT-T15: the web build still opens web and mail links', () async {
    final links = actions(_web);
    expect(await links.open(Uri.parse('https://example.com')), isTrue);
    expect(await links.open(Uri.parse('mailto:a@example.com')), isTrue);
  });

  test('KIT-T15: a launcher that returns false gives false', () async {
    final links = LinkActions(
      capabilities: _phone,
      launch: (uri) async => false,
    );
    expect(await links.open(Uri.parse('https://example.com')), isFalse);
  });

  test('KIT-T15: a launcher that throws gives false, never an error', () async {
    final links = LinkActions(
      capabilities: _phone,
      launch: (uri) async => throw PlatformException(code: 'no-app'),
    );
    expect(await links.open(Uri.parse('https://example.com')), isFalse);
  });

  test('KIT-T15: a share that throws reports a failure', () async {
    final links = LinkActions(
      capabilities: _phone,
      share: (text, {subject, origin}) async =>
          throw PlatformException(code: 'no-sheet'),
    );
    expect(await links.share('Hello'), ShareOutcome.failed);
  });

  test('KIT-T15: a copy that throws reports a failure', () async {
    final links = LinkActions(
      capabilities: _web,
      copy: (text) async => throw PlatformException(code: 'no-clipboard'),
    );
    expect(await links.share('Hello'), ShareOutcome.failed);
  });

  test('KIT-T15: sharing uses the sheet on a phone', () async {
    final outcome = await actions(
      _phone,
    ).share('Hello', origin: const Rect.fromLTWH(0, 0, 1, 1));
    expect(outcome, ShareOutcome.shared);
    expect(shared, ['Hello']);
    expect(copied, isEmpty);
  });

  test('KIT-T15: sharing on the web copies the text', () async {
    expect(await actions(_web).share('Hello'), ShareOutcome.copied);
    expect(copied, ['Hello']);
    expect(shared, isEmpty);
  });
}
