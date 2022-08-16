import 'package:flutter/services.dart';
import 'package:local_auth/auth_strings.dart';
import 'package:local_auth/local_auth.dart';

class FingerPrintAuth{
  final LocalAuthentication auth = LocalAuthentication();
  _SupportState _supportState = _SupportState.unknown;
  bool? _canCheckBiometrics;
  List<BiometricType>? _availableBiometrics;
  String _authorized = 'Não Autorizado';
  bool _isAuthenticating = false;

  FingerPrintAuth(){}

  bool checkBiometrics(){
    bool isSupported=false;
    auth.isDeviceSupported().then((isSupported){
      _supportState = (isSupported
          ? _SupportState.supported
          : _SupportState.unsupported);
      print('biometrics supported $_supportState');
      if(_supportState == _SupportState.supported)
        isSupported = true;
      if(_supportState == _SupportState.unsupported || _supportState == _SupportState.unknown)
        isSupported = false;
    }
    );
    return isSupported;
  }

  _SupportState isAvailable(){
    return _supportState;
  }

  Future<bool> authWithBiometrics() async {
    bool authenticated = false;
    try {
      const iosStrings = const IOSAuthMessages(
          cancelButton: 'Cancelar',
          goToSettingsButton: 'configurações',
          goToSettingsDescription: 'Please set up your Touch ID.',
          lockOut: 'Please reenable your Touch ID');
      const androidStrings = const AndroidAuthMessages(
          cancelButton: 'Cancelar',
          signInTitle: 'Autenticação Requerida',
          biometricHint: 'Verificar Identidade'
      );

      _isAuthenticating = true;
      _authorized = 'Autenticando';
      authenticated = await auth.authenticate(
          localizedReason:
          'Coloque sua digital no sensor para autenticar',
          stickyAuth: true,
          useErrorDialogs: false,
          iOSAuthStrings: iosStrings,
          androidAuthStrings: androidStrings,
          biometricOnly: true);

      _isAuthenticating = false;
      _authorized = 'Autenticando';

    // ignore: nullable_type_in_catch_clause
    } on PlatformException catch (e) {
      print('Erro Biometrics: ${e.message}');
      _isAuthenticating = false;
      _authorized = "Error - ${e.message}";
      return false;
    }
    final String message = authenticated ? 'Autorizado' : 'Não Authorizado';
    _authorized = message;
    print('Autenticou? $_authorized');
    return authenticated;
  }
}
enum _SupportState {
  unknown,
  supported,
  unsupported,
}
