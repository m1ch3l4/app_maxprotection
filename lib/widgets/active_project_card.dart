// @dart=2.9
import 'package:flutter/material.dart';


import '../utils/HexColor.dart';
import 'constants.dart';
import 'custom_route.dart';

class ActiveProjectsCard extends StatelessWidget {
  final Color cardColor;
  final Widget icon;
  final String title;
  final Widget action;
  BuildContext ctx;
  final Function onclickF;
  final width;
  final bool r;

  ActiveProjectsCard({
    this.cardColor,
    this.icon,
    this.title,
    this.action,
    this.ctx,
    this.width,
    this.r,
    this.onclickF
  });

  @override
  Widget build(BuildContext context) {
    /**
     * GestureDetector(

     */
    return Expanded(
          child:InkWell(
        onTap: (){
         if(r){
            onclickF();
         }else {
           Navigator.of(ctx).pushReplacement(FadePageRoute(
             builder: (context) => action,
           ));
         }
    } ,
    child:
        Container(
        margin: EdgeInsets.symmetric(vertical: 10.0),
        padding: EdgeInsets.all(1.0),
        height: 40,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          //mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Row(
              //crossAxisAlignment: CrossAxisAlignment.end,
              //mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                (icon!=null?icon:SizedBox(width:1)),
                SizedBox(width:13),
                Expanded(child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.0,
                    color: HexColor(Constants.black),
                    fontWeight: FontWeight.w400,
                  ),
                ))
              ],
            ),
          ],
        ),
      ),
    ));
  }
}
