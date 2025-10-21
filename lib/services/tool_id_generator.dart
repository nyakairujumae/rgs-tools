import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class ToolIdGenerator {
  static const _uuid = Uuid();
  
  /// Generate a unique tool ID in format: RGS-YYYY-XXXXXX
  /// Example: RGS-2024-A1B2C3
  static String generateToolId() {
    final year = DateTime.now().year;
    final shortId = _uuid.v4().substring(0, 6).toUpperCase();
    return 'RGS-$year-$shortId';
  }
  
  /// Generate a model number in format: MDL-XXXX
  /// Example: MDL-A1B2
  static String generateModelNumber() {
    final shortId = _uuid.v4().substring(0, 4).toUpperCase();
    return 'MDL-$shortId';
  }
  
  /// Generate both serial number and model number
  /// Returns a map with 'serial' and 'model' keys
  static Map<String, String> generateBoth() {
    final year = DateTime.now().year;
    final baseId = _uuid.v4().substring(0, 8).toUpperCase();
    final serialPart = baseId.substring(0, 6);
    final modelPart = baseId.substring(6, 8);
    
    return {
      'serial': 'RGS-$year-$serialPart',
      'model': 'MDL-$year$modelPart',
    };
  }
  
  /// Generate a sequential tool ID with timestamp
  /// Example: TOOL-20241021-143052-A1B
  static String generateSequentialId() {
    final timestamp = DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
    final shortId = _uuid.v4().substring(0, 3).toUpperCase();
    return 'TOOL-$timestamp-$shortId';
  }
  
  /// Generate a numeric tool ID
  /// Example: 20241021001234
  static String generateNumericId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return timestamp.toString().substring(timestamp.toString().length - 12);
  }
  
  /// Generate a simple incremental-style ID
  /// Example: RGS-001234
  static String generateSimpleId() {
    final random = DateTime.now().millisecondsSinceEpoch % 999999;
    return 'RGS-${random.toString().padLeft(6, '0')}';
  }
}

