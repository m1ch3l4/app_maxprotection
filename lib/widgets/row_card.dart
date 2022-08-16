// @dart=2.9
import 'package:flutter/material.dart';


import '../utils/HexColor.dart';
import 'constants.dart';
import 'custom_route.dart';

class RowCard extends StatelessWidget {
  final Color cardColor;
  final Icon iconprefix;
  final String title;
  final Icon iconsufix;
  final Widget action;

  RowCard({
    this.cardColor,
    this.iconprefix,
    this.title,
    this.iconsufix,
    this.action
  });

  @override
  Widget build(BuildContext context) {
    /**
     * GestureDetector(
        onTap: (){
        Navigator.of(context).pushReplacement(FadePageRoute(
        //builder: (context) => (isConsultant?TicketsviewConsultant():Ticketsview()),
        builder: (context) => action,
        ));
        },
        child:
     */
    return Expanded(
      flex: 1,
      child:
        InkWell(
        onTap: (){
      Navigator.of(context).pushReplacement(FadePageRoute(
        builder: (context) => action,
      ));
    } ,
    child:
      Container(
        margin: EdgeInsets.symmetric(vertical: 10.0),
        //padding: EdgeInsets.all(5.0),
        height: 60,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Container(
                  height: 60,
                  width: 40,
                  decoration: new BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        bottomLeft: Radius.circular(10)
                      ),
                    color: HexColor(Constants.red),
                  ),
                  child: iconprefix,
                ),
                SizedBox(width: 10,),
                Expanded(child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.0,
                    color: HexColor(Constants.black),
                    fontWeight: FontWeight.w500,
                  ),
                )),
                SizedBox(width:30),
                iconsufix
              ],
            ),
          ],
        ),
      ),
    ));
  }
}
