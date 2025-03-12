import 'package:flutter/material.dart';

class AppStyles {
  // Elevated Button Style
  static ButtonStyle elevatedButtonStyle({
    Color? backgroundColor,
    Color? foregroundColor,
    double? borderRadius,
    double? horizontalPadding,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? Colors.deepPurpleAccent,
      foregroundColor: foregroundColor ?? Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? 12),
      ),
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding ?? 24),
    );
  }

  // Text Style for Large Titles
  static TextStyle textStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    return TextStyle(
      fontSize: fontSize ?? 18.0,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color ?? Colors.black,
    );
  }

  // Text Style for Buttons
  static TextStyle buttonTextStyle({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }
}
