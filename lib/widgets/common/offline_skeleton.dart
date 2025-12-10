import 'package:flutter/material.dart';
import 'loading_widget.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_helper.dart';

/// Widget that shows skeleton loaders with an offline message
class OfflineSkeleton extends StatelessWidget {
  final Widget skeleton;
  final String? message;
  final IconData? icon;

  const OfflineSkeleton({
    super.key,
    required this.skeleton,
    this.message,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        // Skeleton content
        skeleton,
        
        // Offline banner at the top
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    icon ?? Icons.wifi_off,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message ?? 'You are currently offline. Showing cached data.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Offline skeleton for tool grid screens
class OfflineToolGridSkeleton extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final String? message;

  const OfflineToolGridSkeleton({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return OfflineSkeleton(
      skeleton: ToolCardGridSkeleton(
        itemCount: itemCount,
        crossAxisCount: crossAxisCount,
      ),
      message: message,
    );
  }
}

/// Offline skeleton for list screens
class OfflineListSkeleton extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final String? message;

  const OfflineListSkeleton({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return OfflineSkeleton(
      skeleton: ListSkeletonLoader(
        itemCount: itemCount,
        itemHeight: itemHeight,
      ),
      message: message,
    );
  }
}

/// Offline skeleton for dashboard/stat cards
class OfflineDashboardSkeleton extends StatelessWidget {
  final int cardCount;
  final String? message;

  const OfflineDashboardSkeleton({
    super.key,
    this.cardCount = 4,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return OfflineSkeleton(
      skeleton: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ResponsiveHelper.getGridCrossAxisCount(context),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: cardCount,
        itemBuilder: (context, index) => const StatCardSkeleton(),
      ),
      message: message,
    );
  }
}

/// Offline empty state with retry option
class OfflineEmptyState extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? message;

  const OfflineEmptyState({
    super.key,
    this.onRetry,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: Colors.orange.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 24),
            Text(
              'No Internet Connection',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message ?? 'Please check your internet connection and try again.',
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}



