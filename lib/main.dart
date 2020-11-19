import 'package:activityTracker/providers/premium_provider.dart';
import 'package:activityTracker/screens/pro_screen.dart';
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
            final daysProv = Provider.of<DaysProvider>(context, listen: false);
            return ProjectsProvider(daysProv);
          },
          lazy: false,
        ),
        ChangeNotifierProvider(
          create: (context) {
            final settingsProvider =
                Provider.of<SettingsProvider>(context, listen: false);
            return AuthProvider(settingsProvider);
          },
        ),
        ChangeNotifierProvider(
          create: (context) {
            final authProv = Provider.of<AuthProvider>(context, listen: false);
            return PremiumProvider(authProv);
          },
          lazy: false,
        ),
        ChangeNotifierProvider(
          create: (_) => ScrollProvider(),
        ),
      ],
      builder: (context, _) => Selector<SettingsProvider, Tuple2<bool, int>>(
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
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  final _tabs = [
    NavigationBarTab(
      title: LocaleKeys.Timeline,
      icon: Icons.timeline,
    ),
    NavigationBarTab(
      title: LocaleKeys.Activities,
      icon: Icons.update,
    ),
    NavigationBarTab(
      title: LocaleKeys.Report,
      icon: CupertinoIcons.chart_pie_fill,
    ),
    NavigationBarTab(
      title: LocaleKeys.Export,
      icon: Icons.cloud_upload,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // extendBody: true,
      drawer: AppDrawer(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      appBar: AppBar(
        iconTheme: IconThemeData(
            color: Theme.of(context).appBarTheme.actionsIconTheme.color),
        backgroundColor: Theme.of(context).backgroundColor,
        title: Text(
          _tabs[_selectedIndex].title.tr(),
          style: TextStyle(fontSize: 14),
        ),
        actions: <Widget>[
          RowAppBar(),
        ],
      ),
      body: <Widget>[
        Consumer<DaysProvider>(builder: (_, daysProvider, __) {
          final loaded = context.read<ProjectsProvider>().isLoaded;
          if (daysProvider.days == null ||
              daysProvider.days.length == 0 && loaded) {
            return Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.only(bottom: 10),
                      height: 120,
                      child: Image.asset(
                        'assets/timeline.png',
                        fit: BoxFit.fill,
                      ),
                    ),
                    daysProvider.dateRange == null
                        ? NoRecordsWidget()
                        : Text(
                            LocaleKeys.NoActivityPeriod.tr(),
                            style: TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 16),
                            maxLines: 2,
                            overflow: TextOverflow.clip,
                          )
                  ],
                ),
              ),
            );
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
        onPressed: () => checkPremium(context),
        //backgroundColor: Colors.indigo.withOpacity(0.8),
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

  void checkPremium(BuildContext context) {
    final projProvider = context.read<ProjectsProvider>();
    final isPro = context.read<PremiumProvider>().isPro;
    bool premium = true;

    if (projProvider.isLoaded) {
      if (projProvider.projects.length >= 10) {
        premium = isPro;
      }
      if (premium) {
        showModalBottomSheet(
            shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20.0))),
            context: context,
            isScrollControlled: true,
            builder: (context) => AddProjectScreen(
                project: null, title: LocaleKeys.BeginActivity.tr()));
      } else {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProScreen(),
            ));
      }
    }
  }
}
