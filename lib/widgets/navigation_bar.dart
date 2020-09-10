import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:upTimer/generated/locale_keys.g.dart';

class NavigationBar extends StatelessWidget {
  NavigationBar({this.tabIndex, this.onChangeTabIndex});
  final int tabIndex;
  final Function(int tabIndex) onChangeTabIndex;
  final Color _color = Colors.grey[500];

  final _tabs = [
    _NavigationBarTab(
      title: LocaleKeys.Timeline.tr(),
      icon: Icons.timeline,
    ),
    _NavigationBarTab(
      title: LocaleKeys.Activities.tr(),
      icon: Icons.business, // Icons.queue,
    ),
    _NavigationBarTab(
      title: LocaleKeys.Report.tr(),
      icon: Icons.insert_chart,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final Color _backgroundColor = Theme.of(context).backgroundColor;
    final children = List.generate(
      _tabs.length,
      (int index) => _buildTabUnit(
        context: context,
        index: index,
        isSelected: index == tabIndex,
      ),
    );
    children.insert(2, _buildMiddleTabUnit());
    return BottomAppBar(
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: children,
      ),
      shape: CircularNotchedRectangle(),
      clipBehavior: Clip.hardEdge,
      notchMargin: 6,
      color: _backgroundColor,
    );
  }

  Widget _buildMiddleTabUnit() {
    return Flexible(
      fit: FlexFit.loose,
      flex: 3,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: 45),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: 18 * 1.61803),
          ],
        ),
      ),
    );
  }

  Widget _buildTabUnit({
    BuildContext context,
    int index,
    bool isSelected,
  }) {
    final tab = _tabs[index];
    final color = isSelected
        ? Theme.of(context).bottomNavigationBarTheme.selectedItemColor
        : _color;
    return Flexible(
      flex: 2,
      fit: FlexFit.tight,
      child: Container(
        height: 55,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => onChangeTabIndex(index),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  tab.icon,
                  color: color,
                  size: 18 * 1.61803,
                ),
                Text(
                  tab.title,
                  style: TextStyle(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationBarTab {
  _NavigationBarTab({this.title, this.icon});

  String title;
  IconData icon;
}
