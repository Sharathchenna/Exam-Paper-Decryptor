import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:pointycastle/export.dart';
import 'package:asn1lib/asn1lib.dart';

class DecryptionService {
  static const int aesKeySize = 128;
  static late KeyParameter _aesKeyParameter;
  late AsymmetricBlockCipher _pkCipher;
  late BlockCipher _aesCipher;

  DecryptionService() {
    // Initialize RSA cipher with PKCS1 padding (to match Java's RSA/ECB/PKCS1Padding)
    _pkCipher = PKCS1Encoding(RSAEngine());
    // Initialize AES cipher in ECB mode without padding
    _aesCipher = BlockCipher('AES/ECB');
  }

  /// Loads the AES key using the RSA private key (matches Java implementation)
  Future<bool> loadKey(File aesKeyFile, String privateKeyFile) async {
    try {
      // Read private key file
      final privateKeyBytes = await File(privateKeyFile).readAsBytes();

      // Parse PKCS8 private key
      final privateKey = _parsePrivateKeyFromPKCS8(privateKeyBytes);

      // Initialize RSA cipher for decryption
      _pkCipher.init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));

      // Read and decrypt the AES key
      final encryptedAesKey = await aesKeyFile.readAsBytes();
      final aesKeyBytes = _processInBlocks(_pkCipher, encryptedAesKey);

      // Create AES key parameter
      _aesKeyParameter = KeyParameter(aesKeyBytes);

      return true;
    } catch (e) {
      print('Error loading AES key: $e');
      return false;
    }
  }

  /// Parse PKCS8 encoded private key (matches Java PKCS8EncodedKeySpec)
  RSAPrivateKey _parsePrivateKeyFromPKCS8(Uint8List encodedPrivateKey) {
    final asn1Parser = ASN1Parser(encodedPrivateKey);
    final topSequence = asn1Parser.nextObject() as ASN1Sequence;

    // PKCS8 format
    final privateKeyInfo = topSequence.elements[2] as ASN1OctetString;
    final pkcs1Parser = ASN1Parser(privateKeyInfo.valueBytes());
    final pkcs1Sequence = pkcs1Parser.nextObject() as ASN1Sequence;

    final modulus =
        (pkcs1Sequence.elements[1] as ASN1Integer).valueAsBigInteger;
    final privateExponent =
        (pkcs1Sequence.elements[3] as ASN1Integer).valueAsBigInteger;
    final p = (pkcs1Sequence.elements[4] as ASN1Integer).valueAsBigInteger;
    final q = (pkcs1Sequence.elements[5] as ASN1Integer).valueAsBigInteger;

    return RSAPrivateKey(modulus, privateExponent, p, q);
  }

  /// Process data in blocks for RSA operations
  Uint8List _processInBlocks(AsymmetricBlockCipher engine, Uint8List input) {
    final output = <int>[];
    var offset = 0;

    while (offset < input.length) {
      final blockSize =
          offset + engine.inputBlockSize <= input.length
              ? engine.inputBlockSize
              : input.length - offset;

      final block = input.sublist(offset, offset + blockSize);
      final processed = engine.process(block);
      output.addAll(processed);

      offset += blockSize;
    }

    return Uint8List.fromList(output);
  }

  /// Decrypts a file using the loaded AES key (matches Java implementation)
  Future<bool> decrypt(File inputFile, File outputFile) async {
    try {
      // Initialize AES cipher for decryption
      _aesCipher.init(false, _aesKeyParameter);
      final blockSize = _aesCipher.blockSize;
      final inputBytes = await inputFile.readAsBytes();

      // Process input in complete blocks
      if (inputBytes.length % blockSize != 0) {
        throw Exception(
          'Input length must be a multiple of ${blockSize} bytes',
        );
      }

      final output = <int>[];
      for (var offset = 0; offset < inputBytes.length; offset += blockSize) {
        final block = inputBytes.sublist(offset, offset + blockSize);
        final decryptedBlock = _aesCipher.process(block);
        output.addAll(decryptedBlock);
      }

      await outputFile.writeAsBytes(output);
      return true;
    } catch (e) {
      print('Error decrypting file: $e');
      return false;
    }
  }

  /// Generates an output filename for the decrypted file (matches Java implementation)
  String generateOutputFilename(String inputPath, String destinationDir) {
    final fileName = path.basename(inputPath);
    final parts = fileName.split('_');
    final outputName =
        parts.isNotEmpty
            ? parts.first
            : path.basenameWithoutExtension(fileName);
    return path.join(destinationDir, '${outputName}_decrypted.pdf');
  }
}
