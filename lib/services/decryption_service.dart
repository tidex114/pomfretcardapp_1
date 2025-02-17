import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';
import 'package:pointycastle/api.dart' as api;
import 'package:asn1lib/asn1lib.dart';
import 'package:pointycastle/block/aes.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';



RSAPrivateKey _parsePrivateKeyFromPem(String pem) {
  final rows = pem.split('\n');
  final keyBase64 = rows.sublist(1, rows.length - 1).join('');
  final keyBytes = base64.decode(keyBase64);
  final asn1Parser = ASN1Parser(Uint8List.fromList(keyBytes));
  final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;

  final modulus = (topLevelSeq.elements[1] as ASN1Integer).valueAsBigInteger;
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

Uint8List _decryptWithAES(Uint8List key, Uint8List iv, Uint8List cipherText) {
  // Initialize AES engine and CBC mode with the key and IV
  final aesEngine = AESEngine();
  final cbcBlockCipher = CBCBlockCipher(aesEngine)
    ..init(false, api.ParametersWithIV(api.KeyParameter(key), iv));

  // Decrypt the cipherText
  final decryptedData = Uint8List(cipherText.length);
  var offset = 0;

  while (offset < cipherText.length) {
    offset += cbcBlockCipher.processBlock(cipherText, offset, decryptedData, offset);
  }

  // Remove PKCS7 padding manually
  final paddingValue = decryptedData.last;
  if (paddingValue <= 0 || paddingValue > 16) {
    throw Exception('Invalid padding value');
  }
  final unpaddedData = decryptedData.sublist(0, decryptedData.length - paddingValue);

  return Uint8List.fromList(unpaddedData);
}
Future<Map<String, dynamic>> decryptJsonData(String encryptedJsonBase64) async {
  try {
    final secureStorage = FlutterSecureStorage();
    final privateKeyPem = await secureStorage.read(key: 'private_key');
    if (privateKeyPem != null) {
      final encryptedData = base64.decode(encryptedJsonBase64);
      final privateKey = _parsePrivateKeyFromPem(privateKeyPem);
      final decryptedData = _decryptWithPrivateKey(privateKey, Uint8List.fromList(encryptedData));
      final jsonString = utf8.decode(decryptedData);
      return json.decode(jsonString);
    } else {
      throw Exception('Private key not found in secure storage');
    }
  } catch (e) {
    print('Error during JSON data decryption: $e');
    return {};
  }
}

Future<Uint8List?> decryptPngData(String encryptedKeyBase64, String encryptedDataBase64) async {
  try {
    final secureStorage = FlutterSecureStorage();
    final privateKeyPem = await secureStorage.read(key: 'private_key');
    if (privateKeyPem != null) {
      print('Private key retrieved from secure storage');
      final encryptedKey = base64.decode(encryptedKeyBase64);
      final privateKey = _parsePrivateKeyFromPem(privateKeyPem);
      final aesKey = _decryptWithPrivateKey(privateKey, Uint8List.fromList(encryptedKey));
      final encryptedData = base64.decode(encryptedDataBase64);

      if (encryptedData.length > 16) {
        final iv = encryptedData.sublist(0, 16);
        final cipherText = encryptedData.sublist(16);

        try {
          final decryptedData = _decryptWithAES(aesKey, iv, cipherText);
          await _savePngToFile(decryptedData);
          return decryptedData;
        } catch (e) {
          print('Error during AES decryption: $e');
          throw Exception('AES decryption failed: $e');
        }
      } else {
        throw Exception('Encrypted data is too short to contain a valid IV and ciphertext');
      }
    } else {
      throw Exception('Private key not found in secure storage');
    }
  } catch (e) {
    print('Error during hybrid data decryption: $e');
    return null;
  }
}

Future<void> _savePngToFile(Uint8List pngData) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/profile_image.png';
    final file = File(filePath);
    await file.writeAsBytes(pngData);
  } catch (e) {
    print('Error saving PNG file: $e');
  }
}

Future<Uint8List?> decryptTransactionData(String encryptedKeyBase64, String encryptedDataBase64) async {
  try {
    final secureStorage = FlutterSecureStorage();
    final privateKeyPem = await secureStorage.read(key: 'private_key');

    if (privateKeyPem != null) {


      // Decode the encrypted AES key from Base64
      final encryptedKey = base64.decode(encryptedKeyBase64);
      // Parse the private key from PEM format
      final privateKey = _parsePrivateKeyFromPem(privateKeyPem);

      // Decrypt the AES key using the private key
      final aesKey = _decryptWithPrivateKey(privateKey, Uint8List.fromList(encryptedKey));

      // Decode the encrypted transaction data from Base64
      final encryptedData = base64.decode(encryptedDataBase64);

      // Ensure the encrypted data is large enough to contain an IV and ciphertext
      if (encryptedData.length > 16) {
        // Extract the Initialization Vector (IV)
        final iv = encryptedData.sublist(0, 16);

        // Extract the cipher text
        final cipherText = encryptedData.sublist(16);

        try {
          // Decrypt the cipher text using the AES key and IV
          final decryptedData = _decryptWithAES(aesKey, iv, cipherText);

          // Return the decrypted data
          return decryptedData;
        } catch (e) {
          print('Error during AES decryption: $e');
          throw Exception('AES decryption failed: $e');
        }
      } else {
        throw Exception('Encrypted data is too short to contain a valid IV and ciphertext');
      }
    } else {
      throw Exception('Private key not found in secure storage');
    }
  } catch (e) {
    print('Error during hybrid transaction data decryption: $e');
    return null;
  }
}
