import 'dart:math';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:googleapis/cloudkms/v1.dart';
import 'package:googleapis_auth/auth.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;

class EncryptionService {
  late FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late CloudKMSApi _kmsApi;
  final String projectId = 'adroit-chemist-368310';
  final String locationId = 'global';
  final String keyRingId = 'SymmetricKeys';
  final String masterKeyId = 'MasterKey';

  Future<void> initializeKmsApi() async {
    final client = await _getHttpClient();
    _kmsApi = CloudKMSApi(client);
  }

  Future<AutoRefreshingAuthClient> _getHttpClient() async {
    var scopes = [CloudKMSApi.cloudPlatformScope];
    final credentials = ServiceAccountCredentials.fromJson(credentialsJson);
    return auth.clientViaServiceAccount(credentials, scopes);
  }

  Future<void> createUserKey(String userId) async {
    final userKey = generateSymmetricKey();
    final encryptedUserKey = await encryptKeyWithMasterKey(userKey);

    await _firestore.collection('users').doc(userId).set({
      'encryptedUserKey': encryptedUserKey,
    });
  }

  Future<String> encryptKeyWithMasterKey(encrypt.Key key) async {
    final name =
        'projects/$projectId/locations/$locationId/keyRings/$keyRingId/cryptoKeys/$masterKeyId';
    final response = await _kmsApi.projects.locations.keyRings.cryptoKeys
        .encrypt(EncryptRequest()..plaintext = key.base64, name);
    return response.ciphertext!;
  }

  Future<encrypt.Key> decryptKeyWithMasterKey(String encryptedKey) async {
    final name =
        'projects/$projectId/locations/$locationId/keyRings/$keyRingId/cryptoKeys/$masterKeyId';
    final response = await _kmsApi.projects.locations.keyRings.cryptoKeys
        .decrypt(DecryptRequest()..ciphertext = encryptedKey, name);
    return encrypt.Key.fromBase64(response.plaintext!);
  }

  encrypt.Key generateSymmetricKey() {
    final random = Random.secure();
    final keyBytes = List<int>.generate(32, (i) => random.nextInt(256));
    return encrypt.Key(Uint8List.fromList(keyBytes));
  }
}

final String credentialsJson = '''
{
  "type": "service_account",
  "project_id": "adroit-chemist-368310",
  "private_key_id": "696c060bcf76afae43c92bcb12ed5afcec571e72",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC7l2GKdusa6gzw\nC7U+yxGrGvDiRkZl0lx/cIHb8qct6SsOkogYbIwD/7w330ljNoqtvE1Q5HLd60ZJ\n0bperRxyAhHIHQywPhd47h3hdHoGs9vb/ibEwzXCSO+HNkuogv67UFj89JvbhN0c\nP4UMI1bxkj7VxnSUGa+9Be7jsawzOf8TKLLbHBbdYFK47KwXuUBwiBRP5/oZyT5k\n1EmGt0K9ASZ/jNtBLlxTgGsH7hS/vIy/GO8t7cM2eGZTs5HqYCsLilIaFDnBq3Dg\nQXhOgx6w8CqgKDi0BbUYxNOTSrhSHxUMChWw+rvyJGGP7lhaNTnQOYyKWSUrCYjh\nbuJYJA1NAgMBAAECggEAUsFoCu0GL7Pj7DvGA8MS8tBqRvAomz+vhZrs9sp33QWZ\ndI7JEjlElXkKn/1Vgzqq+BTzaMW3NNZXhjZLCPxGabcnAAhssg1aToOBVBYNxQow\naj8W/EN/4ktJu/UEcH0Fgj3iXAlO/osA/ja5a47liqFxLd6kTDd+sx08c19Mr7Xa\nYOcEyX6mOgd+D61eXFzQc8Ml5Kgwy0zFkNTY/Kee+AGO3Xn95b80+PUnH3XXy98t\nCg83MzqwZ/bn/Mj2pZHQQrASWY0YE0JWvwiJRLDcPIofx0wnopS2rAZYJQKRPHU+\n6e/FwCNAysrMveYVw2umaOJIYHKVoBpAeL3HBOjiAwKBgQDxgPkASVOEpx4N3gcB\n4bWF2wTf+iXq8XCoBfi1olj9Ug/SM7gSa/VfbMJT3GFApNhfEH2DLeCiJyw9Kjqb\nJb5RDsIApSbuTuYOpXJ0Snl8D66uL2bFtpNmCGqYU27haWvkL0QNn33FDs+XsQaq\nWICmUoGpcIq4YwLbLMtzgvINNwKBgQDG2fi2klZjliAyFPCQh9RgRC+9UUgDHGnz\n1Hus0DbWCNVZkHyVufZ4WvHjpglE2C0wnYLTbm3sDgGi64avTD7OLOU+8M/vp2Yu\n76TQ/larxxDzgA12UBaBpw7IxP6odj/4rsbShVeATWHM048xtcYA5fiDvBFAAH9Y\nE8Lh1/jbmwKBgQCj/WYX8bLKwwg/dmLfvjqa+ExpIt2YmfZbwiJOhD1VVuHzZLc7\nmx91es7CT0Witc1PUE1KRF7i/SKnLgO50nlXZWQLOBolfGHv1BzSJrgzrBp7oShy\nXTXd9R0c7pq+ae2fdxEJByJKK3J/mO/jwFErn574RbmM137bAaHtgB+JJQKBgDAs\nfFGWsDEeHJylcAZDsdLEkiA2QdDnIE/+6Rtbsf02VKGHHHeVfr13ouQ4xEQWbxQ5\nBIm+Vgj697CFiLKNMSX3wG34Hxf7IQk761zqUQr6hgPHwPspudodI7rF5r/fLe5M\nQUSdIy6lEI1zr1wmolpzXDpl5HPx6ufmma7nCJYDAoGANBl2pwbmtpp6Y/7QC1BF\nijNDCSyjPRLMOOkIrq6sPpnQDG2x82Dj6B8oEP8vKDD2XLduj1/gGHuF58YRZ+EH\ntDJX+pH6bCTYsZeC5Ft/Z+MGz3vLQ1r50SfvQyBD7OAdW5wTmHf+qgQgxmRgvNxB\n7WA5yHnsEHzIFi9TSCtnlkc=\n-----END PRIVATE KEY-----\n",
  "client_email": "symentricencryption@adroit-chemist-368310.iam.gserviceaccount.com",
  "client_id": "108280336080696887602",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/symentricencryption%40adroit-chemist-368310.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}
''';


