import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';
import 'logger.dart';

/// Helper to upload RGS logo to Supabase storage
/// Call this function from your app (e.g., from a debug menu or admin screen)
class UploadLogoHelper {
  static const String bucketName = 'tool-images'; // or create 'logos' bucket
  static const String fileName = 'rgs.jpg';
  
  /// Upload rgs.jpg from assets to Supabase storage
  /// Returns the public URL if successful
  static Future<String?> uploadRgsLogo() async {
    try {
      Logger.debug('🚀 Starting RGS logo upload...');
      
      // Check if user is authenticated
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) {
        Logger.debug('❌ User not authenticated. Please log in first.');
        return null;
      }
      
      // Note: Asset upload requires BuildContext or rootBundle
      // For now, manual upload via Supabase Dashboard is recommended
      // See instructions below
      
      // For now, let's provide instructions
      Logger.debug('📋 To upload rgs.jpg:');
      Logger.debug('   1. Go to Supabase Dashboard > Storage');
      Logger.debug('   2. Select or create bucket: $bucketName');
      Logger.debug('   3. Click "Upload file"');
      Logger.debug('   4. Select assets/images/rgs.jpg');
      Logger.debug('   5. Name it: $fileName');
      Logger.debug('   6. Make sure bucket is public');
      Logger.debug('   7. Copy the public URL');
      
      return null;
    } catch (e) {
      Logger.debug('❌ Error: $e');
      return null;
    }
  }
  
  /// Get the public URL for rgs.jpg (assuming it's already uploaded)
  static String getRgsLogoUrl(String supabaseUrl) {
    // Supabase public URL format: {supabaseUrl}/storage/v1/object/public/{bucket}/{file}
    return '$supabaseUrl/storage/v1/object/public/$bucketName/$fileName';
  }
}


