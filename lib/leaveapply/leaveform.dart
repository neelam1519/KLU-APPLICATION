import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:klu_flutter/utils/RealtimeDatabase.dart';
import 'package:klu_flutter/utils/loadingdialog.dart';
import 'package:klu_flutter/utils/utils.dart';
import '../utils/Firebase.dart';
import '../utils/shraredprefs.dart';

class LeaveForm extends StatefulWidget {
  @override
  _LeaveFormState createState() => _LeaveFormState();
}

class _LeaveFormState extends State<LeaveForm> {

  DateTime? selectedStartDate;
  // Controllers for text fields
  TextEditingController startDateController = TextEditingController();
  TextEditingController endDateController = TextEditingController();
  TextEditingController reasonController = TextEditingController();
  TextEditingController studentMobileController = TextEditingController();
  TextEditingController parentMobileController = TextEditingController();

  Utils utils=Utils();
  FirebaseService firebaseService=FirebaseService();
  RealtimeDatabase realtimeDatabase=RealtimeDatabase();
  SharedPreferences secureStorage = SharedPreferences();

  // TwilioFlutter twilioFlutter=TwilioFlutter(
  //     accountSid : 'AC20193099ffdd58f19dddcd9889fe39dd', // replace *** with Account SID
  //     authToken : '9dad3924d614df3f2423c479481fe4dd',  // replace xxx with Auth Token
  //     twilioNumber : '+12403923852'  // replace .... with Twilio Number
  // );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Leave Form'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Start Date Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: startDateController,
                      decoration: InputDecoration(labelText: 'Start Date'),
                      readOnly: true,
                      onTap: () =>{selectDate(context, startDateController, true)}
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () =>{ selectDate(context, startDateController, true)
                    }
                    ),
                ],
              ),
              SizedBox(height: 16),
              // End Date Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: endDateController,
                      decoration: InputDecoration(labelText: 'End Date'),
                      readOnly: true,
                      onTap: () => selectDate(context, endDateController, false),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () => selectDate(context, endDateController, false),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(labelText: 'Reason for Leave'),
              ),
              SizedBox(height: 16),
              TextField(
                controller: studentMobileController,
                decoration: InputDecoration(labelText: 'Student Mobile Number'),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 16),
              TextField(
                controller: parentMobileController,
                decoration: InputDecoration(labelText: "Parent Mobile Number"),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {


                  onSubmitButtonPressed();

                },
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> onSubmitButtonPressed() async {
    utils.showDefaultLoading();

    FocusScope.of(context).unfocus();

    String? year=await secureStorage.getSecurePrefsValue("YEAR");
    String? branch=await secureStorage.getSecurePrefsValue("BRANCH");
    String? regNo=await secureStorage.getSecurePrefsValue("REGISTRATION NUMBER");
    String? faID=await secureStorage.getSecurePrefsValue("FACULTY ADVISOR STAFF ID");
    String? faName=await secureStorage.getSecurePrefsValue('FACULTY ADVISOR NAME');
    String? stream=await secureStorage.getSecurePrefsValue("STREAM");
    String? section=await secureStorage.getSecurePrefsValue("SECTION");
    String? staffID=await secureStorage.getSecurePrefsValue('STAFF ID');
    String? privilege=await secureStorage.getSecurePrefsValue('PRIVILEGE');

    try {
      await realtimeDatabase.incrementLeaveCount('KLU/LEAVE COUNT');

      int leaveID = await realtimeDatabase.getLeaveCount('KLU/LEAVE COUNT');
      String leaveCount = leaveID.toString();

      await realtimeDatabase.incrementLeaveCount(
          'KLU/${utils.getTime()}/$year/$branch/$stream/$section/PENDING');
      await realtimeDatabase.incrementLeaveCount(
          'KLU/${utils.getTime()}/$year/$branch/$stream/$section/APPLIED');

      String reason = reasonController.text;
      String studentMobileNumber = studentMobileController.text;
      String parentMobileNumber = parentMobileController.text;
      String startDate = startDateController.text;
      String returnDate = endDateController.text;

      if (reason.length <= 10) {
        utils.showToastMessage('REASON SHOULD BE ATLEAST 10 LETTERS', context);
        LoadingDialog.stopLoadingDialog(context);
        return;
      }
      if (utils.doesContainEmoji(reason)) {
        utils.showToastMessage(
            'REASON MUST NOT CONTAIN OTHER THAN LETTERS', context);
        LoadingDialog.stopLoadingDialog(context);
        return;
      }
      if (!utils.isValidMobileNumber(studentMobileNumber) ||
          !utils.isValidMobileNumber(parentMobileNumber)) {
        utils.showToastMessage('ENTER VALID NUMBER', context);
        LoadingDialog.stopLoadingDialog(context);
        return;
      }
      if (studentMobileNumber == parentMobileNumber) {
        utils.showToastMessage(
            'STUDENT AND PARENT MOBILE NUMBERS ARE SAME', context);
        LoadingDialog.stopLoadingDialog(context);
        return;
      }

      if (startDate.isEmpty || returnDate.isEmpty || reason.isEmpty ||
          studentMobileNumber.isEmpty || parentMobileNumber.isEmpty) {
        utils.showToastMessage('NO EMPTY DATA SHOULD BE THERE', context);
        LoadingDialog.stopLoadingDialog(context);
        return;
      }

      String number = '+91${parentMobileNumber.trim()}';
      print('toNumber: ${number}');

      // twilioFlutter.sendSMS(
      //     toNumber : number,
      //     messageBody : 'This is from MyUniv leave applied');

      Map<String, dynamic> data = {};

      data.addAll({
        'LEAVE ID': leaveCount,
        'REGISTRATION NUMBER': regNo,
        'PARENTS MOBILE NUMBER': parentMobileNumber,
        'STUDENT MOBILE NUMBER': studentMobileNumber,
        'REASON': reason,
        'START DATE': startDate,
        'RETURN DATE': returnDate,
        'FACULTY ADVISOR APPROVAL': 'PENDING',
        'YEAR COORDINATOR APPROVAL': 'PENDING',
        'HOSTEL WARDEN APPROVAL': 'PENDING',
        'VERIFICATION STATUS': 'PENDING',
        'HOSTEL NAME': 'BHARATHI MENS HOSTEL',
        'HOSTEL FLOOR NUMBER': '2',
        'HOSTEL ROOM NUMBER': '215'
      });

      DocumentReference studentRef = FirebaseFirestore.instance.doc(
          'KLU/STUDENTDETAILS/$year/$regNo');
      await firebaseService.uploadMapDetailsToDoc(
          studentRef.collection('LEAVEFORMS').doc(leaveCount), data, regNo!);

      print('studentRef: ${studentRef.path}');

      data.clear();
      data.addAll({leaveCount: studentRef});
      User? user = FirebaseAuth.instance.currentUser;
      String uid = user!.uid;

      print('User ID: $uid');
      print('REGISTRATION NUMBER: ${regNo}');

      DocumentReference classPendingRef = FirebaseFirestore.instance.doc(
          '/KLU/CLASSROOMDETAILS/$year/$branch/$stream/$section/LEAVEFORMS/PENDING');
      await firebaseService.uploadMapDetailsToDoc(classPendingRef, data, regNo);

      //Navigator.of(context).pop();
      Navigator.pop(context);
      EasyLoading.dismiss();

      utils.showToastMessage(
          "The Leave Form is Sent to ${faName!.toUpperCase()} For approval",
          context);
    }catch(e){
      print('onSubmitButton: $e');
    }

  }



  Future<void> selectDate(BuildContext context, TextEditingController controller, bool isStartDate) async {
    DateTime currentDate = DateTime.now();

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedStartDate ?? currentDate,
      firstDate: selectedStartDate ?? currentDate,
      lastDate: DateTime(2025),
    );

    if (pickedDate != null) {
      // Format the selected date as "dd-MM-yyyy"
      String formattedDate = DateFormat('dd-MM-yyyy').format(pickedDate);

      // Update the text field with the formatted date
      controller.text = formattedDate;

      if (isStartDate) {
        // If the selected date is the start date, clear the end date
        endDateController.text = '';
        selectedStartDate = pickedDate;
      }
      // Trigger a rebuild to update the displayed date
      setState(() {});
    }
  }

}
