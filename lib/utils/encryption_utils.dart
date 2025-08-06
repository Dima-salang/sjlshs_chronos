import 'dart:convert';
import 'package:flutter/foundation.dart';

class EncryptionUtils {
  /// Loads the encryption key as raw bytes
  static Future<Uint8List> loadEncryptionKey(String key) async {
    try {
      // Load the key file as raw bytes
      final byteData = key.codeUnits;
      final bytes = Uint8List.fromList(byteData);
      
      // Log the first few bytes for debugging
      debugPrint('Key loaded. First 8 bytes: ${bytes.sublist(0, bytes.length > 8 ? 8 : bytes.length)}');
      
      // Ensure the key is the correct length (32 bytes for AES-256)
      if (bytes.length < 32) {
        throw Exception('Key is too short. Expected 32 bytes, got ${bytes.length}');
      }
      
      // If the key is longer than 32 bytes, use the first 32 bytes
      return bytes.length > 32 ? bytes.sublist(0, 32) : bytes;
    } catch (e) {
      debugPrint('Error loading encryption key: $e');
      rethrow;
    }
  }
  
  /// Loads the encryption key as a base64-encoded string
  static Future<String> loadEncryptionKeyAsBase64(String key) async {
    final encryptionKey = await loadEncryptionKey(key);
    return base64Encode(encryptionKey);
  }
  
  /// For backward compatibility, returns the key as a base64 string
  static Future<String> loadEncryptionKeyAsString(String key) async {
    return await loadEncryptionKeyAsBase64(key);
  }
}
