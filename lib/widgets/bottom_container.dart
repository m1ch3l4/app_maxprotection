import 'package:app_maxprotection/utils/HexColor.dart';
import 'package:app_maxprotection/widgets/constants.dart';
import 'package:flutter/material.dart';

class BottomContainer extends StatelessWidget {
  final double? height;
  final double? width;
  final Widget? child;
  final EdgeInsets? padding;
  BottomContainer({this.height, this.width, this.child, this.padding});


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding!=null ? padding : EdgeInsets.symmetric(horizontal: 0.0),
      decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(5.0),
            topLeft: Radius.circular(5.0),
          )),
      height: height,
      width: width,
      child: child,
    );
  }
}
