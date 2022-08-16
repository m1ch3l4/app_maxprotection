import 'package:fluttertoast/fluttertoast.dart';

import '../widgets/HexColor.dart';
import '../widgets/constants.dart';

class Message{
  static void showMessage(String aviso){
    Fluttertoast.showToast(
        msg: aviso,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: HexColor(Constants.grey),
        textColor: HexColor(Constants.red),
        fontSize: 16.0
    );
  }
}