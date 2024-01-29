import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class RealtimeDatabase {
  final DatabaseReference _databaseReference =
  FirebaseDatabase.instance.ref();

  Future<void> incrementLeaveCount() async {
    final leaveCountRef = _databaseReference.child('LEAVE COUNT');

    final snapshot = await leaveCountRef.get();
    int currentCount = (snapshot.value ?? 0) as int; // Cast to int

    currentCount++;

    await leaveCountRef.set(currentCount);
  }

  Future<int> getLeaveCount() async {
    await Firebase.initializeApp(); // Ensure Firebase is initialized

    final leaveCountRef = FirebaseDatabase.instance.ref().child('LEAVE COUNT');

    final snapshot = await leaveCountRef.get();
    int leaveCount = (snapshot.value ?? 0) as int; // Cast to int

    return leaveCount;
  }
}