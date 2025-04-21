import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:frontend_android/pages/buildHead.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/photoUtils.dart';

class Profile_page extends StatefulWidget {
  static const String id = "profile_page";

  @override
  _ProfilePageState createState() => _ProfilePageState();
}
class UltimaPartida {
  final String modo;        // Código del modo: "Punt_10", etc.
  final String nombreW;     // Nombre del jugador con blancas
  final String nombreB;     // Nombre del jugador con negras
  final String ganadorId;   // ID del jugador que ganó
  final int movimientos;    // Nº de jugadas
  final DateTime fecha;     // Fecha de la partida

  UltimaPartida({
    required this.modo,
    required this.nombreW,
    required this.nombreB,
    required this.ganadorId,
    required this.movimientos,
    required this.fecha,
  });

  factory UltimaPartida.fromJson(Map<String, dynamic> json) {
    return UltimaPartida(
      modo: json['Modo'] ?? '',
      nombreW: json['NombreW'] ?? '',
      nombreB: json['NombreB'] ?? '',
      ganadorId: json['Ganador'].toString(),
      movimientos: json['movimientos'] ?? 0,
      fecha: DateTime.parse(json['created_at']),
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
  List<UltimaPartida> ultimasPartidas = [];

  // URL base del servidor backend (se obtiene de la variable de entorno)
  late final String? serverBackend;
  // ID del usuario (por ejemplo, obtenido de SharedPreferences)
  late final String? userId;

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

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
    fetchStreak();
  }
  Future<void> fetchUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('idJugador');
    serverBackend = dotenv.env['SERVER_BACKEND'];

    if (userId == null || serverBackend == null) {
      print("Falta el id del usuario o la URL del backend");
      return;
    }

    final url = Uri.parse('${serverBackend}getUserInfo?id=$userId');
    try {
      final response = await http.get(url, headers: {
        "Content-Type": "application/json",
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📦 Datos recibidos del backend (getUserInfo): $data');

        setState(() {
          playerName = data['NombreUser'] ?? playerName;
          profileImage = (data['FotoPerfil'] != null && data['FotoPerfil'] != "none")
              ? data['FotoPerfil']
              : "fotoPerfil.png";

          friends = data['Amistades'] ?? friends;
          gamesPlayed = data['totalGames'] ?? gamesPlayed;
          maxStreak = data['maxStreak'] ?? maxStreak;

          int wins = data['totalWins'] ?? 0;
          int losses = data['totalLosses'] ?? 0;
          int draws = data['totalDraws'] ?? 0;
          int total = wins + losses + draws;

          winRate = (total > 0) ? (wins / total) * 100 : 0.0;
        });

        // LLAMADA ADICIONAL: obtener historial de últimas 5 partidas
        final histUrl = Uri.parse('${serverBackend}buscarUlt5PartidasDeUsuario?id=$userId');
        final histResp = await http.get(histUrl);
        if (histResp.statusCode == 200) {
          final List jsonList = jsonDecode(histResp.body);
          setState(() {
            ultimasPartidas = jsonList
                .map((j) => UltimaPartida.fromJson(j as Map<String, dynamic>))
                .toList();
          });
        } else {
          print("❌ Error al obtener historial: ${histResp.statusCode}");
        }

      } else {
        print("❌ Error al obtener el perfil: ${response.statusCode}");
      }
    } catch (error) {
      print("❌ Error en fetchUserInfo: $error");
    }
  }


  void fetchStreak(){

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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileCard(),
            buildWinLossIconsBar(),
            SizedBox(height: 20),
            _buildGameModeCharts(),
          ],
        ),
      ),
    );
  }

  Widget buildWinLossIconsBar() {
    return Container(
      margin: EdgeInsets.only(top: 20),
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
            'Últimos resultados',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              if (index >= ultimasPartidas.length || userId == null) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    Icons.radio_button_unchecked,
                    color: Colors.grey,
                    size: 28,
                  ),
                );
              } else {
                final partida = ultimasPartidas[index];

                // 👇 AQUI ESTA LA CLAVE
                if (partida.ganadorId == null || partida.ganadorId == "null") {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      "-",
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }

                final won = partida.ganadorId == userId;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    won ? Icons.check_circle : Icons.cancel,
                    color: won ? Colors.green : Colors.red,
                    size: 28,
                  ),
                );
              }
            }),
          ),
        ],
      ),
    );
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
          Text(
            playerName,
            style: TextStyle(
              color: Colors.blueAccent,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Divider(color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProfileStat("Amigos", friends.toString()),
              _buildProfileStat("Partidas", gamesPlayed.toString()),
              _buildProfileStat("Victorias", "$winRate%"),
              _buildProfileStat("Racha", maxStreak.toString()),
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
      "Clásica": Icons.extension,
      "Principiante": Icons.verified,
      "Avanzado": Icons.timer_off,
      "Relámpago": Icons.bolt,
      "Incremento": Icons.trending_up,
      "Incremento exprés": Icons.star,
    };

    Map<String, Color> modeColors = {
      "Clásica": Colors.brown,
      "Principiante": Colors.green,
      "Avanzado": Colors.red,
      "Relámpago": Colors.yellow,
      "Incremento": Colors.green,
      "Incremento exprés": Colors.yellow,
    };

    Map<String, List<double>> userData = {
      "Clásica": [4, 5, 6, 4, 3, 5, 4],
      "Principiante": [2, 3, 4],
      "Avanzado": [5, 7, 6, 8, 7, 6, 7, 8, 9, 8],
      "Relámpago": [3, 2],
      "Incremento": [3, 4, 3, 1, 2],
      "Incremento exprés": [],
    };

    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: modeIcons.keys.map((mode) {
        List<double> scores = userData[mode]!;
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
                child: LineChart(
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
                              (e) =>
                              FlSpot(e.key.toDouble(), e.value),
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

  Future<bool> updateUserName(String newName) async {
    if (userId == null || serverBackend == null) {
      print("No se encontró el id del usuario o la URL del backend");
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
        print("Nombre actualizado exitosamente.");
        return true;
      } else {
        print("Error al actualizar el nombre: ${response.statusCode}");
        return false;
      }
    } catch (error) {
      print("Error en la solicitud de actualización: $error");
      return false;
    }
  }

  void _showEditNameDialog() {
    final TextEditingController _nameController = TextEditingController(text: playerName);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('nombre'),
          content: TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nuevo nombre',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
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
                      title: Text('Error'),
                      content: Text('El nombre de usuario "$newName" ya está en uso'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                          },
                          child: Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              },
              child: Text('Guardar'),
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
          title: Text("Selecciona una foto de perfil"),
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
                // Usamos la nueva ruta: assets/fotosPerfil/
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
                          title: Text("Error"),
                          content: Text("La foto de perfil no se pudo actualizar."),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: Text("OK"),
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
              child: Text("Cancelar"),
            ),
          ],
        );
      },
    );
  }

  Future<bool> updateProfilePhoto(String newPhotoName) async {
    if (userId == null || serverBackend == null) {
      print("No se encontró el id del usuario o la URL del backend");
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
        print("Foto actualizada exitosamente.");
        SharedPreferences prefs = await SharedPreferences.getInstance();
        print("$newPhotoName");
        await prefs.setString('fotoPerfil', "$newPhotoName");
        return true;
      } else {
        print("Error al actualizar la foto: ${response.statusCode}");
        return false;
      }
    } catch (error) {
      print("Error en la solicitud de actualización de foto: $error");
      return false;
    }
  }
}
