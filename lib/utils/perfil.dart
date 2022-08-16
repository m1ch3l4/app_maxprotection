class Perfil {
  static var tecnico = false;

  static bool isTecnico() {
    print("isTecnico..."+tecnico.toString());
    return tecnico;
  }
  static setTecnico(bool v) {
    tecnico = v;
    print("setou o tecnico..."+tecnico.toString());
  }
}