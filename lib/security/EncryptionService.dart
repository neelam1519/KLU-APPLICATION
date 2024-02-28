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
        print('EncryptedValue: $key ${encryptedValue.toString()}');
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

  Future<String> getKmsKey() async {
    try {
      final credentials = ServiceAccountCredentials.fromJson({
        "type": "service_account",
        "project_id": "adroit-chemist-368310",
        "private_key_id": "4420b08d2803e6995be1534ef81a6c4488f5bdff",
        "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvwIBADANBgkqhkiG9w0BAQEFAASCBKkwggSlAgEAAoIBAQD3YOGBPFS4PDdG\nZDuYO4gPkB00k0F5bZxtWbqn39uk/055waMAZkQAXM3RC1sVJn8NTHvkXcCc0JdS\nYPMf5RUQ52ZQ8M3Xg0POQgPFPe7DHF2DyX41YfqP5N5UPziBqQ/A9GyBAk6o7hm2\nDLFA61nnld/apFqs4deFNj/EdLYGUeKdtUI0aQqxlTCT96hOZX3kIpsE14k61pmf\n4wkbQDIwfhAR45b7Nr/YihhQrt+sJOCAx90zG/BoUXTZjeb5TZdF88MtqKEBsL/b\nimQaAFWzcKeDUAhKQhgj2Q/H28MtUcj1txb+XZ48HkQgCkcbFqTA0PvtMl0rqun0\nFymfgQYVAgMBAAECggEATE3m4Q0x+K4iQqUyOK/MNTi3uXrejE0CHjy6NYP4ZTmX\nBDl1RO9GdHIrzhpZmvmH4RtBb9x3SCeTNYbQF3t69v7ZcYgFhj9oD9wO+60x058R\nPVBOjLrPJclrxsLFdEEoqdT7DwQeLT9cUOozVpoB3kw9g1yE16TF7MIiA0AY0XOf\nVYxoCJUlB5BrXI7QbW8JZuG9cH+5CUP1mWZcDQhWV1L6VPVH5zNVQF9k3/SOZEUo\nEutI75tf0B4YvZPUi1uQyclQgbkqNdYe1//T3Bka3aPCmPh3s3KkNR9jEICrac4c\noXUaZYdoy5MJJvsg6Gmp7DcPKvghukatXtAIuls3VQKBgQD/vZB5PL18ABIFcymo\nN5SZu9ZEOoF9l+0QFOgZtgsQlwJKCBuXXPpk2wqEjwlQsNEvQuLdhh8bcag3SPz4\nuag0Iam8/V/uETnNEVTC1bnepCnyRPIO8hLNAZ3NNOWRw0LI63QMfyawMPM3Afs0\nnsX5rpW0K+GB7EOSJ+ZEZRA78wKBgQD3oSTt++xGT3nJFbV7uSksUTAh7aqOq2Wo\nUv5peFM3QlBnelrwZxgkyukj12kSTubHXVWYUIzXC/z5yrYcN0/UD5uWodUUKOc+\nMGK9i8ndo+QxWlc6c1GuJI3Z9ZQcyqBmr6fCMODctP4iz3agQ2v63iUzy+llga5k\nRyomwkLf1wKBgQCkXKjlwmvlrgXnCsTTICWZSGfFIfTnSyVJGKazH5Ss7ODDw8I3\n3cHv3/c6itNp0LogrdQwm2qSsNFz9qzfDjNUje4RUKa+0sNbULAxKDt1I/zxf+4y\nPNJof4lzwXNp4xyhFPJYtb+frVYjHFrezsxeVB5S1YDxh29GF+6eNnXgkQKBgQDM\ncgLnaULdmehWmNHJYEoaCL3QhUR3nhLEMiFSOsGZsepoRKCoMrXASrbJnKNnNjVb\nDDgLFRXyxjcKlM5d5VzHHEu8xcgCaPLiaVhcXflAQHu6M3gpDeS1/gAPn621R6W+\noe/DaE9+aQAZBWhPUNrpuFbGuOftom+04vxuG5zS6QKBgQC1H0+IT991YqCdoV7K\nCjtdlQ5g7KsKRprMsqO+AVBhLGGvc6viTv9kjSQiWWDKw7s2GIhy5RrRLY54O/T2\n9OzNi5+A5AfEMidC6gVhBEFBnXx8m15L1//VbkFYsVOZ79nGXYhIq61VYGWQFBux\n1GwEp9qvm9ZkGg2d8Fc/lTPK8g==\n-----END PRIVATE KEY-----\n",
        "client_email": "encryption@adroit-chemist-368310.iam.gserviceaccount.com",
        "client_id": "117174862467257676777",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/encryption%40adroit-chemist-368310.iam.gserviceaccount.com",
        "universe_domain": "googleapis.com"
      }
      );

      final scopes = ['https://www.googleapis.com/auth/cloud-platform'];
      final client = http.Client();

      // Correct the argument list to pass all three required parameters
      final accessCredentials = await auth.obtainAccessCredentialsViaServiceAccount(
          credentials,
          scopes,
          client
      );

      final httpClient = auth.authenticatedClient(
        client,
        accessCredentials,
      );

      final response = await httpClient.get(
          Uri.parse('https://cloudkms.googleapis.com/v1/projects/adroit-chemist-368310/locations/global/keyRings/Symmentrickeys/cryptoKeys/MasterKey')
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final String key = responseData['name'];
        return key;
      } else {
        throw Exception('Failed to load KMS key. Status code: ${response.statusCode}. Reason: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Failed to get KMS key: $e');
    }
  }
}
