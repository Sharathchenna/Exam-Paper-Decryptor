import 'dart:io';
import 'package:flutter/material.dart';
import 'package:decryptor/models/decryption_config.dart';
import 'package:decryptor/services/decryption_service.dart';
import 'package:decryptor/services/zip_service.dart';
import 'package:decryptor/theme/app_theme.dart';
import 'package:decryptor/widgets/custom_text_field.dart';
import 'package:decryptor/widgets/folder_selector.dart';
import 'package:path/path.dart' as path;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DecryptionConfig _config = DecryptionConfig();
  final TextEditingController _collegeCodeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final DecryptionService _decryptionService = DecryptionService();
  final ZipService _zipService = ZipService();

  bool _isProcessing = false;
  List<String> _logs = [];
  int _processedFiles = 0;
  int _totalFiles = 0;

  @override
  void initState() {
    super.initState();
    _collegeCodeController.addListener(_updateCollegeCode);
    _passwordController.addListener(_updatePassword);
  }

  @override
  void dispose() {
    _collegeCodeController.removeListener(_updateCollegeCode);
    _passwordController.removeListener(_updatePassword);
    _collegeCodeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _updateCollegeCode() {
    setState(() {
      _config.collegeCode = _collegeCodeController.text;
    });
  }

  void _updatePassword() {
    setState(() {
      _config.zipPassword = _passwordController.text;
    });
  }

  void _addLog(String message) {
    setState(() {
      _logs.add(
        '${DateTime.now().toIso8601String().substring(11, 19)} - $message',
      );
    });
  }

  Future<void> _startDecryption() async {
    if (!_config.isComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _logs = [];
      _processedFiles = 0;
      _totalFiles = 0;
    });

    try {
      _addLog('Starting decryption process...');

      // Create desktop output directory with date
      final date = DateTime.now().toString().split(' ')[0];
      final desktopPath = path.join(
        Platform.environment['USERPROFILE'] ??
            Platform.environment['HOME'] ??
            '',
        'Desktop',
        'decryption_$date',
      );

      Directory(desktopPath).createSync(recursive: true);
      _addLog('Created output directory: $desktopPath');

      // Extract zip file
      _addLog('Extracting zip file...');
      final extractedPath = await _zipService.extractZipFile(
        _config.sourceDirectory,
        _config.zipPassword,
      );
      _addLog('Files extracted successfully');

      // Copy key files to C:/keys
      _addLog('Copying key files...');
      const keysPath = r'C:\keys';
      await _zipService.copyKeysToDirectory(
        path.join(extractedPath, 'keys'),
        keysPath,
      );
      _addLog('Key files copied successfully');

      // Load encryption key
      _addLog('Loading encryption key...');
      final keyFile = File(
        path.join(keysPath, '${_config.collegeCode}aes.key'),
      );
      final privateKeyFile = path.join(
        keysPath,
        '${_config.collegeCode}private.key',
      );

      final success = await _decryptionService.loadKey(keyFile, privateKeyFile);
      if (!success) {
        throw Exception('Failed to load encryption key');
      }
      _addLog('Encryption key loaded successfully');

      // Process encrypted files
      final encryptedDir = Directory(
        path.join(extractedPath, '6036_encrypted'),
      );
      if (!encryptedDir.existsSync()) {
        throw Exception('Encrypted files directory not found');
      }

      final files = encryptedDir.listSync();
      _totalFiles = files.length;
      _addLog('Found $_totalFiles files to decrypt');

      for (var file in files) {
        if (file is! File) continue;

        final fileName = path.basename(file.path);
        _addLog('Processing file: $fileName');

        final outputFileName = _decryptionService.generateOutputFilename(
          file.path,
          desktopPath,
        );

        final success = await _decryptionService.decrypt(
          File(file.path),
          File(outputFileName),
        );

        if (success) {
          _addLog('✅ Successfully decrypted: $fileName');
        } else {
          _addLog('❌ Failed to decrypt: $fileName');
        }

        setState(() {
          _processedFiles++;
        });
      }

      _addLog(
        'Decryption process completed: $_processedFiles/$_totalFiles files processed',
      );
    } catch (e) {
      _addLog('Error during decryption: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  double get _progressValue =>
      _totalFiles > 0 ? _processedFiles / _totalFiles : 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left sidebar
          Container(
            width: 280,
            color: AppTheme.primaryColor,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.lock_open,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'PDF Decryptor',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Text(
                  'RSA-AES Decryption',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Secure PDF File Decryptor',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(color: Colors.white24),
                const SizedBox(height: 24),
                Text(
                  'This tool decrypts PDF files that have been encrypted using the RSA-AES hybrid encryption scheme. Please provide all required fields to begin the decryption process.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                    height: 1.6,
                  ),
                ),
                const Spacer(),
                const Divider(color: Colors.white24),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.shield,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Secure Decryption',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Using RSA-AES Hybrid',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.white.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: Container(
              color: AppTheme.backgroundColor,
              child: ListView(
                padding: const EdgeInsets.all(32),
                children: [
                  Text(
                    'Configuration',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set up your decryption parameters',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Form
                  Card(
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // College code field
                          CustomTextField(
                            label: 'College Code',
                            hintText: 'Enter your college code',
                            controller: _collegeCodeController,
                            prefixIcon: Icons.school,
                          ),
                          const SizedBox(height: 24),

                          // Zip password field
                          CustomTextField(
                            label: 'Zip Password',
                            hintText: 'Enter password for the zip file',
                            controller: _passwordController,
                            prefixIcon: Icons.lock,
                            obscureText: true,
                          ),
                          const SizedBox(height: 24),

                          // Source zip file selector
                          FolderSelector(
                            label: 'Source Zip File',
                            hintText: 'Select the encrypted zip file',
                            selectedPath: _config.sourceDirectory,
                            onPathSelected: (path) {
                              setState(() {
                                _config.sourceDirectory = path;
                              });
                            },
                            leadingIcon: Icons.folder_zip_outlined,
                            fileMode: true,
                            allowedExtensions: ['zip'],
                          ),
                          const SizedBox(height: 32),

                          // Start button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed:
                                  _isProcessing ? null : _startDecryption,
                              child:
                                  _isProcessing
                                      ? const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text('Processing...'),
                                        ],
                                      )
                                      : const Text('Start Decryption'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Progress section
                  if (_isProcessing || _logs.isNotEmpty)
                    Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Decryption Progress',
                                  style:
                                      Theme.of(
                                        context,
                                      ).textTheme.headlineMedium,
                                ),
                                Text(
                                  '$_processedFiles/$_totalFiles',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Progress bar
                            LinearProgressIndicator(
                              value: _progressValue,
                              backgroundColor: Colors.grey[200],
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryColor,
                              ),
                              minHeight: 10,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            const SizedBox(height: 24),

                            // Logs
                            Text(
                              'Activity Log',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: const Color(0xFF212121),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: ListView.builder(
                                itemCount: _logs.length,
                                reverse: true,
                                itemBuilder: (context, index) {
                                  final logIndex = _logs.length - index - 1;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      _logs[logIndex],
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(
                                        color:
                                            _logs[logIndex].contains('Error') ||
                                                    _logs[logIndex].contains(
                                                      'Failed',
                                                    )
                                                ? Colors.red[300]
                                                : _logs[logIndex].contains(
                                                  'Successfully',
                                                )
                                                ? Colors.green[300]
                                                : Colors.white,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
