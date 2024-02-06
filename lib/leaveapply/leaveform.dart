import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:klu_flutter/leaveapply/studentformsview.dart';
import 'package:klu_flutter/model/model.dart';
import 'package:klu_flutter/utils/RealtimeDatabase.dart';
import 'package:klu_flutter/utils/utils.dart';
import 'package:twilio_flutter/twilio_flutter.dart';
import '../utils/Firebase.dart';
import '../utils/shraredprefs.dart';

class LeaveForm extends StatefulWidget {
  @override
  _LeaveFormState createState() => _LeaveFormState();
}

class _LeaveFormState extends State<LeaveForm> {

  String COLLECTION_NAME="KLU";
  DateTime? selectedStartDate;
  // Controllers for text fields
  TextEditingController startDateController = TextEditingController();
  TextEditingController endDateController = TextEditingController();
  TextEditingController reasonController = TextEditingController();
  TextEditingController studentMobileController = TextEditingController();
  TextEditingController parentMobileController = TextEditingController();
  Utils utils=Utils();
  TwilioFlutter twilioFlutter=TwilioFlutter(
      accountSid : 'AC20193099ffdd58f19dddcd9889fe39dd', // replace *** with Account SID
      authToken : '9dad3924d614df3f2423c479481fe4dd',  // replace xxx with Auth Token
      twilioNumber : '+12403923852'  // replace .... with Twilio Number
  );

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
                  onSubmitBUttonPressed();
                },
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> onSubmitBUttonPressed() async {
    utils.showDefaultLoading();
    FocusScope.of(context).unfocus();
    FirebaseService firebaseService = FirebaseService();
    RealtimeDatabase realtimedatabase=RealtimeDatabase();
    SharedPreferences secureStorage = SharedPreferences();

    await realtimedatabase.incrementLeaveCount('KLU/LEAVE COUNT');

    String? year=await secureStorage.getSecurePrefsValue("YEAR");
    String? branch=await secureStorage.getSecurePrefsValue("BRANCH");
    String? regNo=await secureStorage.getSecurePrefsValue("REGISTRATION NUMBER");
    String? faID=await secureStorage.getSecurePrefsValue("FACULTY ADVISOR STAFF ID");
    String? faName=await secureStorage.getSecurePrefsValue('FACULTY ADVISOR NAME');
    String? stream=await secureStorage.getSecurePrefsValue("STREAM");
    String? section=await secureStorage.getSecurePrefsValue("SECTION");

    int leaveid= await realtimedatabase.getLeaveCount('KLU/LEAVE COUNT');
    String leavecount=leaveid.toString();

    print('leave count: ${leavecount.toString()}');

    await realtimedatabase.incrementLeaveCount('KLU/${utils.getTime()}/$year/$branch/$stream/$section/PENDING');
    await realtimedatabase.incrementLeaveCount('KLU/${utils.getTime()}/$year/$branch/$stream/$section/APPLIED');

    String reason = reasonController.text;
    if(reason.length<=20){
      utils.showToastMessage('REASON SHOULD BE ATLEAST 20 LETTERS', context);
      EasyLoading.dismiss();
      return;
    }
    if(utils.doesContainEmoji(reason)){
      utils.showToastMessage('REASON MUST NOT CONTAIN EMOJIS', context);
      EasyLoading.dismiss();
      return;
    }
    String studentMobileNumber = studentMobileController.text;
    String parentMobileNumber = parentMobileController.text;
    if(!utils.isValidMobileNumber(studentMobileNumber) || !utils.isValidMobileNumber(parentMobileNumber)){
      utils.showToastMessage('ENTER VALID NUMBER', context);
      EasyLoading.dismiss();
      return;
    }
    if(studentMobileNumber==parentMobileNumber) {
      utils.showToastMessage('STUDENT AND PARENT MOBILE NUMBERS ARE SAME', context);
      EasyLoading.dismiss();
      return;
    }
    String startdate=startDateController.text;
    String enddate=endDateController.text;

    if(startdate.isEmpty || enddate.isEmpty || reason.isEmpty || studentMobileNumber.isEmpty || parentMobileNumber.isEmpty){
      utils.showToastMessage('NO EMPTY DATA SHOULD BE THERE', context);
      EasyLoading.dismiss();
      return;
    }

    // String number='+91${parentMobileNumber.trim()}';
    // print('toNumber: ${number}');
    //
    // twilioFlutter.sendSMS(
    //     toNumber : number,
    //     messageBody : 'This is from MyUniv leave applied');

    Map<String,dynamic> data={};

    data.addAll({'LEAVE ID': leavecount,'REGISTRATION NUMBER': regNo,'PARENTS MOBILE NUMBER': parentMobileNumber,'STUDENT MOBILE NUMBER': studentMobileNumber,
      'REASON': reason,'START DATE': startdate,'RETURN DATE':enddate,'FACULTY ADVISOR APPROVAL': false,'YEAR COORDINATOR APPROVAL':false,
        'HOSTEL WARDEN APPROVAL' :false,'FACULTY ADVISOR DECLINED' :false, 'YEAR COORDINATOR DECLINED' : false,'HOSTEL WARDEN DECLINED' : false,'VERIFICATION':'PENDING'});

    CollectionReference studentPendingRef=FirebaseFirestore.instance.collection('/$COLLECTION_NAME/STUDENT DETAILS/$year/$branch/$stream/$regNo/LEAVE FORMS');

    print('Student Pending Reference: ${studentPendingRef.toString()}');
    await firebaseService.uploadDataToCollection(studentPendingRef, leavecount, data);

    DocumentReference studentRef=FirebaseFirestore.instance.doc("$COLLECTION_NAME/STUDENT DETAILS/$year/$branch/$stream/$regNo");
    DocumentReference faPendingRef=FirebaseFirestore.instance.doc('/KLU/CLASS ROOM DETAILS/$year/$branch/$stream/$section/LEAVE FORMS/PENDING');

    print('Student Reference: ${studentRef.toString()}');
    print('Faculty Advisor Reference: ${faPendingRef.toString()}');

    await firebaseService.storeDocumentReference(faPendingRef,leavecount,studentRef);
    // Pop the current route and any previous StudentsLeaveApply routes
    Navigator.pop(context);

    utils.showToastMessage("The Leave Form is Sent to Faculty Advisor ${faName!.toUpperCase()} For approval", context);

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
