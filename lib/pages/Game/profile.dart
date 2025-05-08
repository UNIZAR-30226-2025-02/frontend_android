import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' as chess;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:frontend_android/pages/buildHead.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/photoUtils.dart';
import '../Game/game_review_page.dart';

class Profile_page extends StatefulWidget {
  static const String id = "profile_page";

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class UltimaPartida {
  final String modo;
  final String ganadorId;
  final int movimientos;
  final DateTime fecha;
  final String pgn; // NUEVO
  final String rival;
  final int variacionJW;
  final int variacionJB;

  UltimaPartida({
    required this.modo,
    required this.ganadorId,
    required this.movimientos,
    required this.fecha,
    required this.pgn, // NUEVO
    required this.rival,
    required this.variacionJW,
    required this.variacionJB,
  });

  factory UltimaPartida.fromJson(Map<String, dynamic> json) {
    num? parseVariacion(dynamic valor) {
      if (valor == null) return 0;
      if (valor is num) return valor;
      if (valor is String) return double.tryParse(valor) ?? 0;
      return 0;
    }

    return UltimaPartida(
      modo: json['Modo'] ?? '',
      ganadorId: json['Ganador'].toString(),
      movimientos: json['movimientos'] ?? 0,
      fecha: DateTime.parse(json['created_at']),
      pgn: json['PGN'] ?? '',
      rival: "pruebaRival",
      variacionJW: parseVariacion(json['Variacion_JW'])!.round(),
      variacionJB: parseVariacion(json['Variacion_JB'])!.round(),
    );
  }
}

class _ProfilePageState extends State<Profile_page> {
  // Datos del usuario (valores por defecto)
  String playerName = "Cargando...";
  // Nuevo valor por defecto usando la nueva ruta:
  String profileImage = "assets/fotosPerfil/fotoPerfil.png";
  int friends = 0;
  int gamesPlayed = 0;
  double winRate = 0.0;
  int maxStreak = 0;
  String gmail= "";
  List<UltimaPartida> ultimasPartidas = [];
  late final responseClasica;
  late final responsePrincipiante;
  late final responseAvanzado;
  late final responseRelampago;
  late final responseIncremento;
  late final responseIncrementoExpres;
  // URL base del servidor backend (se obtiene de la variable de entorno)
  late final String? serverBackend;
  // ID del usuario (por ejemplo, obtenido de SharedPreferences)
  late final String? userId;
  bool _isLoading = true;

  // Lista de nombres de archivos (sin ruta) de las imágenes disponibles
  List<String> multiavatarImages = [
    "avatar_1.webp",
    "avatar_2.webp",
    "avatar_3.webp",
    "avatar_4.webp",
    "avatar_5.webp",
    "avatar_6.webp",
    "avatar_7.webp",
    "avatar_8.webp",
    "avatar_9.webp",
    "avatar_10.webp",
    "avatar_11.webp",
    "avatar_12.webp",
    "avatar_13.webp",
    "avatar_14.webp",
    "avatar_15.webp",
    "avatar_16.webp",
    "avatar_17.webp",
    "avatar_18.webp",
    "avatar_19.webp",
    "avatar_20.webp",
    "avatar_21.webp",
    "avatar_22.webp",
    "avatar_23.webp",
    "avatar_24.webp",
    "avatar_25.webp",
    "avatar_26.webp",
    "avatar_27.webp",
    "avatar_28.webp",
    "avatar_29.webp",
    "avatar_30.webp",
    "avatar_31.webp",
    "avatar_32.webp",

  ];
  Map<String, List<double>> userData = {};

  @override
  void initState() {
    super.initState();
    fetchUserInfo();

  }
  Future<void> fetchUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('idJugador');
    serverBackend = dotenv.env['SERVER_BACKEND'];

    if (userId == null || serverBackend == null) {
      return;
    }

    final url = Uri.parse('${serverBackend}getUserInfo?id=$userId');
    try {
      final response = await http.get(url, headers: {
        "Content-Type": "application/json",
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          playerName = data['NombreUser'] ?? playerName;
          profileImage = (data['FotoPerfil'] != null && data['FotoPerfil'] != "none")
              ? data['FotoPerfil']
              : "fotoPerfil.png";

          friends = data['Amistades'] ?? friends;
          gamesPlayed = data['totalGames'] ?? gamesPlayed;
          maxStreak = data['maxStreak'] ?? maxStreak;
          gmail = data['Correo']?? "";

          int wins = data['totalWins'] ?? 0;
          int losses = data['totalLosses'] ?? 0;
          int draws = data['totalDraws'] ?? 0;
          int total = wins + losses + draws;

          winRate = (total > 0) ? (wins / total) * 100 : 0.0;
        });

        final histUrl = Uri.parse('${serverBackend}buscarUlt10PartidasDeUsuario?id=$userId');
        final histResp = await http.get(histUrl);
        if (histResp.statusCode == 200) {
          final List jsonList = jsonDecode(histResp.body);
          setState(() {
            ultimasPartidas = jsonList
                .map((j) => UltimaPartida.fromJson(j as Map<String, dynamic>))
                .toList();
          });
        } else {
        }

      } else {
      }
    } catch (error) {
      if (kDebugMode) {
        print("❌ Error en fetchUserInfo: $error");
      }
    }

    // Clásica
    final urlClasica = Uri.parse('${serverBackend}buscarPartidasPorModo?id=$userId&modo=Punt_10');
    responseClasica = await http.get(urlClasica);

    // Principiante
    final urlPrincipiante = Uri.parse('${serverBackend}buscarPartidasPorModo?id=$userId&modo=Punt_30');
    responsePrincipiante = await http.get(urlPrincipiante);

    // Avanzado
    final urlAvanzado = Uri.parse('${serverBackend}buscarPartidasPorModo?id=$userId&modo=Punt_5');
    responseAvanzado = await http.get(urlAvanzado);

    // Relámpago
    final urlRelampago = Uri.parse('${serverBackend}buscarPartidasPorModo?id=$userId&modo=Punt_3');
    responseRelampago = await http.get(urlRelampago);

    // Incremento
    final urlIncremento = Uri.parse('${serverBackend}buscarPartidasPorModo?id=$userId&modo=Punt_5_10');
    responseIncremento = await http.get(urlIncremento);

    // Incremento exprés
    final urlIncrementoExpres = Uri.parse('${serverBackend}buscarPartidasPorModo?id=$userId&modo=Punt_3_2');
    responseIncrementoExpres = await http.get(urlIncrementoExpres);
    userData = await construirUserDataPorModo(userId: userId, serverBackend: serverBackend);

    setState(() {
      _isLoading = false;
    });
  }

  Future<Map<String, List<double>>> construirUserDataPorModo({
    required String? userId,
    required String? serverBackend,
  }) async {
    // Mapeo frontend <-> backend
    final modoMapeado = {
      "Rápida": "Punt_10",
      "Clásica": "Punt_30",
      "Blitz": "Punt_5",
      "Bullet": "Punt_3",
      "Incremento": "Punt_5_10",
      "Incremento exprés": "Punt_3_2",
    };

    Map<String, List<double>> userData = {};

    for (final entry in modoMapeado.entries) {
      final modoFront = entry.key;
      final modoBack = entry.value;

      final url = Uri.parse('$serverBackend/buscarUlt5PartidasDeUsuarioPorModo?id=$userId&modo=$modoBack');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List partidas = jsonDecode(response.body);
        final List<double> elos = [];

        for (final partida in partidas) {
          final pgn = partida['PGN'] ?? '';
          if (pgn.isNotEmpty) {
            final eloInfo = extraerEloDesdePGN(pgn, userId);
            elos.add(eloInfo["miElo"]!.toDouble());
          }
        }
        userData[modoFront] = elos;
      } else {
        userData[modoFront] = []; // lista vacía por si falla
      }
    }

    return userData;
  }

  Map<String, String> extraerNombresDesdePGN(String pgn) {
    final aliasW = RegExp(r'\[White Alias "(.*?)"\]');
    final aliasB = RegExp(r'\[Black Alias "(.*?)"\]');
    final w = aliasW.firstMatch(pgn)?.group(1) ?? "Desconocido";
    final b = aliasB.firstMatch(pgn)?.group(1) ?? "Desconocido";
    return {"blancas": w, "negras": b};
  }

  String normalizarPGN(String pgnCrudo) {
    // Divide cada tag en su propia línea
    final tagsSeparados = pgnCrudo.replaceAllMapped(
      RegExp(r'(\[.*?\])'),
          (match) => '${match.group(1)}\n',
    );

    // Asegúrate de que las jugadas estén separadas después de los tags
    final conSaltos = tagsSeparados.replaceAll(RegExp(r'\]\s+(?=\d+\.)'), ']\n');

    return conSaltos.trim();
  }

  List<String> convertirPGNaHistorial(String pgn) {
    final List<String> movimientos = [];
    final game = chess.Chess();

    if (!game.load_pgn(pgn)) {
      return movimientos;
    }

    final history = game.getHistory({'verbose': true});

    for (var move in history) {
      final from = move['from'];
      final to = move['to'];
      final flags = move['flags'] ?? '';
      String promotion = '';

      // Si el movimiento fue una promoción, extraemos la letra desde SAN (ej: gxh8=R)
      if (flags.contains('p') && move['san'].contains('=')) {
        final san = move['san'];
        final index = san.indexOf('=');
        if (index != -1 && index + 1 < san.length) {
          promotion = san[index + 1].toLowerCase(); // r, q, b, n
        }
      }

      movimientos.add("$from$to$promotion");
    }

    return movimientos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // ✅ Al volver atrás, forzamos que se recargue la cabecera con la foto nueva
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: Image.asset("assets/logoNombre.png", height: 50),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black, Colors.grey[900]!],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(color: Colors.blueAccent),
      )
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileCard(),
            SizedBox(height: 20),
            _buildGameModeCharts(),
            SizedBox(height: 20),
            buildHistory(),
          ],
        ),
      ),
    );
  }


  Map<String, int> extraerEloDesdePGN(String pgn, String? userId) {
    final regexWhiteId = RegExp(r'\[White "(.*?)"\]');
    final regexWhiteElo = RegExp(r'\[White Elo "(.*?)"\]');
    final regexBlackId = RegExp(r'\[Black "(.*?)"\]');
    final regexBlackElo = RegExp(r'\[Black Elo "(.*?)"\]');

    final whiteId = regexWhiteId.firstMatch(pgn)?.group(1) ?? '';
    final whiteElo = int.tryParse(regexWhiteElo.firstMatch(pgn)?.group(1) ?? '') ?? 1000;

    final blackId = regexBlackId.firstMatch(pgn)?.group(1) ?? '';
    final blackElo = int.tryParse(regexBlackElo.firstMatch(pgn)?.group(1) ?? '') ?? 1000;

    final esBlancas = userId == whiteId;

    return {
      "miElo": esBlancas ? whiteElo : blackElo,
      "rivalElo": esBlancas ? blackElo : whiteElo,
    };
  }


  Widget _buildProfileCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Avatar: para mostrar la imagen en la UI, si profileImage es solo el nombre, concatenamos la ruta.
              CircleAvatar(
                radius: 35,
                backgroundImage: AssetImage(getRutaSeguraFoto(profileImage)),

              ),
              // Botones en una fila aparte
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _showEditPhotoDialog, // Función para editar foto
                    icon: Icon(Icons.image, color: Colors.white),
                    label: Text('Foto'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8), // Separación horizontal
                  ElevatedButton.icon(
                    onPressed: _showEditNameDialog, // Función para editar nombre
                    icon: Icon(Icons.edit, color: Colors.white),
                    label: Text('Nombre'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              )
            ],
          ),
          SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                playerName,
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (gmail.isNotEmpty)
                Text(
                  '($gmail)',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
          Divider(color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProfileStat("Amigos", friends.toString()),
              _buildProfileStat("Partidas", gamesPlayed.toString()),
              _buildProfileStat("% Victoria", "${winRate.toStringAsFixed(0)}%"),
              _buildProfileStat("Racha Max.", maxStreak.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStat(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(title, style: TextStyle(color: Colors.white70, fontSize: 14))
      ],
    );
  }

  Widget _buildGameModeCharts() {
    Map<String, IconData> modeIcons = {
      "Rápida": Icons.extension,
      "Clásica": Icons.verified,
      "Blitz": Icons.timer,
      "Bullet": Icons.flash_on,
      "Incremento": Icons.trending_up,
      "Incremento exprés": Icons.star,
    };

    Map<String, Color> modeColors = {
      "Rápida": Colors.brown,
      "Clásica": Colors.green,
      "Blitz": Colors.red,
      "Bullet": Colors.yellow,
      "Incremento": Colors.green,
      "Incremento exprés": Colors.yellow,
    };

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: Colors.blueAccent),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: modeIcons.keys.map((mode) {
        List<double> scores = userData![mode] ?? [];

        return Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 4)],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(modeIcons[mode], color: modeColors[mode], size: 32),
              SizedBox(height: 6),
              Text(
                mode,
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Expanded(
                child: scores.isEmpty
                    ? Center(
                  child: Text(
                    "Sin datos",
                    style: TextStyle(color: Colors.white70),
                  ),
                )
                    : LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: scores
                            .asMap()
                            .entries
                            .map(
                              (e) => FlSpot(
                              e.key.toDouble(), e.value),
                        )
                            .toList(),
                        isCurved: true,
                        color: Colors.blueAccent,
                        barWidth: 2,
                        dotData: FlDotData(show: false),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String modoFriendly(String modoBack) {
    const m = {
      "Punt_10": "Rápida",
      "Punt_30": "Clásica",
      "Punt_5":  "Blitz",
      "Punt_3":  "Bullet",
      "Punt_5_10": "Incremento",
      "Punt_3_2":  "Incremento exprés",
    };
    return m[modoBack] ?? modoBack;
  }

  int contarMovimientosDesdePGN(String pgn) {
    final regex = RegExp(r'\d+\.\s*[a-hNBRQK]'); // busca patrones como "1. e4" o "2. Nf3"
    return regex.allMatches(pgn).length;
  }

  Map<String, int> extraerEloJugadoresDesdePGN(String pgn) {
    final whiteEloMatch = RegExp(r'\[White Elo "(.*?)"\]').firstMatch(pgn);
    final blackEloMatch = RegExp(r'\[Black Elo "(.*?)"\]').firstMatch(pgn);
    int movimientos = contarMovimientosDesdePGN(pgn);

    int whiteElo = (double.tryParse(whiteEloMatch?.group(1) ?? '')?.round()) ?? 1000;
    int blackElo = (double.tryParse(blackEloMatch?.group(1) ?? '')?.round()) ?? 1000;

    return {
      "whiteElo": whiteElo,
      "blackElo": blackElo,
      "movimientos": movimientos,
    };
  }

  String formatearEloJugador(int elo) {
    if (elo >= 0) {
      return '(+${elo})';
    } else {
      return '(-${elo})';
    }
  }

  int extraerVariacionElo(UltimaPartida partida, String userId) {
    final regexJugadorBlancas = RegExp(r'\[White "(.*?)"\]');
    final whitePlayer = regexJugadorBlancas.firstMatch(partida.pgn)?.group(1) ?? '';

    final variacionJB = partida.pgn.contains('[VariationW "') ? _extraerVariacion(partida.pgn, "VariationW") : 0;
    final variacionJW = partida.pgn.contains('[VariationB "') ? _extraerVariacion(partida.pgn, "VariationB") : 0;

    final esBlancas = whitePlayer == userId;

    return esBlancas ? variacionJB : variacionJW;
  }

  int _extraerVariacion(String pgn, String tag) {
    final regex = RegExp('\\[$tag "(.*?)"\\]');
    final match = regex.firstMatch(pgn);
    if (match != null) {
      return double.tryParse(match.group(1) ?? '0')?.round() ?? 0;
    }
    return 0;
  }

  Widget buildHistory() {
    Map<String, IconData> modeIcons = {
      "Rápida": Icons.extension,
      "Clásica": Icons.verified,
      "Blitz": Icons.timer,
      "Bullet": Icons.flash_on,
      "Incremento": Icons.trending_up,
      "Incremento exprés": Icons.star,
    };

    Map<String, Color> modeColors = {
      "Rápida": Colors.brown,
      "Clásica": Colors.green,
      "Blitz": Colors.red,
      "Bullet": Colors.yellow,
      "Incremento": Colors.green,
      "Incremento exprés": Colors.yellow,
    };

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historial de Partidas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(Colors.grey[800]),
                dataRowColor: MaterialStateProperty.all(Colors.transparent),
                horizontalMargin: 16,
                columnSpacing: 24,
                columns: [
                  DataColumn(label: Text('Modo', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('Blancas', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('Negras', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('Res.', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('Movs', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('Fecha', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('', style: TextStyle(color: Colors.white))),
                ],
                rows: ultimasPartidas.map((p) {
                  final fechaFmt = '${p.fecha.day.toString().padLeft(2, '0')}/'
                      '${p.fecha.month.toString().padLeft(2, '0')}/'
                      '${p.fecha.year}';
                  final res = p.ganadorId == userId ? "✅" : (p.ganadorId == "null" ? "🤝" : "❌");
                  final nombres = extraerNombresDesdePGN(p.pgn);
                  final elos = extraerEloJugadoresDesdePGN(p.pgn);

                  final modoNombre = modoFriendly(p.modo);
                  final iconoModo = modeIcons[modoNombre] ?? Icons.help_outline;
                  final colorModo = modeColors[modoNombre] ?? Colors.blueAccent;

                  final whiteElo = elos["whiteElo"] ?? 1000;
                  final blackElo = elos["blackElo"] ?? 1000;
                  final movimiento = elos["movimientos"] ?? 0;
                  final regexJugadorBlancas = RegExp(r'\[White "(.*?)"\]');
                  final whitePlayer = regexJugadorBlancas.firstMatch(p.pgn)?.group(1) ?? '';
                  final esBlancas = whitePlayer == userId;


                  final variacion = esBlancas ? p.variacionJW : p.variacionJB;

                  return DataRow.byIndex(
                    index: ultimasPartidas.indexOf(p),
                    onSelectChanged: (_) async {
                      // 1) Convertir PGN a lista de movimientos
                      final movimientos = convertirPGNaHistorial(p.pgn);

                      // 2) Leer tu userId
                      final prefs  = await SharedPreferences.getInstance();
                      final userId = prefs.getString('idJugador') ?? '';

                      // 3) Extraer alias blancas/negras del PGN
                      final whiteId = RegExp(r'\[White "(.*?)"\]').firstMatch(p.pgn)?.group(1) ?? '';
                      final blackId = RegExp(r'\[Black "(.*?)"\]').firstMatch(p.pgn)?.group(1) ?? '';

                      final eresBlancas = whiteId == userId;
                      final rivalId     = eresBlancas ? blackId : whiteId;
                      final url = Uri.parse('${serverBackend}getUserInfo?id=$rivalId');
                      final response = await http.get(url, headers: { "Content-Type": "application/json" });

                        final rivalData = jsonDecode(response.body);
                        String rivalFoto = rivalData['FotoPerfil'] ??
                            'fotoPerfil.png';

                        // aquí puedes usar rivalFoto como quieras

                      final rivalFotoSegura = getRutaSeguraFoto(rivalFoto);


                      final aliasWhite = RegExp(r'\[White Alias "(.*?)"\]').firstMatch(p.pgn)?.group(1) ?? 'Desconocido';
                      final aliasBlack = RegExp(r'\[Black Alias "(.*?)"\]').firstMatch(p.pgn)?.group(1) ?? 'Desconocido';

                      final rivalNombre = eresBlancas ? aliasBlack : aliasWhite;
                      final miNombre= eresBlancas ? aliasWhite : aliasBlack;

                      final myElo    = eresBlancas ? whiteElo : blackElo;
                      final rivalElo = eresBlancas ? blackElo : whiteElo;
                      // 5) Empujar a GameReviewPage con nombre y elos
                      final miFoto = prefs.getString('fotoPerfil') ?? "none";
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GameReviewPage(
                            historial: movimientos,
                            pgn:       p.pgn,
                            rival:     rivalNombre,
                            miElo:     myElo.toString(),
                            rivalElo:  rivalElo.toString(),
                            yo : miNombre,
                            rivalFoto: rivalFotoSegura,
                            miFoto: getRutaSeguraFoto(miFoto),
                          ),
                        ),
                      );
                    },
                    cells: [
                      DataCell(Icon(iconoModo, color: colorModo)),
                      DataCell(Text('${nombres["blancas"]} ($whiteElo)', style: TextStyle(color: Colors.white))),
                      DataCell(Text('${nombres["negras"]} ($blackElo)', style: TextStyle(color: Colors.white))),
                      DataCell(Row(
                        children: [
                          Text(res, style: TextStyle(fontSize: 18)),
                          SizedBox(width: 4),
                          Text('(${variacion >= 0 ? '+' : ''}$variacion)', style: TextStyle(color: Colors.white70)),
                        ],
                      )),
                      DataCell(Text(movimiento.toString(), style: TextStyle(color: Colors.white))),
                      DataCell(Text(fechaFmt, style: TextStyle(color: Colors.white))),
                      const DataCell(Icon(Icons.visibility, color: Colors.blueAccent)),
                    ],
                  );
                }).toList(),
              )
              ),
          ),
        ],
      ),
    );
  }

  Future<bool> updateUserName(String newName) async {
    if (userId == null || serverBackend == null) {
      return false;
    }

    final url = Uri.parse('${serverBackend}editUser');

    final bodyData = jsonEncode({
      "id": userId,
      "NombreUser": newName,
      "FotoPerfil": profileImage,
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: bodyData,
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (error) {
      return false;
    }
  }

  void _showEditNameDialog() {
    final TextEditingController _nameController = TextEditingController(text: playerName);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Colors.blueAccent, width: 1.5),
          ),
          title: Row(
            children: [
              Icon(Icons.edit, color: Colors.blueAccent),
              SizedBox(width: 8),
              Text('Editar nombre', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: TextField(
            controller: _nameController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Nuevo nombre',
              labelStyle: TextStyle(color: Colors.white70),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blueAccent),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blueAccent),
              ),
            ),
            cursorColor: Colors.blueAccent,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar', style: TextStyle(color: Colors.blueAccent)),
            ),
            TextButton(
              onPressed: () async {
                String newName = _nameController.text;
                bool success = await updateUserName(newName);
                if (success) {
                  setState(() {
                    playerName = newName;
                  });
                  Navigator.of(context).pop();
                } else {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: Colors.grey[900],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: Colors.blueAccent, width: 1.5),
                      ),
                      title: Text('Error', style: TextStyle(color: Colors.white)),
                      content: Text(
                        'El nombre de usuario "$newName" ya está en uso',
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                          },
                          child: Text('OK', style: TextStyle(color: Colors.blueAccent)),
                        ),
                      ],
                    ),
                  );
                }
              },
              child: Text('Guardar', style: TextStyle(color: Colors.blueAccent)),
            ),
          ],
        );
      },
    );
  }

  void _showEditPhotoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Colors.blueAccent, width: 1.5),
          ),
          title: Row(
            children: [
              Icon(Icons.image, color: Colors.blueAccent),
              SizedBox(width: 8),
              Text("Foto de perfil", style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: multiavatarImages.length,
              itemBuilder: (context, index) {
                String imageFileName = multiavatarImages[index];
                String imagePath = "assets/fotosPerfil/$imageFileName";
                return GestureDetector(
                  onTap: () async {
                    setState(() {
                      profileImage = imageFileName;
                    });
                    bool success = await updateProfilePhoto(imageFileName);
                    if (!success) {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: Colors.grey[900],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(color: Colors.blueAccent, width: 1.5),
                          ),
                          title: Text("Error", style: TextStyle(color: Colors.white)),
                          content: Text(
                            "La foto de perfil no se pudo actualizar.",
                            style: TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: Text("OK", style: TextStyle(color: Colors.blueAccent)),
                            ),
                          ],
                        ),
                      );
                    }
                    Navigator.of(context).pop();
                  },
                  child: Image.asset(imagePath),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancelar", style: TextStyle(color: Colors.blueAccent)),
            ),
          ],
        );
      },
    );
  }

  Future<bool> updateProfilePhoto(String newPhotoName) async {
    if (userId == null || serverBackend == null) {
      return false;
    }

    final url = Uri.parse('${serverBackend}editUser');

    final bodyData = jsonEncode({
      "id": userId,
      "NombreUser": playerName,  // Mantenemos el nombre actual
      "FotoPerfil": newPhotoName  // Solo el nombre de la imagen
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: bodyData,
      );
      if (response.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('fotoPerfil', "$newPhotoName");
        return true;
      } else {
        return false;
      }
    } catch (error) {
      return false;
    }
  }
}
