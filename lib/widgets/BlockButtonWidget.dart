import 'package:flutter/material.dart';

import '../utils/HexColor.dart';
import 'constants.dart';
import 'custom_route.dart';

class BlockButtonWidget extends StatelessWidget{

  final Color? cardColor;
  Widget? icon;
  final String? image;
  final String? title;
  final Widget? action;
  BuildContext? ctx;
  final Function? onclickF;
  final double? width;
  final bool? r;
  double? bheight;

  Function? disableBlink;

  BlockButtonWidget({
    this.cardColor,
    this.icon,
    this.title,
    this.action,
    this.ctx,
    this.width,
    this.r,
    this.onclickF,
    this.image,
    this.bheight
  });

  @override
  Widget build(BuildContext context) {
    double tam = MediaQuery.of(context).size.height;
    //print("largura do botao..."+width.toString());
    return GestureDetector(
          child:
          Container(
            height: (bheight!<400?50:80),
            width: width,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cardColor,
              boxShadow: [ BoxShadow(
                color: Colors.grey,
                //blurRadius: 5.0, // soften the shadow
                spreadRadius: 1.0, //extend the shadow
                offset: Offset(
                  1.0, // Move to right 5  horizontally
                  1.0, // Move to bottom 5 Vertically
                ),
              )]
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: (width!>200?MainAxisAlignment.spaceAround:MainAxisAlignment.spaceBetween),
              children: <Widget>[
                Container(
                  alignment: (width!>200?Alignment.centerRight:Alignment.centerLeft),
                  width: (width!>200?width!*0.38:width!*0.32),
                  padding: (width!>200?EdgeInsets.only(right:15):EdgeInsets.only(left: 10)),
                  child:InkWell(
                    child: (image!=null?Image.asset(image!,width: (tam<700?40:45),height: (tam<700?40:45),):icon),
                  ),
                ),
                Container(
                    alignment: (width!>200?Alignment.centerLeft:Alignment.center),
                    width: (width!>200?width!*0.62:width!*0.68),
                    padding: EdgeInsets.only(right: 6),
                  child: Text(title!,style:TextStyle(fontSize: (tam<700?11.5:13),color: HexColor(Constants.textColor)),textAlign: TextAlign.center,)
                )
              ],
            )
        ),onTap: () {
      if(r!){
        onclickF!();
      }else {
        if(title == "Leads"){
          disableBlink!();
        }
        Navigator.of(ctx!).push(FadePageRoute(
          builder: (context) => action!,
        ));
      }
    });
  }

}