import 'package:flutter/material.dart';

import 'app_palette.dart';

extension AppThemeContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
