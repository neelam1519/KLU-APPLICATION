
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:klu_flutter/utils/utils.dart';

class Reader{
  Utils utils=Utils();

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

          // Extract header names from Data instances
          var headerNames = headers.map((data) => data!.value.toString().trim()).toList();
          print('Headers: $headerNames');

          List<int> indexes = [];

          for (MapEntry<String, String> header in headerAndValues.entries) {
            String key = header.key.trim();
            String values = header.value.trim();
            var allIndexes = <int>[];
            var columnIndex = headers.indexWhere((header) => header!.value.toString() == key);
            if (columnIndex != -1) {
              var columnValues = excel.tables[table]!.rows.skip(1).map((row) => row[columnIndex]!.value.toString()).toList();
              print('Values for column $key: $columnValues');
              for (var i = 0; i < columnValues.length; i++) {
                List<dynamic> columnValuesList = columnValues[i].split(',');
                print('columnValuesList: ${columnValuesList.toString()}');
                for (String columnValue in columnValuesList) {
                  if (columnValue == values) {
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
            var targetRowValuesMap = Map<String, String>();
            print('targetRowValuesMap: ${targetRowValuesMap.toString}');
            var rowsList = excel.tables[table]!.rows.toList();
            var targetRowValues = rowsList.elementAt(indexes[0] + 1).map((data) => data!.value.toString()).toList();
            var row = rowsList.elementAt(indexes[0] + 1);

            print('Row: ${row.toString()}');

            for (var i = 0; i < headers.length; i++) {
              targetRowValuesMap[headerNames[i]] = row[i]!.value.toString();
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