import 'package:flutter/material.dart';

class Line extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      height: 0.5,
      decoration: BoxDecoration(border: Border(top: BorderSide(width: 0.1))),
    );
  }
}
