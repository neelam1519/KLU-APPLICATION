import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:klu_flutter/utils/Firebase.dart';
import 'package:klu_flutter/utils/shraredprefs.dart';

class PushNotificationService {
  FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initialize() async {
    print('pushNotificationService is started');
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    });

    FirebaseMessaging.onBackgroundMessage(backgroundHandler);
    // Get the token
    await getToken();
  }

  Future<void> backgroundHandler(RemoteMessage message) async {
    print('Background message received');
    print('Handling a background message ${message.messageId}');
  }

  Future<String?> getToken() async {
    try {
      String? token = await _fcm.getToken();
      print('Token: $token');
      await updateToken(token!);
      return token;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> updateToken(String token) async{
    SharedPreferences sharedPreferences=SharedPreferences();
    FirebaseService firebaseService=FirebaseService();
    String? yearCoordinatorStream='', faYear='', faStream='', faSection='',yearCoordinatorYear='',hostelName='',
        hostelFloor='',hostelType='';

    String? privilege=await sharedPreferences.getSecurePrefsValue('PRIVILEGE');
    String? year=await sharedPreferences.getSecurePrefsValue('YEAR');
    String? stream=await sharedPreferences.getSecurePrefsValue('STREAM');
    String? regNo=await sharedPreferences.getSecurePrefsValue('REGISTRATION NUMBER');
    String? branch=await sharedPreferences.getSecurePrefsValue('BRANCH');
    faYear = await sharedPreferences.getSecurePrefsValue('FACULTY ADVISOR YEAR');
    faStream = await sharedPreferences.getSecurePrefsValue('FACULTY ADVISOR STREAM');
    yearCoordinatorStream = await sharedPreferences.getSecurePrefsValue('YEAR COORDINATOR STREAM');
    branch = await sharedPreferences.getSecurePrefsValue('BRANCH');
    yearCoordinatorYear = await sharedPreferences.getSecurePrefsValue('YEAR COORDINATOR YEAR');
    faSection = await sharedPreferences.getSecurePrefsValue('FACULTY ADVISOR SECTION');
    hostelName = await sharedPreferences.getSecurePrefsValue('HOSTEL NAME');
    hostelFloor = await sharedPreferences.getSecurePrefsValue('HOSTEL FLOOR');
    hostelType = await sharedPreferences.getSecurePrefsValue('HOSTEL TYPE');
    String? staffID = await sharedPreferences.getSecurePrefsValue('STAFF ID');

    sharedPreferences.storeValueInSecurePrefs('TOKEN', token);
    print('privilege: ${privilege}');

    DocumentReference documentReference=FirebaseFirestore.instance.doc('KLU/ERROR DETAILS');
    if(privilege=='STUDENT'){
      documentReference=FirebaseFirestore.instance.doc('KLU/STUDENT DETAILS/$year/$branch/$stream/$regNo');
      Map<String,String> data={'TOKEN': token};
      await firebaseService.uploadMapDetailsToDoc(documentReference, data);

    }else if(privilege=='FACULTY ADVISOR' || privilege == 'YEAR COORDINATOR' || privilege == 'FACULTY ADVISOR AND YEAR COORDINATOR'){

      documentReference==FirebaseFirestore.instance.doc('KLU/STAFF DETAILS/$branch/$staffID');
      Map<String,String> data={'TOKEN': token};
      await firebaseService.uploadMapDetailsToDoc(documentReference, data);

    }else if(privilege=='HOSTEL WARDEN'){

      documentReference=FirebaseFirestore.instance.doc('KLU/HOSTELS STAFF DETAILS/$hostelName/$staffID');
      Map<String,String> data={'TOKEN': token};
      await firebaseService.uploadMapDetailsToDoc(documentReference, data);

    }

    print('Document Reference: ${documentReference.path}');
  }

}