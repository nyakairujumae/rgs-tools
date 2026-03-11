import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../utils/logger.dart';

/// Service for organization (company) operations - used in company setup wizard.
class OrganizationService {
  static const String _logoBucket = 'tool-images';

  /// Create organization and assign current user as admin.
  /// Returns org id on success.
  static Future<String> createOrganizationAndAssignUser({
    required String name,
    required String slug,
    String? logoUrl,
    String? address,
    String? phone,
    String? website,
    String industry = 'general',
    String workerLabel = 'Technician',
    String workerLabelPlural = 'Technicians',
  }) async {
    final response = await SupabaseService.client.rpc(
      'create_organization_and_assign_user',
      params: {
        'p_name': name,
        'p_slug': slug,
        'p_logo_url': logoUrl,
        'p_address': address,
        'p_phone': phone,
        'p_website': website,
        'p_industry': industry,
        'p_worker_label': workerLabel,
        'p_worker_label_plural': workerLabelPlural,
      },
    );
    if (response == null) throw Exception('Failed to create organization');
    return response.toString();
  }

  /// Update organization setup (logo, details).
  static Future<void> updateOrganizationSetup({
    required String orgId,
    String? logoUrl,
    String? address,
    String? phone,
    String? website,
  }) async {
    await SupabaseService.client.rpc(
      'update_organization_setup',
      params: {
        'p_org_id': orgId,
        'p_logo_url': logoUrl,
        'p_address': address,
        'p_phone': phone,
        'p_website': website,
      },
    );
  }

  /// Upload organization logo to storage.
  /// [imageFile] can be File (mobile) or XFile (web) or Uint8List.
  static Future<String?> uploadOrganizationLogo(dynamic imageFile, String orgId) async {
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      String extension = 'jpg';
      dynamic uploadData = imageFile;

      if (imageFile is Uint8List) {
        uploadData = imageFile;
      } else if (kIsWeb) {
        // XFile from image_picker on web
        try {
          final path = imageFile.path as String?;
          if (path != null) extension = path.split('.').last;
          uploadData = await imageFile.readAsBytes();
        } catch (_) {}
      } else {
        // File on mobile
        try {
          final path = imageFile.path as String?;
          if (path != null) extension = path.split('.').last;
        } catch (_) {}
        uploadData = imageFile;
      }

      final fileName = 'organization-logos/$orgId/logo.$extension';
      await SupabaseService.client.storage
          .from(_logoBucket)
          .upload(fileName, uploadData, fileOptions: const FileOptions(upsert: true));

      final url = SupabaseService.client.storage
          .from(_logoBucket)
          .getPublicUrl(fileName);
      Logger.debug('Organization logo uploaded: $url');
      return url;
    } catch (e) {
      Logger.debug('Error uploading org logo: $e');
      rethrow;
    }
  }
}
