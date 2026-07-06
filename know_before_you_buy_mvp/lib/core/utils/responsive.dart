import 'package:flutter/widgets.dart';

class Responsive {
  const Responsive._();

  static double maxContentWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= 900 ? 720 : double.infinity;
  }
}
