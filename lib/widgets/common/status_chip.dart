import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Reusable status chip widget
/// Displays status with appropriate colors and styling
class StatusChip extends StatelessWidget {
  final String status;
  final String? label;
  final bool showIcon;
  final VoidCallback? onTap;

  const StatusChip({
    super.key,
    required this.status,
    this.label,
    this.showIcon = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getStatusColor(status);
    final displayText = label ?? status;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Icon(
                _getStatusIcon(status),
                size: 12,
                color: color,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              displayText,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Icons.check_circle;
      case 'in use':
        return Icons.person;
      case 'maintenance':
        return Icons.build;
      case 'retired':
        return Icons.archive;
      default:
        return Icons.help;
    }
  }
}

/// Condition chip widget
class ConditionChip extends StatelessWidget {
  final String condition;
  final String? label;
  final bool showIcon;
  final VoidCallback? onTap;

  const ConditionChip({
    super.key,
    required this.condition,
    this.label,
    this.showIcon = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getConditionColor(condition);
    final displayText = label ?? condition;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Icon(
                _getConditionIcon(condition),
                size: 12,
                color: color,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              displayText,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getConditionIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'excellent':
        return Icons.star;
      case 'good':
        return Icons.star_half;
      case 'fair':
        return Icons.star_border;
      case 'poor':
        return Icons.warning;
      case 'needs repair':
        return Icons.build;
      default:
        return Icons.help;
    }
  }
}

