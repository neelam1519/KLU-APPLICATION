import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:intl/intl.dart';
import 'package:klu_flutter/utils/shraredprefs.dart';
import 'package:path_provider/path_provider.dart';

import '../main.dart';

class Utils {
  Future<void> showToastMessage(String message, BuildContext context) async {
    showToast(
      message,
      context: context,
      animation: StyledToastAnimation.slideFromBottom,
      reverseAnimation: StyledToastAnimation.slideToBottom,
      position: StyledToastPosition.bottom,
      animDuration: Duration(milliseconds: 400),
      duration: Duration(seconds: 2),
      curve: Curves.elasticOut,
      reverseCurve: Curves.elasticIn,
    );
  }

  void showDefaultLoading() {
    EasyLoading.show(
      status: 'Loading...',
      maskType: EasyLoadingMaskType.black, // or EasyLoadingMaskType.clear
    );
  }

  // Show loading with progress and a status message
  void showProgressLoading() {
    EasyLoading.showProgress(0.5, status: 'Loading...');
  }

  // Show success message with a checkmark
  void showSuccessMessage(String message) {
    EasyLoading.showSuccess(message);
  }

  // Show error message with a warning icon
  void showErrorMessage() {
    EasyLoading.showError('Failed to load!');
  }

  // Show information message with an info icon
  void showInfoMessage() {
    EasyLoading.showInfo('Information message');
  }

  int romanToInteger(String roman) {
    Map<String, int> romanValues = {
      'I': 1,
      'V': 5,
      'X': 10,
      'L': 50,
      'C': 100,
      'D': 500,
      'M': 1000,
    };

    int result = 0;
    int prevValue = 0;

    for (int i = roman.length - 1; i >= 0; i--) {
      int currentValue = romanValues[roman[i]] ?? 0;

      if (currentValue < prevValue) {
        result -= currentValue;
      } else {
        result += currentValue;
      }

      prevValue = currentValue;
    }

    return result;
  }

  Future<void> clearTemporaryDirectory() async {
    try {
      final tempDir = await getTemporaryDirectory();
      await Directory(tempDir.path).delete(recursive: true);
      print('Temporary directory cleared!');
    } catch (e) {
      print('Error clearing temporary directory: $e');
    }
  }

  bool isValidMobileNumber(String mobileNumber) {
    // Define a simple regex pattern for a 10-digit mobile number
    final RegExp mobileRegex = RegExp(r'^[0-9]{10}$');

    // Use the regex pattern to check if the mobile number is valid
    return mobileRegex.hasMatch(mobileNumber);
  }
  bool doesContainEmoji(String input) {
    // Define a regex pattern to match emojis
    final emojiRegex = RegExp(
      r'[\u{1F600}-\u{1F64F}'
      r'|\u{1F300}-\u{1F5FF}'
      r'|\u{1F680}-\u{1F6FF}'
      r'|\u{1F700}-\u{1F77F}'
      r'|\u{1F780}-\u{1F7FF}'
      r'|\u{1F800}-\u{1F8FF}'
      r'|\u{1F900}-\u{1F9FF}'
      r'|\u{1FA00}-\u{1FA6F}'
      r'|\u{2600}-\u{26FF}]',
      unicode: true,
    );

    // Check if the input string contains any emojis
    return emojiRegex.hasMatch(input);
  }

  Future<List<String>> moveStringToFirstPlace(List<String> myList, String targetString) async {
    // Remove the target string from its current position
    myList.remove(targetString);

    // Insert the target string at the beginning of the list
    myList.insert(0, targetString);
    return myList;
  }

  bool isRomanNumeral(String input) {
    RegExp romanNumeralRegExp =
    RegExp(r'^M{0,3}(CM|CD|D?C{0,3})(XC|XL|L?X{0,3})(IX|IV|V?I{0,3})$');
    return romanNumeralRegExp.hasMatch(input);
  }

  void exceptions(Object e,String name){
    if (e is FirebaseException) {
      // Handle Firebase server-side errors
      print(name);
      print('Firebase server-side error:');
      print('Code: ${e.code}');
      print('Message: ${e.message}');
    } else if (e is StateError) {
      // Handle state-related errors
      print(name);
      print('StateError: $e');
    } else if (e is ArgumentError) {
      // Handle argument-related errors
      print(name);
      print('ArgumentError: $e');
    } else if (e is RangeError) {
      print(name);
      // Handle range-related errors
      print('RangeError: $e');
    } else {
      // Handle any other unexpected errors
      print(name);
      print('Unexpected error: $e');
    }
  }

  Future<void> clearSecureStorage() async {
    final FlutterSecureStorage secureStorage = FlutterSecureStorage();
    await secureStorage.deleteAll();
  }


  Future<CollectionReference> DocumentToCollection(DocumentReference documentReference) async {
    List<String> pathSegments = documentReference.path.split('/');

    // Remove the last segment (document ID)
    pathSegments.removeLast();

    // Reconstruct the path without the last segment
    String collectionPath = pathSegments.join('/');

    // Get the Firestore instance and return the new CollectionReference
    return FirebaseFirestore.instance.collection(collectionPath);
  }
  String getTime(){
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('dd-MM-yyyy').format(now);
    print('Formatted Date: $formattedDate');
    return formattedDate;
  }

  List<String> getOneWeekDates() {
    // Get today's date
    DateTime now = DateTime.now();

    // Calculate the start date of the previous week (6 days ago)
    DateTime startDate = now.subtract(Duration(days: 6));

    print('Previous days: ${startDate.toString()}');

    // Generate dates for each day in the previous week
    List<DateTime> previousWeekDates = List.generate(7, (index) => startDate.add(Duration(days: index)),);

    // Format each date in the "dd-MM-yyyy" format
    List<String> formattedDates = previousWeekDates.map((date) => DateFormat('dd-MM-yyyy').format(date),).toList();

    // Print the formatted dates
    print('Previous Week Dates: $formattedDates');

    return formattedDates;
  }

  String intToRoman(int num) {
    if (num < 1 || num > 3999) {
      // Handle out-of-range values
      return 'Out of range (1-3999)';
    }

    // Roman numeral symbols and their values
    final List<String> romanSymbols = ['I', 'IV', 'V', 'IX', 'X', 'XL', 'L', 'XC', 'C', 'CD', 'D', 'CM', 'M'];
    final List<int> romanValues = [1, 4, 5, 9, 10, 40, 50, 90, 100, 400, 500, 900, 1000];

    String result = '';
    int i = 12; // Start from the highest value

    while (num > 0) {
      int div = num ~/ romanValues[i];
      num %= romanValues[i];
      result += romanSymbols[i] * div;
      i--;
    }

    return result;
  }

  Future<bool> checkInternetConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return false;
    } else {
      return true;
    }
  }

  String removeDomainFromEmail(String email) {
    // Find the position of the '@' symbol
    int atIndex = email.indexOf('@');

    // If '@' symbol is found, extract the username (part before '@')
    if (atIndex != -1) {
      String username = email.substring(0, atIndex);
      return username;
    } else {
      // If '@' symbol is not found, return the original email
      return email;
    }
  }

  String getBranchFromRegNo(String regNo) {
    // Check if the registration number is not null and has a valid length
    if (regNo != null) {
      // Extract the character at the specified index
      String branchCode = regNo[6];
      print(branchCode);

      // Check the extracted character and return the corresponding branch
      switch (branchCode) {
        case '4':
          return 'CSE';
        case '5':
          return 'ECE';
      // Add more cases for other branches if needed
        default:
          return 'Unknown Branch';
      }
    } else {
      // Return a default value for invalid registration numbers
      return 'Invalid Registration Number';
    }
  }
  String getYearFromRegNo(String regNo) {
    // Check if the registration number is not null and has a valid length
    if (regNo != null) {
      // Extract the character at the specified index
      String branchCode = regNo[3];
      print(branchCode);

      // Check the extracted character and return the corresponding branch
      switch (branchCode) {
        case '0':
          return '4';
        case '1':
          return '3';
        case '2':
          return "2";
        case '3':
          return '1';
        default:
          return 'Unknown Branch';
      }
    } else {
      // Return a default value for invalid registration numbers
      return 'Invalid Registration Number';
    }
  }

  Future<void> getImageBytesFromUrl(String? imageUrl) async {
    try {
      SharedPreferences sharedPreferences = await SharedPreferences();

      if (imageUrl == null || imageUrl.isEmpty) {
        // Handle the case where the image URL is null or empty
        return null;
      }
      // Download the image using http
      http.Response response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode == 200) {
        // Convert the response body to bytes
        Uint8List imageBytes = Uint8List.fromList(response.bodyBytes);

        // Encode the bytes to a base64 string and store in SharedPreferences
        sharedPreferences.storeValueInSecurePrefs('PROFILE IMAGE', base64.encode(imageBytes));

        print('Image bytes successfully fetched and stored in SharedPreferences.');
      } else {
        print('Failed to load image. Status code: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      print('Error loading image: $error');
      return null;
    }
  }

  String getRegNo(String email) {
    // Split the email address using '@'
    List<String> parts = email.split('@');

    // Check if the email has the domain part
    if (parts.length == 2) {
      // Return the part before '@'
      return parts[0];
    } else {
      // Return the original email if it doesn't have the expected format
      return email;
    }
  }

  Future<String?> lecturerORStudent(String input) async {
    // Removes special characters
    String cleanedInput = input.replaceAll(RegExp(r'[^\w\s]'), '');

    RegExp digitRegex = RegExp(r'^[0-9]+$');
    RegExp letterRegex = RegExp(r'^[a-zA-Z]+$');

    bool containsNumbers = digitRegex.hasMatch(cleanedInput);
    bool containsLetters = letterRegex.hasMatch(cleanedInput);

    if (containsNumbers && !containsLetters) {
      // Only numbers
      return 'STUDENT';
    } else if (!containsNumbers && containsLetters) {
      // Only letters
      return 'STAFF';
    } else {
      // Both or neither
      return null;
    }
  }



}

