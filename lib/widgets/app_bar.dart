import 'package:flutter/material.dart';

class CustomAppBar {
  static PreferredSizeWidget build({
    Widget? leading, // Allows custom back button
  }) {
    return AppBar(
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.black),
      leading: leading,
    );
  }
}
