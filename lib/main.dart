import 'package:activityTracker/providers/premium_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:activityTracker/providers/auth_provider.dart';
import 'package:activityTracker/providers/days_provider.dart';
import 'package:activityTracker/providers/scroll_provider.dart';
import 'package:activityTracker/widgets/day_grouping.dart';
import 'package:activityTracker/widgets/drawer.dart';
import 'package:tuple/tuple.dart';
import 'generated/codegen_loader.g.dart';
import 'helpers/themes.dart';
import 'providers/projects_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/add_project_screen.dart';
import 'screens/backup/export_screen.dart';
import 'screens/charts/charts_screen.dart';
import 'screens/projects_screen.dart';
import 'widgets/line.dart';
import 'widgets/navigation_bar.dart';
import 'generated/locale_keys.g.dart';
import 'widgets/row_app_bar.dart';

// flutter pub run easy_localization:generate --source-dir ./assets/translations
// flutter pub run easy_localization:generate -S assets/translations -f keys -o locale_keys.g.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(EasyLocalization(
    child: MyApp(),
    supportedLocales: [Locale('en'), Locale('ru')],
    path: 'assets/translations/',
    fallbackLocale: Locale('en'),
    startLocale: Locale('en'),
    useOnlyLangCode: true,
    assetLoader: CodegenLoader(),
  ));
}

class MyApp extends StatelessWidget {
  Future<void> _initProviders(BuildContext context) async {
    await Provider.of<ProjectsProvider>(context, listen: false).loadDb;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => SettingsProvider(),
            lazy: false,
          ),
          ChangeNotifierProvider(
            create: (_) => DaysProvider(),
            lazy: false,
          ),
          ChangeNotifierProvider(
            create: (context) {
              final daysProv =
                  Provider.of<DaysProvider>(context, listen: false);
              return ProjectsProvider(daysProv);
            },
            lazy: false,
          ),
          ChangeNotifierProvider(
            create: (_) => PremiumProvider(),
            lazy: false,
          ),
          ChangeNotifierProvider(
            create: (_) => AuthProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => ScrollProvider(),
          ),
        ],
        builder: (context, child) =>
            Selector<SettingsProvider, Tuple2<bool, int>>(
              child: MyHomePage(),
              selector: (_, set) =>
                  Tuple2(set.darkTheme, set.language), //  set.darkTheme,
              builder: (context, data, child) {
                context.locale = context.supportedLocales[data.item2 ?? 0];
                return MaterialApp(
                  localizationsDelegates: context.localizationDelegates,
                  supportedLocales: context.supportedLocales,
                  locale: context.supportedLocales[data.item2 ?? 0],
                  title: 'Activity Tracker',
                  theme: data.item1 ?? false ? darkTheme : lightTheme,
                  home: child,
                );
              },
            )
        // builder: (context, _) => FutureBuilder(
        //   future: _initProviders(context),
        //   builder: (context, snapshot) {
        //     if (snapshot.connectionState == ConnectionState.waiting)
        //       return MaterialApp(
        //           home: Scaffold(
        //               body: Center(
        //         child: Text(LocaleKeys.Loading.tr()),
        //       )));
        //     return Selector<SettingsProvider, Tuple2<bool, int>>(
        //       child: MyHomePage(),
        //       selector: (_, set) =>
        //           Tuple2(set.darkTheme, set.language), //  set.darkTheme,
        //       builder: (context, data, child) {
        //         context.locale = context.supportedLocales[data.item2 ?? 0];
        //         return MaterialApp(
        //           localizationsDelegates: context.localizationDelegates,
        //           supportedLocales: context.supportedLocales,
        //           locale: context.supportedLocales[data.item2 ?? 0],
        //           title: 'Activity Tracker',
        //           theme: data.item1 ?? false ? darkTheme : lightTheme,
        //           home: child,
        //         );
        //       },
        //     );
        //   },
        // ),
        );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final _tabs = [
      NavigationBarTab(
        title: LocaleKeys.Timeline.tr(),
        icon: Icons.timeline,
      ),
      NavigationBarTab(
        title: LocaleKeys.Activities.tr(),
        icon: Icons.update, // Icons.queue,
      ),
      NavigationBarTab(
        title: LocaleKeys.Report.tr(),
        icon: CupertinoIcons.chart_pie_fill,
      ),
      NavigationBarTab(
        title: LocaleKeys.Export.tr(),
        icon: Icons.cloud_upload,
      ),
    ];
    return Scaffold(
      // extendBody: true,
      drawer: AppDrawer(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      appBar: AppBar(
        iconTheme: IconThemeData(
            color: Theme.of(context).appBarTheme.actionsIconTheme.color),
        backgroundColor: Theme.of(context).backgroundColor,
        title: Text(
          _tabs[_selectedIndex].title,
          style: TextStyle(fontSize: 14),
        ),
        actions: <Widget>[
          RowAppBar(),
        ],
      ),
      body: <Widget>[
        Consumer<DaysProvider>(builder: (_, daysProvider, __) {
          if (daysProvider.days == null || daysProvider.days.length == 0) {
            return daysProvider.dateRange == null
                ? NoRecordsWidget()
                : Center(
                    child: Text(
                    LocaleKeys.NoActivityPeriod.tr(),
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.clip,
                  ));
          }
          return ScrollablePositionedList.builder(
            itemBuilder: (ctx, index) => DayGrouping(daysProvider.days[index]),
            itemCount: daysProvider.days.length,
            itemScrollController:
                context.read<ScrollProvider>().itemScrollController,
          );
        }),
        ProjectsScreen(),
        ChartsScreen(),
        ExportScreen(),
      ].elementAt(_selectedIndex),
      floatingActionButton: FloatingActionButton(
        child: Icon(
          Icons.add,
          color: Colors.white,
          size: 35,
        ),
        onPressed: () => showModalBottomSheet(
            shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(25.0))),
            context: context,
            isScrollControlled: true,
            builder: (context) => AddProjectScreen(
                project: null, title: LocaleKeys.BeginActivity.tr())),
        backgroundColor: Colors.indigo.withOpacity(0.8),
      ),
      bottomNavigationBar: NavigationBar(
        tabIndex: _selectedIndex,
        onChangeTabIndex: (index) {
          if (_selectedIndex != index) setState(() => _selectedIndex = index);
        },
        tabs: _tabs,
      ),
    );
  }
}
