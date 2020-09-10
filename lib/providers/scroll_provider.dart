import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ScrollProvider with ChangeNotifier {
  final ItemScrollController itemScrollController = ItemScrollController();

  void jumpTo() {
    itemScrollController.scrollTo(
        index: 0,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic);
  }
}
