import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoadingDialog extends StatelessWidget {
  final String message;


  final Widget loadingIndicator;


  LoadingDialog({required this.message, required this.loadingIndicator});

  static Future<void> spinKitLoadingDialog(BuildContext context, String message) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return LoadingDialog(message: message, loadingIndicator: SpinKitCubeGrid(color: Colors.blue, size: 50.0));
      },
    );
  }


  static Future<void> rotatingPlaneLoadingDialog(BuildContext context, String message) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return LoadingDialog(message: message, loadingIndicator: SpinKitRotatingPlain(color: Colors.blue, size: 50.0));
      },
    );
  }

  static Future<void> doubleBounceLoadingDialog(BuildContext context, String message) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return LoadingDialog(message: message, loadingIndicator: SpinKitDoubleBounce(color: Colors.blue, size: 50.0));
      },
    );
  }

  static Future<void> wanderingCubesLoadingDialog(BuildContext context, String message) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return LoadingDialog(message: message, loadingIndicator: SpinKitWanderingCubes(color: Colors.blue, size: 50.0));
      },
    );
  }

  static Future<void> fadingFourLoadingDialog(BuildContext context, String message) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return LoadingDialog(message: message, loadingIndicator: SpinKitFadingFour(color: Colors.blue, size: 50.0));
      },
    );
  }

  static Future<void> fadingCubeLoadingDialog(BuildContext context, String message) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return LoadingDialog(message: message, loadingIndicator: SpinKitFadingCube(color: Colors.blue, size: 50.0));
      },
    );
  }

  static Future<void> pulseLoadingDialog(BuildContext context, String message) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return LoadingDialog(message: message, loadingIndicator: SpinKitPulse(color: Colors.blue, size: 50.0));
      },
    );
  }

  static Future<void> chasingDotsLoadingDialog(BuildContext context, String message) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return LoadingDialog(message: message, loadingIndicator: SpinKitChasingDots(color: Colors.blue, size: 50.0));
      },
    );
  }

  static Future<void> threeBouncesLoadingDialog(BuildContext context, String message) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return LoadingDialog(message: message, loadingIndicator: SpinKitThreeBounce(color: Colors.blue, size: 50.0));
      },
    );
  }

  static Future<void> circleLoadingDialog(BuildContext context, String message) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return LoadingDialog(message: message, loadingIndicator: SpinKitCircle(color: Colors.blue, size: 50.0));
      },
    );
  }

  static Future<void> cubeGridLoadingDialog(BuildContext context, String message) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return LoadingDialog(message: message, loadingIndicator: SpinKitCubeGrid(color: Colors.blue, size: 50.0));
      },
    );
  }

  static Future<void> fadingCircleLoadingDialog(BuildContext context, String message) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return LoadingDialog(message: message, loadingIndicator: SpinKitFadingCircle(color: Colors.blue, size: 50.0));
      },
    );
  }

  static Future<void> pouringHourGlassRLoadingDialog(BuildContext context, String message) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return LoadingDialog(message: message, loadingIndicator: SpinKitPouringHourGlassRefined(color: Colors.blue, size: 50.0));
      },
    );
  }

  static void stopLoadingDialog(BuildContext context) {
    print('stopLoadingDialog: ${context.toString()}');
    try {
      Navigator.of(context).pop();
    } catch (e) {
      // Handle the error, print or log it for debugging
      print('Error occurred while stopping loading dialog: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Container(
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 80,
                width: 80,
                child: loadingIndicator,
              ),
              SizedBox(height: 20),
              Text(
                message ?? 'Loading...',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
