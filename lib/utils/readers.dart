
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/cupertino.dart';
import 'package:klu_flutter/utils/storage.dart';
import 'package:klu_flutter/utils/utils.dart';

class Reader{
  Utils utils=Utils();
  Storage storage = Storage();


  Future<Map<String, String>> downloadedDetail(String encodedPath, String filename, Map<String, String> data) async {

    String fileUrl = 'https://firebasestorage.googleapis.com/v0/b/myuniv-ed957.appspot.com/o/$encodedPath.xlsx?alt=media';
    print("downloadedDetail: ${fileUrl.toString()}");

    String filePath = await storage.downloadFileInCache(fileUrl, '$filename.xlsx');
    Map<String, String> details = await readExcelFile(filePath, data);

    // Remove white spaces in map values and keys
    details = details.map((key, value) => MapEntry(key.trim(), value.trim()));
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
            String value = header.value.trim();

            var columnIndex = headerNames.indexOf(key);
            print('columnIndex: ${columnIndex.toString()}');

            if (columnIndex != -1) {
              List<List<String>> columnValues = excel.tables[table]!.rows.skip(1)
                  .map((row) => removeDot(row[columnIndex]!.value).split(',')) // Apply removeDot function and split by comma
                  .toList();

              List<int> tempList = [];

              // Iterate through each list of strings in columnValues
              for (int rowIndex = 0; rowIndex < columnValues.length; rowIndex++) {
                List<String> listString = columnValues[rowIndex];

                // Iterate through each string in the current list
                for (int stringIndex = 0; stringIndex < listString.length; stringIndex++) {
                  String stringValue = listString[stringIndex];

                  // Print the current string value for debugging
                  print('stringValue: $stringValue');

                  // Check if the current string value is a Roman numeral
                  if (utils.isRomanNumeral(stringValue)) {
                    // Convert Roman numeral to integer
                    int romanValue = utils.romanToInteger(stringValue);

                    // Print the converted integer value for debugging
                    print('romanValue: $romanValue');

                    // Compare the converted integer value with the specified value
                    if (romanValue.toString() == value) {
                      // If they match, add the rowIndex to tempList
                      tempList.add(rowIndex);
                    }
                  } else {
                    // If not a Roman numeral, compare the string value directly
                    if (stringValue == value) {
                      // If they match, add the rowIndex to tempList
                      tempList.add(rowIndex);
                    }
                  }
                }
              }

              // Print the tempList for debugging
              print('tempList: $tempList');

              // Update the indexes list
              indexes = updateIndexList(tempList, indexes);
            } else {
              print('Column "$key" not found.');
            }
          }


          print('Indexes: ${indexes}');
          if (indexes.length == 1) {
            Map<String, String> targetRowValuesMap = {};
            var rowsList = excel.tables[table]!.rows.toList();

            // Get the row index from the indexes list
            int rowIndex = indexes[0] + 1; // Adding 1 to skip the header row

            // Check if the rowIndex is within the bounds of the rowsList
            if (rowIndex >= 0 && rowIndex < rowsList.length) {
              var row = rowsList[rowIndex];

              // Iterate through the header names and corresponding values in the row
              for (int i = 0; i < headerNames.length; i++) {
                String headerName = headerNames[i];
                String cellValue = removeDot(row[i]?.value ?? '').toString();

                // Add the header name and cell value to the targetRowValuesMap
                targetRowValuesMap[headerName] = cellValue;
              }
              targetRowValuesMap=updateTargetRowValues(targetRowValuesMap);
              print('Target Row Values Map: $targetRowValuesMap');
              return targetRowValuesMap;
            } else {
              print('Row index is out of bounds.');
              return {}; // Return an empty map if the row index is out of bounds
            }
          }else if (indexes.isEmpty) {
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

  Map<String, String> updateTargetRowValues(Map<String, String> targetRowValuesMap) {
    Map<String, String> updatedMap = {}; // Create a new map to store the updated values

    // Iterate through the map entries
    targetRowValuesMap.forEach((key, value) {
      // Split the value string by comma
      List<String> splitValues = value.split(',');

      // Convert Roman numerals to integers and update the split values if needed
      for (int i = 0; i < splitValues.length; i++) {
        if (utils.isRomanNumeral(splitValues[i])) {
          // If the split value is a Roman numeral, convert it to an integer
          int romanValue = utils.romanToInteger(splitValues[i]);

          // Update the split value with the converted integer
          splitValues[i] = romanValue.toString();
        }
      }

      // Join the split values back into a single string
      String updatedValue = splitValues.join(',');

      // Update the updatedMap with the modified value
      updatedMap[key] = updatedValue;
    });

    return updatedMap; // Return the updated map
  }


  List<int> updateIndexList(List<int> temp, List<int> index) {
    if (index.isEmpty) {
      // If the index list is empty, add all elements of the temp list to it
      index.addAll(temp);
    } else {
      // Create a copy of the index list to avoid modifying it while iterating
      List<int> indexCopy = List.from(index);

      // Iterate through the index list
      for (int i = 0; i < indexCopy.length; i++) {
        // Check if the element at the current index is not present in the temp list
        if (!temp.contains(indexCopy[i])) {
          // If not present, remove it from the index list
          index.remove(indexCopy[i]);
        }
      }
    }

    // Return the updated index list
    return index;
  }


  String removeDot(dynamic value) {
    if (value is double || value is DoubleCellValue) {
      var stringValue = value.toString();
      var decimalIndex = stringValue.indexOf('.');

      // Check if the value contains a decimal point
      if (decimalIndex != -1) {
        // Check if there are any non-zero digits after the decimal point
        if (stringValue.substring(decimalIndex + 1).contains(RegExp(r'[1-9]'))) {
          // There are non-zero digits after the decimal point, keep the decimal part
          stringValue = stringValue;
        } else {
          // There are no non-zero digits after the decimal point, remove the decimal point and trailing zeros
          stringValue = stringValue.split('.')[0];
        }
      }
      return stringValue;
    }

    // Return the value as is if it's not a double
    return value.toString();
  }
  
}