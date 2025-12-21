import 'package:flutter/foundation.dart';

/// Model representing an admin position with its permissions
class AdminPosition {
  final String id;
  final String name;
  final String? description;
  final bool isActive;
  final List<PositionPermission> permissions;
  final DateTime createdAt;
  final DateTime updatedAt;

  AdminPosition({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
    required this.permissions,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminPosition.fromJson(Map<String, dynamic> json) {
    return AdminPosition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      permissions: (json['position_permissions'] as List<dynamic>?)
          ?.map((p) => PositionPermission.fromJson(p))
          .toList() ?? [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'is_active': isActive,
      'position_permissions': permissions.map((p) => p.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Check if position has a specific permission
  bool hasPermission(String permissionName) {
    return permissions.any((p) => 
      p.permissionName == permissionName && p.isGranted
    );
  }
}

/// Model representing a single permission for a position
class PositionPermission {
  final String id;
  final String positionId;
  final String permissionName;
  final bool isGranted;

  PositionPermission({
    required this.id,
    required this.positionId,
    required this.permissionName,
    required this.isGranted,
  });

  factory PositionPermission.fromJson(Map<String, dynamic> json) {
    return PositionPermission(
      id: json['id'] as String,
      positionId: json['position_id'] as String,
      permissionName: json['permission_name'] as String,
      isGranted: json['is_granted'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'position_id': positionId,
      'permission_name': permissionName,
      'is_granted': isGranted,
    };
  }
}



