import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_helper.dart';

/// Model for stat card data
class StatCardData {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String? subtitle;
  final String? trend;
  final bool? trendPositive;
  final VoidCallback? onTap;

  const StatCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.subtitle,
    this.trend,
    this.trendPositive,
    this.onTap,
  });
}

/// Dashboard statistics cards widget for web desktop
/// Displays stats in a responsive grid layout
class WebStatCards extends StatelessWidget {
  final List<StatCardData> stats;
  final int crossAxisCount;

  const WebStatCards({
    Key? key,
    required this.stats,
    this.crossAxisCount = 4,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive column count
    int columns = crossAxisCount;
    if (screenWidth < 1200) {
      columns = 3;
    }
    if (screenWidth < 900) {
      columns = 2;
    }
    if (screenWidth < 600) {
      columns = 1;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: 2.5, // Increased from 2.0 to give more height
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        return StatCard(data: stats[index]);
      },
    );
  }
}

/// Individual stat card component
class StatCard extends StatefulWidget {
  final StatCardData data;

  const StatCard({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = AppTheme.cardSurfaceColor(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.data.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? AppTheme.primaryColor.withOpacity(0.3)
                  : (isDark
                      ? AppTheme.webDarkCardBorder
                      : AppTheme.webLightCardBorder),
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : AppTheme.getCardShadows(context),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icon and label row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: widget.data.iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        widget.data.icon,
                        color: widget.data.iconColor,
                        size: 24,
                      ),
                    ),
                    const Spacer(),
                    if (widget.data.trend != null) _buildTrendIndicator(isDark),
                  ],
                ),

                const SizedBox(height: 12),

                // Value and label
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.data.value,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.data.label,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    if (widget.data.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.data.subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendIndicator(bool isDark) {
    final isPositive = widget.data.trendPositive ?? true;
    final trendColor = isPositive ? AppTheme.successColor : AppTheme.errorColor;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isPositive ? Icons.trending_up : Icons.trending_down,
          size: 16,
          color: trendColor,
        ),
        const SizedBox(width: 4),
        Text(
          widget.data.trend!,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: trendColor,
          ),
        ),
      ],
    );
  }
}

/// Loading skeleton for stat cards
class StatCardSkeleton extends StatelessWidget {
  final int count;
  final int crossAxisCount;

  const StatCardSkeleton({
    Key? key,
    this.count = 4,
    this.crossAxisCount = 4,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    int columns = crossAxisCount;
    if (screenWidth < 1200) columns = 3;
    if (screenWidth < 900) columns = 2;
    if (screenWidth < 600) columns = 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: 2.0,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: count,
      itemBuilder: (context, index) {
        return _SkeletonCard();
      },
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = AppTheme.cardSurfaceColor(context);
    final shimmerBase = isDark ? Colors.white10 : Colors.black12;
    final shimmerHighlight = isDark ? Colors.white24 : Colors.black26;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppTheme.webDarkCardBorder
              : AppTheme.webLightCardBorder,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: shimmerBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 32,
                  decoration: BoxDecoration(
                    color: shimmerBase,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: shimmerBase,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
