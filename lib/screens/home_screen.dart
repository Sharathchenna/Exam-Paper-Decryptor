import 'dart:io';
import 'package:flutter/material.dart';
import 'package:decryptor/models/decryption_config.dart';
import 'package:decryptor/services/decryption_service.dart';
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
  final DecryptionService _decryptionService = DecryptionService();

  bool _isProcessing = false;
  List<String> _logs = [];
  int _processedFiles = 0;
  int _totalFiles = 0;

  @override
  void initState() {
    super.initState();
    _collegeCodeController.addListener(_updateCollegeCode);
  }

  @override
  void dispose() {
    _collegeCodeController.removeListener(_updateCollegeCode);
    _collegeCodeController.dispose();
    super.dispose();
  }

  void _updateCollegeCode() {
    setState(() {
      _config.collegeCode = _collegeCodeController.text;
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

      // Get all files in source directory
      final sourceDir = Directory(_config.sourceDirectory);
      final files = sourceDir.listSync().whereType<File>().toList();

      setState(() {
        _totalFiles = files.length;
      });

      _addLog('Found $_totalFiles files to decrypt');

      // Load AES key using RSA private key
      final aesKeyPath = path.join(
        _config.keyDirectory,
        '${_config.collegeCode}aes.key',
      );
      final privateKeyPath = path.join(
        _config.keyDirectory,
        '${_config.collegeCode}private.key',
      );

      _addLog('Loading encryption keys...');
      final keysLoaded = await _decryptionService.loadKey(
        File(aesKeyPath),
        privateKeyPath, // Changed to pass the path as String
      );

      if (!keysLoaded) {
        _addLog(
          'Failed to load encryption keys. Check if the files exist and the college code is correct.',
        );
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      _addLog('Keys loaded successfully');

      // Process each file
      for (var file in files) {
        final fileName = path.basename(file.path);
        _addLog('Processing file: $fileName');

        // Generate output file name based on the pattern in RSA_AES_decr
        final outputFileName = _decryptionService.generateOutputFilename(
          file.path,
          _config.destinationDirectory,
        );

        // Decrypt the file
        final success = await _decryptionService.decrypt(
          File(file.path), // Changed to pass a File object
          File(outputFileName), // Changed to pass a File object
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

                          // Source folder selector
                          FolderSelector(
                            label: 'Source Folder',
                            hintText:
                                'Select folder containing encrypted files',
                            selectedPath: _config.sourceDirectory,
                            onPathSelected: (path) {
                              setState(() {
                                _config.sourceDirectory = path;
                              });
                            },
                            leadingIcon: Icons.folder_zip_outlined,
                          ),
                          const SizedBox(height: 24),

                          // Keys folder selector
                          FolderSelector(
                            label: 'Keys Folder',
                            hintText: 'Select folder containing key files',
                            selectedPath: _config.keyDirectory,
                            onPathSelected: (path) {
                              setState(() {
                                _config.keyDirectory = path;
                              });
                            },
                            leadingIcon: Icons.key,
                          ),
                          const SizedBox(height: 24),

                          // Destination folder selector
                          FolderSelector(
                            label: 'Destination Folder',
                            hintText: 'Select folder for decrypted files',
                            selectedPath: _config.destinationDirectory,
                            onPathSelected: (path) {
                              setState(() {
                                _config.destinationDirectory = path;
                              });
                            },
                            leadingIcon: Icons.folder_open,
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
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
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
