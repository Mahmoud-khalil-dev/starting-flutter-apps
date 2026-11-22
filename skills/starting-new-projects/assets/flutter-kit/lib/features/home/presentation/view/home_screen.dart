import 'package:flutter/material.dart';
import 'package:kit_app/core/widgets/app_state_view.dart';
import 'package:kit_app/core/widgets/app_state_views.dart';
import 'package:kit_app/l10n/app_localizations.dart';

/// The first screen of a new app: an empty state that says where to start.
/// Replace its body with the app's own home.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: AppStateView(
          status: ScreenStatus.empty,
          content: (_) => const SizedBox.shrink(),
          empty: AppEmptyView(
            icon: Icons.auto_awesome_outlined,
            title: l10n.homeEmptyTitle,
            body: l10n.homeEmptyBody,
          ),
        ),
      ),
    );
  }
}
