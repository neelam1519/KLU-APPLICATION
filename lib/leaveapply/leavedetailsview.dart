import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:klu_flutter/leaveapply/studentformsview.dart';
import 'package:klu_flutter/utils/utils.dart';
import '../utils/Firebase.dart';
import '../utils/shraredprefs.dart';
import 'lecturerleaveformsview.dart';

class LeaveDetailsView extends StatefulWidget {
  final String leaveid;
  final String leaveformtype;
  final String lecturerRef;
  LeaveDetailsView({required this.leaveid, required this.leaveformtype, required this.lecturerRef});
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
  String? privilege;
  late DocumentReference lecturerReference;
  List<String> details=[];

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  Future<void> initializeData() async {
    privilege = await sharedPreferences.getSecurePrefsValue("PRIVILEGE");
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
    List<String> orderOfDetails = ['LEAVE ID', 'START DATE', 'RETURN DATE', 'REGISTRATION NUMBER', 'NAME', 'YEAR', 'BRANCH', 'STREAM', 'SECTION',
      'FACULTY ADVISOR STAFF ID', 'STUDENT MOBILE NUMBER', 'PARENTS MOBILE NUMBER', 'REASON', 'HOSTEL NAME', 'HOSTEL ROOM NUMBER', 'FACULTY ADVISOR MAIL',
      'FACULTY ADVISOR APPROVAL', 'YEAR COORDINATOR APPROVAL', 'HOSTEL WARDEN APPROVAL', 'VERIFICATION STATUS'];

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
                String detailValue = totalLeaveDetails[detailKey].toString() ?? '';
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
                          icon: Icon(Icons.check),
                          onPressed: () {
                            // Handle accept button press
                            onAccept();
                          },
                        ),
                        Text('Accept'), // Text for the accept button
                      ],
                    ),
                  if (shouldShowDelete())
                    Column(
                      children: [
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            // Handle delete button press
                              deleteDetails(context);
                          },
                        ),
                        Text('Delete'), // Text for the delete button
                      ],
                    ),
                  if (shouldShowRejectButton)
                    Column(
                      children: [
                        IconButton(
                          icon: Icon(Icons.close),
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
      CollectionReference leaveRef=FirebaseFirestore.instance.collection(documentToCollection(widget.lecturerRef));
      DocumentReference redirectingRef=FirebaseFirestore.instance.doc('KLU/CONFIRMED DETAILS');
      DocumentReference? value;
      String field='';
      String? faYear = await sharedPreferences.getSecurePrefsValue('FACULTY ADVISOR YEAR');
      String? faStream = await sharedPreferences.getSecurePrefsValue('FACULTY ADVISOR STREAM');
      String? faBranch = await sharedPreferences.getSecurePrefsValue('BRANCH');
      String? faSection = await sharedPreferences.getSecurePrefsValue('FACULTY ADVISOR SECTION');
      String? yearCoordinatorStream=await sharedPreferences.getSecurePrefsValue('YEAR COORDINATOR STREAM');
      String? yearCoordinatorBranch=await sharedPreferences.getSecurePrefsValue('BRANCH');

      if(privilege=='FACULTY ADVISOR') {

        redirectingRef = FirebaseFirestore.instance.doc('/KLU/ADMINS/$faYear/$faBranch/YEAR COORDINATOR/$faStream/LEAVE FORMS/PENDING');
        print('onAccept ${redirectingRef.toString()}');
        field='FACULTY ADVISOR APPROVAL';

      }else if(privilege=='YEAR COORDINATOR'){
        redirectingRef = FirebaseFirestore.instance.doc('/KLU/HOSTELS/$faYear/$faBranch/YEAR COORDINATOR/$faStream/LEAVE FORMS/PENDING');
        print('onAccept ${redirectingRef.toString()}');
        field='FACULTY ADVISOR APPROVAL';
      }

      value = await firebaseService.getDocumentReferenceFieldValue(leaveRef.doc('PENDING'), widget.leaveid);
      print('onAccept ${value.toString()}');
      await firebaseService.storeDocumentReference(leaveRef.doc('ACCEPTED'), widget.leaveid, value!);
      await firebaseService.deleteField(leaveRef.doc('PENDING'), widget.leaveid);
      await firebaseService.updateBooleanField(value.collection('LEAVE FORMS').doc(widget.leaveid),field, true);
      await firebaseService.storeDocumentReference(redirectingRef, widget.leaveid, value);

      Navigator.pop(context);
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (context) => LecturerLeaveFormsView(privilege: privilege,)));

      EasyLoading.dismiss();
    } catch (e) {
      // Handle errors
      utils.exceptions(e,'onAccept');
      utils.showToastMessage('Error is occured try after some time', context);
      EasyLoading.dismiss();
      // You might want to add proper error handling here, depending on your application's requirements
    }
  }

  String documentToCollection(String document){
    List<String> pathSegments = document.split('/');
    pathSegments.removeLast();
    String newPath = pathSegments.join('/');
    return newPath;
  }

  Future<void> onReject() async{
    print('onReject: ');
    try {
      utils.showDefaultLoading();
      String? staffid = await sharedPreferences.getSecurePrefsValue("STAFF ID");
      String? privilege=await sharedPreferences.getSecurePrefsValue('PRIVILEGE');

      CollectionReference leaveRef=FirebaseFirestore.instance.collection('KLU');
      DocumentReference? value;
      String field='';

      if(privilege=='FACULTY ADVISOR'){
        String? faYear = await sharedPreferences.getSecurePrefsValue('FACULTY ADVISOR YEAR');
        String? faStream = await sharedPreferences.getSecurePrefsValue('FACULTY ADVISOR STREAM');
        String? faBranch = await sharedPreferences.getSecurePrefsValue('BRANCH');
        String? faSection = await sharedPreferences.getSecurePrefsValue('FACULTY ADVISOR SECTION');

        leaveRef = FirebaseFirestore.instance.collection('KLU/CLASS ROOM DETAILS/$faYear/$faBranch/$faStream/$faSection/LEAVE FORMS/');
        field='FACULTY ADVISOR DECLINED';
      }else{
        utils.showToastMessage('AN ERROR OCCURED', context);
      }

      value = await firebaseService.getDocumentReferenceFieldValue(leaveRef.doc('PENDING'), widget.leaveid);
      await firebaseService.storeDocumentReference(leaveRef.doc('REJECTED'), widget.leaveid, value!);
      await firebaseService.deleteField(leaveRef.doc('PENDING'), widget.leaveid);
      await firebaseService.updateBooleanField(value.collection('LEAVE FORMS').doc(widget.leaveid), field, true);

      Navigator.pop(context);
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (context) => LecturerLeaveFormsView(privilege: privilege,)));
      EasyLoading.dismiss();

    } catch (e) {
      // Handle errors
      EasyLoading.dismiss();
      utils.showToastMessage('Error is occured try after some time', context);
      utils.exceptions(e,'onReject');
      // You might want to add proper error handling here, depending on your application's requirements
    }
  }

  bool shouldShowDelete() {
    bool facultyAdvisorApproval = totalLeaveDetails['FACULTY ADVISOR APPROVAL'] == 'true';
    bool yearCoordinatorApproval = totalLeaveDetails['YEAR COORDINATOR APPROVAL'] == 'true';
    bool hostelWardenApproval = totalLeaveDetails['HOSTEL WARDEN APPROVAL'] == 'true';
    bool facultyAdvisorDecline = totalLeaveDetails['FACULTY ADVISOR DECLINE'] == 'true';
    bool yearCoordinatorDecline = totalLeaveDetails['YEAR COORDINATOR DECLINE'] == 'true';
    bool hostelWardenDecline = totalLeaveDetails['HOSTEL WARDEN DECLINE'] == 'true';

    return !(facultyAdvisorApproval || yearCoordinatorApproval || hostelWardenApproval) &&
        !(facultyAdvisorDecline || yearCoordinatorDecline || hostelWardenDecline) &&
        privilege == 'STUDENT';
  }

  Future<Map<String,dynamic>> getLeaveDetails() async {
    try {
      utils.showDefaultLoading();
      DocumentReference studentDetailsRef = FirebaseFirestore.instance.collection('KLU').doc('ERROR DETAILS');
      DocumentReference leaveDetailsRef = FirebaseFirestore.instance.collection('KLU').doc('ERROR DETAILS');

      String? year = await sharedPreferences.getSecurePrefsValue('YEAR');
      String? branch = await sharedPreferences.getSecurePrefsValue('BRANCH');
      String? stream = await sharedPreferences.getSecurePrefsValue('STREAM');
      String? regNo = await sharedPreferences.getSecurePrefsValue('REGISTRATION NUMBER');

      Map<String, dynamic> studentDetails = {};
      Map<String, dynamic> leaveDetails = {};
      Map<String, dynamic> studentLeaveDetails = {};

      print('PRIVILAGE :$privilege');
      print('lecturerRef: $lecturerReference');

      if (privilege == 'STUDENT') {
        studentDetailsRef = FirebaseFirestore.instance.doc('KLU/STUDENT DETAILS/$year/$branch/$stream/$regNo');
        print('studentDetailsRef: ${studentDetailsRef.path}');
      } else
      if (privilege == 'FACULTY ADVISOR' || privilege == 'YEAR COORDINATOR' || privilege == 'FACULTY ADVISOR AND YEAR COORDINATOR' || privilege == 'HOSTEL WARDEN' || privilege=='HOD') {
        studentDetailsRef = (await firebaseService.getDocumentReferenceFieldValue(lecturerReference, widget.leaveid))!;
      } else {
        utils.showToastMessage('Error occurred. Contact developer. Error code: 1', context);
        EasyLoading.dismiss();
      }

      print('studentDetailsRef: $studentDetailsRef');

      studentDetails = await firebaseService.getMapDetailsFromDoc(studentDetailsRef);
      leaveDetailsRef = studentDetailsRef.collection('LEAVE FORMS').doc(widget.leaveid);
      print('leaveDetailsRef: ${leaveDetailsRef.toString()}');
      leaveDetails = await firebaseService.getMapDetailsFromDoc(leaveDetailsRef);

      studentLeaveDetails.addAll(studentDetails);
      studentLeaveDetails.addAll(leaveDetails);

      for (MapEntry<String, dynamic> str in studentLeaveDetails.entries) {
        String key = str.key;
        dynamic value = str.value;
        print('$key : $value');
      }

      bool faApproval = studentLeaveDetails['FACULTY ADVISOR APPROVAL'] ??
          false;
      bool faDecline = studentLeaveDetails['FACULTY ADVISOR DECLINE'] ?? false;
      bool yearCoordinatorApproval = studentLeaveDetails['YEAR COORDINATOR APPROVAL'] ??
          false;
      bool yearCoordinatorDecline = studentLeaveDetails['YEAR COORDINATOR DECLINE'] ??
          false;
      bool hostelWardenDecline = studentLeaveDetails['HOSTEL WARDEN DECLINE'] ??
          false;
      bool hostelWardenApproval = studentLeaveDetails['HOSTEL WARDEN APPROVAL'] ??
          false;

      bool verified = faApproval && yearCoordinatorApproval &&
          hostelWardenApproval;
      bool declined = faDecline || yearCoordinatorDecline ||
          hostelWardenDecline;

      String verification;
      if (verified) {
        verification = "APPROVED";
      } else if (declined) {
        if (faDecline) {
          verification = 'FACULTY ADVISOR DECLINED';
        } else if (yearCoordinatorDecline) {
          verification = 'YEAR COORDINATOR DECLINED';
        } else if (hostelWardenDecline) {
          verification = 'HOSTEL WARDEN DECLINED';
        } else {
          verification = 'UNKNOWN ERROR';
        }
      } else {
        verification = 'PENDING';
      }

      // Adding the custom verification status
      studentLeaveDetails['VERIFICATION STATUS'] = verification;
      List<String> keys = studentLeaveDetails.keys.toList();

      EasyLoading.dismiss();
      print('TotalLeaveData: $keys');
      return studentLeaveDetails;

    }catch(e){
      utils.showToastMessage('Error occured try after some time', context);
      utils.exceptions(e, 'getLeaveDetails');
      EasyLoading.dismiss();
      return {};
    }
  }

  Future<void> deleteDetails(BuildContext context) async {
    try {
      utils.showDefaultLoading();
      String? year=await sharedPreferences.getSecurePrefsValue('YEAR');
      String? stream=await sharedPreferences.getSecurePrefsValue('STREAM');
      String? regNo=await sharedPreferences.getSecurePrefsValue('REGISTRATION NUMBER');
      String? branch=await sharedPreferences.getSecurePrefsValue('BRANCH');
      String? section=await sharedPreferences.getSecurePrefsValue('SECTION');

      DocumentReference documentRefForStudent=FirebaseFirestore.instance.doc("KLU/STUDENT DETAILS/$year/$branch/$stream/$regNo/LEAVE FORMS/${widget.leaveid}");
      DocumentReference documentRefForTeacher=FirebaseFirestore.instance.doc("KLU/CLASS ROOM DETAILS/$year/$branch/$stream/$section/LEAVE FORMS/PENDING");

      await firebaseService.deleteDocument(documentRefForStudent);
      await firebaseService.deleteField(documentRefForTeacher, widget.leaveid);

      EasyLoading.dismiss();
      // Pop the current route and any previous StudentsLeaveApply routes
      Navigator.pop(context);
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (context) => StudentsLeaveFormsView()));
      utils.showToastMessage("Sucessfully deleted", context);
      // Safely access currentContext using null-aware operator
    } catch (error) {
      EasyLoading.dismiss();
      print('Error deleting field ${widget.leaveid}: $error');
      utils.showToastMessage("Problem in deleting", context);
    }
  }

}
