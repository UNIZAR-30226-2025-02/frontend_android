String getRutaSeguraFoto(String? fotoGuardada) {
  if (fotoGuardada == null || fotoGuardada.isEmpty || fotoGuardada.endsWith('/none')) {
    return 'assets/fotosPerfil/fotoPerfil.png';
  }

  // Si ya es una ruta completa, no la modifiques
  return fotoGuardada.startsWith('assets/')
      ? fotoGuardada
      : 'assets/fotosPerfil/$fotoGuardada';
}
