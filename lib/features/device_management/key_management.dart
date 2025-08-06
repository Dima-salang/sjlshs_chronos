import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class SecretsManager {
  final storage = FlutterSecureStorage();

  /// QR SCANNER ENCRYPTION KEY
  Future<void> saveEncryptionKey(String key) async {
    await storage.write(key: 'encryption_key', value: key);
  }


  Future<String?> getEncryptionKey() async {
    final key = await storage.read(key: 'encryption_key');
    if (key == null) return null;
    debugPrint("Retrieved key: $key");
    return key;
  }




  /// LOCAL PIN RELATED FUNCTIONS

  Future<void> savePin(String pin) async {
    final pinHash = sha256.convert(utf8.encode(pin));
    await storage.write(key: 'pin', value: pinHash.toString());
  }


  Future<bool> checkPin(String pin) async {
    final pinHash = sha256.convert(utf8.encode(pin)).toString();
    final storedPinHash = await storage.read(key: 'pin');
    return pinHash == storedPinHash;
  }

}