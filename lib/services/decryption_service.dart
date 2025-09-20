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
  
  // Debug logging callback
  Function(String)? _debugLogger;
  bool _debugEnabled = true;
  
  void setDebugLogger(Function(String) logger) {
    _debugLogger = logger;
  }
  
  void setDebugEnabled(bool enabled) {
    _debugEnabled = enabled;
  }
  
  void _debugLog(String message) {
    if (!_debugEnabled) return;
    
    if (_debugLogger != null) {
      _debugLogger!('[DEBUG] $message');
    } else {
      print('[DEBUG] $message');
    }
  }

  DecryptionService() {
    // Initialize RSA cipher with PKCS1 padding (to match Java's RSA/ECB/PKCS1Padding)
    _pkCipher = PKCS1Encoding(RSAEngine());
    // Initialize AES cipher in ECB mode without padding
    _aesCipher = BlockCipher('AES/ECB');
  }

  /// Loads the AES key using the RSA private key (matches Java implementation)
  Future<bool> loadKey(File aesKeyFile, String privateKeyFile) async {
    try {
      _debugLog('Starting key loading process...');
      _debugLog('AES key file: ${aesKeyFile.path}');
      _debugLog('Private key file: $privateKeyFile');

      // Check if files exist
      if (!aesKeyFile.existsSync()) {
        _debugLog('ERROR: AES key file does not exist: ${aesKeyFile.path}');
        return false;
      }
      if (!File(privateKeyFile).existsSync()) {
        _debugLog('ERROR: Private key file does not exist: $privateKeyFile');
        return false;
      }

      // Read private key file
      _debugLog('Reading private key file...');
      final privateKeyBytes = await File(privateKeyFile).readAsBytes();
      _debugLog('Private key file size: ${privateKeyBytes.length} bytes');
      _debugLog('Private key first 50 bytes (hex): ${privateKeyBytes.take(50).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

      // Parse PKCS8 private key
      _debugLog('Parsing PKCS8 private key...');
      final privateKey = _parsePrivateKeyFromPKCS8(privateKeyBytes);
      _debugLog('Private key parsed successfully');
      _debugLog('RSA key modulus bit length: ${privateKey.modulus!.bitLength}');
      _debugLog('RSA key modulus: ${privateKey.modulus.toString().substring(0, 50)}...');

      // Initialize RSA cipher for decryption
      _debugLog('Initializing RSA cipher for decryption...');
      _pkCipher.init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
      _debugLog('RSA cipher input block size: ${_pkCipher.inputBlockSize}');
      _debugLog('RSA cipher output block size: ${_pkCipher.outputBlockSize}');

      // Read and decrypt the AES key
      _debugLog('Reading encrypted AES key...');
      final encryptedAesKey = await aesKeyFile.readAsBytes();
      _debugLog('Encrypted AES key size: ${encryptedAesKey.length} bytes');
      _debugLog('Encrypted AES key (hex): ${encryptedAesKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

      _debugLog('Decrypting AES key using RSA...');
      final aesKeyBytes = _processInBlocks(_pkCipher, encryptedAesKey);
      _debugLog('Decrypted AES key size: ${aesKeyBytes.length} bytes');
      _debugLog('Decrypted AES key (hex): ${aesKeyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

      // Validate AES key size
      if (aesKeyBytes.length != 16) { // 128-bit AES key
        _debugLog('WARNING: AES key size is ${aesKeyBytes.length} bytes, expected 16 bytes for AES-128');
      }

      // Create AES key parameter
      _debugLog('Creating AES key parameter...');
      _aesKeyParameter = KeyParameter(aesKeyBytes);
      _debugLog('AES key parameter created successfully');

      _debugLog('Key loading completed successfully');
      return true;
    } catch (e, stackTrace) {
      _debugLog('ERROR in loadKey: $e');
      _debugLog('Stack trace: $stackTrace');
      print('Error loading AES key: $e');
      return false;
    }
  }

  /// Parse PKCS8 encoded private key (matches Java PKCS8EncodedKeySpec)
  RSAPrivateKey _parsePrivateKeyFromPKCS8(Uint8List encodedPrivateKey) {
    try {
      _debugLog('Parsing PKCS8 private key structure...');
      _debugLog('Encoded key length: ${encodedPrivateKey.length} bytes');
      
      final asn1Parser = ASN1Parser(encodedPrivateKey);
      final topSequence = asn1Parser.nextObject() as ASN1Sequence;
      _debugLog('Top-level ASN.1 sequence has ${topSequence.elements.length} elements');

      // PKCS8 format validation
      if (topSequence.elements.length < 3) {
        throw Exception('Invalid PKCS8 structure: expected at least 3 elements, got ${topSequence.elements.length}');
      }

      _debugLog('Extracting private key info from PKCS8 structure...');
      final privateKeyInfo = topSequence.elements[2] as ASN1OctetString;
      _debugLog('Private key info length: ${privateKeyInfo.valueBytes().length} bytes');
      
      final pkcs1Parser = ASN1Parser(privateKeyInfo.valueBytes());
      final pkcs1Sequence = pkcs1Parser.nextObject() as ASN1Sequence;
      _debugLog('PKCS1 sequence has ${pkcs1Sequence.elements.length} elements');

      // Validate PKCS1 structure
      if (pkcs1Sequence.elements.length < 6) {
        throw Exception('Invalid PKCS1 structure: expected at least 6 elements, got ${pkcs1Sequence.elements.length}');
      }

      _debugLog('Extracting RSA key components...');
      final modulus = (pkcs1Sequence.elements[1] as ASN1Integer).valueAsBigInteger;
      final privateExponent = (pkcs1Sequence.elements[3] as ASN1Integer).valueAsBigInteger;
      final p = (pkcs1Sequence.elements[4] as ASN1Integer).valueAsBigInteger;
      final q = (pkcs1Sequence.elements[5] as ASN1Integer).valueAsBigInteger;

      _debugLog('RSA key components extracted:');
      _debugLog('  Modulus bit length: ${modulus!.bitLength}');
      _debugLog('  Private exponent bit length: ${privateExponent!.bitLength}');
      _debugLog('  Prime p bit length: ${p!.bitLength}');
      _debugLog('  Prime q bit length: ${q!.bitLength}');

      final rsaKey = RSAPrivateKey(modulus, privateExponent, p, q);
      _debugLog('RSA private key created successfully');
      return rsaKey;
    } catch (e, stackTrace) {
      _debugLog('ERROR parsing PKCS8 private key: $e');
      _debugLog('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Process data in blocks for RSA operations
  Uint8List _processInBlocks(AsymmetricBlockCipher engine, Uint8List input) {
    try {
      _debugLog('Processing data in blocks for RSA operation...');
      _debugLog('Input length: ${input.length} bytes');
      _debugLog('Engine input block size: ${engine.inputBlockSize}');
      _debugLog('Engine output block size: ${engine.outputBlockSize}');

      final output = <int>[];
      var offset = 0;
      var blockNumber = 0;

      while (offset < input.length) {
        blockNumber++;
        final blockSize = offset + engine.inputBlockSize <= input.length
            ? engine.inputBlockSize
            : input.length - offset;

        _debugLog('Processing block $blockNumber:');
        _debugLog('  Offset: $offset');
        _debugLog('  Block size: $blockSize');

        final block = input.sublist(offset, offset + blockSize);
        _debugLog('  Block data (hex): ${block.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

        try {
          final processed = engine.process(block);
          _debugLog('  Processed block size: ${processed.length}');
          _debugLog('  Processed data (hex): ${processed.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
          output.addAll(processed);
        } catch (e) {
          _debugLog('  ERROR processing block $blockNumber: $e');
          rethrow;
        }

        offset += blockSize;
      }

      final result = Uint8List.fromList(output);
      _debugLog('Block processing completed. Total output length: ${result.length} bytes');
      return result;
    } catch (e, stackTrace) {
      _debugLog('ERROR in _processInBlocks: $e');
      _debugLog('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Decrypts a file using the loaded AES key (matches Java implementation)
  Future<bool> decrypt(File inputFile, File outputFile) async {
    try {
      _debugLog('Starting file decryption...');
      _debugLog('Input file: ${inputFile.path}');
      _debugLog('Output file: ${outputFile.path}');

      // Check if input file exists
      if (!inputFile.existsSync()) {
        _debugLog('ERROR: Input file does not exist: ${inputFile.path}');
        return false;
      }

      // Initialize AES cipher for decryption
      _debugLog('Initializing AES cipher for decryption...');
      _aesCipher.init(false, _aesKeyParameter);
      final blockSize = _aesCipher.blockSize;
      _debugLog('AES block size: $blockSize bytes');

      // Read input file
      _debugLog('Reading input file...');
      final inputBytes = await inputFile.readAsBytes();
      _debugLog('Input file size: ${inputBytes.length} bytes');
      _debugLog('Input file first 32 bytes (hex): ${inputBytes.take(32).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

      // Process input in complete blocks
      _debugLog('Validating input length against block size...');
      if (inputBytes.length % blockSize != 0) {
        _debugLog('ERROR: Input length (${inputBytes.length}) is not a multiple of block size ($blockSize)');
        _debugLog('Remainder: ${inputBytes.length % blockSize} bytes');
        throw Exception(
          'Input length must be a multiple of $blockSize bytes',
        );
      }

      final totalBlocks = inputBytes.length ~/ blockSize;
      _debugLog('Total blocks to process: $totalBlocks');

      final output = <int>[];
      var blockNumber = 0;

      for (var offset = 0; offset < inputBytes.length; offset += blockSize) {
        blockNumber++;
        _debugLog('Processing AES block $blockNumber/$totalBlocks (offset: $offset)');

        final block = inputBytes.sublist(offset, offset + blockSize);
        _debugLog('  Input block (hex): ${block.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

        try {
          final decryptedBlock = _aesCipher.process(block);
          _debugLog('  Decrypted block size: ${decryptedBlock.length} bytes');
          _debugLog('  Decrypted block (hex): ${decryptedBlock.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
          output.addAll(decryptedBlock);
        } catch (e) {
          _debugLog('  ERROR processing AES block $blockNumber: $e');
          rethrow;
        }
      }

      _debugLog('All blocks processed successfully. Total output size: ${output.length} bytes');

      // Create output directory if it doesn't exist
      final outputDir = outputFile.parent;
      if (!outputDir.existsSync()) {
        _debugLog('Creating output directory: ${outputDir.path}');
        outputDir.createSync(recursive: true);
      }

      // Write output file
      _debugLog('Writing decrypted data to output file...');
      await outputFile.writeAsBytes(output);
      _debugLog('Output file written successfully');

      // Verify output file
      if (outputFile.existsSync()) {
        final outputSize = outputFile.lengthSync();
        _debugLog('Output file verification: size = $outputSize bytes');
        if (outputSize != output.length) {
          _debugLog('WARNING: Output file size ($outputSize) does not match expected size (${output.length})');
        }
      } else {
        _debugLog('ERROR: Output file was not created successfully');
        return false;
      }

      _debugLog('File decryption completed successfully');
      return true;
    } catch (e, stackTrace) {
      _debugLog('ERROR in decrypt: $e');
      _debugLog('Stack trace: $stackTrace');
      print('Error decrypting file: $e');
      return false;
    }
  }

  /// Generates an output filename for the decrypted file (matches Java implementation)
  String generateOutputFilename(String inputPath, String destinationDir) {
    _debugLog('Generating output filename...');
    _debugLog('Input path: $inputPath');
    _debugLog('Destination directory: $destinationDir');
    
    final fileName = path.basename(inputPath);
    _debugLog('Input filename: $fileName');
    
    final parts = fileName.split('_');
    _debugLog('Filename parts: $parts');
    
    final outputName = parts.isNotEmpty
        ? parts.first
        : path.basenameWithoutExtension(fileName);
    _debugLog('Output base name: $outputName');
    
    final fullOutputPath = path.join(destinationDir, '${outputName}_decrypted.pdf');
    _debugLog('Full output path: $fullOutputPath');
    
    return fullOutputPath;
  }
}
