// Mobile-specific implementation
// This file is imported when dart:io is available

import 'dart:io';

/// Mobile-specific helper functions
String getFilePath(dynamic file) {
  if (file is File) {
    return file.path;
  }
  throw Exception('Expected File on mobile platform');
}

