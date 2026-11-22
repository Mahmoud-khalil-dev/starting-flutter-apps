import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/telemetry/recording_mask.dart';
import 'package:kit_app/core/widgets/app_sensitive.dart';
import 'package:kit_app/core/widgets/app_text_field.dart';

import '../../helpers/pump_app.dart';

/// A masker that leaves a mark a test can find, standing in for a project's
/// session recorder.
class _Mask extends StatelessWidget {
  const _Mask({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

Widget _recording(Widget child) => _Mask(child: child);

Widget _scoped(Widget child) =>
    RecordingMaskScope(masker: _recording, child: child);

void main() {
  testWidgets(
    'KIT-T11: AppSensitive hands its child to the registered masker',
    (t) async {
      await pumpApp(t, _scoped(const AppSensitive(child: Text('Alex'))));
      expect(
        find.ancestor(of: find.text('Alex'), matching: find.byType(_Mask)),
        findsOneWidget,
      );
    },
  );

  testWidgets('KIT-T11: with no masker registered AppSensitive masks nothing', (
    t,
  ) async {
    await pumpApp(t, const AppSensitive(child: Text('Alex')));
    expect(find.text('Alex'), findsOneWidget);
    expect(find.byType(_Mask), findsNothing);
  });

  testWidgets('KIT-T11: a kit text field is masked unless it opts out', (
    t,
  ) async {
    await pumpApp(t, _scoped(const AppTextField(label: 'Email')));
    expect(
      find.ancestor(of: find.byType(TextField), matching: find.byType(_Mask)),
      findsOneWidget,
    );

    await pumpApp(
      t,
      _scoped(const AppTextField(label: 'Search', sensitive: false)),
    );
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(_Mask), findsNothing);
  });

  test('KIT-T11: the default masker returns the child unchanged', () {
    const child = Text('Alex');
    expect(unmasked(child), same(child));
  });
}
