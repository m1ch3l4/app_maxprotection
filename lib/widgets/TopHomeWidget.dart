import 'package:flutter/material.dart';

import '../utils/HexColor.dart';
import 'constants.dart';
import 'custom_route.dart';

class TopHomeWidget extends StatelessWidget{
  final Color? cardColor;
  Widget? icon;
  final String? title;
  final Widget? action;
  BuildContext? ctx;
  final Function? onclickF;
  final double? width;
  final bool? r;

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

  Function? disableBlink;

  @override
  Widget build(BuildContext context) {
   return Container(
     decoration: BoxDecoration(
       color: cardColor
     ),
     width: width,
     height: 30,
     child: Row(
       mainAxisAlignment: MainAxisAlignment.spaceBetween,
       children: [
         Container(
           alignment: Alignment.center,
           width: 34,
           height: 36,
           child: icon,
           decoration: BoxDecoration(
             color: HexColor(Constants.red),
             borderRadius: BorderRadius.circular(5.0),
           ),
         ),
         //SizedBox(width: 5,),
         InkWell(
           child: Container(alignment:Alignment.center,width: width!*0.545,child:Text(title!,textAlign:TextAlign.center,style: TextStyle(color:HexColor(Constants.textColor),fontSize: 11.0),)),
           onTap: (){
    if(r!){
    onclickF!();
    }else {
    if(title == "Leads"){
    disableBlink!();
    }
    Navigator.of(ctx!).pushReplacement(FadePageRoute(
    builder: (context) => action!,
    ));
    }},
         ),
         InkWell(
           child: Icon(Icons.arrow_forward_ios_outlined, color:HexColor(Constants.red)),
        onTap: (){
        if(r!){
        onclickF!();
        }else {
        if(title == "Leads"){
        disableBlink!();
        }
        Navigator.of(ctx!).push(FadePageRoute(
        builder: (context) => action!,
        ));
        }}
         )
       ],
     )
   );
  }
  
}