import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

class EncryptionService {

  final iv = IV.fromLength(16); // IV length for AES is typically 16 bytes

  // Function to generate a unique key for a user based on their UID
  Key generateKeyFromUid(String uid) {
    final salt = utf8.encode(uid); // Convert UID to bytes
    final hashBytes = sha256.convert(salt).bytes; // Generate SHA-256 hash
    return Key(Uint8List.fromList(hashBytes)); // Convert hash bytes to Uint8List and return as the key
  }

  Future<void> encryptData(String uid) async {
    final plainText = 'Encrypting the Data';
    final aes = Encrypter(AES(generateKeyFromUid(uid))); // Use the generated key for encryption

    final encrypted = aes.encrypt(plainText, iv: iv);
    print('Encrypted Data: ${encrypted.base64}');

    await decryptData(encrypted, uid);
  }

  Future<void> decryptData(Encrypted encrypted, String uid) async {
    final aes = Encrypter(AES(generateKeyFromUid(uid))); // Use the generated key for decryption

    final decrypted = aes.decrypt(encrypted, iv: iv);
    print('Decrypted Data: $decrypted');
  }
}
