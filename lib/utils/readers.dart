
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/cupertino.dart';
import 'package:klu_flutter/utils/storage.dart';
import 'package:klu_flutter/utils/utils.dart';

class Reader{
  Utils utils=Utils();
  Storage storage = Storage();


  Future<Map<String, String>> downloadedDetail(String encodedPath, String filename, Map<String, String> data) async {

    String fileUrl = 'https://firebasestorage.googleapis.com/v0/b/klu_details/o/$encodedPath.xlsx?alt=media';
    print("downloadedDetail: ${fileUrl.toString()}");

    String filePath = await storage.downloadFileInCache(fileUrl, '$filename.xlsx');
    Map<String, String> details = await readExcelFile(filePath, data);

    // Remove white spaces in map values and keys
    details = details.map((key, value) => MapEntry(key.trim(), value.trim()));

    print('downloadedDetail: ${details.toString()}');

    return details;
  }

  Future<List<String>> getColumnValues(String filePath, String headerName) async {
    var file = File(filePath);
    var bytes = await file.readAsBytes();
    var excel = Excel.decodeBytes(bytes);

    // Assume the data is in the first sheet
    var sheet = excel.tables.keys.first;
    var table = excel.tables[sheet];

    // Find the header index
    var headerIndex = table!.rows[0].indexWhere((cell) => cell!.value.toString().toLowerCase() == headerName.toLowerCase());
    if (headerIndex == -1) {
      throw ArgumentError('Header $headerName not found in the file.');
    }


    RegExp digitRegex = RegExp(r'\.([1-9]+)');
    RegExp zeroRegex = RegExp(r'\.(0+)');
    RegExp alphabetRegex = RegExp(r'\.([A-Za-z]+)');

    // Extract column values
    var columnValues = <String>[];
    for (var i = 1; i < table.maxRows; i++) {
      var value = table.cell(CellIndex.indexByColumnRow(columnIndex: headerIndex, rowIndex: i)).value;
      if (value != null) {
        // Convert the value to a string
        String stringValue = value.toString();


        // Remove the decimal part if it's a double
        if (value is double || value is DoubleCellValue) {
          stringValue = value.toString().split('.').last;

          var digitMatch = digitRegex.firstMatch(value.toString());
          var zeroMatch = zeroRegex.firstMatch(value.toString());
          var alphabetMatch = alphabetRegex.firstMatch(value.toString());

          if (digitMatch != null) {
            // There are digits [1-9] after the decimal point
            stringValue=value.toString();
          } else if (zeroMatch != null) {
            // There are zeros 0 after the decimal point
            stringValue=value.toString().split('.').first;
          } else if (alphabetMatch != null) {
            stringValue=value.toString();
          } else {
            // There are no digits [1-9], zeros 0, or alphabets [A-Za-z] after the decimal point
            stringValue=value.toString();
          }
        }

        //print('$stringValue  integerValue');

        // Check if parsing was successful before adding to columnValues
        columnValues.add(stringValue);
      }
    }


    return columnValues;
  }

  Future<Map<String, String>> readExcelFile(String filePath, Map<String, String> headerAndValues) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      for (final table in excel.tables.keys) {
        print('Sheet Name: $table');

        // Access properties safely using conditional expressions or null checks
        print('Max Columns: ${excel.tables[table]?.maxColumns ?? 0}');
        print('Max Rows: ${excel.tables[table]?.maxRows ?? 0}');

        RegExp digitRegex = RegExp(r'\.([1-9]+)');
        RegExp zeroRegex = RegExp(r'\.(0+)');
        RegExp alphabetRegex = RegExp(r'\.([A-Za-z]+)');

        if (excel.tables[table]?.rows != null) {
          var headers = excel.tables[table]!.rows.first;

          // Filter out null headers or headers with null values using `where`
          headers = headers.where((data) => data != null && data.value != null).toList();

          // Extract header names from the filtered list
          var headerNames = headers.map((data) => data!.value.toString().trim()).toList();

          print('headerNames: $headerNames');

        List<int> indexes = [];

          for (MapEntry<String, String> header in headerAndValues.entries) {
            String key = header.key.trim();
            String values = header.value.trim();

            var allIndexes = <int>[];
            var columnIndex = headers.indexWhere((header) => header!.value.toString() == key);

            if (columnIndex != -1) {
              var columnValues = excel.tables[table]!.rows.skip(1).map((row) => row[columnIndex]!.value).toList();
              for (var i = 0; i < columnValues.length; i++) {

              var columnValue = columnValues[i];
              List<String> listStringValue=columnValue.toString().split(',');

              for(String stringValue in listStringValue) {
                // Remove the decimal part if it's a double
                if (columnValue is double || columnValue is DoubleCellValue) {
                  stringValue = columnValue
                      .toString()
                      .split('.')
                      .last;

                  var digitMatch = digitRegex.firstMatch(
                      columnValue.toString());
                  var zeroMatch = zeroRegex.firstMatch(columnValue.toString());
                  var alphabetMatch = alphabetRegex.firstMatch(
                      columnValue.toString());

                  if (digitMatch != null) {
                    // There are digits [1-9] after the decimal point
                    stringValue = columnValue.toString();
                  } else if (zeroMatch != null) {
                    // There are zeros 0 after the decimal point
                    stringValue = columnValue
                        .toString()
                        .split('.')
                        .first;
                  } else if (alphabetMatch != null) {
                    stringValue = columnValue.toString();
                  } else {
                    // There are no digits [1-9], zeros 0, or alphabets [A-Za-z] after the decimal point
                    stringValue = columnValue.toString();
                  }
                }
                if (stringValue == values) {
                  allIndexes.add(i);
                }
              }
              }
              print('allIndexes: ${allIndexes.toString()}');
              if (indexes.isEmpty) {
                indexes.addAll(allIndexes);
              } else {
                indexes = indexes.where((element) => allIndexes.contains(element)).toList();
                print('indexLength: ${indexes.toString()}');
              }
            } else {
              print('Column "$key" not found.');
            }
            print('indexLength: ${indexes.length}');
          }

          if (indexes.length == 1) {
            //var targetRowValuesMap = Map<String, String>();
            Map<String,String> targetRowValuesMap={};
            var rowsList = excel.tables[table]!.rows.toList();
            var row = rowsList.elementAt(indexes[0] + 1);

            for (var i = 0; i < headers.length; i++) {
              var columnValue = row[i]!.value;

              // Remove the decimal part if it's a double
              if (columnValue is double || columnValue is DoubleCellValue) {
                var stringValue = columnValue.toString();
                var decimalIndex = stringValue.indexOf('.');

                if (decimalIndex != -1) {
                  // Check if there are any digits after the decimal point
                  print('decimal value: ');
                  if (stringValue.substring(decimalIndex + 1).contains(RegExp(r'[1-9]'))) {
                    // There are digits [1-9] after the decimal point
                    stringValue = stringValue;
                  } else {
                    // There are no digits [1-9] after the decimal point
                    stringValue = stringValue.split('.').first;
                  }
                }

                targetRowValuesMap[headerNames[i]] = stringValue;
              } else {
                targetRowValuesMap[headerNames[i]] = columnValue.toString();
              }
            }


            print('Target Row Values Map: ${targetRowValuesMap.toString()}');

            return targetRowValuesMap;
          } else if (indexes.isEmpty) {
            print('None of the specified values found in the columns.');
          } else {
            print('Multiple indexes found for the specified values.');
          }
        } else {
          print('Header not found.');
        }
      }
    } catch (e) {
      print('Error reading Excel file: $e');
    }
    return {};
  }

}