import 'package:flutter/widgets.dart';

/// Wraps a subtree so a session recorder leaves it out of its recordings.
/// The kit knows no recorder: a project that records sessions registers a
/// function that wraps [child] in its recorder's mask widget. The default,
/// [unmasked], returns [child] unchanged.
typedef RecordingMasker = Widget Function(Widget child);

/// The default [RecordingMasker]: records nothing, so it masks nothing.
Widget unmasked(Widget child) => child;

/// Hands the app's [RecordingMasker] to the widgets below it. `App` installs
/// it from the locator; with none above, [of] answers [unmasked].
class RecordingMaskScope extends InheritedWidget {
  const RecordingMaskScope({
    required this.masker,
    required super.child,
    super.key,
  });

  final RecordingMasker masker;

  static RecordingMasker of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<RecordingMaskScope>()
          ?.masker ??
      unmasked;

  @override
  bool updateShouldNotify(RecordingMaskScope old) => old.masker != masker;
}
