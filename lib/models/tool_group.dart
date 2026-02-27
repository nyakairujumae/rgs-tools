import 'tool.dart';

/// Represents a group of tools that share the same name, category, and brand.
/// Used for UI display to show count badges instead of duplicate cards.
class ToolGroup {
  final String name;
  final String category;
  final String? brand;
  final String? model;
  final List<Tool> instances;
  final String? representativeImage;

  ToolGroup({
    required this.name,
    required this.category,
    this.brand,
    this.model,
    required this.instances,
    this.representativeImage,
  });

  /// Generate a unique key for grouping tools (case-insensitive)
  static String getGroupKey(Tool tool) {
    return '${tool.name.toLowerCase().trim()}|${tool.category.toLowerCase().trim()}|${(tool.brand ?? '').toLowerCase().trim()}';
  }

  /// Total number of instances
  int get totalCount => instances.length;

  /// Number of available instances
  int get availableCount =>
      instances.where((t) => t.status == 'Available').length;

  /// Number of assigned instances
  int get assignedCount => instances.where((t) => t.assignedTo != null).length;

  /// Number of in-use instances
  int get inUseCount => instances.where((t) => t.status == 'In Use').length;

  /// Number of maintenance instances
  int get maintenanceCount =>
      instances.where((t) => t.status == 'Maintenance').length;

  /// Number of retired instances
  int get retiredCount => instances.where((t) => t.status == 'Retired').length;

  /// Get a summary string for status distribution
  String get statusSummary {
    final parts = <String>[];
    if (availableCount > 0) parts.add('$availableCount Available');
    if (inUseCount > 0) parts.add('$inUseCount In Use');
    if (assignedCount > availableCount) {
      // Some assigned but not in use
      final otherAssigned = assignedCount - inUseCount;
      if (otherAssigned > 0) parts.add('$otherAssigned Assigned');
    }
    if (maintenanceCount > 0) parts.add('$maintenanceCount Maintenance');
    if (retiredCount > 0) parts.add('$retiredCount Retired');

    return parts.isEmpty ? 'No status' : parts.join(', ');
  }

  /// Get the best representative tool for display
  /// Priority: 1) Available + Good condition, 2) Available, 3) Good condition, 4) First with image, 5) First
  Tool? get representativeTool {
    // First, try to find an available tool with good condition
    try {
      final availableGood = instances.firstWhere(
        (t) => t.status == 'Available' && 
               (t.condition.toLowerCase() == 'good' || t.condition.toLowerCase() == 'excellent'),
      );
      return availableGood;
    } catch (e) {
      // No available + good found
    }
    
    // Second, try to find any available tool
    try {
      final available = instances.firstWhere(
        (t) => t.status == 'Available',
      );
      return available;
    } catch (e) {
      // No available found
    }
    
    // Third, try to find a tool with good condition
    try {
      final goodCondition = instances.firstWhere(
        (t) => t.condition.toLowerCase() == 'good' || t.condition.toLowerCase() == 'excellent',
      );
      return goodCondition;
    } catch (e) {
      // No good condition found
    }
    
    // Fourth, get first tool with image
    try {
      return instances.firstWhere(
        (t) => t.imagePath != null && t.imagePath!.isNotEmpty,
      );
    } catch (e) {
      // No image found, return first
      return instances.first;
    }
  }

  /// Get the best status to display for the tool group
  /// Priority: Available > In Use > Maintenance > Retired
  String get bestStatus {
    if (availableCount > 0) return 'Available';
    if (inUseCount > 0) return 'In Use';
    if (maintenanceCount > 0) return 'Maintenance';
    if (retiredCount > 0) return 'Retired';
    return representativeTool?.status ?? 'Unknown';
  }

  /// Group a list of tools by their composite key
  static List<ToolGroup> groupTools(List<Tool> tools) {
    final Map<String, List<Tool>> grouped = {};

    for (final tool in tools) {
      final key = getGroupKey(tool);
      grouped.putIfAbsent(key, () => []).add(tool);
    }

    return grouped.entries.map((entry) {
      final instances = entry.value;
      final firstTool = instances.first;
      final representativeImage = instances
          .firstWhere(
            (t) => t.imagePath != null && t.imagePath!.isNotEmpty,
            orElse: () => firstTool,
          )
          .imagePath;

      return ToolGroup(
        name: firstTool.name,
        category: firstTool.category,
        brand: firstTool.brand,
        model: firstTool.model,
        instances: instances,
        representativeImage: representativeImage,
      );
    }).toList();
  }
}
