// @dart=2.9
import 'package:flutter/material.dart';

import '../utils/HexColor.dart';
import 'constants.dart';
import 'custom_route.dart';

class TopHomeWidget extends StatelessWidget{
  final Color cardColor;
  Widget icon;
  final String title;
  final Widget action;
  BuildContext ctx;
  final Function onclickF;
  final width;
  final bool r;

  TopHomeWidget({
  this.cardColor,
  this.icon,
  this.title,
  this.action,
  this.ctx,
  this.width,
  this.r,
  this.onclickF,
    this.disableBlink
  });

  Function disableBlink;

  @override
  Widget build(BuildContext context) {
   return Container(
     decoration: BoxDecoration(
       color: cardColor
     ),
     //width: width,
     height: 30,
     child: Row(
       mainAxisAlignment: MainAxisAlignment.end,
       //mainAxisSize: MainAxisSize.min,
       children: [
         Container(
           width: 28,
           height: 40,
           child: icon,
           decoration: BoxDecoration(
             color: HexColor(Constants.red),
             borderRadius: BorderRadius.circular(5.0),
           ),
         ),
         SizedBox(width: 5,),
         InkWell(
           child: Text(title,style: TextStyle(color:HexColor(Constants.textColor),fontSize: 14.0),),
           onTap: (){
    if(r){
    onclickF();
    }else {
    if(title == "Leads"){
    disableBlink();
    }
    Navigator.of(ctx).pushReplacement(FadePageRoute(
    builder: (context) => action,
    ));
    }},
         ),
         InkWell(
           child: Icon(Icons.arrow_forward_ios_outlined, color:HexColor(Constants.red)),
        onTap: (){
        if(r){
        onclickF();
        }else {
        if(title == "Leads"){
        disableBlink();
        }
        Navigator.of(ctx).pushReplacement(FadePageRoute(
        builder: (context) => action,
        ));
        }}
         )
       ],
     )
   );
  }
  
}