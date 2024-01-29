import 'package:flutter/material.dart';
import 'model/model.dart';

class LeaveDataProvider extends ChangeNotifier {
  LeaveCardViewData? _leaveData;

  LeaveCardViewData? get leaveData => _leaveData;

  void updateData(LeaveCardViewData newData) {
    print("New Data:  $newData");
    _leaveData = newData;
    notifyListeners();
  }
}
