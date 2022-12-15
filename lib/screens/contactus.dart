import 'package:contactus/contactus.dart';
import 'package:flutter/material.dart';

import '../utils/HexColor.dart';
import '../widgets/constants.dart';


void main() => runApp(ContatcusScreen());

class ContatcusScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        bottomNavigationBar: ContactUsBottomAppBar(
          companyName: 'Max Protection',
          textColor: Colors.white,
          backgroundColor: HexColor(Constants.red),
          email: 'contato@maxprotection.com.br',
          textFont: 'OpenSans',
        ),
        backgroundColor: HexColor(Constants.red),
        body: ContactUs(
            cardColor: Colors.white,
            textColor: HexColor(Constants.red),
            logo: AssetImage('images/icon2.png'),
            email: 'contato@maxprotection',
            companyName: 'Max Protection',
            companyFontSize: 32.0,
            companyFont: 'OpenSans',
            companyColor: Colors.white,
            dividerColor: Colors.white,
            phoneNumber: '+5551999879275',
            website: 'https://www.maxprotection.com.br',
            tagLine: 'Gestão de Segurança da Informação',
            taglineColor: Colors.white,
            //linkedinURL: 'https://www.linkedin.com/company/maxprotectionsecuritysolutions',
            instagram: 'maxprotectionsecurity',
            facebookHandle: 'maxprotectionsolutions'),
      ),
    );
  }
}