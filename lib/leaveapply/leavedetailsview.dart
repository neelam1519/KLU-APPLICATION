import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:googleapis/apigeeregistry/v1.dart';
import 'package:klu_flutter/leaveapply/studentformsview.dart';
import 'package:klu_flutter/utils/RealtimeDatabase.dart';
import 'package:klu_flutter/utils/loadingdialog.dart';
import 'package:klu_flutter/utils/utils.dart';
import '../utils/Firebase.dart';
import '../utils/shraredprefs.dart';
import 'lecturerleaveformsview.dart';

class LeaveDetailsView extends StatefulWidget {
  final String leaveid;
  final String leaveformtype;
  final String lecturerRef;
  final String type;
  LeaveDetailsView({required this.leaveid, required this.leaveformtype, required this.lecturerRef,required this.type});
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
                    SizedBox(height: 13), // Add some space between each RichText widget
                  ],
                );
              }).toList(),
              SizedBox(height: 20), // Add space between details and buttons
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


  Future<void> onAccept() async {
    print('onAccept: ');
    try {

      utils.showDefaultLoading();
      CollectionReference leaveRef=await utils.DocumentToCollection(lecturerReference);
      DocumentReference redirectingRef=FirebaseFirestore.instance.doc('KLU/ERROR DETAILS');
      DocumentReference? value;
      String field='';
      String? faYear = await sharedPreferences.getSecurePrefsValue('FACULTY ADVISOR YEAR');
      String? faStream = await sharedPreferences.getSecurePrefsValue('FACULTY ADVISOR STREAM');
      String? faBranch = await sharedPreferences.getSecurePrefsValue('BRANCH');
      String? hostelName='BHARATHI MENS HOSTEL';
      String? hostelFloor='2';
      String? hostelType='NORMAL';

      String verified='PENDING';

      if(privilege=='FACULTY ADVISOR') {

        redirectingRef = FirebaseFirestore.instance.doc('/KLU/ADMINS/$faYear/$faBranch/YEARCOORDINATOR/$faStream/LEAVEFORMS/PENDING');
        print('onAccept ${redirectingRef.toString()}');
        field='FACULTY ADVISOR APPROVAL';

      }else if(privilege=='YEAR COORDINATOR' || privilege=='HOD'){
        redirectingRef = FirebaseFirestore.instance.doc('/KLU/HOSTELS/$hostelName/$hostelType/$hostelFloor/PENDING');
        print('onAccept ${redirectingRef.toString()}');
        field='YEAR COORDINATOR APPROVAL';
      }else if(privilege=='FACULTY ADVISOR AND YEAR COORDINATOR'){
        if(widget.type=='SECTION'){
          redirectingRef = FirebaseFirestore.instance.doc('/KLU/ADMINS/$faYear/$faBranch/YEARCOORDINATOR/$faStream/LEAVEFORMS/PENDING');
          print('onAccept ${redirectingRef.toString()}');
          field='FACULTY ADVISOR APPROVAL';
        }else if(widget.type=='YEAR COORDINATOR'){
          redirectingRef = FirebaseFirestore.instance.doc('/KLU/HOSTELS/$hostelName/$hostelType/$hostelFloor/PENDING');
          print('onAccept ${redirectingRef.toString()}');
          field='YEAR COORDINATOR APPROVAL';
        }
      }else if(privilege=='HOSTEL WARDEN'){
        field='HOSTEL WARDEN APPROVAL';
        verified='APPROVED';
      }

      await realtimeDatabase.incrementLeaveCount('/KLU/${utils.getTime()}/${studentLeaveDetails['YEAR']}/${studentLeaveDetails['BRANCH']}/'
          '${studentLeaveDetails['STREAM']}/${studentLeaveDetails['SECTION']}/ACCEPTED');

      await realtimeDatabase.decrementLeaveCount('/KLU/${utils.getTime()}/${studentLeaveDetails['YEAR']}/${studentLeaveDetails['BRANCH']}/'
          '${studentLeaveDetails['STREAM']}/${studentLeaveDetails['SECTION']}/PENDING');

      List<String> listData=[];
      listData.add(widget.leaveid);

      Map<String,dynamic>? values = await firebaseService.getValuesFromDocRef(leaveRef.doc('PENDING'),listData);
      value=values![widget.leaveid];
      print('onAccept ${value.toString()}');

      Map<String,dynamic> data={widget.leaveid:value};

      await firebaseService.uploadMapDetailsToDoc(leaveRef.doc('ACCEPTED'), data,staffID!);
      await firebaseService.deleteField(leaveRef.doc('PENDING'), widget.leaveid);

      data.clear();
      data={field:'APPROVED','VERIFICATION STATUS':verified,'$staffID TIMESTAMP': utils.getCurrentTimeStamp()};
      print("Updating Fields: ${data.toString()}");
      print('Redirecting Reference: ${redirectingRef.path}');

      await firebaseService.uploadMapDetailsToDoc(value!.collection('LEAVEFORMS').doc(widget.leaveid),data,staffID!);

      data.clear();
      data.addAll({widget.leaveid:value});
      if(privilege !='HOSTEL WARDEN'){
        await firebaseService.uploadMapDetailsToDoc(redirectingRef, data,staffID!);
      }

      Navigator.pop(context);

      EasyLoading.dismiss();
    } catch (e) {
      utils.exceptions(e,'onAccept');
      utils.showToastMessage('Error is occured try after some time', context);
      EasyLoading.dismiss();
      // You might want to add proper error handling here, depending on your application's requirements
    }
  }

  Future<void> onReject() async {
    print('onReject: ');
    try {
      utils.showDefaultLoading();
      DocumentReference? value;
      CollectionReference collectionReference = await utils.DocumentToCollection(lecturerReference);
      String field = '';

      if(privilege=='FACULTY ADVISOR') {
        field='FACULTY ADVISOR APPROVAL';
      } else if(privilege=='YEAR COORDINATOR' || privilege=='HOD'){
        field='YEAR COORDINATOR APPROVAL';
      } else if(privilege=='FACULTY ADVISOR AND YEAR COORDINATOR'){
        if(widget.type=='SECTION'){
          field='FACULTY ADVISOR APPROVAL';
        } else if(widget.type=='YEAR COORDINATOR'){
          field='YEAR COORDINATOR APPROVAL';
        }
      } else if(privilege=='HOSTEL WARDEN'){
        field='HOSTEL WARDEN APPROVAL';
      } else {
        utils.showToastMessage('Error occurred while rejecting', context);
        return;
      }

      print('Incrementing leave count...');
      await realtimeDatabase.incrementLeaveCount(
          '/KLU/${utils.getTime()}/${studentLeaveDetails['YEAR']}/${studentLeaveDetails['BRANCH']}/${studentLeaveDetails['STREAM']}/${studentLeaveDetails['SECTION']}/REJECTED'
      );

      print('Decrementing leave count...');
      await realtimeDatabase.decrementLeaveCount(
          '/KLU/${utils.getTime()}/${studentLeaveDetails['YEAR']}/${studentLeaveDetails['BRANCH']}/${studentLeaveDetails['STREAM']}/${studentLeaveDetails['SECTION']}/PENDING'
      );

      Map<String, dynamic> data={};

      print('Getting document reference field value...');
      List<String> listData=[widget.leaveid];
      Map<String,dynamic>? values = await firebaseService.getValuesFromDocRef(collectionReference.doc('PENDING'), listData);
      value=values![widget.leaveid];

      data.clear();
      data.addAll({widget.leaveid:value});
      print('Storing document reference...');
      await firebaseService.uploadMapDetailsToDoc(collectionReference.doc('REJECTED'), data,staffID!);

      print('Deleting field...');
      await firebaseService.deleteField(
          collectionReference.doc('PENDING'), widget.leaveid
      );
      data.clear();
      data = {
        field: 'REJECTED',
        'VERIFICATION STATUS': 'REJECTED',
      };
      print('Uploading map details to doc...');
      await firebaseService.uploadMapDetailsToDoc(
          value!.collection('LEAVEFORMS').doc(widget.leaveid), data, staffID!
      );
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
        Map<String,dynamic>? values = await firebaseService.getValuesFromDocRef(lecturerReference, listData);
        studentDetailsRef=values![widget.leaveid];
      } else {
        utils.showToastMessage('Error occurred. Contact developer. Error code: 1', context);
        EasyLoading.dismiss();
      }

      print('studentDetailsRef: $studentDetailsRef');

      studentDetails = await firebaseService.getMapDetailsFromDoc(studentDetailsRef);
      leaveDetailsRef = studentDetailsRef.collection('LEAVEFORMS').doc(widget.leaveid);
      print('leaveDetailsRef: ${leaveDetailsRef.toString()}');
      leaveDetails = await firebaseService.getMapDetailsFromDoc(leaveDetailsRef);

      studentLeaveDetails.addAll(studentDetails);
      studentLeaveDetails.addAll(leaveDetails);

      EasyLoading.dismiss();
      return studentLeaveDetails;

    }catch(e){
      utils.showToastMessage('Error occured try after some time', context);
      utils.exceptions(e, 'getLeaveDetails');
      EasyLoading.dismiss();
      return {};
    }
  }

}
