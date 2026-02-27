import 'package:flutter/material.dart';

const _logoDarkModeAsset = 'assets/images/logo_dark.png';
const _logoLightModeAsset = 'assets/images/logo_light.png';

String getThemeLogoAsset(Brightness brightness) =>
    brightness == Brightness.dark ? _logoDarkModeAsset : _logoLightModeAsset;
