import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:klu_flutter/utils/Firebase.dart';
import 'package:klu_flutter/utils/shraredprefs.dart';
import 'package:klu_flutter/utils/utils.dart';

class Review extends StatefulWidget {
  @override
  _ReviewState createState() => _ReviewState();
}

class _ReviewState extends State<Review> {
  TextEditingController _textEditingController = TextEditingController(); // Create a controller for the TextField

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Review'),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 16.0), // Add padding to the top
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _textEditingController, // Assign the controller to the TextField
                decoration: InputDecoration(
                  hintText: 'Write your review...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(height: 20), // Add spacing between the TextField and the button
            SizedBox(
              width: double.infinity, // Make the button expand to the maximum width available
              child: ElevatedButton(
                onPressed: () {
                  String review = _textEditingController.text; // Get the text entered by the user
                  reviewSubmit(review);
                  print('Review: $review'); // Print the review
                },
                child: Text('Submit Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> reviewSubmit(String review) async{
    Utils utils=Utils();

    if(review.isEmpty){
      utils.showToastMessage('Enter Review', context);
      return;
    }
    FirebaseService firebaseService=FirebaseService();
    SharedPreferences sharedPreferences=SharedPreferences();
    utils.showDefaultLoading();

    String date=utils.getTime();
    String? privilege=await sharedPreferences.getSecurePrefsValue('PRIVILEGE');
    DocumentReference documentReference=FirebaseFirestore.instance.doc('/KLU/REVIEWS');

    String? regNo=await sharedPreferences.getSecurePrefsValue('REGISTRATION NUMBER');
    String? staffID=await sharedPreferences.getSecurePrefsValue('STAFF ID');

    Map<String,String> data={};

    if(privilege=='STUDENT'){
      documentReference=FirebaseFirestore.instance.doc('/KLU/REVIEWS/STUDENT/$date');
      data.addAll({regNo!:review});
    }else{
      documentReference=FirebaseFirestore.instance.doc('/KLU/REVIEWS/STAFF/$date');
      data.addAll({staffID!: review});
    }

    firebaseService.uploadMapDetailsToDoc(documentReference, data,'review');

    utils.showToastMessage('REVIEW IS SUBMITTED SUCESSFULLY', context);

    EasyLoading.dismiss();
    Navigator.pop(context);

  }

  @override
  void dispose() {
    _textEditingController.dispose(); // Dispose the controller when the widget is disposed
    super.dispose();
  }
}
