class NameFormatter {
  static String format(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;

    final normalized = trimmed.replaceAll(RegExp(r'\s+'), ' ');
    final parts = normalized.split(' ');
    final formatted = parts.map((part) {
      if (part.isEmpty) return part;
      final lower = part.toLowerCase();
      if (lower.length == 1) return lower.toUpperCase();
      return '${lower[0].toUpperCase()}${lower.substring(1)}';
    }).join(' ');
    return formatted;
  }
}
