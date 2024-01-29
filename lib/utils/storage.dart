import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class Storage{

  Future<String> downloadFileInCache(String fileUrl, String fileName) async {
    try {
      Dio dio = Dio();

      // Get the temporary directory for caching
      Directory tempDir = await getTemporaryDirectory();
      String tempPath = tempDir.path;

      // Define the file path in the cache directory
      String filePath = '$tempPath/$fileName';

      // Download the file
      await dio.download(fileUrl, filePath);
      print('File downloaded successfully: ${filePath.toString()}');
      return filePath;
    } catch (e) {
      print('Error downloading file: $e');
      return ''; // Return an empty string or handle the error as needed
    }
  }

}