import 'dart:typed_data';
import 'dart:html' as html;
import 'package:dio/dio.dart';

class DownloadFileWeb {
  static Future<void> downloadFile(String fileUrl, String filename) async {
    try {
      // Download file as bytes using Dio
      Response<List<int>> response = await Dio().get<List<int>>(
        fileUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      // Create a blob from the response data
      final blob = html.Blob([Uint8List.fromList(response.data!)]);

      // Create a link element
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", filename)
        ..click();

      // Clean up
      html.Url.revokeObjectUrl(url);
      print('File downloaded successfully');
    } catch (e) {
      print('Error downloading file: $e');
    }
  }
}