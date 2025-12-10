// Stub file for conditional imports
import 'package:flutter/material.dart';

class ImageHelper {
  static Widget defaultPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Icon(
        Icons.image,
        size: (width != null && height != null) 
            ? (width < height ? width : height) * 0.4 
            : 40,
        color: Colors.grey[400],
      ),
    );
  }
}

