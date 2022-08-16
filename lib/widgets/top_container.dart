// @dart=2.9
import 'package:flutter/material.dart';

import '../utils/HexColor.dart';
import 'constants.dart';

class TopContainer extends StatelessWidget {
  final double height;
  final double width;
  final Widget child;
  final EdgeInsets padding;
  TopContainer({this.height, this.width, this.child, this.padding});


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding!=null ? padding : EdgeInsets.symmetric(horizontal: 20.0),
      decoration: BoxDecoration(
          color: HexColor(Constants.red),
          borderRadius: BorderRadius.only(
            bottomRight: Radius.circular(5.0),
            bottomLeft: Radius.circular(5.0),
          )),
      height: height,
      width: width,
      child: child,
    );
  }
}
