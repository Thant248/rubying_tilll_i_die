import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'dart:html' as html;
import 'package:flutter_frontend/const/permissions.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
class DownloadFile {
  static Future<void> downloadFile(
      String fileUrl, String filename, BuildContext context) async {
    try {
      // if (kIsWeb) {
      //   // Web platform: Use `dart:html` for downloading
      //   Response<List<int>> response = await Dio().get<List<int>>(
      //     fileUrl,
      //     options: Options(responseType: ResponseType.bytes),
      //   );
      //   final blob = html.Blob([Uint8List.fromList(response.data!)]);
      //   final url = html.Url.createObjectUrlFromBlob(blob);
      //   final anchor = html.AnchorElement(href: url)
      //     ..setAttribute("download", filename)
      //     ..click();
      //   html.Url.revokeObjectUrl(url);
      // } else {
      // Mobile platforms: Check permissions and download
      final PermissionClass permission = PermissionClass();
      bool permissionGranted = await permission.checkPermission();
      if (permissionGranted) {
        Directory? dir = await getExternalStorageDirectory();
        String fullPath = '${dir?.path}/$filename';
        await Dio().download(fileUrl, fullPath);
        if (fileUrl.endsWith('.png') ||
            fileUrl.endsWith('.jpg') ||
            fileUrl.endsWith('.jpeg') ||
            fileUrl.endsWith('.gif') ||
            fileUrl.endsWith('.bmp')) {
          await GallerySaver.saveImage(fileUrl, albumName: 'MiMo').then((success) {
            if(success != null && success) {
              fullPath = 'saved to gallery';
            }
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Download Completed: $fullPath", style: const TextStyle(fontSize: 14),)),
        );
      }
      // }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download Failed: $e")),
      );
    }
  }
}