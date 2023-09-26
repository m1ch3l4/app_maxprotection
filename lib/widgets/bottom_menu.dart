import 'package:app_maxprotection/screens/inner_openbytext.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../screens/inner_openticket.dart';
import '../screens/ticketlist-consultor.dart';
import '../screens/ticketsview-consultor.dart';
import '../utils/HexColor.dart';
import 'active_project_card.dart';
import 'bottom_container.dart';
import 'constants.dart';

class BottomMenu extends StatelessWidget{

  late BuildContext ctx;
  late ScrollController sc;
  late double width;
  late Map<String, dynamic> usr;
  bool isConsultor=false;
  bool isTecnico = false;
  double screenh=0.0;

  BottomMenu(BuildContext context, ScrollController _sc, double _width, Map<String, dynamic> user){
    this.ctx = context;
    this.sc = _sc;
    this.width = _width;
    usr = user;
    print("tipo..."+user["tipo"]);
    if(usr["tipo"]=="C")
      isConsultor=true;
    if(usr["tipo"]=="T")
      isTecnico = true;
    screenh = MediaQuery.of(context).size.height;
  }



/** advancedStatusCheck(NewVersion newVersion) async {
  final status = await newVersion.getVersionStatus();
  if (status != null) {
    debugPrint(status.releaseNotes);
    debugPrint(status.appStoreLink);
    debugPrint(status.localVersion);
    debugPrint(status.storeVersion);
    debugPrint(status.canUpdate.toString());
    newVersion.showUpdateDialog(
      context: ctx,
      versionStatus: status,
      dialogTitle: 'Custom Title',
      dialogText: 'Custom Text',
    );
  }
}**/


@override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
        context: ctx,
        removeTop: true,
        child: ListView(
          controller: sc,
          children: <Widget>[
            SizedBox(
              height: 8.0,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 30,
                  height: 5,
                  decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.all(Radius.circular(12.0))),
                ),
              ],
            ),
            SizedBox(
              height: 5.0,
            ),
            BottomContainer(
              height: 30,
              width: width,
              child:
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                      'Mais Serviços',
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 18.0,
                        color: HexColor(Constants.red),
                        fontWeight: FontWeight.w400,
                      )
                  ),
                  SizedBox(width:10),
                  Icon(Icons.keyboard_arrow_up,
                      color: HexColor(Constants.red), size: 24.0),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    alignment: Alignment.center,
                      color: HexColor(Constants.grey),
                      padding: EdgeInsets.symmetric(
                          horizontal: 15.0, vertical: 10.0),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                ActiveProjectsCard(
                                  width: (screenh<700?width*0.38:width*0.42),
                                  ctx:context,
                                  r:false,
                                  action: (isConsultor?TicketsviewConsultor(1):TicketlistConsultor(null,1)),
                                  cardColor: Colors.white,
                                  icon: Icon(Icons.support,
                                      color: HexColor(Constants.red), size: 20.0),
                                  title: 'Tickets Abertos',
                                ),
                                SizedBox(width: (screenh<700?width*0.04:width*0.06)),
                                ActiveProjectsCard(
                                  width: (screenh<700?width*0.38:width*0.42),
                                  ctx:context,
                                  r:false,
                                  action: (isConsultor?TicketsviewConsultor(2):TicketlistConsultor(null,2)),
                                  cardColor: Colors.white,
                                  icon:Icon(Icons.watch_later_outlined,
                                      color: HexColor(Constants.red), size: 20.0),
                                  title: 'Tickets em Atendimento',
                                ),
                              ],
                            ),
                            if(isTecnico)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                ActiveProjectsCard(
                                  r:false,
                                  ctx:context,
                                  width: (screenh<700?width*0.38:width*0.9),
                                  //action: (isConsultor?TicketsviewConsultor(1):TicketlistConsultor(null,1)),
                                  action: InnerOpenTicket(),
                                  cardColor: Colors.white,
                                  icon: Icon(Icons.mic,
                                      color: HexColor(Constants.red), size: 20.0),
                                  title: 'Abrir Chamado por Voz',
                                )
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                ActiveProjectsCard(
                                  r:false,
                                  ctx:context,
                                  width: (screenh<700?width*0.38:width*0.9),
                                  //action: (isConsultor?TicketsviewConsultor(1):TicketlistConsultor(null,1)),
                                  action: InnerOpenTicketbytext(),
                                  cardColor: Colors.white,
                                  icon: Icon(Icons.keyboard,
                                      color: HexColor(Constants.red), size: 20.0),
                                  title: 'Abrir Chamado por Texto',
                                )
                              ],
                            ),
                          ]))]),
            SizedBox(
              height: 5,
            ),
          ],
        ));
  }

}