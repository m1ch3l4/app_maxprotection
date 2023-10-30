import 'package:app_maxprotection/widgets/top_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import '../screens/home_page.dart';
import '../utils/HexColor.dart';
import 'constants.dart';
import 'custom_route.dart';

class headerNoticias extends StatelessWidget{

  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  BuildContext? ctx;
  double? width;
  Function? f;

  @override
  Widget build(BuildContext context) {
    return _header(width!, context);
  }

  headerNoticias(GlobalKey<ScaffoldState> key, BuildContext context, double w, Function onclick){
    _scaffoldKey = key;
    width = w;
    ctx = context;
    f = onclick;
  }

  Widget _header(double width, BuildContext context){
    return TopContainer(
      height: 140,
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
                  icon: const Icon(Icons.home_outlined, color:Colors.white,size: 20.0),
                  tooltip: 'Abrir Menu',
                  onPressed: () {
                    Navigator.of(ctx!).push(FadePageRoute(
                      builder: (ctx) => HomePage(),
                    ));
                  },
                ),
              ],
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text("NOTÍCIAS",style: TextStyle(fontWeight: FontWeight.bold,fontSize:18.0, color: Colors.white),),
                Spacer(),
                GestureDetector(
                  child: Container(
                    padding: EdgeInsets.only(
                      bottom: 3, // Space between underline and text
                    ),
                    decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(
                          color: Colors.white,
                          width: 1.0, // Underline thickness
                        ))
                    ),
                    child: Text(
                      "VER TODAS",
                      style: TextStyle(
                        fontSize: 11.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  onTap: (){
                    f!();
                  },
                ),
              ],
            ),
            Spacer()
          ]),
    );
  }

}