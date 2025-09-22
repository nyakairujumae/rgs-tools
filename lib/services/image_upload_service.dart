import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class ImageUploadService {
  static const String _bucketName = 'tool-images';

  /// Upload an image file to Supabase Storage
  static Future<String?> uploadImage(File imageFile, String toolId) async {
    try {
      // Check if user is authenticated
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated. Please log in again.');
      }

      // Create a unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.path.split('.').last;
      final fileName = 'tool_${toolId}_$timestamp.$extension';

      print('Attempting to upload image: $fileName to bucket: $_bucketName');
      print('User ID: ${user.id}');

      // Upload the file to Supabase Storage
      final response = await SupabaseService.client.storage
          .from(_bucketName)
          .upload(fileName, imageFile);

      if (response.isNotEmpty) {
        // Get the public URL for the uploaded image
        final imageUrl = SupabaseService.client.storage
            .from(_bucketName)
            .getPublicUrl(fileName);

        print('Image uploaded successfully: $imageUrl');
        return imageUrl;
      }

      return null;
    } catch (e) {
      print('Error uploading image: $e');
      
      // Provide more specific error messages
      if (e.toString().contains('not authorized') || e.toString().contains('unauthorized')) {
        throw Exception('Not authorized to upload images. Please check your permissions or try logging out and back in.');
      } else if (e.toString().contains('Bucket not found')) {
        throw Exception('Storage bucket not found. Please create the "tool-images" bucket in Supabase Storage.');
      } else if (e.toString().contains('User not authenticated')) {
        throw Exception('Please log in again to upload images.');
      } else {
        throw Exception('Failed to upload image: $e');
      }
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
      print('Storage bucket $_bucketName exists and is accessible');
    } catch (e) {
      // If bucket doesn't exist, we might need to create it
      // Note: Bucket creation usually requires admin privileges
      // For now, we'll just log the error
      print('Storage bucket might not exist or is not accessible: $e');
    }
  }

  /// Check if user is properly authenticated
  static bool isUserAuthenticated() {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) {
      print('User is not authenticated');
      return false;
    }
    print('User is authenticated: ${user.id}');
    return true;
  }

  /// Check authentication and bucket status
  static Future<Map<String, dynamic>> checkStorageStatus() async {
    final status = {
      'authenticated': false,
      'bucketExists': false,
      'user': null,
      'error': null,
    };

    try {
      // Check authentication
      final user = SupabaseService.client.auth.currentUser;
      if (user != null) {
        status['authenticated'] = true;
        status['user'] = {
          'id': user.id,
          'email': user.email,
          'role': user.userMetadata?['role'] ?? 'user',
        };
      }

      // Check bucket
      try {
        await SupabaseService.client.storage.from(_bucketName).list();
        status['bucketExists'] = true;
      } catch (e) {
        status['error'] = 'Bucket not accessible: $e';
      }
    } catch (e) {
      status['error'] = 'Check failed: $e';
    }

    return status;
  }
}
