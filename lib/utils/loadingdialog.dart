import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoadingDialog{

  void showDefaultLoading(String loadingText) {
    EasyLoading.show(
      status: loadingText,
      maskType: EasyLoadingMaskType.black,
    );
  }

  void showProgressLoading(String loadingText) {
    EasyLoading.showProgress(0.5,
        status: loadingText,
        maskType: EasyLoadingMaskType.black,
    );
  }

  void showSuccessMessage(String loadingText) {
    EasyLoading.showSuccess(loadingText,
      maskType: EasyLoadingMaskType.black,
    );
  }

  void showErrorMessage(String loadingText) {
    EasyLoading.showError(loadingText,
      maskType: EasyLoadingMaskType.black,
    );
  }


  void showInfoMessage(String loadingText) {
    EasyLoading.showInfo(loadingText,
      maskType: EasyLoadingMaskType.black,
    );
  }

}
