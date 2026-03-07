import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class ToolIdGenerator {
  static const _uuid = Uuid();

  /// Derive a short uppercase prefix from an org name.
  /// e.g. "Linkin" → "LNK", "Royal Gulf Services" → "RGS", "Acme Corp" → "AC"
  static String derivePrefix(String orgName) {
    final words = orgName.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return 'TOOL';
    if (words.length == 1) {
      // Single word: strip vowels, take first 3 chars; fallback to first 3 chars
      final noVowels = words[0].replaceAll(RegExp(r'[aeiouAEIOU]'), '');
      final result = noVowels.isNotEmpty ? noVowels.substring(0, noVowels.length.clamp(0, 3)) : words[0].substring(0, words[0].length.clamp(0, 3));
      return result.toUpperCase().padRight(2, words[0][0].toUpperCase());
    }
    // Multi-word: first letter of each word (up to 4)
    return words.take(4).map((w) => w[0]).join().toUpperCase();
  }

  /// Generate a unique tool ID in format: PREFIX-YYYY-XXXXXX
  /// Example: LNK-2026-A1B2C3
  static String generateToolId({String prefix = 'TOOL'}) {
    final year = DateTime.now().year;
    final shortId = _uuid.v4().substring(0, 6).toUpperCase();
    return '$prefix-$year-$shortId';
  }

  /// Generate a model number in format: PREFIX-MDL-XXXX
  /// Example: LNK-MDL-A1B2
  static String generateModelNumber({String prefix = 'TOOL'}) {
    final shortId = _uuid.v4().substring(0, 4).toUpperCase();
    return '$prefix-MDL-$shortId';
  }

  /// Generate both serial number and model number.
  /// Returns a map with 'serial' and 'model' keys.
  static Map<String, String> generateBoth({String prefix = 'TOOL'}) {
    final year = DateTime.now().year;
    final baseId = _uuid.v4().substring(0, 8).toUpperCase();
    final serialPart = baseId.substring(0, 6);
    final modelPart = baseId.substring(6, 8);

    return {
      'serial': '$prefix-$year-$serialPart',
      'model': '$prefix-MDL-$year$modelPart',
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
  /// Example: TOOL-001234
  static String generateSimpleId() {
    final random = DateTime.now().millisecondsSinceEpoch % 999999;
    return 'TOOL-${random.toString().padLeft(6, '0')}';
  }
}

