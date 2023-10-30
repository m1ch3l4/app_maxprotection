import 'package:app_maxprotection/widgets/top_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/home_page.dart';
import '../utils/HexColor.dart';
import 'constants.dart';
import 'custom_route.dart';

class simpleHeader extends StatelessWidget{

  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  BuildContext? ctx;
  double? width;
  double? height;

  @override
  Widget build(BuildContext context) {
    return _header(width!, context);
  }

  simpleHeader(GlobalKey<ScaffoldState> key, BuildContext context, double w, double h){
    _scaffoldKey = key;
    width = w;
    height = h;
    ctx = context;
  }

  Widget _header(double width, BuildContext context){
    return TopContainer(
      height: (height!=null?height:200),
      width: width,
      color: HexColor(Constants.blue),
      child: Column(
        //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Row(children: [SizedBox(height: 10,)],),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.menu, color:Colors.white,size: 20.0),
                  tooltip: 'Abrir Menu',
                  onPressed: () {
                    _scaffoldKey.currentState!.openDrawer();
                  },
                ),
                Spacer(),
                Image.asset("images/lg.png",width: 150,height: 69,),
                Spacer(),
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color:Colors.white,size: 20.0),
                  tooltip: 'Abrir Menu',
                  onPressed: () {
                    /**Navigator.of(ctx).push(FadePageRoute(
                      builder: (ctx) => HomePage(),
                    ));**/
                    Navigator.of(context).maybePop(context).then((value) {
                      if (value == false) {
                        Navigator.pushReplacement(
                            context,
                            FadePageRoute(
                              builder: (ctx) => HomePage(),
                            ));
                      }
                    });
                  },
                ),
              ],
            )
          ]),
    );
  }

}
