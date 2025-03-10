import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:decryptor/theme/app_theme.dart';

class FolderSelector extends StatelessWidget {
  final String label;
  final String hintText;
  final String selectedPath;
  final void Function(String) onPathSelected;
  final IconData leadingIcon;
  final bool fileMode;
  final List<String>? allowedExtensions;

  const FolderSelector({
    super.key,
    required this.label,
    required this.hintText,
    required this.selectedPath,
    required this.onPathSelected,
    this.leadingIcon = Icons.folder_outlined,
    this.fileMode = false,
    this.allowedExtensions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            if (fileMode) {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type:
                    allowedExtensions != null ? FileType.custom : FileType.any,
                allowedExtensions: allowedExtensions,
              );
              if (result != null) {
                onPathSelected(result.files.single.path!);
              }
            } else {
              String? result = await FilePicker.platform.getDirectoryPath();
              if (result != null) {
                onPathSelected(result);
              }
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEEF2FF), width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(leadingIcon, color: AppTheme.primaryColor, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    selectedPath.isEmpty ? hintText : selectedPath,
                    style:
                        selectedPath.isEmpty
                            ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondaryColor,
                            )
                            : Theme.of(context).textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.folder_open_outlined,
                    color: AppTheme.primaryColor,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
