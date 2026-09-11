import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'api_service.dart';

class WatermarkScreen extends StatefulWidget {
  const WatermarkScreen({super.key});

  @override
  State<WatermarkScreen> createState() => _WatermarkScreenState();
}

class _WatermarkScreenState extends State<WatermarkScreen> {
  File? _selectedFile;
  final TextEditingController _textController = TextEditingController(text: "CONFIDENTIAL");
  String _position = 'center';
  double _opacity = 0.5;
  Color _currentColor = Colors.red;
  bool _isLoading = false;

  final List<String> _positions = [
    'top-left', 'top-center', 'top-right',
    'center',
    'bottom-left', 'bottom-center', 'bottom-right'
  ];

  Future<void> _pickFile() async {
    PlatformFile? result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(result.path!);
      });
    }
  }

  void _pickColor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: _currentColor,
            onColorChanged: (color) {
              setState(() => _currentColor = color);
            },
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Got it'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2, 8).toUpperCase()}';
  }

  Future<void> _applyWatermark() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF file first.')),
      );
      return;
    }

    if (_textController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter watermark text.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      File? watermarkedFile = await ApiService.watermarkPdf(
        file: _selectedFile!,
        text: _textController.text,
        position: _position,
        opacity: _opacity,
        colorHex: _colorToHex(_currentColor),
      );

      if (watermarkedFile != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Watermark applied successfully!')),
        );
        OpenFilex.open(watermarkedFile.path);
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
    return SingleChildScrollView(
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
          TextField(
            controller: _textController,
            decoration: const InputDecoration(labelText: 'Watermark Text'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _position,
            decoration: const InputDecoration(labelText: 'Position'),
            items: _positions.map((pos) {
              return DropdownMenuItem(
                value: pos,
                child: Text(pos),
              );
            }).toList(),
            onChanged: (value) => setState(() => _position = value!),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Opacity:'),
              Expanded(
                child: Slider(
                  value: _opacity,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  label: _opacity.toStringAsFixed(1),
                  onChanged: (value) => setState(() => _opacity = value),
                ),
              ),
              Text(_opacity.toStringAsFixed(1)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Color: '),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _pickColor,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _currentColor,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(_colorToHex(_currentColor)),
            ],
          ),
          const SizedBox(height: 30),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            ElevatedButton(
              onPressed: _applyWatermark,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Apply Watermark', style: TextStyle(fontSize: 16)),
            ),
        ],
      ),
    );
  }
}
