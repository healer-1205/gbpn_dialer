import 'package:flutter/material.dart';

extension DeviceSizeExtensions on BuildContext {
  double get screenHeight => MediaQuery.of(this).size.height;
  double get screenWidth => MediaQuery.of(this).size.width;
}
