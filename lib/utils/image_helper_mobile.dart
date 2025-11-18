// Mobile-specific implementation
import 'dart:io';
import 'package:flutter/material.dart';
import 'image_helper_stub.dart' as stub;

extension ImageHelperMobile on stub.ImageHelper {
  static Widget buildLocalFileImage(
    String path,
    double? width,
    double? height,
    BoxFit fit,
    Widget? placeholder,
    Widget? errorWidget,
  ) {
    final file = File(path);
    if (!file.existsSync()) {
      return errorWidget ?? stub.ImageHelper._defaultPlaceholder(width, height);
    }
    
    return Image.file(
      file,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? stub.ImageHelper._defaultPlaceholder(width, height);
      },
    );
  }

  static bool checkFileExists(String path) {
    return File(path).existsSync();
  }
}

