import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void finishView(BuildContext context, [Object? result]) {
  if (Navigator.canPop(context)) {
    Navigator.pop(context, result);
  } else {
    if (Platform.isAndroid) {
      SystemNavigator.pop();
    } else if (Platform.isIOS) {
      exit(0);
    }
  }
}
