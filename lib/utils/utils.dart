import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
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
}
