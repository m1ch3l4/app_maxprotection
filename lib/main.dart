import 'package:app_maxprotection/screens/VerifyMfa.dart';
import 'package:app_maxprotection/screens/home_page.dart';
import 'package:app_maxprotection/screens/welcome_screen.dart';
import 'package:app_maxprotection/utils/HexColor.dart';
import 'package:app_maxprotection/widgets/constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:device_preview/device_preview.dart';
import 'utils/SharedPref.dart';

Future<void> _messageHandler(RemoteMessage message) async {
  print('APP_MAX...background message ${message.notification!.body}');
}

var usr = null;
var mfa = null;
var logoff = null;
void main() {

  SharedPreferences sharedPref;

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.white, // navigation bar color
    statusBarColor: Colors.transparent, // status bar color
  ));

  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SharedPreferences.getInstance().then((instance) => runMyApp(instance));
}

Future runMyApp(SharedPreferences inst) async{
  usr = inst.get("usuario");
  mfa = inst.get("mfa");
  logoff = inst.getString("logoff");
  print("usuario..."+usr.toString());
  await Firebase.initializeApp();
  runApp(MyApp());
  /**runApp(
    DevicePreview(
      enabled: true,
      tools: [
        ...DevicePreview.defaultTools,
      ],
      builder: (context) => MyApp(),
    ),
  );**/
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

    //MaterialColor bgColor = MaterialColor(0xFF1b3445,colorBlue);
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
        unselectedWidgetColor: HexColor(Constants.blue),
        //primarySwatch: bgColor,
        textSelectionTheme: TextSelectionThemeData(cursorColor: greyColor),
        colorScheme: ColorScheme.light(primary: HexColor(Constants.red)),
        buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
        // fontFamily: 'SourceSansPro',
        textTheme: TextTheme(
          headline1: TextStyle(
            fontFamily: 'Metropolis',
            fontSize: 14.0,
            // fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
          headline3: TextStyle(
            fontFamily: 'Metropolis',
            fontSize: 10.0,
            // fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
          button: TextStyle(
            // OpenSans is similar to NotoSans but the uppercases look a bit better IMO
            fontFamily: 'Metropolis',
          ),
          caption: TextStyle(
            fontFamily: 'Metropolis',
            fontSize: 12.0,
            fontWeight: FontWeight.normal,
            color: accentColor,
          ),
          headline2: TextStyle(fontFamily: 'Metropolis',fontSize: 14.0),
          headline4: TextStyle(fontFamily: 'Metropolis'),
          headline5: TextStyle(fontFamily: 'Metropolis'),
          headline6: TextStyle(fontFamily: 'Metropolis'),
          subtitle1: TextStyle(fontFamily: 'Metropolis', fontSize: 14.0,color:Colors.white),
          bodyText1: TextStyle(fontFamily: 'Metropolis'),
          bodyText2: TextStyle(fontFamily: 'Metropolis'),
          subtitle2: TextStyle(fontFamily: 'Metropolis'),
          overline: TextStyle(fontFamily: 'Metropolis'),
        ),
      ),
      home: getScreen(),
      //home: (usr!=null && mfa!=null?HomePage():WelcomeScreen()),
      /**home: LoginScreen(),
      navigatorObservers: [TransitionRouteObserver()],
      initialRoute: LoginScreen.routeName,
      routes: {
        LoginScreen.routeName: (context) => LoginScreen(),
        HomePage.routeName: (context)=>HomePage()
      },**/
    );
  }
  Widget getScreen(){
    Widget screen = WelcomeScreen("");

    if(usr!=null && logoff=="true") {
      print("WelcomeScreen");
      screen = WelcomeScreen(logoff);
    }
    if(usr!=null && mfa!=null && logoff!="true") {
      print("HomePage");
      screen = HomePage();
    }
    if(usr!=null && mfa==null && logoff!="true") {
      print("VerifyMfa");
      screen =  verifyTwoFactor();
    }
    if(usr==null){
      print("primeira instalacao");
      screen =  WelcomeScreen("");
    }
    return screen;
  }
}
