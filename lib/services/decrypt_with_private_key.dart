import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:pointycastle/export.dart';
import 'package:pointycastle/api.dart' as api;
import 'package:pomfretcardapp/pages/config.dart';
import 'package:asn1lib/asn1lib.dart';

RSAPrivateKey _parsePrivateKeyFromPem(String pem) {
  final rows = pem.split('\n');
  final keyBase64 = rows.sublist(1, rows.length - 1).join('');
  final keyBytes = base64.decode(keyBase64);
  final asn1Parser = ASN1Parser(Uint8List.fromList(keyBytes));
  final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;

  final modulus = (topLevelSeq.elements[1] as ASN1Integer).valueAsBigInteger;
  final publicExponent = (topLevelSeq.elements[2] as ASN1Integer).valueAsBigInteger;
  final privateExponent = (topLevelSeq.elements[3] as ASN1Integer).valueAsBigInteger;
  final p = (topLevelSeq.elements[4] as ASN1Integer).valueAsBigInteger;
  final q = (topLevelSeq.elements[5] as ASN1Integer).valueAsBigInteger;

  return RSAPrivateKey(modulus, privateExponent, p, q);
}

Uint8List _decryptWithPrivateKey(RSAPrivateKey privateKey, Uint8List cipherText) {
  final oaepEncoding = OAEPEncoding.withSHA256(RSAEngine())
    ..init(false, api.PrivateKeyParameter<RSAPrivateKey>(privateKey));
  return oaepEncoding.process(cipherText);
}

Future<Map<String, dynamic>> decryptJsonData(String encryptedJsonBase64) async {
  try {
    final secureStorage = FlutterSecureStorage();
    final privateKeyPem = await secureStorage.read(key: 'private_key');
    if (privateKeyPem != null) {
      // Decode the Base64-encoded encrypted data
      final encryptedData = base64.decode(encryptedJsonBase64);

      // Decode the private key from PEM format
      final privateKey = _parsePrivateKeyFromPem(privateKeyPem);

      // Decrypt the data using the private key with OAEP padding
      final decryptedData = _decryptWithPrivateKey(privateKey, Uint8List.fromList(encryptedData));

      // Convert decrypted data to JSON string
      final jsonString = utf8.decode(decryptedData);

      // Parse JSON string to a Map
      print("DCRPT SERVICE: decrypted json is $jsonString" );
      return json.decode(jsonString);
    } else {
      throw Exception('Private key not found in secure storage');
    }
  } catch (e) {
    print('Error during JSON data decryption: $e');
    return {};
  }
}