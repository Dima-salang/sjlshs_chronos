import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart'; 

String generateDeviceId() {
    final random = Random().nextInt(1000000).toString();
    return random;
}

// set device id
// write to deviceID file in assets
Future<void> setDeviceId() async { 
    final deviceId = generateDeviceId();
    try {
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('device_id', deviceId);
    } catch (e) {
      debugPrint('Error setting device ID: $e');
    }
}


Future<String?> getDeviceID() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('device_id');
}







