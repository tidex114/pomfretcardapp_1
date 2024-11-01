import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:pointycastle/export.dart';
import 'package:asn1lib/asn1lib.dart';


AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateRSAKeyPair() {
  SecureRandom secureRandom = exampleSecureRandom();

  // Create an RSA key generator and initialize it
  final keyGen = RSAKeyGenerator()
    ..init(ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64),
        secureRandom));

  // Use the generator
  final pair = keyGen.generateKeyPair();

  // Cast the generated key pair into the RSA key types
  final myPublic = pair.publicKey as RSAPublicKey;
  final myPrivate = pair.privateKey as RSAPrivateKey;

  return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(myPublic, myPrivate);
}

SecureRandom exampleSecureRandom() {
  final secureRandom = FortunaRandom();

  final seedSource = Random.secure();
  final seeds = <int>[];
  for (int i = 0; i < 32; i++) {
    seeds.add(seedSource.nextInt(255));
  }
  secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

  return secureRandom;
}

String encodePublicKeyToPem(RSAPublicKey publicKey) {
  final asn1Sequence = ASN1Sequence()
    ..add(ASN1Integer(publicKey.modulus!))
    ..add(ASN1Integer(publicKey.exponent!));
  final dataBase64 = base64.encode(asn1Sequence.encodedBytes);
  final formattedBase64 = insertNewlines(dataBase64, 64);
  return '-----BEGIN RSA PUBLIC KEY-----\n${formattedBase64}\n-----END RSA PUBLIC KEY-----';
}

String encodePrivateKeyToPem(RSAPrivateKey privateKey) {
  final asn1Sequence = ASN1Sequence()
    ..add(ASN1Integer(BigInt.from(0)))
    ..add(ASN1Integer(privateKey.modulus!))
    ..add(ASN1Integer(privateKey.publicExponent!))
    ..add(ASN1Integer(privateKey.privateExponent!))
    ..add(ASN1Integer(privateKey.p!))
    ..add(ASN1Integer(privateKey.q!))
    ..add(ASN1Integer(privateKey.privateExponent! % (privateKey.p! - BigInt.one)))
    ..add(ASN1Integer(privateKey.privateExponent! % (privateKey.q! - BigInt.one)))
    ..add(ASN1Integer(privateKey.q!.modInverse(privateKey.p!)));
  final dataBase64 = base64.encode(asn1Sequence.encodedBytes);
  final formattedBase64 = insertNewlines(dataBase64, 64);
  return '-----BEGIN RSA PRIVATE KEY-----\n${formattedBase64}\n-----END RSA PRIVATE KEY-----';
}

String insertNewlines(String str, int chunkSize) {
  final buffer = StringBuffer();
  for (int i = 0; i < str.length; i += chunkSize) {
    buffer.write(str.substring(i, i + chunkSize > str.length ? str.length : i + chunkSize));
    buffer.write('\n');
  }
  return buffer.toString().trim();
}
