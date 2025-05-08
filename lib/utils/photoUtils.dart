String getRutaSeguraFoto(String? fotoGuardada) {
  if (fotoGuardada == null || fotoGuardada.isEmpty || fotoGuardada.endsWith('/none') || fotoGuardada == "none") {
    return 'assets/fotosPerfil/fotoPerfil.png';
  }

  return fotoGuardada.startsWith('assets/')
      ? fotoGuardada
      : 'assets/fotosPerfil/$fotoGuardada';
}
