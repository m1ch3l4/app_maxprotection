// @dart=2.9
import 'package:flutter/material.dart';

import '../utils/HexColor.dart';
import 'constants.dart';

class closePopup extends StatelessWidget{

  closePopup();
  
  @override
  Widget build(BuildContext context) {
    return SizedBox( //<-- SEE HERE
        width: 30,
        height: 30,
        child: FittedBox(
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: () {Navigator.pop(context);},
              child: Icon(
                Icons.close,
                size: 25,
                color: HexColor(Constants.red),
              ),
            )));
  }
  
}