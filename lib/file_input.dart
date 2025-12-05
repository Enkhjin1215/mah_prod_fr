import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class FileInput extends StatefulWidget {
  final String label;
  final Function(PlatformFile?) onFileSelected; // ⬅️ parent руу file буцаана

  const FileInput({super.key, required this.label, required this.onFileSelected});

  @override
  State<FileInput> createState() => _FileInputState();
}

class _FileInputState extends State<FileInput> {
  PlatformFile? selectedFile; // ⬅️ FilePicker-ийн file info

  Future<void> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf']);

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          selectedFile = result.files.first;
        });

        widget.onFileSelected(selectedFile); // ⬅️ Parent-д файл дамжуулж байна
      }
    } catch (e) {
      print('File pick error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        InkWell(
          onTap: pickFile,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    selectedFile?.name ?? "Файл сонгох",
                    style: TextStyle(color: selectedFile == null ? Colors.grey : Colors.black),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.upload_file, color: Colors.blue),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
