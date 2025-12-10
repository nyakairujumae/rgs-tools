import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Helper utility for handling images across platforms (mobile and web)
class ImageHelper {
  /// Display an image from a path or File, handling both local files (mobile) and URLs (web)
  static Widget buildImage({
    required dynamic imageSource, // Can be String? (path/URL) or File (mobile only)
    required double? width,
    required double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    // Handle null/empty
    if (imageSource == null) {
      return errorWidget ?? _defaultPlaceholder(width, height);
    }

    String? imagePath;
    
    // Extract path from File object (mobile) or use string directly
    if (kIsWeb) {
      // On web, imageSource should be a String (URL or path)
      if (imageSource is String) {
        imagePath = imageSource;
      } else {
        return errorWidget ?? _defaultPlaceholder(width, height);
      }
    } else {
      // On mobile, could be File or String
      if (imageSource is String) {
        imagePath = imageSource;
      } else {
        // Try to get path from File object
        try {
          imagePath = _getFilePath(imageSource);
        } catch (e) {
          return errorWidget ?? _defaultPlaceholder(width, height);
        }
      }
    }

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

    // Local file (mobile only) - use conditional import
    return _buildLocalFileImage(imagePath, width, height, fit, placeholder, errorWidget);
  }

  /// Build image from local file path (mobile only)
  static Widget _buildLocalFileImage(
    String path,
    double? width,
    double? height,
    BoxFit fit,
    Widget? placeholder,
    Widget? errorWidget,
  ) {
    // This will be replaced by conditional import
    return _buildLocalFileImageStub(path, width, height, fit, placeholder, errorWidget);
  }

  static Widget _buildLocalFileImageStub(
    String path,
    double? width,
    double? height,
    BoxFit fit,
    Widget? placeholder,
    Widget? errorWidget,
  ) {
    // Stub - will be replaced by actual implementation
    return errorWidget ?? _defaultPlaceholder(width, height);
  }

  /// Get file path from File object (mobile only)
  static String? _getFilePath(dynamic file) {
    if (kIsWeb) return null;
    try {
      // Use dynamic to access .path property
      return file.path as String?;
    } catch (e) {
      return null;
    }
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
  static bool imageExists(dynamic imageSource) {
    if (imageSource == null) return false;
    
    String? imagePath;
    if (imageSource is String) {
      imagePath = imageSource;
    } else if (!kIsWeb) {
      try {
        imagePath = _getFilePath(imageSource);
      } catch (e) {
        return false;
      }
    } else {
      return false;
    }
    
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
      return _checkFileExists(imagePath);
    } catch (e) {
      return false;
    }
  }

  static bool _checkFileExists(String path) {
    // Stub - will be replaced by conditional import
    return false;
  }
}
