import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ApiService {
  // Live Hetzner Server
  static String get baseUrl {
    return 'http://178.156.229.53:8001';
  }

  static Future<File?> translatePdf({
    required File file,
    required String sourceLang,
    required String targetLang,
  }) async {
    var uri = Uri.parse('$baseUrl/api/translate-pdf');
    var request = http.MultipartRequest('POST', uri);
    
    request.fields['source_language'] = sourceLang;
    request.fields['target_language'] = targetLang;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    print('================ API CALL ================');
    print('Endpoint: POST $uri');
    print('Fields: ${request.fields}');
    print('Files: ${request.files.map((f) => f.filename).toList()}');

    var response = await request.send();

    print('Response Status: ${response.statusCode}');
    print('==========================================');

    if (response.statusCode == 200) {
      return await _saveFile(response, 'translated_${targetLang}.pdf');
    } else {
      throw Exception('Failed to translate PDF: ${response.statusCode}');
    }
  }

  static Future<File?> watermarkPdf({
    required File file,
    required String text,
    required String position,
    required double opacity,
    required String colorHex,
  }) async {
    var uri = Uri.parse('$baseUrl/editor/pdf/watermark');
    var request = http.MultipartRequest('POST', uri);

    request.fields['text'] = text;
    request.fields['position'] = position;
    request.fields['opacity'] = opacity.toString();
    request.fields['color'] = colorHex;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    print('================ API CALL ================');
    print('Endpoint: POST $uri');
    print('Fields: ${request.fields}');
    print('Files: ${request.files.map((f) => f.filename).toList()}');

    var response = await request.send();

    print('Response Status: ${response.statusCode}');
    print('==========================================');

    if (response.statusCode == 200) {
      return await _saveFile(response, 'watermarked.pdf');
    } else {
      throw Exception('Failed to apply watermark: ${response.statusCode}');
    }
  }

  static Future<File> _saveFile(http.StreamedResponse response, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);

    final fileStream = file.openWrite();
    await response.stream.pipe(fileStream);
    await fileStream.flush();
    await fileStream.close();

    return file;
  }
}
