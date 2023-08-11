import 'package:app_maxprotection/utils/HexColor.dart';
import 'package:app_maxprotection/widgets/constants.dart';
import 'package:flutter/material.dart';
class RadialButton extends StatelessWidget {
  final String buttonText;
  final double width;
  final Function onpressed;

  RadialButton({
    required this.buttonText,
    required this.width,
    required this.onpressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
        width: width,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
                color: HexColor(Constants.red), offset: Offset(0, 4), blurRadius: 5.0)
          ],
          gradient: RadialGradient(
            colors: [HexColor(Constants.innerRed),HexColor(Constants.red)]
          ),
          color: HexColor(Constants.red),
          borderRadius: BorderRadius.circular(20),
        ),
        child: ElevatedButton(
          style: ButtonStyle(
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.0),
              ),
            ),
            minimumSize: MaterialStateProperty.all(Size(width, 49)),
            backgroundColor:
            MaterialStateProperty.all(Colors.transparent),
            // elevation: MaterialStateProperty.all(3),
            shadowColor:
            MaterialStateProperty.all(Colors.transparent),
          ),
          onPressed: () {
            onpressed();
          },
          child: Padding(
            padding: const EdgeInsets.only(
              top: 10,
              bottom: 10,
            ),
            child: Text(
              buttonText,
              style: TextStyle(
                fontSize: 18,
                // fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
  }
}