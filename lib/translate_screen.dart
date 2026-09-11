import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'api_service.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  File? _selectedFile;
  String _sourceLang = 'en';
  String _targetLang = 'bn';
  bool _isLoading = false;

  final Map<String, String> _languages = {
    'en': 'English',
    'bn': 'Bengali',
    'es': 'Spanish',
    'fr': 'French',
  };

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _translatePdf() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF file first.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      File? translatedFile = await ApiService.translatePdf(
        file: _selectedFile!,
        sourceLang: _sourceLang,
        targetLang: _targetLang,
      );

      if (translatedFile != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Translation successful!')),
        );
        OpenFilex.open(translatedFile.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.upload_file),
            label: Text(_selectedFile != null ? 'File: ${_selectedFile!.path.split('/').last}' : 'Select PDF File'),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _sourceLang,
            decoration: const InputDecoration(labelText: 'Source Language'),
            items: _languages.entries.map((entry) {
              return DropdownMenuItem(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
            onChanged: (value) => setState(() => _sourceLang = value!),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _targetLang,
            decoration: const InputDecoration(labelText: 'Target Language'),
            items: _languages.entries.map((entry) {
              return DropdownMenuItem(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
            onChanged: (value) => setState(() => _targetLang = value!),
          ),
          const SizedBox(height: 30),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            ElevatedButton(
              onPressed: _translatePdf,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Translate PDF', style: TextStyle(fontSize: 16)),
            ),
        ],
      ),
    );
  }
}
