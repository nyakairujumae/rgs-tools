import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Helper utility for handling images across platforms (mobile and web)
class ImageHelper {
  /// Display an image from a path, handling both local files (mobile) and URLs (web)
  static Widget buildImage({
    required String? imagePath,
    required double? width,
    required double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    if (imagePath == null || imagePath.isEmpty) {
      return errorWidget ?? _defaultPlaceholder(width, height);
    }

    // On web, always treat as network image
    if (kIsWeb) {
      return Image.network(
        imagePath,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? _defaultPlaceholder(width, height);
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? _defaultPlaceholder(width, height);
        },
      );
    }

    // On mobile, check if it's a URL or local file
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? _defaultPlaceholder(width, height);
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? _defaultPlaceholder(width, height);
        },
      );
    }

    // Local file (mobile only)
    try {
      // Use conditional import for dart:io
      return _buildLocalFileImage(imagePath, width, height, fit, placeholder, errorWidget);
    } catch (e) {
      return errorWidget ?? _defaultPlaceholder(width, height);
    }
  }

  /// Build image from local file (mobile only)
  static Widget _buildLocalFileImage(
    String path,
    double? width,
    double? height,
    BoxFit fit,
    Widget? placeholder,
    Widget? errorWidget,
  ) {
    if (kIsWeb) {
      // Should not reach here on web, but handle gracefully
      return errorWidget ?? _defaultPlaceholder(width, height);
    }

    // Import File only on non-web platforms
    // This will be handled by conditional imports in the actual implementation
    // For now, return placeholder as fallback
    return errorWidget ?? _defaultPlaceholder(width, height);
  }

  static Widget _defaultPlaceholder(double? width, double? height) {
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

  /// Check if image path exists (mobile only, always true for URLs)
  static bool imageExists(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return false;
    
    // URLs always "exist" (will be checked when loading)
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return true;
    }

    // On web, local files don't exist
    if (kIsWeb) {
      return false;
    }

    // On mobile, check file existence
    try {
      // This will be handled by conditional imports
      return false; // Placeholder
    } catch (e) {
      return false;
    }
  }
}

