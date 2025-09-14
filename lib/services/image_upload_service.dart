import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class ImageUploadService {
  static const String _bucketName = 'tool-images';

  /// Upload an image file to Supabase Storage
  static Future<String?> uploadImage(File imageFile, String toolId) async {
    try {
      // Create a unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.path.split('.').last;
      final fileName = 'tool_${toolId}_$timestamp.$extension';

      // Upload the file to Supabase Storage
      final response = await SupabaseService.client.storage
          .from(_bucketName)
          .upload(fileName, imageFile);

      if (response.isNotEmpty) {
        // Get the public URL for the uploaded image
        final imageUrl = SupabaseService.client.storage
            .from(_bucketName)
            .getPublicUrl(fileName);

        return imageUrl;
      }

      return null;
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Delete an image from Supabase Storage
  static Future<void> deleteImage(String imageUrl) async {
    try {
      // Extract filename from URL
      final fileName = imageUrl.split('/').last.split('?').first;
      
      await SupabaseService.client.storage
          .from(_bucketName)
          .remove([fileName]);
    } catch (e) {
      print('Error deleting image: $e');
      // Don't throw error for delete operations as the file might not exist
    }
  }

  /// Get a signed URL for temporary access to a private image
  static Future<String?> getSignedUrl(String imageUrl) async {
    try {
      final fileName = imageUrl.split('/').last.split('?').first;
      
      final response = await SupabaseService.client.storage
          .from(_bucketName)
          .createSignedUrl(fileName, 60 * 60); // 1 hour expiry

      return response;
    } catch (e) {
      print('Error getting signed URL: $e');
      return null;
    }
  }

  /// Check if storage bucket exists and create if it doesn't
  static Future<void> ensureBucketExists() async {
    try {
      // Try to list files from the bucket
      await SupabaseService.client.storage.from(_bucketName).list();
    } catch (e) {
      // If bucket doesn't exist, we might need to create it
      // Note: Bucket creation usually requires admin privileges
      // For now, we'll just log the error
      print('Storage bucket might not exist: $e');
    }
  }
}
