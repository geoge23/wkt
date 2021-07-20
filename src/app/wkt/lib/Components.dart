import 'package:flutter/material.dart';

class LocalAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(55);

  @override
  Widget build(BuildContext ctx) {
    return AppBar(
        title: Row(
      children: [
        Padding(
          padding: EdgeInsets.only(right: 5),
          child: Icon(Icons.line_weight_outlined),
        ),
        Text('wkt')
      ],
      mainAxisAlignment: MainAxisAlignment.center,
    ));
  }
}
