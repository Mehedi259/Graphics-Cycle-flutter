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

class _WatermarkScreenState extends State<WatermarkScreen>
    with AutomaticKeepAliveClientMixin {
  File? _selectedFile;
  final TextEditingController _textController =
      TextEditingController(text: 'CONFIDENTIAL');
  String _position = 'center';
  double _opacity = 0.5;
  Color _currentColor = const Color(0xFFE53935);
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  final List<String> _positions = [
    'top-left',
    'top-center',
    'top-right',
    'center',
    'bottom-left',
    'bottom-center',
    'bottom-right',
  ];

  Future<void> _pickFile() async {
    PlatformFile? result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      setState(() => _selectedFile = File(result.path!));
    }
  }

  void _pickColor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Pick Watermark Color',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: _currentColor,
            onColorChanged: (color) => setState(() => _currentColor = color),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6C3CE1),
            ),
            child: const Text('Done',
                style: TextStyle(fontWeight: FontWeight.w700)),
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
      _showSnack('Please select a PDF file first.', isError: true);
      return;
    }
    if (_textController.text.isEmpty) {
      _showSnack('Please enter watermark text.', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      File? watermarkedFile = await ApiService.watermarkPdf(
        file: _selectedFile!,
        text: _textController.text,
        position: _position,
        opacity: _opacity,
        colorHex: _colorToHex(_currentColor),
      );
      if (watermarkedFile != null && mounted) {
        _showSnack('Watermark applied successfully!', isError: false);
        OpenFilex.open(watermarkedFile.path);
      }
    } catch (e) {
      if (mounted) _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor:
            isError ? const Color(0xFFE53935) : const Color(0xFF43A047),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // File Picker Card
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Document',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6C3CE1),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickFile,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0ECFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _selectedFile != null
                            ? const Color(0xFF6C3CE1)
                            : const Color(0xFFD8CFFE),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C3CE1), Color(0xFF9B5DFF)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.picture_as_pdf_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedFile != null
                                    ? _selectedFile!.path.split('/').last
                                    : 'Tap to browse PDF file',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedFile != null
                                      ? const Color(0xFF2D1B69)
                                      : const Color(0xFF9E9E9E),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_selectedFile != null) ...[
                                const SizedBox(height: 2),
                                const Text(
                                  'PDF selected ✓',
                                  style: TextStyle(
                                      fontSize: 12, color: Color(0xFF6C3CE1)),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(
                          _selectedFile != null
                              ? Icons.check_circle_rounded
                              : Icons.upload_rounded,
                          color: _selectedFile != null
                              ? const Color(0xFF6C3CE1)
                              : const Color(0xFF9E9E9E),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Watermark Settings Card
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Watermark Settings',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6C3CE1),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Watermark Text
                _buildInputField(
                  controller: _textController,
                  label: 'Watermark Text',
                  icon: Icons.text_fields_rounded,
                ),
                const SizedBox(height: 12),

                // Position
                _buildPositionDropdown(),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Appearance Card
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Appearance',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6C3CE1),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Opacity
                Row(
                  children: [
                    const Icon(Icons.opacity_rounded,
                        size: 20, color: Color(0xFF6C3CE1)),
                    const SizedBox(width: 8),
                    const Text(
                      'Opacity',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2D1B69),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0ECFC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${(_opacity * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6C3CE1),
                        ),
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: const Color(0xFF6C3CE1),
                    inactiveTrackColor: const Color(0xFFE8E0FF),
                    thumbColor: const Color(0xFF6C3CE1),
                    overlayColor: const Color(0x226C3CE1),
                    trackHeight: 4,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 10),
                  ),
                  child: Slider(
                    value: _opacity,
                    min: 0.1,
                    max: 1.0,
                    divisions: 9,
                    onChanged: (v) => setState(() => _opacity = v),
                  ),
                ),

                const SizedBox(height: 8),

                // Color
                Row(
                  children: [
                    const Icon(Icons.palette_rounded,
                        size: 20, color: Color(0xFF6C3CE1)),
                    const SizedBox(width: 8),
                    const Text(
                      'Color',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2D1B69),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _pickColor,
                      child: Row(
                        children: [
                          Text(
                            _colorToHex(_currentColor),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6C3CE1),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _currentColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: _currentColor.withOpacity(0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Apply Button
          _isLoading
              ? _buildLoadingCard('Applying watermark...')
              : _buildGradientButton(
                  label: 'Apply Watermark',
                  icon: Icons.water_drop_rounded,
                  onPressed: _applyWatermark,
                ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E0FF)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2D1B69),
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF6C3CE1), size: 20),
          labelText: label,
          labelStyle:
              const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildPositionDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E0FF)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: _position,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.grid_view_rounded,
                color: Color(0xFF6C3CE1), size: 20),
            labelText: 'Position',
            labelStyle: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
            border: InputBorder.none,
          ),
          icon: const Icon(Icons.keyboard_arrow_down,
              color: Color(0xFF6C3CE1)),
          items: _positions
              .map((p) => DropdownMenuItem(value: p, child: Text(p)))
              .toList(),
          onChanged: (v) => setState(() => _position = v!),
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C3CE1), Color(0xFF9B5DFF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C3CE1).withOpacity(0.45),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard(String message) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF0ECFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8CFFE)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation(Color(0xFF6C3CE1)),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6C3CE1),
            ),
          ),
        ],
      ),
    );
  }
}
