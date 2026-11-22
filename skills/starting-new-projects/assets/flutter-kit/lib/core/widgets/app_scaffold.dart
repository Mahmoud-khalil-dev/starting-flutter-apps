import 'package:flutter/material.dart';
import 'package:kit_app/core/theme/app_colors.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/app_text_styles.dart';
import 'package:kit_app/core/widgets/connection_banner.dart';

/// Every new screen's frame: title bar, the connection banner, the body
/// capped at [AppDimensions.contentMaxWidth] (unless [wide]), and an
/// optional bottom bar that rides above the keyboard.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.body,
    this.title,
    this.actions = const [],
    this.bottomBar,
    this.wide = false,
    this.leading,
    super.key,
  });

  final String? title;
  final List<Widget> actions;
  final Widget body;
  final Widget? bottomBar;
  final bool wide;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final connection = ConnectionScope.maybeOf(context);
    final content = wide
        ? body
        : Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppDimensions.contentMaxWidth,
              ),
              child: body,
            ),
          );
    return Scaffold(
      backgroundColor: context.colors.background,
      resizeToAvoidBottomInset: true,
      appBar: title == null && actions.isEmpty && leading == null
          ? null
          : AppBar(
              leading: leading,
              title: title == null
                  ? null
                  : Text(title!, style: context.text.title),
              actions: actions,
            ),
      body: Column(
        children: [
          if (connection != null)
            ConnectionBanner(
              statuses: connection.statuses,
              initial: connection.initial,
            ),
          Expanded(
            child: bottomBar == null
                ? SafeArea(top: false, child: content)
                : content,
          ),
        ],
      ),
      bottomNavigationBar: bottomBar,
    );
  }
}
