import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/certification.dart';
import '../utils/logger.dart';

/// Fires local notifications for calibration certificates that are
/// overdue or expiring within 1 / 7 / 30 days.
///
/// Call [checkAndNotify] once after the user logs in and cert data
/// is loaded.  It can safely be called multiple times — duplicate
/// notifications within the same calendar day are suppressed via a
/// stable notification ID derived from (certId + thresholdDays).
class CalibrationReminderService {
  CalibrationReminderService._();
  static final CalibrationReminderService instance =
      CalibrationReminderService._();

  static const String _channelId = 'calibration_reminders';
  static const String _channelName = 'Calibration Reminders';
  static const String _channelDesc =
      'Alerts for tools with expiring or overdue calibration certificates';

  // Thresholds (days). Notifications fire when daysUntilExpiry <= threshold.
  static const List<int> _thresholds = [1, 7, 30];

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ── Init ────────────────────────────────────────────────────────────────────

  Future<void> _ensureInitialized() async {
    if (_initialized || kIsWeb) return;
    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        const InitializationSettings(
            android: androidSettings, iOS: iosSettings),
      );

      // Create dedicated Android channel
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
        showBadge: true,
        playSound: true,
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      _initialized = true;
      Logger.debug('✅ [CalibrationReminder] Initialized');
    } catch (e) {
      Logger.debug('❌ [CalibrationReminder] Init error: $e');
    }
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Check [certifications] and fire local notifications for anything
  /// overdue or within the configured thresholds.
  Future<void> checkAndNotify(List<Certification> certifications) async {
    if (kIsWeb) return;
    await _ensureInitialized();
    if (!_initialized) return;

    int fired = 0;

    for (final cert in certifications) {
      final days = cert.daysUntilExpiry;

      if (days < 0) {
        // Overdue
        final notifId = _stableId(cert.id ?? cert.certificationNumber, -1);
        await _show(
          id: notifId,
          title: '🔴 Calibration Overdue',
          body:
              '${cert.toolName} — ${cert.certificationType} expired ${(-days)} day${days == -1 ? '' : 's'} ago.',
          payload: cert.toolId,
        );
        fired++;
        continue;
      }

      for (final threshold in _thresholds) {
        if (days <= threshold) {
          final notifId = _stableId(cert.id ?? cert.certificationNumber, threshold);
          final urgency = days == 0
              ? '⚠️ Due TODAY'
              : days == 1
                  ? '⚠️ Due TOMORROW'
                  : '🟡 Due in $days days';
          await _show(
            id: notifId,
            title: '$urgency — Calibration Expiring',
            body:
                '${cert.toolName}: ${cert.certificationType} expires ${_expiryLabel(days)}.',
            payload: cert.toolId,
          );
          fired++;
          break; // only fire the tightest threshold
        }
      }
    }

    if (fired > 0) {
      Logger.debug('✅ [CalibrationReminder] Fired $fired notification(s)');
    } else {
      Logger.debug('ℹ️ [CalibrationReminder] No expiring/overdue certs found');
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await _plugin.show(
        id,
        title,
        body,
        NotificationDetails(
          android: const AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            categoryIdentifier: 'calibration',
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
    } catch (e) {
      Logger.debug('❌ [CalibrationReminder] show() error: $e');
    }
  }

  /// Stable int ID derived from cert identifier + threshold bucket.
  /// Keeps the same notification in-place when re-checked.
  int _stableId(String certKey, int threshold) {
    // Use a simple hash to stay within 32-bit int range
    final raw = 'cal_${certKey}_$threshold'.hashCode.abs();
    return raw % 100000 + 10000; // 10000–109999 range
  }

  String _expiryLabel(int days) {
    if (days == 0) return 'today';
    if (days == 1) return 'tomorrow';
    return 'in $days days';
  }
}
