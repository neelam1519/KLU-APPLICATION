import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:klu_flutter/model/model.dart';

class SharedPreferences{
  final storage = FlutterSecureStorage();

  Future<void> storeMapValuesInSecureStorage(Map<String, String> mapValues) async {

    try {
      for (MapEntry<String, String> entry in mapValues.entries) {
        String key = entry.key;
        String value = entry.value;

        // Store each key-value pair in secure storage
        await storage.write(key: key, value: value);
        print('$key :  $value');
      }
      print('Map values stored in secure storage successfully!');
    } catch (error) {
      print('Error storing map values: $error');
      // Handle the error as needed
    }
  }

  Future<void> storeListInSecureStorage(List<String> yourList, String key) async {

    try {
      // Convert the list to a JSON string
      String jsonString = jsonEncode(yourList);

      // Store the JSON string in secure storage
      await storage.write(key: key, value: jsonString);

      print('List stored in secure storage successfully!');
    } catch (error) {
      print('Error storing list: $error');
      // Handle the error as needed
    }
  }

  Future<String?> getSecurePrefsValue(String key) async {
    try {
      return await storage.read(key: key);
    } catch (error) {
      print('Error retrieving value from secure storage: $error');
      return null;
    }
  }

  Future<void> storeValueInSecurePrefs(String key,String value) async {
    try {
      return await storage.write(key: key, value: value);
    } catch (error) {
      print('Error retrieving value from secure storage: $error');
      return null;
    }
  }

}