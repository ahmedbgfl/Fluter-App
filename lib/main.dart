import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart' show ChangeNotifierProvider, Consumer;
import 'app_state.dart';
import 'theme.dart';
import 'screens/today_screen.dart';
import 'screens/classes_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/curriculum_screen.dart';
import 'screens/weeks_screen.dart';
import 'screens/plan_screen.dart';
import 'screens/events_screen.dart';
import 'screens/tests_screen.dart';
import 'screens/backup_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const DafterYawmiApp(),
    ),
  );
}

class DafterYawmiApp extends StatelessWidget {
  const DafterYawmiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'الدفتر اليومي للأستاذ',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeShell(),
    );
  }
}

class NavDestinationInfo {
  final String label;
  final IconData icon;
  final Widget Function() builder;
  const NavDestinationInfo(this.label, this.icon, this.builder);
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selected = 0;

  static final destinations = <NavDestinationInfo>[
    NavDestinationInfo('اليوم', Icons.today_rounded, () => const TodayScreen()),
    NavDestinationInfo('الأقسام', Icons.groups_2_rounded, () => const ClassesScreen()),
    NavDestinationInfo('التوقيت الأسبوعي', Icons.grid_view_rounded, () => const ScheduleScreen()),
    NavDestinationInfo('التوزيع السنوي', Icons.menu_book_rounded, () => const CurriculumScreen()),
    NavDestinationInfo('الأسابيع الدراسية', Icons.calendar_view_week_rounded, () => const WeeksScreen()),
    NavDestinationInfo('الدفتر اليومي', Icons.edit_calendar_rounded, () => const PlanScreen()),
    NavDestinationInfo('المناسبات والعطل', Icons.celebration_rounded, () => const EventsScreen()),
    NavDestinationInfo('الفروض والاختبارات', Icons.assignment_rounded, () => const TestsScreen()),
    NavDestinationInfo('النسخ الاحتياطي', Icons.backup_rounded, () => const BackupScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        if (!state.loaded) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          final body = KeyedSubtree(
            key: ValueKey(_selected),
            child: destinations[_selected].builder(),
          );

          if (wide) {
            return Scaffold(
              appBar: AppBar(title: Text(destinations[_selected].label)),
              body: Row(
                children: [
                  NavigationRail(
                    extended: constraints.maxWidth >= 1000,
                    selectedIndex: _selected,
                    onDestinationSelected: (i) => setState(() => _selected = i),
                    labelType: constraints.maxWidth >= 1000
                        ? NavigationRailLabelType.none
                        : NavigationRailLabelType.selected,
                    destinations: [
                      for (final d in destinations)
                        NavigationRailDestination(icon: Icon(d.icon), label: Text(d.label)),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: Padding(padding: const EdgeInsets.all(12), child: body)),
                ],
              ),
            );
          }

          return Scaffold(
            appBar: AppBar(title: Text(destinations[_selected].label)),
            drawer: Drawer(
              child: SafeArea(
                child: ListView(
                  children: [
                    const DrawerHeader(
                      decoration: BoxDecoration(color: AppColors.sealDeep),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: Text('📘 الدفتر اليومي للأستاذ',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                      ),
                    ),
                    for (var i = 0; i < destinations.length; i++)
                      ListTile(
                        leading: Icon(destinations[i].icon),
                        title: Text(destinations[i].label),
                        selected: i == _selected,
                        onTap: () {
                          setState(() => _selected = i);
                          Navigator.pop(context);
                        },
                      ),
                  ],
                ),
              ),
            ),
            body: Padding(padding: const EdgeInsets.all(10), child: body),
          );
        });
      },
    );
  }
}
