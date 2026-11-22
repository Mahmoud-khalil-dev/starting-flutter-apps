import 'package:flutter/material.dart';
import 'package:kit_app/app/kit_gallery/kit_gallery_samples.dart';
import 'package:kit_app/app/shell/app_shell.dart';
import 'package:kit_app/app/shell/app_two_pane.dart';
import 'package:kit_app/app/shell/shell_destinations.dart';
import 'package:kit_app/core/router/route_names.dart';
import 'package:kit_app/core/session/app_role.dart';
import 'package:kit_app/core/widgets/app_group.dart';
import 'package:kit_app/core/widgets/app_row.dart';
import 'package:kit_app/core/widgets/app_state_views.dart';

/// The shell for one role around a two-pane page, for the gallery and the
/// shell goldens. Tabs switch locally; nothing is routed.
class KitShellSample extends StatefulWidget {
  const KitShellSample({required this.role, super.key});

  final AppRole role;

  @override
  State<KitShellSample> createState() => _KitShellSampleState();
}

class _KitShellSampleState extends State<KitShellSample> {
  String _location = RouteNames.home;

  @override
  Widget build(BuildContext context) => AppShell(
    role: widget.role,
    location: _location,
    badges: const {ShellTab.settings},
    onSelect: (path) => setState(() => _location = path),
    child: AppTwoPane(
      list: ListView(
        children: [
          AppGroup(
            children: [
              for (final title in [
                sample(context, en: 'Project review', ar: 'مراجعة المشروع'),
                sample(context, en: 'Follow-up', ar: 'متابعة'),
                sample(context, en: 'Weekly plan', ar: 'خطة الأسبوع'),
              ])
                AppRow.navigation(title: title, onTap: () {}),
            ],
          ),
        ],
      ),
      emptyDetail: AppEmptyView(
        title: sample(context, en: 'Nothing here yet', ar: 'لا شيء هنا بعد'),
      ),
    ),
  );
}
