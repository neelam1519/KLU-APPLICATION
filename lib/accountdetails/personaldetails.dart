import 'package:flutter/material.dart';
import 'package:klu_flutter/utils/shraredprefs.dart';

class PersonalDetails extends StatefulWidget {
  @override
  _PersonalDetailsState createState() => _PersonalDetailsState();
}

class _PersonalDetailsState extends State<PersonalDetails> {
  SharedPreferences sharedPreferences = SharedPreferences();
  String? privilege;

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  Future<void> initializeData() async {
    privilege = await sharedPreferences.getSecurePrefsValue('PRIVILEGE');
    setState(() {}); // Trigger a rebuild after getting privilege data
  }

  @override
  Widget build(BuildContext context) {
    Widget detailsWidget;
    if (privilege == 'STUDENT') {
      detailsWidget = StudentDetailsWidget();
    } else if (privilege == 'FACULTY ADVISOR') {
      detailsWidget = FacultyAdvisorDetailsWidget();
    } else if (privilege == 'FACULTY ADVISOR AND YEAR COORDINATOR') {
      detailsWidget = FacultyAdvisorAndCoordinatorDetailsWidget();
    } else if (privilege == 'HOD') {
      detailsWidget = HodDetailsWidget();
    } else if (privilege == 'YEAR COORDINATOR') {
      detailsWidget = YearCoordinatorDetailsWidget();
    } else {
      detailsWidget = Center(child: Text('Invalid privilege'));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Personal Details'),
      ),
      body: detailsWidget,
    );
  }
}

class StudentDetailsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Name: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Neelam Madhusudhan Reddy',
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Registration Number:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '99210041602',
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Email:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '99210041602@klu.ac.in',
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Branch:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'CSE',
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'YEAR:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '3',
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'SPECIALIZATION:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'CYBER SECURITY',
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Gender:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 10),
                  DropdownButton<String>(
                    value: 'Male',
                    onChanged: (String? newValue) {
                      // Handle dropdown value change
                    },
                    items: <String>['Male', 'Female','Other'].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 20), // Add some space between the details and the button
        Row(
          mainAxisAlignment: MainAxisAlignment.center, // Align the button to the center horizontally
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // Handle button press
                },
                style: ButtonStyle(
                  fixedSize: MaterialStateProperty.all(null), // Allow the button to adjust its width based on the content
                ),
                child: Text('Update'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class FacultyAdvisorDetailsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Faculty Advisor Details'));
  }
}

class FacultyAdvisorAndCoordinatorDetailsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Faculty Advisor and Year Coordinator Details'));
  }
}

class HodDetailsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('HOD Details'));
  }
}

class YearCoordinatorDetailsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Year Coordinator Details'));
  }
}
