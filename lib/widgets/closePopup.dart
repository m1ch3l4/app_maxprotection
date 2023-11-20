import 'package:flutter/material.dart';

import '../utils/HexColor.dart';
import 'constants.dart';

class closePopup extends StatelessWidget{
  BuildContext dContext;
  closePopup(this.dContext);
  
  @override
  Widget build(BuildContext context) {
    return SizedBox( //<-- SEE HERE
        width: 30,
        height: 30,
        child: FittedBox(
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: () {
                //Navigator.pop(dContext);
                Navigator.of(dContext, rootNavigator: true).pop();
                },
              child: Icon(
                Icons.close,
                size: 25,
                color: HexColor(Constants.red),
              ),
            )));
  }
  
}