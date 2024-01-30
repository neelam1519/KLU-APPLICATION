import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:klu_flutter/leaveapply/leavedetailsview.dart';
import 'package:klu_flutter/utils/Firebase.dart';
import 'package:klu_flutter/utils/utils.dart';

import '../model/model.dart';
import '../utils/shraredprefs.dart';

class LecturerLeaveFormsView extends StatefulWidget {
  late String? privilege;
  LecturerLeaveFormsView({required this.privilege});
  @override
  _LecturerDataState createState() => _LecturerDataState();

}

class _LecturerDataState extends State<LecturerLeaveFormsView> {
  int selectedIndex = 0;
  late String leaveFormType='PENDING';
  late LeaveCardViewData leaveCardViewData;
  FirebaseService firebaseService = FirebaseService();
  SharedPreferences sharedPreferences = SharedPreferences();
  Utils utils=Utils();
  late List<String> yearList=[];
  late List<String> streamList=[];
  late DocumentReference? detailsRetrievingRef=FirebaseFirestore.instance.doc('KLU/ERROR DETAILS');
  late String? section='',branch,year,stream,staffID;
  late String? yearCoordinatorStream='',yearCoordinatorBranch='',hodBranch='',faYear='',faStream='',faBranch='',faSection='';
  DocumentReference studentLeaveForms=FirebaseFirestore.instance.doc('KLU/ERROR DETAILS');

  List<String> spinnerOptions1 = [];
  List<String> spinnerOptions2 = [];
  String selectedSpinnerOption1 = '';
  String selectedSpinnerOption2 = '';

  // Boolean flags to control visibility for each spinner and button
  bool isSpinner1Visible = false;
  bool isSpinner2Visible = false;
  bool isButtonVisible = false;

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  Future<void> initializeData() async {
    yearCoordinatorStream=await sharedPreferences.getSecurePrefsValue('YEAR COORDINATOR STREAM');
    yearCoordinatorBranch=await sharedPreferences.getSecurePrefsValue('BRANCH');
    hodBranch=await sharedPreferences.getSecurePrefsValue('BRANCH');
    faYear=await sharedPreferences.getSecurePrefsValue('FACULTY ADVISOR YEAR');
    faStream=await sharedPreferences.getSecurePrefsValue('FACULTY ADVISOR STREAM');
    faBranch=await sharedPreferences.getSecurePrefsValue('BRANCH');
    faSection=await sharedPreferences.getSecurePrefsValue('FACULTY ADVISOR SECTION');

    updateRef();

    if (widget.privilege == 'HOD') {
      isButtonVisible = true;
      isSpinner1Visible = true;
      isSpinner2Visible = true;

      String? year = await sharedPreferences.getSecurePrefsValue('HOD YEAR');
      yearList = year!.split(',');
      String? stream = await sharedPreferences.getSecurePrefsValue('HOD STREAM');
      streamList = stream!.split(',');

      spinnerOptions1=streamList;
      spinnerOptions2=yearList;
      selectedSpinnerOption1=streamList[0];
      selectedSpinnerOption2=yearList[0];

      print('initializeData $yearList  $streamList');

      detailsRetrievingRef = FirebaseFirestore.instance.doc('/KLU/ADMINS/$selectedSpinnerOption2/$hodBranch/YEAR COORDINATOR/$selectedSpinnerOption1/LEAVE FORMS/$leaveFormType');

    }else if(widget.privilege == 'FACULTY ADVISOR'){

      detailsRetrievingRef = FirebaseFirestore.instance.doc('/KLU/CLASS ROOM DETAILS/$faYear/$faBranch/$faStream/$faSection/LEAVE FORMS/$leaveFormType');

    }else if (widget.privilege == 'YEAR COORDINATOR') {
      isButtonVisible = true;
      isSpinner1Visible = true;
      isSpinner2Visible=true;

      String? year = await sharedPreferences.getSecurePrefsValue('YEAR COORDINATOR YEAR');
      yearList = year!.split(',');
      String? stream = await sharedPreferences.getSecurePrefsValue('YEAR COORDINATOR STREAM');
      streamList = stream!.split(',');

      spinnerOptions1=streamList;
      spinnerOptions2=yearList;
      selectedSpinnerOption1=streamList[0];
      selectedSpinnerOption2=yearList[0];

      print('initializeData $yearList  $selectedSpinnerOption1');

      detailsRetrievingRef = FirebaseFirestore.instance.doc('/KLU/ADMINS/$selectedSpinnerOption2/$yearCoordinatorBranch/YEAR COORDINATOR/$selectedSpinnerOption1/LEAVE FORMS/$leaveFormType');

    } else if (widget.privilege == 'FACULTY ADVISOR AND YEAR COORDINATOR') {
      isButtonVisible = true;
      isSpinner1Visible = true;
      isSpinner2Visible = true;

      section = await sharedPreferences.getSecurePrefsValue('FACULTY ADVISOR SECTION');

      spinnerOptions1 = ['SECTION', 'YEAR COORDINATOR'];
      selectedSpinnerOption1='SECTION';
      spinnerOptions2.add(section!);
      selectedSpinnerOption2 = section ?? 'SECTION NOT FOUND';
      String? year = await sharedPreferences.getSecurePrefsValue('YEAR COORDINATOR YEAR');
      yearList = year!.split(',');

      print('initializeData: $section $selectedSpinnerOption1 $spinnerOptions1 $spinnerOptions2');

      if(selectedSpinnerOption1=='SECTION'){
        detailsRetrievingRef = FirebaseFirestore.instance.doc('/KLU/CLASS ROOM DETAILS/$faYear/$faBranch/$faStream/$selectedSpinnerOption2/LEAVE FORMS/$leaveFormType');
      }else if(selectedSpinnerOption1=='YEAR COORDINATOR'){
        detailsRetrievingRef = FirebaseFirestore.instance.doc('/KLU/ADMINS/$selectedSpinnerOption2/$yearCoordinatorBranch/YEAR COORDINATOR/$yearCoordinatorStream/LEAVE FORMS/$leaveFormType');
      }else{
        utils.showToastMessage('UNABLE TO GET THE REFERENCE DETAILS', context);
      }

    } else {
      utils.showToastMessage('UNABLE TO GET THE SPINNER DETAILS', context);
    }
    setState(() {});
  }

  void updateRef(){
    if(widget.privilege=='HOD'){

      detailsRetrievingRef = FirebaseFirestore.instance.doc('/KLU/ADMINS/$selectedSpinnerOption2/$hodBranch/YEAR COORDINATOR/$selectedSpinnerOption1/LEAVE FORMS/$leaveFormType');

    }else if(widget.privilege=='FACULTY ADVISOR'){

      detailsRetrievingRef = FirebaseFirestore.instance.doc('/KLU/CLASS ROOM DETAILS/$faYear/$faBranch/$faStream/$faSection/LEAVE FORMS/$leaveFormType');

    }else if(widget.privilege=='YEAR COORDINATOR'){

      detailsRetrievingRef = FirebaseFirestore.instance.doc('/KLU/ADMINS/$selectedSpinnerOption2/$yearCoordinatorBranch/YEAR COORDINATOR/$selectedSpinnerOption1/LEAVE FORMS/$leaveFormType');

    }else if(widget.privilege=='FACULTY ADVISOR AND YEAR COORDINATOR'){

      if(selectedSpinnerOption1=='SECTION'){
        detailsRetrievingRef = FirebaseFirestore.instance.doc('/KLU/CLASS ROOM DETAILS/$faYear/$faBranch/$faStream/$selectedSpinnerOption2/LEAVE FORMS/$leaveFormType');
      }else if(selectedSpinnerOption1=='YEAR COORDINATOR'){
        detailsRetrievingRef = FirebaseFirestore.instance.doc('/KLU/ADMINS/$selectedSpinnerOption2/$yearCoordinatorBranch/YEAR COORDINATOR/$yearCoordinatorStream/LEAVE FORMS/$leaveFormType');
      }else{
        utils.showToastMessage('UNABLE TO GET THE FA AND YEAR DETAILS', context);
      }
    }else{
      utils.showToastMessage('UNABLE TO GET THE REFERENCE DETAILS', context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          // First Spinner
          Visibility(
            visible: isSpinner1Visible,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButton<String>(
                value: selectedSpinnerOption1,
                onChanged: (String? newValue) {
                  updateRef();
                  setState(() {
                    selectedSpinnerOption1 = newValue!;
                    //updateSpinner();
                    // Handle changes for the first spinner
                  });
                },
                items: spinnerOptions1.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),

          // Second Spinner
          Visibility(
            visible: isSpinner2Visible,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButton<String>(
                value: selectedSpinnerOption2,
                onChanged: (String? newValue) {
                  updateRef();
                  setState(() {
                    selectedSpinnerOption2 = newValue!;
                  });
                },
                items: spinnerOptions2.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),

          // Check Button
          Visibility(
            visible: isButtonVisible,
            child: IconButton(
              icon: Icon(Icons.check),
              onPressed: () {
                // Handle the check button press
                // You can access the selected values from the spinners here
              },
            ),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.pending),
            label: 'PENDING',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check),
            label: 'ACCEPTED',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.clear),
            label: 'REJECTED',
          ),
        ],
        currentIndex: selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  Widget _buildBody() {
    switch (selectedIndex) {
      case 0:
        leaveFormType=='PENDING';
        updateRef();
        return buildTab();
      case 1:
        leaveFormType=='ACCEPTED';
        updateRef();
        return buildTab();
      case 2:
        leaveFormType=='REJECTED';
        updateRef();
        return buildTab();
      default:
        return Container();
    }
  }

  Widget buildTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: detailsRetrievingRef!.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(child: Text('No Leave Data Available'));
        } else {
          Map<String, dynamic> leaveCardData = snapshot.data!.data() as Map<String, dynamic>;

          return FutureBuilder<Map<String, dynamic>>(
            future: retrieveData(leaveCardData),
            builder: (context, dataSnapshot) {
              if (dataSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (dataSnapshot.hasError) {
                return Center(child: Text('Error: ${dataSnapshot.error}'));
              } else {
                Map<String, dynamic> data = dataSnapshot.data!;
                print('buildTab: ${data.toString()}');

                return ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    String key = data.keys.elementAt(index);
                    print('ListView.builder  key=$key');
                    Map<String, dynamic> value = data[key];
                    for(MapEntry<String, dynamic> entry in value.entries){
                      print('ListView.builder  ${entry.key}  ${entry.value}');
                    }
                    return Card(
                      child: ListTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Start: ${value['START DATE']}'),
                                Text(" TO "),
                                Text('Return: ${value['RETURN DATE']}'),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('ID: ${value['LEAVE ID']}'),
                                Text('Status: ${value['VERIFIED']}'),
                              ],
                            ),
                          ],
                        ),
                        onTap: () async {
                          // Navigate to leave data screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LeaveDetailsView(
                                leaveid: value['LEAVE ID'],
                                leaveformtype: leaveFormType,
                                lecturerRef: detailsRetrievingRef!.path,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              }
            },
          );
        }
      },
    );
  }

  Future<Map<String, dynamic>> retrieveData(Map<String, dynamic> leaveCardData) async {
    List<String> dataRequired = ['START DATE', 'RETURN DATE', 'LEAVE ID', 'FACULTY ADVISOR APPROVAL', 'YEAR COORDINATOR APPROVAL', 'HOSTEL WARDEN APPROVAL',
      'FACULTY ADVISOR DECLINED', 'YEAR COORDINATOR DECLINED', 'HOSTEL WARDEN DECLINED',];
    // Map to store retrieved data
    Map<String, dynamic> retrievedDataMap = {};

    for (MapEntry<String, dynamic> entry in leaveCardData.entries) {
      String key = entry.key;
      DocumentReference value = entry.value;
      studentLeaveForms = value.collection('LEAVE FORMS').doc(key);

      // Retrieve data for the current entry
      Map<String, dynamic>? retrievedData = await firebaseService.getValuesFromDocRef(studentLeaveForms, dataRequired);
      if (retrievedData != null) {
        // Get the value for a specific key, for example, 'FACULTY ADVISOR APPROVAL'
        dynamic facultyAdvisorApproval = retrievedData['FACULTY ADVISOR APPROVAL'];
        dynamic facultyAdvisorDeclined = retrievedData['FACULTY ADVISOR DECLINED'];
        dynamic yearCoordinatorApproval = retrievedData['YEAR COORDINATOR APPROVAL'];
        dynamic yearCoordinatorDeclined = retrievedData['YEAR COORDINATOR DECLINED'];
        dynamic hostelWardenApproval = retrievedData['HOSTEL WARDEN APPROVAL'];
        dynamic hostelWardenDeclined = retrievedData['HOSTEL WARDEN DECLINED'];

        bool verified = facultyAdvisorApproval && yearCoordinatorApproval && hostelWardenApproval;
        bool declined = facultyAdvisorDeclined || yearCoordinatorDeclined || hostelWardenDeclined;

        String verification;
        if (verified) {
          verification = "APPROVED";
        } else if (declined) {
          if (facultyAdvisorDeclined) {
            verification = 'FACULTY ADVISOR DECLINED';
          } else if (yearCoordinatorDeclined) {
            verification = 'YEAR COORDINATOR DECLINED';
          } else {
            verification = 'HOSTEL WARDEN DECLINED';
          }
        } else {
          verification = 'PENDING';
        }
        retrievedData.addAll({'VERIFIED': verification});
      }
      retrievedDataMap[key] = retrievedData;
    }
    for(MapEntry<String, dynamic> entry in retrievedDataMap.entries){
      String key = entry.key;
      dynamic value = entry.value;
      print('retrievedDataMap: $key : $value');
    }
    // Return the map containing all retrieved data
    return retrievedDataMap;
  }

}
