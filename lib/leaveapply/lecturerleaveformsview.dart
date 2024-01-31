import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:klu_flutter/leaveapply/leavedetailsview.dart';
import 'package:klu_flutter/utils/Firebase.dart';
import 'package:klu_flutter/utils/utils.dart';

import '../utils/shraredprefs.dart';


class LecturerLeaveFormsView extends StatefulWidget {
  final String? privilege;

  LecturerLeaveFormsView({required this.privilege});

  @override
  _LecturerDataState createState() => _LecturerDataState();
}

class _LecturerDataState extends State<LecturerLeaveFormsView> {
  int selectedIndex = 0;
  late String leaveFormType = 'PENDING';
  late FirebaseService firebaseService=FirebaseService();
  late SharedPreferences sharedPreferences=SharedPreferences();
  late Utils utils=Utils();
  late List<String> yearList = [];
  late List<String> streamList = [];
  late DocumentReference? detailsRetrievingRef=FirebaseFirestore.instance.doc('KLU/ERROR DETAILS');
  late String? section, branch, year, stream, staffID;
  late String? yearCoordinatorStream='', yearCoordinatorBranch='', hodBranch='', faYear='', faStream='', faBranch='', faSection='',yearCoordinatorYear='',hostelName='',
      hostelFloor='',hostelType='';
  DocumentReference studentLeaveForms = FirebaseFirestore.instance.doc('KLU/ERROR DETAILS');

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
    print('testRef: ${detailsRetrievingRef.toString()}');
    print('initializeData');
    yearCoordinatorStream = await sharedPreferences.getSecurePrefsValue('YEAR COORDINATOR STREAM');
    yearCoordinatorBranch = await sharedPreferences.getSecurePrefsValue('BRANCH');
    yearCoordinatorYear = await sharedPreferences.getSecurePrefsValue('YEAR COORDINATOR YEAR');
    yearCoordinatorBranch = await sharedPreferences.getSecurePrefsValue('BRANCH');
    hodBranch = await sharedPreferences.getSecurePrefsValue('BRANCH');
    faYear = await sharedPreferences.getSecurePrefsValue('FACULTY ADVISOR YEAR');
    faStream = await sharedPreferences.getSecurePrefsValue('FACULTY ADVISOR STREAM');
    faBranch = await sharedPreferences.getSecurePrefsValue('BRANCH');
    faSection = await sharedPreferences.getSecurePrefsValue('FACULTY ADVISOR SECTION');
    hostelName = await sharedPreferences.getSecurePrefsValue('HOSTEL NAME');
    hostelFloor = await sharedPreferences.getSecurePrefsValue('HOSTEL FLOOR');
    hostelType = await sharedPreferences.getSecurePrefsValue('HOSTEL TYPE');

    print('test privilege: ${widget.privilege}');

    if (widget.privilege == 'HOD') {
      isButtonVisible = true;
      isSpinner1Visible = true;
      isSpinner2Visible = true;

      String? hodYear = await sharedPreferences.getSecurePrefsValue('HOD YEAR');
      yearList = hodYear!.split(',');
      String? hodStream = await sharedPreferences.getSecurePrefsValue('HOD STREAM');
      streamList = hodStream!.split(',');

      spinnerOptions1 = streamList;
      spinnerOptions2 = yearList;
      selectedSpinnerOption1 = streamList.isNotEmpty ? streamList[0] : '';
      selectedSpinnerOption2 = yearList.isNotEmpty ? yearList[0] : '';

    } else if(widget.privilege == 'FACULTY ADVISOR' || widget.privilege=='HOSTEL WARDEN'){

    } else if(widget.privilege == 'YEAR COORDINATOR') {
      isButtonVisible = true;
      isSpinner1Visible = true;
      isSpinner2Visible = true;

      yearList = yearCoordinatorYear!.split(',');
      String? yearCoordinatorStream = await sharedPreferences.getSecurePrefsValue('YEAR COORDINATOR STREAM');
      streamList = yearCoordinatorStream!.split(',');

      spinnerOptions1 = streamList;
      spinnerOptions2 = yearList;
      selectedSpinnerOption1 = streamList.isNotEmpty ? streamList[0] : '';
      selectedSpinnerOption2 = yearList.isNotEmpty ? yearList[0] : '';

    } else if (widget.privilege == 'FACULTY ADVISOR AND YEAR COORDINATOR') {
      isSpinner1Visible = true;
      isSpinner2Visible = true;

      section = await sharedPreferences.getSecurePrefsValue('FACULTY ADVISOR SECTION');

      spinnerOptions1 = ['SECTION', 'YEAR COORDINATOR'];
      selectedSpinnerOption1 = 'SECTION';

      spinnerOptions2 = [section ?? 'SECTION NOT FOUND'];
      selectedSpinnerOption2 = spinnerOptions2[0];

      print('initializeData ${section.toString()}  ${yearCoordinatorYear.toString()}');
    } else {
      utils.showToastMessage('UNABLE TO GET THE SPINNER DETAILS ${widget.privilege}', context);
    }
    setState(() {});
  }

  void updateRef() {
    try {
      print('updateRef');

      if (widget.privilege == 'HOD') {
        detailsRetrievingRef = FirebaseFirestore.instance.doc('/KLU/ADMINS/$selectedSpinnerOption2/$hodBranch/YEAR COORDINATOR/$selectedSpinnerOption1/LEAVE FORMS/$leaveFormType');
      } else if (widget.privilege == 'FACULTY ADVISOR') {
        print('entered faculty advisor');
        detailsRetrievingRef = FirebaseFirestore.instance.doc('/KLU/CLASS ROOM DETAILS/$faYear/$faBranch/$faStream/$faSection/LEAVE FORMS/$leaveFormType}');
        print('detailRetrievingRef test: ${detailsRetrievingRef!.path}');
      } else if(widget.privilege=='HOSTEL WARDEN'){
        detailsRetrievingRef = FirebaseFirestore.instance.doc('/KLU/HOSTELS/$hostelName/$hostelType/$hostelFloor/$leaveFormType');
      }else if (widget.privilege == 'YEAR COORDINATOR') {
        detailsRetrievingRef = FirebaseFirestore.instance.doc('/KLU/ADMINS/$selectedSpinnerOption2/$yearCoordinatorBranch/YEAR COORDINATOR/$selectedSpinnerOption1/LEAVE FORMS/$leaveFormType');
      } else if (widget.privilege == 'FACULTY ADVISOR AND YEAR COORDINATOR') {
        if (selectedSpinnerOption1 == 'SECTION') {
          detailsRetrievingRef = FirebaseFirestore.instance.doc('/KLU/CLASS ROOM DETAILS/${faYear ?? 'year'}/${faBranch ?? 'branch'}/${faStream ?? 'stream'}/${selectedSpinnerOption2 ?? 'option2'}/LEAVE FORMS/$leaveFormType');
        } else if (selectedSpinnerOption1 == 'YEAR COORDINATOR') {
          detailsRetrievingRef = FirebaseFirestore.instance.doc('/KLU/ADMINS/$selectedSpinnerOption2/${yearCoordinatorBranch ?? 'branch'}/YEAR COORDINATOR/${yearCoordinatorStream ?? 'stream'}/LEAVE FORMS/$leaveFormType');
        }
      } else {
        utils.showToastMessage('UNABLE TO GET THE REFERENCE DETAILS', context);
      }

      print('detailsRetrievingRef: ${detailsRetrievingRef!.path}');
    } catch (e) {
      // Handle the exception as per your application's requirements
      print('Error constructing detailsRetrievingRef: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    String appBarTitle = 'Leave Forms';

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
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
                    updateSpinner();
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
                  print('isSpinner2Visible');
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
                if(leaveFormType=='PENDING'){
                  showAlertDialog(context);
                }else{
                  utils.showToastMessage('option is disabled here', context);
                }
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


  Future<void> acceptAllForms() async {
    try {
      if (widget.privilege == 'YEAR COORDINATOR' || widget.privilege == 'HOD' || widget.privilege == 'FACULTY ADVISOR AND YEAR COORDINATOR') {
        utils.showDefaultLoading();
        // Assuming detailsRetrievingRef is a DocumentReference
        CollectionReference collectionReference = await utils.DocumentToCollection(detailsRetrievingRef!);

        // Get the pending forms
        Map<String, dynamic> formRef = await firebaseService.getMapDetailsFromDoc(collectionReference.doc('PENDING'));

        // Loop through each form
        for (MapEntry<String, dynamic> entry in formRef.entries) {
          String key = entry.key;
          DocumentReference value = entry.value;

          // Update YEAR COORDINATOR APPROVAL to true
          await firebaseService.updateBooleanField(value.collection('LEAVE FORMS').doc(key), 'YEAR COORDINATOR APPROVAL', true);

          // Move the form to ACCEPTED collection
          await firebaseService.storeDocumentReference(collectionReference.doc('ACCEPTED'), key, value);

          // Get required fields
          List<String> requiredFieldNames = [
            'HOSTEL NAME',
            'HOSTEL ROOM NUMBER',
            'HOSTEL TYPE'
          ];
          Map<String, dynamic>? userDetails = await firebaseService.getValuesFromDocRef(value, requiredFieldNames);

          // Extract required fields
          String hostelName = userDetails!['HOSTEL NAME'];
          String hostelType = userDetails['HOSTEL TYPE'];
          String hostelFloor = userDetails['HOSTEL ROOM NUMBER'];

          // Move the form to HOSTEL PENDING collection
          DocumentReference hostelRef = FirebaseFirestore.instance.doc('/KLU/HOSTELS/$hostelName/$hostelType/${hostelFloor.substring(0, 1)}/PENDING');
          await firebaseService.storeDocumentReference(hostelRef, key, value);

          // Delete the form from the original collection
          await firebaseService.deleteField(detailsRetrievingRef!, key);
        }
      } else {
        utils.showToastMessage('You are not authorized to accept all', context);
      }
    } catch (e) {
      utils.showToastMessage('Error occurred while accepting. Contact developer.', context);
    }
    EasyLoading.dismiss();
  }


  Future<void> showAlertDialog(BuildContext context) async{
    // Show the alert dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Alert'),
          content: Text('You want to accept all forms'),
          actions: [
            TextButton(
              onPressed: () async {
                // Handle the "OK" button press
                await acceptAllForms();
                Navigator.of(context).pop(); // Close the dialog
                // Add your logic for the "OK" action here
              },
              child: Text('OK'),
            ),
            TextButton(
              onPressed: () {
                // Handle the "Cancel" button press
                Navigator.of(context).pop(); // Close the dialog
                // Add your logic for the "Cancel" action here
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      print('onItemTapped');
      selectedIndex = index;
    });
  }

  Widget _buildBody() {
    leaveFormType = selectedIndex == 0 ? 'PENDING' : (selectedIndex == 1 ? 'ACCEPTED' : 'REJECTED');
    updateRef();
    return buildTab();
  }

  void updateSpinner(){
    if(widget.privilege=='FACULTY ADVISOR AND YEAR COORDINATOR'){
      if(selectedSpinnerOption1=='SECTION'){
        isButtonVisible=false;
        spinnerOptions2.clear();
        spinnerOptions2.add(section!);
        selectedSpinnerOption2 = section ?? 'SECTION NOT FOUND';
      }else if(selectedSpinnerOption1=='YEAR COORDINATOR'){
        isButtonVisible=true;
        spinnerOptions2.clear();
        yearList = yearCoordinatorYear!.split(',');
        yearList.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
        spinnerOptions2.addAll(yearList);
        selectedSpinnerOption2=spinnerOptions2[0];
      }
    }
  }

  Widget buildTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: detailsRetrievingRef!.snapshots(),
      builder: (context, snapshot) {
        print('buildTab snapshot: ${snapshot.toString()}');
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: Colors.grey[200],
              ),
              child: Text(
                'No $leaveFormType Forms Available',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.red, // Customize the color
                ),
              ),
            ),
          );
        } else {
          Map<String, dynamic> leaveCardData = snapshot.data!.data() as Map<String, dynamic>;

          return FutureBuilder<Map<String, dynamic>>(
            future: retrieveData(leaveCardData),
            builder: (context, dataSnapshot) {
              if (dataSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (dataSnapshot.hasError) {
                return Center(child: Text('Error: ${dataSnapshot.error}'));
              }  else if (!dataSnapshot.hasData || dataSnapshot.data!.isEmpty) {
                return Center(
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: Colors.grey[200],
                    ),
                    child: Text(
                      'No $leaveFormType Forms Available',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.red, // Customize the color
                      ),
                    ),
                  ),
                );
              } else {
                Map<String, dynamic> data = dataSnapshot.data!;
                print('buildTab: ${data.toString()}');

                return ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    String key = data.keys.elementAt(index);
                    print('ListView.builder  key=$key');
                    Map<String, dynamic> value = data[key];

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
                                type: selectedSpinnerOption1,
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
    List<String> dataRequired = [
      'START DATE',
      'RETURN DATE',
      'LEAVE ID',
      'FACULTY ADVISOR APPROVAL',
      'YEAR COORDINATOR APPROVAL',
      'HOSTEL WARDEN APPROVAL',
      'FACULTY ADVISOR DECLINED',
      'YEAR COORDINATOR DECLINED',
      'HOSTEL WARDEN DECLINED',
    ];
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
            verification = 'DECLINED';
          } else if (yearCoordinatorDeclined) {
            verification = 'DECLINED';
          } else {
            verification = 'DECLINED';
          }
        } else {
          verification = 'PENDING';
        }
        retrievedData.addAll({'VERIFIED': verification});
      }
      retrievedDataMap[key] = retrievedData;
    }
    for (MapEntry<String, dynamic> entry in retrievedDataMap.entries) {
      String key = entry.key;
      dynamic value = entry.value;
      print('retrievedDataMap: $key : $value');
    }
    // Return the map containing all retrieved data
    return retrievedDataMap;
  }
}
