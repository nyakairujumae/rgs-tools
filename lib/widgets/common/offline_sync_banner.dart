import 'package:flutter/material.dart';
import '../../services/sync_service.dart';
import '../../theme/app_theme.dart';

/// Slim banner shown at the top of list screens.
///
/// - Offline → amber bar with wifi_off icon + pending count
/// - Back online + pending ops → blue syncing bar with progress indicator
/// - Online + nothing pending → renders nothing (zero height)
class OfflineSyncBanner extends StatelessWidget {
  final bool isOffline;

  const OfflineSyncBanner({super.key, required this.isOffline});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: SyncService().pendingCount,
      builder: (context, pending, _) {
        // Online and nothing to sync — invisible
        if (!isOffline && pending == 0) return const SizedBox.shrink();

        final isSyncing = !isOffline && pending > 0;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          color: isSyncing
              ? AppTheme.primaryColor.withOpacity(0.9)
              : const Color(0xFFF59E0B),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            children: [
              if (isSyncing)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                const Icon(Icons.wifi_off_rounded, size: 16, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isSyncing
                      ? 'Back online — syncing $pending pending change${pending == 1 ? '' : 's'}…'
                      : pending > 0
                          ? 'Offline — $pending change${pending == 1 ? '' : 's'} will sync when connected'
                          : 'Offline — showing cached data',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
