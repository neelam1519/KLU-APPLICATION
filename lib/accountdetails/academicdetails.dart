import 'package:flutter/material.dart';
import 'package:klu_flutter/utils/shraredprefs.dart';
import 'package:klu_flutter/utils/utils.dart';

class AcademicDetails extends StatefulWidget {
  @override
  _AcademicDetailsState createState() => _AcademicDetailsState();
}

class _AcademicDetailsState extends State<AcademicDetails> {
  final SharedPreferences sharedPreferences = SharedPreferences();
  Utils utils=Utils();
  String? privilege;
  List<String> data = [];

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  Future<void> initializeData() async {
    data = [];
    privilege = await sharedPreferences.getSecurePrefsValue('PRIVILEGE');

    if (privilege == 'STUDENT') {
      data = ['NAME', 'REGISTRATION NUMBER','EMAIL ID', 'YEAR', 'BRANCH', 'STREAM'];
    } else if (privilege == 'FACULTY ADVISOR') {
      data = ['FACULTY ADVISOR YEAR', 'FACULTY ADVISOR STREAM','SECTION','SLOT'];
    }else if(privilege == 'YEAR COORDINATOR' || privilege == 'HOD' ){
      data = ['YEAR COORDINATOR YEAR', 'YEAR COORDINATOR STREAM'];
    }else if(privilege == 'FACULTY ADVISOR AND YEAR COORDINATOR'){
      data=['FACULTY ADVISOR YEAR', 'FACULTY ADVISOR STREAM','SECTION','SLOT','YEAR COORDINATOR YEAR', 'YEAR COORDINATOR STREAM'];
    }else{
      utils.showToastMessage('Unabe to get Details', context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Academic Details'),
      ),
      body: Center(
        child: FutureBuilder(
          future: initializeData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else {
              return ListView.builder(
                itemCount: data.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      '${data[index]} : ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: FutureBuilder<String?>(
                      future: getPersonalDetail(data[index]),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        } else if (snapshot.hasData) {
                          return Text(
                            snapshot.data!,
                            style: TextStyle(fontSize: 16),
                          );
                        } else {
                          return Text(
                            'N/A',
                            style: TextStyle(fontSize: 16),
                          );
                        }
                      },
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }

  Future<String?> getPersonalDetail(String key) async {
    String? detail = await sharedPreferences.getSecurePrefsValue(key);
    return detail;
  }
}
