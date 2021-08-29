import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class NavigationBar extends StatelessWidget {
  final int tabIndex;
  final Function(int tabIndex) onChangeTabIndex;
  final List<NavigationBarTab> tabs;

  NavigationBar(
      {required this.tabIndex,
      required this.onChangeTabIndex,
      required this.tabs});

  final Color _color = Colors.grey[500] as Color;
  @override
  Widget build(BuildContext context) {
    final Color _backgroundColor = Theme.of(context).backgroundColor;
    final children = List.generate(
      tabs.length,
      (int index) => _buildTabUnit(
        context: context,
        index: index,
        isSelected: index == tabIndex,
      ),
    );
    children.insert(2, _buildMiddleTabUnit(context));
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

  Widget _buildMiddleTabUnit(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.12;
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: width),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(height: 27),
        ],
      ),
    );
  }

  Widget _buildTabUnit({
    required BuildContext context,
    required int index,
    required bool isSelected,
  }) {
    final tab = tabs[index];
    final color = isSelected
        ? Theme.of(context).bottomNavigationBarTheme.selectedItemColor
        : _color;
    final width = MediaQuery.of(context).size.width * 0.22;
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: width, minHeight: 55),
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
                size: 27,
              ),
              Text(
                tab.title!.tr(),
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NavigationBarTab {
  NavigationBarTab({this.title, this.icon});

  String? title;
  IconData? icon;
}
