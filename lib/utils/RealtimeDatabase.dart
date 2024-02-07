import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class RealtimeDatabase {
  final DatabaseReference databaseReference = FirebaseDatabase.instance.ref();

  Future<void> incrementLeaveCount(String path) async {
    final leaveCountRef = databaseReference.child(path);

    final snapshot = await leaveCountRef.get();
    int currentCount = (snapshot.value ?? 0) as int;

    currentCount++;

    await leaveCountRef.set(currentCount);
  }

  Future<void> decrementLeaveCount(String path) async {
    final leaveCountRef = databaseReference.child(path);

    final snapshot = await leaveCountRef.get();
    int currentCount = (snapshot.value ?? 0) as int;

    currentCount--;

    await leaveCountRef.set(currentCount);
  }

  Future<int> getLeaveCount(String path) async {

    final leaveCountRef = databaseReference.child(path);

    final snapshot = await leaveCountRef.get();
    int leaveCount = (snapshot.value ?? 0) as int; // Cast to int

    return leaveCount;
  }

  Future<List<String>> getKeyNamesInsideKeys(String path) async {
    DatabaseReference databaseReference = FirebaseDatabase.instance.reference();

    // Get the reference for the provided path
    DatabaseReference parentNodeReference = databaseReference.child(path);

    // Create a Completer to handle the asynchronous operation
    Completer<List<String>> completer = Completer<List<String>>();

    // Listen for value changes
    parentNodeReference.onValue.listen((event) {
      DataSnapshot snapshot = event.snapshot;
      if (snapshot.value != null) {
        Map<dynamic, dynamic>? data = snapshot.value as Map<dynamic, dynamic>?; // Cast to Map<dynamic, dynamic> or null
        if (data != null) {
          // Iterate over the keys and add them to the list
          List<String> keys = data.keys.map((key) => key.toString()).toList();
          completer.complete(keys); // Resolve the completer with the list of keys
        } else {
          completer.complete([]); // Resolve with an empty list if data is null
        }
      } else {
        completer.complete([]); // Resolve with an empty list if snapshot value is null
      }
    });

    // Return the future from the completer
    return completer.future;
  }

}