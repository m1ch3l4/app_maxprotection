//@dart=2.9
import 'package:app_maxprotection/screens/home_page.dart';
import 'package:app_maxprotection/screens/login_screen.dart';
import 'package:app_maxprotection/screens/welcome_screen.dart';
import 'package:app_maxprotection/transition_route_observer.dart';
import 'package:app_maxprotection/utils/HexColor.dart';
import 'package:app_maxprotection/widgets/constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'utils/SharedPref.dart';

var usr = null;
void main() {

  SharedPreferences sharedPref;

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.white, // navigation bar color
    statusBarColor: HexColor(Constants.red), // status bar color
  ));

  WidgetsFlutterBinding.ensureInitialized();
  //initializeFirebase().then(_)=> runApp(MyApp()));
  //return runApp(MyApp());
  SharedPreferences.getInstance().then((instance) => runMyApp(instance));


}

Future runMyApp(SharedPreferences inst) async{
  usr = inst.get("usuario");
  //print("usuario..."+usr.toString());
  initializeFirebase().then((_) => runApp(MyApp()));
}

Future initializeFirebase() async {
  await Firebase.initializeApp();
}

class MyApp extends StatelessWidget {

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey(debugLabel: "Main Navigator");


  Map<int, Color> colorBlue ={
    50:Color.fromRGBO(27,52,69, .1),
    100:Color.fromRGBO(27,52,69, .2),
    200:Color.fromRGBO(27,52,69, .3),
    300:Color.fromRGBO(27,52,69, .4),
    400:Color.fromRGBO(27,52,69, .5),
    500:Color.fromRGBO(27,52,69, .6),
    600:Color.fromRGBO(27,52,69, .7),
    700:Color.fromRGBO(27,52,69, .8),
    800:Color.fromRGBO(27,52,69, .9),
    900:Color.fromRGBO(27,52,69, 1),};

  Map<int, Color> colorRed ={
    50:Color.fromRGBO(163,35,48, .1),
    100:Color.fromRGBO(163,35,48, .2),
    200:Color.fromRGBO(163,35,48, .3),
    300:Color.fromRGBO(163,35,48, .4),
    400:Color.fromRGBO(163,35,48, .5),
    500:Color.fromRGBO(163,35,48, .6),
    600:Color.fromRGBO(163,35,48, .7),
    700:Color.fromRGBO(163,35,48, .8),
    800:Color.fromRGBO(163,35,48, .9),
    900:Color.fromRGBO(163,35,48, 1),};

  Map<int, Color> colorGrey ={
    50:Color.fromRGBO(232,230,230, .1),
    100:Color.fromRGBO(232,230,230, .2),
    200:Color.fromRGBO(232,230,230, .3),
    300:Color.fromRGBO(232,230,230, .4),
    400:Color.fromRGBO(232,230,230, .5),
    500:Color.fromRGBO(232,230,230, .6),
    600:Color.fromRGBO(232,230,230, .7),
    700:Color.fromRGBO(232,230,230, .8),
    800:Color.fromRGBO(232,230,230, .9),
    900:Color.fromRGBO(232,230,230, 1),};

  @override
  Widget build(BuildContext context) {

    MaterialColor bgColor = MaterialColor(0xFF1b3445,colorBlue);
    MaterialColor accentColor = MaterialColor(0xFFa32330,colorRed);
    MaterialColor greyColor = MaterialColor(0xFFe8e6e6,colorGrey);

    return MaterialApp(
      navigatorKey: navigatorKey,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('pt','BR'),
      ],
      debugShowCheckedModeBanner: false,
      title: 'Security App',
      theme: ThemeData(
        // brightness: Brightness.dark,
        primarySwatch: bgColor,
        accentColor: accentColor,
        textSelectionTheme: TextSelectionThemeData(cursorColor: greyColor),
        colorScheme: ColorScheme.light(primary: HexColor(Constants.red)),
        buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
        // fontFamily: 'SourceSansPro',
        textTheme: TextTheme(
          headline1: TextStyle(
            fontFamily: 'OpenSans',
            fontSize: 14.0,
            // fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
          headline3: TextStyle(
            fontFamily: 'OpenSans',
            fontSize: 10.0,
            // fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
          button: TextStyle(
            // OpenSans is similar to NotoSans but the uppercases look a bit better IMO
            fontFamily: 'OpenSans',
          ),
          caption: TextStyle(
            fontFamily: 'NotoSans',
            fontSize: 12.0,
            fontWeight: FontWeight.normal,
            color: accentColor,
          ),
          headline2: TextStyle(fontFamily: 'Quicksand',fontSize: 14.0),
          headline4: TextStyle(fontFamily: 'Quicksand'),
          headline5: TextStyle(fontFamily: 'NotoSans'),
          headline6: TextStyle(fontFamily: 'NotoSans'),
          subtitle1: TextStyle(fontFamily: 'NotoSans', fontSize: 14.0,color:accentColor),
          bodyText1: TextStyle(fontFamily: 'NotoSans'),
          bodyText2: TextStyle(fontFamily: 'NotoSans'),
          subtitle2: TextStyle(fontFamily: 'NotoSans'),
          overline: TextStyle(fontFamily: 'NotoSans',color:accentColor),

        ),
      ),
      //home: InnerTickets(),
      //home: LoginScreen(),
      home: (usr!=null?HomePage():WelcomeScreen()),
      /**home: LoginScreen(),
      navigatorObservers: [TransitionRouteObserver()],
      initialRoute: LoginScreen.routeName,
      routes: {
        LoginScreen.routeName: (context) => LoginScreen(),
        HomePage.routeName: (context)=>HomePage()
      },**/
    );
  }
}
