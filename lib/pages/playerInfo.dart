

import 'package:shared_preferences/shared_preferences.dart';

class playerInfo {
  String? idJugador;
  String? usuario;
  String? correo;
  String? estadoUser;
  String? fotoPerfil;

  playerInfo(String? idJugador, String? usuario, String? correo,
      String? estadoUser, String? fotoPerfil) {
    this.idJugador = idJugador;
    this.usuario = usuario;
    this.correo = correo;
    this.estadoUser = estadoUser;
    this.fotoPerfil = fotoPerfil;
  }

  void setUsuario(String usuario){
    this.usuario = usuario;
  }

  void setEstadoUser(String estadUser){
    this.estadoUser;
  }

  void setFotoPerfil(String fotoPerfil){
    this.fotoPerfil;
  }
}