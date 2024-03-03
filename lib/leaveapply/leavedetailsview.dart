import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:klu_flutter/leaveapply/studentformsview.dart';
import 'package:klu_flutter/security/EncryptionService.dart';
import 'package:klu_flutter/services/sendnotification.dart';
import 'package:klu_flutter/utils/RealtimeDatabase.dart';
import 'package:klu_flutter/utils/loadingdialog.dart';
import 'package:klu_flutter/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/Firebase.dart';
import '../utils/shraredprefs.dart';
import 'package:permission_handler/permission_handler.dart';

class LeaveDetailsView extends StatefulWidget {
  final String leaveid;
  final String leaveformtype;
  final String lecturerRef;
  final String type;
  final String regNo;
  LeaveDetailsView({required this.leaveid, required this.leaveformtype, required this.lecturerRef,required this.type,required this.regNo});
  @override
  _LeaveDataState createState() => _LeaveDataState();
}

class _LeaveDataState extends State<LeaveDetailsView> {
  Map<String,dynamic> totalLeaveDetails={};
  bool shouldShowAcceptButton=false;
  bool shouldShowDeleteButton=false;
  bool shouldShowRejectButton=false;
  Utils utils=Utils();
  FirebaseService firebaseService = FirebaseService();
  SharedPreferences sharedPreferences = SharedPreferences();
  RealtimeDatabase realtimeDatabase=RealtimeDatabase();
  EncryptionService encryptionService=EncryptionService();
  String? privilege,staffID;
  late DocumentReference lecturerReference;
  List<String> details=[];
  Map<String, dynamic> studentLeaveDetails = {};

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  Future<void> initializeData() async {
    privilege = await sharedPreferences.getSecurePrefsValue("PRIVILEGE");
    staffID=await sharedPreferences.getSecurePrefsValue('STAFF ID');
    lecturerReference=FirebaseFirestore.instance.doc(widget.lecturerRef);
    if ((widget.leaveformtype != 'ACCEPTED' && widget.leaveformtype != 'REJECTED') && widget.leaveformtype == 'PENDING' && privilege != 'STUDENT') {
      shouldShowAcceptButton = true;
      shouldShowRejectButton = true;
    }
    totalLeaveDetails = await getLeaveDetails();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    List<String> orderOfDetails = ['LEAVE ID', 'START DATE', 'RETURN DATE', 'REGISTRATION NUMBER', 'NAME', 'YEAR', 'BRANCH', 'STREAM',
      'SECTION', 'FACULTY ADVISOR STAFF ID', 'STUDENT MOBILE NUMBER', 'PARENTS MOBILE NUMBER', 'REASON', 'HOSTEL NAME', 'HOSTEL ROOM NUMBER',
      'FACULTY ADVISOR APPROVAL', 'YEAR COORDINATOR APPROVAL', 'HOSTEL WARDEN APPROVAL', 'VERIFICATION STATUS','REASON FOR REJECTION'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Leave Data'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Your existing details display
              ...orderOfDetails.map((detailKey) {
                String detailValue = totalLeaveDetails[detailKey]?.toString() ?? ''; // Use null-aware operator to check for null value
                // Check if detailValue is empty or null, if so, don't display it
                if (detailValue.isEmpty) {
                  return SizedBox(); // Return an empty SizedBox if detailValue is empty or null
                }
                return Column(
                  children: [
                    // If the detailValue is a mobile number, show IconButton
                    if (utils.isValidMobileNumber(detailValue))
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: TextStyle(fontSize: 16, color: Colors.black),
                              children: [
                                TextSpan(
                                  text: '$detailKey: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                  text: '$detailValue',
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.phone),
                            onPressed: () {
                              _makePhoneCall(detailValue);
                            },
                          ),
                        ],
                      ),
                    // If the detailValue is not a mobile number, show RichText
                    if (!utils.isValidMobileNumber(detailValue))
                      Column(
                        children: [
                          RichText(
                            text: TextSpan(
                              style: TextStyle(fontSize: 16, color: Colors.black),
                              children: [
                                TextSpan(
                                  text: '$detailKey: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                  text: '$detailValue',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    SizedBox(height: 15), // Add some space between each RichText widget
                  ],
                );
              }).toList(),
              //SizedBox(height: 20), // Add space between details and buttons
              // Row with three buttons, each with dynamic visibility
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (shouldShowAcceptButton)
                    Column(
                      children: [
                        IconButton(
                          icon: Icon(Icons.check, color: Colors.green), // Change color to green
                          onPressed: () {
                            // Handle accept button press
                            onAccept();
                          },
                        ),
                        Text('Accept'), // Text for the accept button
                      ],
                    ),
                  if (shouldShowRejectButton)
                    Column(
                      children: [
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.red), // Change color to red
                          onPressed: () {
                            // Handle reject button press
                            onReject();
                          },
                        ),
                        Text('Reject'), // Text for the reject button
                      ],
                    ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    var status = await Permission.phone.status;
    print('Initial Permission Status: $status'); // Add this line
    if (status.isGranted) {
      String url = 'tel:$phoneNumber';
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        throw 'Could not launch $url';
      }
    } else if (status.isDenied) {
      var permissionStatus = await Permission.phone.request();
      print('Permission Status after request: $permissionStatus'); // Add this line
      if (permissionStatus.isGranted) {
        String url = 'tel:$phoneNumber';
        if (await canLaunch(url)) {
          await launch(url);
        } else {
          throw 'Could not launch $url';
        }
      } else {
        // Handle permission denied or show a dialog to inform the user
      }
    }
  }


  Future<void> onAccept() async {
    print('onAccept: ');
    try {

      utils.showDefaultLoading();
      CollectionReference leaveRef=await utils.DocumentToCollection(lecturerReference);
      DocumentReference redirectingRef=FirebaseFirestore.instance.doc('KLU/ERROR DETAILS');
      DocumentReference? value;
      String? faYear = studentLeaveDetails['YEAR'];
      String? faStream =studentLeaveDetails['STREAM'];
      String? faBranch = studentLeaveDetails['BRANCH'];
      String? hostelName=studentLeaveDetails['HOSTEL NAME'];
      String? hostelType=studentLeaveDetails['HOSTEL TYPE'];
      String? hostelFloor=studentLeaveDetails['HOSTEL FLOOR NUMBER'];

      String verified='PENDING';
      String salt='';
      String notificationStaffID='';
      DocumentReference notificationReference=FirebaseFirestore.instance.doc('KLU/STUDENTDETAILS/CSE/99210041602');

      print('PRIVILEGE: ${privilege}');
      if(privilege=='FACULTY ADVISOR') {

        redirectingRef = FirebaseFirestore.instance.doc('/KLU/ADMINS/$faYear/$faBranch/YEARCOORDINATOR/$faStream/LEAVEFORMS/PENDING');
        salt=studentLeaveDetails['YEAR COORDINATOR EMAIL ID'];
        notificationStaffID=studentLeaveDetails['YEAR COORDINATOR STAFF ID'];
        notificationReference=FirebaseFirestore.instance.doc('KLU/STAFFDETAILS/${studentLeaveDetails['BRANCH']}/$notificationStaffID');
        print('FA not: ${notificationReference.toString()}');

      }else if(privilege=='YEAR COORDINATOR' || privilege=='HOD'){

        redirectingRef = FirebaseFirestore.instance.doc('/KLU/HOSTELS/$hostelName/$hostelType/$hostelFloor/PENDING');
        salt=studentLeaveDetails['HOSTEL WARDEN EMAIL ID'];
        notificationStaffID=studentLeaveDetails['HOSTEL WARDEN STAFF ID'];
        notificationReference=FirebaseFirestore.instance.doc('KLU/HOSTELWARDENDETAILS/$hostelName/$notificationStaffID');

      }else if(privilege=='FACULTY ADVISOR AND YEAR COORDINATOR'){
          if(widget.type=='SECTION'){

          redirectingRef = FirebaseFirestore.instance.doc('/KLU/ADMINS/$faYear/$faBranch/YEARCOORDINATOR/$faStream/LEAVEFORMS/PENDING');
          salt=studentLeaveDetails['YEAR COORDINATOR EMAIL ID'];
          privilege='FACULTY ADVISOR';
          notificationStaffID=studentLeaveDetails['HOSTEL WARDEN STAFF ID'];
          notificationReference=FirebaseFirestore.instance.doc('KLU/STAFFDETAILS/${studentLeaveDetails['BRANCH']}/$notificationStaffID');

          }else if(widget.type=='YEAR COORDINATOR'){

          redirectingRef = FirebaseFirestore.instance.doc('/KLU/HOSTELS/${hostelName}/$hostelType/$hostelFloor/PENDING');
          salt=studentLeaveDetails['HOSTEL WARDEN EMAIL ID'];
          privilege='YEAR COORDINATOR';
          notificationStaffID=studentLeaveDetails['HOSTEL WARDEN STAFF ID'];
          notificationReference=FirebaseFirestore.instance.doc('KLU/HOSTELWARDENDETAILS/$hostelName/$notificationStaffID');

          }
      }else if(privilege=='HOSTEL WARDEN'){
        verified='APPROVED';
      }

      print('Leave Reference: ${leaveRef.toString()}');
      print('Redirecting Reference: ${redirectingRef.toString()}');

      await realtimeDatabase.incrementLeaveCount('/KLU/${utils.getTime()}/${studentLeaveDetails['YEAR']}/${studentLeaveDetails['BRANCH']}/${studentLeaveDetails['STREAM']}/${studentLeaveDetails['SECTION']}/ACCEPTED');
      await realtimeDatabase.decrementLeaveCount('/KLU/${utils.getTime()}/${studentLeaveDetails['YEAR']}/${studentLeaveDetails['BRANCH']}/${studentLeaveDetails['STREAM']}/${studentLeaveDetails['SECTION']}/PENDING');


      value=FirebaseFirestore.instance.doc('KLU/STUDENTDETAILS/${studentLeaveDetails['YEAR']}/${studentLeaveDetails['REGISTRATION NUMBER']}');

      Map<String,dynamic> data={widget.leaveid:value.path};
      await firebaseService.uploadMapDetailsToDoc(leaveRef.doc('ACCEPTED'), data,staffID!,utils.getEmail());
      await firebaseService.deleteField(leaveRef.doc('PENDING'), widget.leaveid);

      data.clear();
      data={'${privilege} APPROVAL':'APPROVED','VERIFICATION STATUS':verified,'$staffID TIMESTAMP': utils.getCurrentTimeStamp()};
      await firebaseService.uploadMapDetailsToDoc(value.collection('LEAVEFORMS').doc(widget.leaveid),data,staffID!,'${studentLeaveDetails['REGISTRATION NUMBER']}@klu.ac.in');

      List<String> lecturerFcmToken=['FCMTOKEN'];
      print('NotificationReference: ${notificationReference.toString()}');
      Map<String, dynamic>? lecturerfcmtoken=await firebaseService.getValuesFromDocRef(notificationReference, lecturerFcmToken, utils.getEmail()) ?? {'FCMTOKEN':''};
      print('Lecturer FCM TOKEN: ${lecturerfcmtoken.toString()}');
      Map<String,String> additionalNotificationData={};

      data.clear();
      data.addAll({widget.leaveid:value.path});
      if(privilege !='HOSTEL WARDEN'){
        await firebaseService.uploadMapDetailsToDoc(redirectingRef, data,staffID!,salt);
        print('Sending Notification');
        sendPushMessage(recipientToken: lecturerfcmtoken['FCMTOKEN'], title: 'Leave Applications', body: '${studentLeaveDetails['REGISTRATION NUMBER']} $privilege APPROVED', additionalData: additionalNotificationData);
      }

      sendPushMessage(recipientToken: studentLeaveDetails['FCMTOKEN'], title: 'Leave Applications', body: '${widget.leaveid} $privilege APPROVED', additionalData: additionalNotificationData);

      Navigator.pop(context);
      EasyLoading.dismiss();
    } catch (e) {
      utils.exceptions(e,'onAccept');
      utils.showToastMessage('Error occurred try after some time', context);
      EasyLoading.dismiss();
      // You might want to add proper error handling here, depending on your application's requirements
    }
  }


  Future<void> onReject() async {
    print('onReject: ');
    try {
      utils.showDefaultLoading();
      String? hostelName=studentLeaveDetails['HOSTEL NAME'];
      DocumentReference value;
      CollectionReference collectionReference = await utils.DocumentToCollection(lecturerReference);
      String field = '';
      String notificationStaffID='';
      DocumentReference notificationReference=FirebaseFirestore.instance.doc('KLU/STUDENTDETAILS/CSE/99210041602');

      if(privilege=='FACULTY ADVISOR') {
        field='FACULTY ADVISOR APPROVAL';
        notificationStaffID=studentLeaveDetails['YEAR COORDINATOR STAFF ID'];
        notificationReference=FirebaseFirestore.instance.doc('KLU/STAFFDETAILS/${studentLeaveDetails['BRANCH']}/$notificationStaffID');
        print('FA not: ${notificationReference.toString()}');
      } else if(privilege=='YEAR COORDINATOR' || privilege=='HOD'){

        field='YEAR COORDINATOR APPROVAL';
        notificationStaffID=studentLeaveDetails['HOSTEL WARDEN STAFF ID'];
        notificationReference=FirebaseFirestore.instance.doc('KLU/HOSTELWARDENDETAILS/$hostelName/$notificationStaffID');

      } else if(privilege=='FACULTY ADVISOR AND YEAR COORDINATOR'){
        if(widget.type=='SECTION'){

          privilege='FACULTY ADVISOR';
          field='FACULTY ADVISOR APPROVAL';
          notificationStaffID=studentLeaveDetails['YEAR COORDINATOR STAFF ID'];
          notificationReference=FirebaseFirestore.instance.doc('KLU/STAFFDETAILS/${studentLeaveDetails['BRANCH']}/$notificationStaffID');

        } else if(widget.type=='YEAR COORDINATOR'){

          privilege='YEAR COORDINATOR';
          notificationStaffID=studentLeaveDetails['HOSTEL WARDEN STAFF ID'];
          notificationReference=FirebaseFirestore.instance.doc('KLU/HOSTELWARDENDETAILS/$hostelName/$notificationStaffID');
          field='YEAR COORDINATOR APPROVAL';

        }
      } else if(privilege=='HOSTEL WARDEN'){
        field='HOSTEL WARDEN APPROVAL';
      } else {
        utils.showToastMessage('Error occurred while rejecting', context);
        return;
      }

      print('Incrementing leave count...');
      await realtimeDatabase.incrementLeaveCount('/KLU/${utils.getTime()}/${studentLeaveDetails['YEAR']}/${studentLeaveDetails['BRANCH']}/${studentLeaveDetails['STREAM']}/${studentLeaveDetails['SECTION']}/REJECTED');
      print('Decrementing leave count...');
      await realtimeDatabase.decrementLeaveCount('/KLU/${utils.getTime()}/${studentLeaveDetails['YEAR']}/${studentLeaveDetails['BRANCH']}/${studentLeaveDetails['STREAM']}/${studentLeaveDetails['SECTION']}/PENDING');

      Map<String, dynamic> data={};

      value=FirebaseFirestore.instance.doc('KLU/STUDENTDETAILS/${studentLeaveDetails['YEAR']}/${studentLeaveDetails['REGISTRATION NUMBER']}');


      data.clear();
      data.addAll({widget.leaveid:value.path});
      print('Storing document reference...');
      await firebaseService.uploadMapDetailsToDoc(collectionReference.doc('REJECTED'), data,staffID!,utils.getEmail());

      print('Deleting field...');
      await firebaseService.deleteField(collectionReference.doc('PENDING'), widget.leaveid);
      data.clear();
      data = {field: 'REJECTED', 'VERIFICATION STATUS': 'REJECTED','$staffID TIMESTAMP': utils.getCurrentTimeStamp()};
      print('Uploading map details to doc...');
      DocumentReference valueRef=FirebaseFirestore.instance.doc(value.path);
      await firebaseService.uploadMapDetailsToDoc(valueRef.collection('LEAVEFORMS').doc(widget.leaveid), data, staffID!, '${studentLeaveDetails['REGISTRATION NUMBER']}@klu.ac.in');

      sendPushMessage(recipientToken: studentLeaveDetails['FCMTOKEN'], title: 'Leave Applications', body: '${widget.leaveid} $privilege DECLINED', additionalData: {});

      Navigator.pop(context);
      // Stop the loading dialog before navigating back
      EasyLoading.dismiss();
    }catch (e) {
      // Handle errors
      utils.showToastMessage('Error occurred, please try again later', context);
      print('Error onReject: $e');
      utils.exceptions(e, 'onReject');
      // You might want to add proper error handling here, depending on your application's requirements
    }
  }

  void showRejectionDialog() {
    String rejectionReason = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Reason for Rejection'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) {
                  rejectionReason = value;
                },
                decoration: InputDecoration(
                  hintText: 'Enter reason...',
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {

                if (rejectionReason.isEmpty) {
                  utils.showToastMessage('Reason should not be null', context);
                } else {
                  Navigator.of(context).pop(); // Close dialog
                  //onReject(rejectionReason);

                }
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String,dynamic>> getLeaveDetails() async {
    try {
      utils.showDefaultLoading();
      DocumentReference studentDetailsRef = FirebaseFirestore.instance.collection('KLU').doc('ERROR DETAILS');
      DocumentReference leaveDetailsRef = FirebaseFirestore.instance.collection('KLU').doc('ERROR DETAILS');

      String? year = await sharedPreferences.getSecurePrefsValue('YEAR');
      String? regNo = await sharedPreferences.getSecurePrefsValue('REGISTRATION NUMBER');

      Map<String, dynamic> studentDetails = {};
      Map<String, dynamic> leaveDetails = {};

      if (privilege == 'STUDENT') {
        studentDetailsRef = FirebaseFirestore.instance.doc('KLU/STUDENTDETAILS/$year/$regNo');
        print('studentDetailsRef: ${studentDetailsRef.path}');
      }else if (privilege == 'FACULTY ADVISOR' || privilege == 'YEAR COORDINATOR' || privilege == 'FACULTY ADVISOR AND YEAR COORDINATOR' || privilege == 'HOSTEL WARDEN' || privilege=='HOD') {
        List<String> listData=[widget.leaveid];

        Map<String,dynamic>? values = await firebaseService.getValuesFromDocRef(lecturerReference, listData,utils.getEmail());
        print('values:${values.toString()}');
        studentDetailsRef=FirebaseFirestore.instance.doc(values![widget.leaveid]);

      } else {
        utils.showToastMessage('Error occurred. Contact developer. Error code: 1', context);
        EasyLoading.dismiss();
      }

      print('studentDetailsRef: $studentDetailsRef');

      studentDetails = await firebaseService.getMapDetailsFromDoc(studentDetailsRef,'${widget.regNo}@klu.ac.in');
      leaveDetailsRef = studentDetailsRef.collection('LEAVEFORMS').doc(widget.leaveid);
      print('leaveDetailsRef: ${leaveDetailsRef.toString()}');
      leaveDetails = await firebaseService.getMapDetailsFromDoc(leaveDetailsRef,'${widget.regNo}@klu.ac.in');

      studentLeaveDetails.addAll(studentDetails);
      studentLeaveDetails.addAll(leaveDetails);

      EasyLoading.dismiss();
      print('StudentLeaveDetails: ${studentDetails.toString()}');
      return studentLeaveDetails;

    }catch(e){
      utils.showToastMessage('Error occurred try after some time', context);
      utils.exceptions(e, 'getLeaveDetails');
      EasyLoading.dismiss();
      return {};
    }
  }

}
