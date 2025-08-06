import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class EncryptionUtils {
  /// Loads the encryption key as raw bytes
  static Uint8List? loadEncryptionKey(String key) {
    try {
      // Load the key file as raw bytes
      Uint8List bytes;
      // try decoding as base64
      try {
        bytes = base64Decode(key);
      } catch (e) {
        bytes = Uint8List.fromList(utf8.encode(key));
      }
      
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
      return null;
    }
  }
  
  /// Loads the encryption key as a base64-encoded string
  static String? loadEncryptionKeyAsBase64(String key) {
    final encryptionKey = loadEncryptionKey(key);
    if (encryptionKey == null) return null;
    return base64Encode(encryptionKey);
  }
  
  /// For backward compatibility, returns the key as a base64 string
  static String? loadEncryptionKeyAsString(String key) {
    return loadEncryptionKeyAsBase64(key);
  }
}
