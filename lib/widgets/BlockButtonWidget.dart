// @dart=2.9
import 'package:flutter/material.dart';

import '../utils/HexColor.dart';
import 'constants.dart';
import 'custom_route.dart';

class BlockButtonWidget extends StatelessWidget{

  final Color cardColor;
  Widget icon;
  final String image;
  final String title;
  final Widget action;
  BuildContext ctx;
  final Function onclickF;
  final width;
  final bool r;

  Function disableBlink;

  BlockButtonWidget({
    this.cardColor,
    this.icon,
    this.title,
    this.action,
    this.ctx,
    this.width,
    this.r,
    this.onclickF,
    this.image
  });

  @override
  Widget build(BuildContext context) {
    double tam = MediaQuery.of(context).size.height;
    return
          Container(
            height: 80,
            width: width,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Spacer(),
                    InkWell(
                    child: (image!=null?Image.asset(image,width: (tam<700?40:45),height: (tam<700?40:45),):icon),
                    onTap: () {
                        if(r){
                          onclickF();
                        }else {
                          if(title == "Leads"){
                            disableBlink();
                          }
                          Navigator.of(ctx).pushReplacement(FadePageRoute(
                            builder: (context) => action,
                          ));
                        }
                    },
                  ),
                  SizedBox(width: 4,),
                  Text(title,style:TextStyle(fontSize: (tam<700?12:13),color: HexColor(Constants.textColor))),
                    Spacer()
                  ],
                )
              ],
            )
        );
  }

}