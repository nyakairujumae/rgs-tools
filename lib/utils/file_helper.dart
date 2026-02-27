import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;
import 'package:flutter/material.dart';

/// Helper to check if a local file exists and return an Image widget
/// Returns null if file doesn't exist or on web platform
Widget? buildLocalFileImage(String? filePath, {BoxFit fit = BoxFit.cover, double? width, double? height}) {
  if (kIsWeb || filePath == null || filePath.startsWith('http')) {
    return null;
  }
  
  try {
    // This will only compile on non-web platforms
    final file = io.File(filePath);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: fit,
        width: width,
        height: height,
      );
    }
  } catch (e) {
    // File doesn't exist or can't be accessed
  }
  return null;
}

