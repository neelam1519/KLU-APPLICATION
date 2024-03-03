import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

class EncryptionService {

  final iv = IV.fromLength(16); // IV length for AES is typically 16 bytes

  // Function to generate a unique key for a user based on their UID
  encrypt.Key generateKey(String email) {
    final salt = utf8.encode(email); // Convert UID to bytes
    final hashBytes = sha256.convert(salt).bytes; // Generate SHA-256 hash
    return encrypt.Key(Uint8List.fromList(hashBytes)); // Convert hash bytes to Uint8List and return as the key
  }


  Future<Map<String, dynamic>> encryptData(String keySalt, Map<String, dynamic> data) async {
    try {
      final encrypter = Encrypter(AES(await generateKey(keySalt), mode: AESMode.cbc, padding: "PKCS7"));
      final keysToEncrypt = data.keys.toList();
      final iv = IV.fromSecureRandom(16);

      Map<String, dynamic> encryptedData = {};
      for (var key in keysToEncrypt) {
        final value = data[key];
        if (ExcludeKeys(key)) {
          // Convert value to string if it's not already
          final String stringValue = value.toString();
          final encrypted = encrypter.encrypt(stringValue, iv: iv);
          encryptedData[key] = (base64.encode(iv.bytes) + ":" + encrypted.base64);
        } else {
          // Convert value to string if it's not already
          final String stringValue = value.toString();
          encryptedData[key] = stringValue; // Store value as string
        }
      }
      return encryptedData;
    } catch (error) {
      print('Error encrypting data: $error');
      return {}; // Return an empty map or handle the error as needed
    }
  }

  bool ExcludeKeys(String key) {
    final keysToExclude = ['FCMTOKEN', 'UID','REGISTRATION NUMBER']; // List of keys to exclude from encryption
    return !keysToExclude.contains(key);
  }

  Future<Map<String, dynamic>> decryptData(String keySalt, Map<String, dynamic> encryptedData) async {
    final encrypter = Encrypter(AES(await generateKey(keySalt), mode: AESMode.cbc, padding: "PKCS7"));
    final keysToDecrypt = encryptedData.keys.toList();

    Map<String, dynamic> decryptedData = {};
    for (var key in keysToDecrypt) {
      final encryptedValue = encryptedData[key];
      if (ExcludeKeys(key)) {
        final ivAndEncrypted = encryptedValue.split(":");
        if (ivAndEncrypted.length != 2) {
          print("Error decrypting value for key: $key. Invalid format.");
          continue; // Skip to the next iteration
        }
        final iv = IV.fromBase64(ivAndEncrypted[0]);
        final encrypted = Encrypted.fromBase64(ivAndEncrypted[1]);
        final decryptedValue = encrypter.decrypt(encrypted, iv: iv);
        decryptedData[key] = decryptedValue;
      } else {
        decryptedData[key] = encryptedValue; // Keep value as it is without decryption
      }
    }
    return decryptedData;
  }

}
