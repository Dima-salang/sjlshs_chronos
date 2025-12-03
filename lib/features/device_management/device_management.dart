import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

/// Generates a persistent device ID that remains the same across app reinstalls
/// Uses platform-specific identifiers:
/// - Android: android_id (SSAID)
/// - iOS: identifierForVendor (IDFV)
/// Falls back to a stored UUID if platform ID cannot be obtained
Future<String> getOrCreateDeviceId() async {
  final prefs = await SharedPreferences.getInstance();
  
  // Check if we already have a device ID
  String? deviceId = prefs.getString('persistent_device_id');
  
  if (deviceId != null) {
    return deviceId;
  }
  
  // If no stored ID, try to get platform ID
  try {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String? platformId;
    
    if (Theme.of(navigatorKey.currentContext!).platform == TargetPlatform.android) {
      final androidInfo = await deviceInfo.androidInfo;
      platformId = androidInfo.id; // android_id (SSAID)
    } else if (Theme.of(navigatorKey.currentContext!).platform == TargetPlatform.iOS) {
      final iosInfo = await deviceInfo.iosInfo;
      platformId = iosInfo.identifierForVendor; // identifierForVendor (IDFV)
    }
    
    // If we got a platform ID, use it as the device ID
    if (platformId != null && platformId.isNotEmpty) {
      deviceId = '${_getAppSpecificPrefix()}_$platformId';
    } else {
      // Fallback: Generate a UUID and store it
      deviceId = '${_getAppSpecificPrefix()}_${_generateUuid()}';
    }
    
    // Store the ID for future use
    await prefs.setString('persistent_device_id', deviceId);
    return deviceId;
  } catch (e) {
    debugPrint('Error getting device ID: $e');
    // Final fallback: Generate a new UUID
    final fallbackId = '${_getAppSpecificPrefix()}_${_generateUuid()}';
    await prefs.setString('persistent_device_id', fallbackId);
    return fallbackId;
  }
}

/// Gets the existing device ID or creates a new one if it doesn't exist
/// This is the main function to use when you need the device ID
Future<String> getDeviceID() async {
  return getOrCreateDeviceId();
}

/// Generates a UUID v4
String _generateUuid() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  
  // Set version (4) and variant (2) bits
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// Gets an app-specific prefix to ensure uniqueness across different apps
String _getAppSpecificPrefix() {
  // This helps prevent collisions if the same device has multiple apps using this code
  return 'sjlshs_chronos';
}

// Global navigator key to access context for platform detection
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


Future<List<Map<String, dynamic>>> getSyncStatus() async {
  final deviceId = await getDeviceID();
  final snapshot = await FirebaseFirestore.instance
      .collection('devices')
      .orderBy('lastSync', descending: true)
      .get();

  final statusList = await Future.wait(snapshot.docs.map((doc) async {
    final data = doc.data();
    final name = (data != null && data.containsKey('name') && data['name'] != null)
        ? data['name']
        : doc.id;
    final lastSync = (data != null && data.containsKey('lastSync'))
        ? (data['lastSync'] as Timestamp?)?.toDate()
        : null;
    return {
      'deviceId': doc.id,
      'name': name,
      'lastSync': lastSync,
      'isThisDevice': doc.id == deviceId,
    };
  }));
  return statusList;
}


/// Gets the device name. It will first check for a name in Firestore,
/// then fall back to a locally stored name, and finally to the device ID.
Future<String> getDeviceName() async {
  final prefs = await SharedPreferences.getInstance();
  final deviceId = await getDeviceID();

  try {
    final deviceDoc =
        await FirebaseFirestore.instance.collection('devices').doc(deviceId).get();
    if (deviceDoc.exists &&
        deviceDoc.data()!.containsKey('name') &&
        deviceDoc.data()!['name'] != null) {
      final firestoreName = deviceDoc.data()!['name'];
      // Cache the name locally
      await prefs.setString('device_name', firestoreName);
      return firestoreName;
    }
  } catch (e) {
    debugPrint('Error fetching device name from Firestore: $e');
  }

  // If Firestore fails or no name is set, try local storage
  final localName = prefs.getString('device_name');
  if (localName != null && localName.isNotEmpty) {
    return localName;
  }

  // As a final fallback, return the device ID itself.
  return deviceId;
}

/// Sets the user-friendly name for the device.
Future<void> setDeviceName(String name) async {
  final deviceId = await getDeviceID();
  final prefs = await SharedPreferences.getInstance();

  // Cache the name locally for quick access.
  await prefs.setString('device_name', name);

  // Update the device name in Firestore.
  // Using set with merge:true will create the document if it doesn't exist,
  // or update it if it does, without overwriting other fields.
  await FirebaseFirestore.instance
      .collection('devices')
      .doc(deviceId)
      .set({'name': name}, SetOptions(merge: true));
}

/// Deletes a device from Firestore by device ID.
/// This is typically used by admins to remove devices that are no longer needed
/// or were accidentally synced.
/// 
/// Throws an exception if the device cannot be deleted.
Future<void> deleteDevice(String deviceId) async {
  try {
    await FirebaseFirestore.instance
        .collection('devices')
        .doc(deviceId)
        .delete();
    debugPrint('Device $deviceId deleted successfully');
  } catch (e) {
    debugPrint('Error deleting device $deviceId: $e');
    rethrow;
  }
}


