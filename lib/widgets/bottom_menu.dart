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

  BottomMenu(BuildContext context, ScrollController _sc, double _width, Map<String, dynamic> user){
    this.ctx = context;
    this.sc = _sc;
    this.width = _width;
    usr = user;
    if(usr["tipo"]=="C")
      isConsultor=true;
    if(usr["tipo"]=="T")
      isTecnico = true;
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
                  SizedBox(width:20),
                  Icon(Icons.keyboard_arrow_up,
                      color: HexColor(Constants.red), size: 30.0),
                ],
              ),
            ),
            Column(
                children: <Widget>[
                  Container(
                      color: HexColor(Constants.grey),
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 10.0),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                ActiveProjectsCard(
                                  ctx:context,
                                  r:false,
                                  action: (isConsultor?TicketsviewConsultor(1):TicketlistConsultor(null,1)),
                                  cardColor: Colors.white,
                                  icon: Icon(Icons.support,
                                      color: HexColor(Constants.red), size: 20.0),
                                  title: 'Tickets Abertos',
                                ),
                                SizedBox(width: 20.0),
                                ActiveProjectsCard(
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
                            Row(
                              children: <Widget>[
                                //(isTecnico?
                                ActiveProjectsCard(
                                  r:false,
                                  ctx:context,
                                  //action: (isConsultor?TicketsviewConsultor(1):TicketlistConsultor(null,1)),
                                  action: InnerOpenTicket(),
                                  cardColor: Colors.white,
                                  icon: Icon(Icons.mic,
                                      color: HexColor(Constants.red), size: 20.0),
                                  title: 'Abrir Chamado por Voz',
                                ),//:SizedBox(height: 0,)),
                              ],
                            ),
                            Row(
                              children: <Widget>[
                                (isTecnico?
                                ActiveProjectsCard(
                                  r:false,
                                  ctx:context,
                                  action: InnerOpenTicketbytext(),
                                  cardColor: Colors.white,
                                  icon: Icon(Icons.menu_book,
                                      color: HexColor(Constants.red), size: 20.0),
                                  title: 'Abrir Chamado por Texto',
                                ):SizedBox(height: 0,)),
                              ],
                            )
                          ]))]),
            SizedBox(
              height: 5,
            ),
          ],
        ));
  }

}