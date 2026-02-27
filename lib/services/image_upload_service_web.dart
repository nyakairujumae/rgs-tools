// Web-specific implementation
// This file is imported when dart:html is available

/// Web-specific helper functions
String getFilePath(dynamic file) {
  // On web, files don't have paths
  // Return a placeholder or extract from file name
  try {
    if (file.name != null) return file.name as String;
    if (file.fileName != null) return file.fileName as String;
    return 'image.jpg';
  } catch (e) {
    return 'image.jpg';
  }
}

