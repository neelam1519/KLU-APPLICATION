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
    await Firebase.initializeApp(); // Ensure Firebase is initialized

    final leaveCountRef = FirebaseDatabase.instance.ref().child(path);

    final snapshot = await leaveCountRef.get();
    int leaveCount = (snapshot.value ?? 0) as int; // Cast to int

    return leaveCount;
  }
}