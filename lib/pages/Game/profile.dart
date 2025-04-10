import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:frontend_android/pages/buildHead.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Profile_page extends StatefulWidget {
  static const String id = "profile_page";

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<Profile_page> {
  // Datos del usuario (valores por defecto)
  String playerName = "Cargando...";
  String profileImage = "assets/fotoPerfil.png";
  int friends = 0;
  int gamesPlayed = 0;
  double winRate = 0.0;
  int maxStreak = 0;
  int actualStreak = 0;

  // URL base del servidor backend (se obtiene de la variable de entorno)
  String? serverBackend;
  // ID del usuario (por ejemplo, obtenido de SharedPreferences)
  String? userId;

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
  }

  Future<void> fetchUserInfo() async {
    // Recuperar el ID del usuario desde SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('idJugador');

    // Obtener la URL del backend desde el archivo .env
    serverBackend = dotenv.env['SERVER_BACKEND'];

    if (userId == null || serverBackend == null) {
      print("Falta el id del usuario o la URL del backend");
      return;
    }

    // Construir la URL para obtener la información, pasando el id del usuario
    final url = Uri.parse('${serverBackend}getUserInfo?id=$userId');

    print("userId: $userId");
    print("serverBackend: $serverBackend");
    print("URL que estoy llamando: ${serverBackend}getUserInfo?id=$userId");

    try {
      final response = await http.get(url, headers: {
        "Content-Type": "application/json",
        // Agrega autorización si fuera necesario, por ejemplo: "Authorization": "Bearer $token"
      });
      print("STATUS CODE: ${response.statusCode}");
      print("RESPONSE BODY: ${response.body}");

      if (response.statusCode == 200) {
        // Se espera que el backend retorne un JSON que incluya las siguientes propiedades:
        // "NombreUser", "FotoPerfil", "friends", "gamesPlayed", "winRate" y "maxStreak"
        final data = jsonDecode(response.body);
        setState(() {
          playerName = data['NombreUser'] ?? playerName;

          profileImage = (data['FotoPerfil'] != null && data['FotoPerfil'] != "none")
              ? data['FotoPerfil']
              : "assets/fotoPerfil.png";

          friends = data['Amistades'] ?? 0;  // Si no lo tenés en el backend aún, ponelo en 0 o quitalo

          gamesPlayed = data['totalGames'] ?? 0;

          // winRate = (victorias / partidas totales) * 100
          winRate = (data['totalGames'] > 0)
              ? ((data['totalWins'] / data['totalGames']) * 100).toDouble()
              : 0.0;

          maxStreak = data['maxStreak'] ?? 0;

          actualStreak = data['actualStreak'] ?? 0;
        });
      } else {
        print("Error al obtener el perfil: ${response.statusCode}");
      }
    } catch (error) {
      print("Error en fetchUserInfo: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: BuildHeadArrow(),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileCard(),
            SizedBox(height: 20),
            _buildGameModeCharts(),
          ],
        ),
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
              // Si profileImage es una URL externa se puede usar NetworkImage, de lo contrario se usa AssetImage.
              CircleAvatar(
                radius: 35,
                backgroundImage: profileImage.startsWith("assets")
                    ? AssetImage(profileImage) as ImageProvider
                    : NetworkImage(profileImage),
              ),
              ElevatedButton.icon(
                onPressed: _showEditNameDialog,
                icon: Icon(Icons.edit, color: Colors.white),
                label: Text('Editar', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              )
            ],
          ),
          SizedBox(height: 10),
          Text(
            playerName,
            style: TextStyle(
                color: Colors.blueAccent,
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),
          Divider(color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProfileStat("Amigos", friends.toString()),
              _buildProfileStat("Partidas", gamesPlayed.toString()),
              _buildProfileStat("% Victoria", "${winRate.toStringAsFixed(2)}%"),
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
    // Aseguramos que ya se hayan cargado userId y serverBackend
    if (userId == null || serverBackend == null) {
      print("No se encontró el id del usuario o la URL del backend");
      return false;
    }

    // Construimos la URL para el endpoint de edición
    final url = Uri.parse('${serverBackend}editUser');

    // Preparamos el cuerpo de la solicitud JSON con los datos requeridos por el backend.
    final bodyData = jsonEncode({
      "id": userId,
      "NombreUser": newName,
      "FotoPerfil": profileImage, // Se envía el valor actual de la foto.
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
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar', style: TextStyle(color: Colors.redAccent)),
            ),
            TextButton(
              onPressed: () async {
                String newName = _nameController.text.trim();

                if (newName.isEmpty) return;

                bool success = await updateUserName(newName);

                if (success) {
                  setState(() {
                    playerName = newName;
                  });
                  Navigator.of(context).pop();
                  Future.delayed(Duration.zero, () {
                    _showSuccessDialog('Nombre actualizado correctamente');
                  });
                } else {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: Colors.grey[900],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: Colors.blueAccent, width: 1.5),
                      ),
                      title: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.redAccent),
                          SizedBox(width: 8),
                          Text('Error', style: TextStyle(color: Colors.white)),
                        ],
                      ),
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

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.blueAccent, width: 1.5),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.greenAccent),
            SizedBox(width: 8),
            Text('Éxito', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          message,
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
}
