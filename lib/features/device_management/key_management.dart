import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class SecretsManager {
  final storage = FlutterSecureStorage();

  /// QR SCANNER ENCRYPTION KEY
  Future<void> saveEncryptionKey(String key) async {
    final keyHash = sha256.convert(utf8.encode(key)).toString();
    await storage.write(key: 'encryption_key', value: keyHash);
  }


  Future<String?> getEncryptionKey() async {
    final keyHash = await storage.read(key: 'encryption_key');
    if (keyHash == null) return null;
    final key = sha256.convert(utf8.encode(keyHash)).toString();
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