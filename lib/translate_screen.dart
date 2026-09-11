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

class _TranslateScreenState extends State<TranslateScreen>
    with AutomaticKeepAliveClientMixin {
  File? _selectedFile;
  String _sourceLang = 'en';
  String _targetLang = 'bn';
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  final Map<String, String> _languages = {
    'en': 'English',
    'bn': 'Bengali',
    'ar': 'Arabic',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'hi': 'Hindi',
    'zh': 'Chinese',
    'ja': 'Japanese',
    'ko': 'Korean',
  };

  Future<void> _pickFile() async {
    PlatformFile? result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      setState(() => _selectedFile = File(result.path!));
    }
  }

  Future<void> _translatePdf() async {
    if (_selectedFile == null) {
      _showSnack('Please select a PDF file first.', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      File? translatedFile = await ApiService.translatePdf(
        file: _selectedFile!,
        sourceLang: _sourceLang,
        targetLang: _targetLang,
      );
      if (translatedFile != null && mounted) {
        _showSnack('Translation successful! Opening file...', isError: false);
        OpenFilex.open(translatedFile.path);
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
        backgroundColor: isError ? const Color(0xFFE53935) : const Color(0xFF43A047),
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
                                    fontSize: 12,
                                    color: Color(0xFF6C3CE1),
                                  ),
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

          // Language Selection Card
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Language Settings',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6C3CE1),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: 'From',
                  icon: Icons.language_rounded,
                  value: _sourceLang,
                  items: _languages,
                  onChanged: (v) => setState(() => _sourceLang = v!),
                ),
                const SizedBox(height: 12),
                // Swap icon row
                Center(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        final tmp = _sourceLang;
                        _sourceLang = _targetLang;
                        _targetLang = tmp;
                      });
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C3CE1), Color(0xFF9B5DFF)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C3CE1).withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.swap_vert_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildDropdown(
                  label: 'To',
                  icon: Icons.translate_rounded,
                  value: _targetLang,
                  items: _languages,
                  onChanged: (v) => setState(() => _targetLang = v!),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Translate Button
          _isLoading
              ? _buildLoadingCard('Translating your PDF with AI...')
              : _buildGradientButton(
                  label: 'Translate PDF',
                  icon: Icons.translate_rounded,
                  onPressed: _translatePdf,
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

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E0FF)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF6C3CE1), size: 20),
            labelText: label,
            labelStyle: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9E9E9E),
            ),
            border: InputBorder.none,
          ),
          icon:
              const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6C3CE1)),
          items: items.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: onChanged,
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
