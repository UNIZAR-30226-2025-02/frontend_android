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
  // Valor inicial que se muestra hasta que se reciba el dato del backend.
  String playerName = "Cargando...";
  int friends = 10;
  int gamesPlayed = 100;
  double winRate = 55.0;
  int maxStreak = 5;

  // URL base de tu servidor backend
  late final String? serverBackend;

  // ID del usuario (reemplaza este valor por el real o extraídolo del login/local storage)
  late final String? userId;

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
  }

  Future<void> fetchUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('idJugador');
    serverBackend = dotenv.env['SERVER_BACKEND'];
    // Construye la URL para obtener la información, pasando el id del usuario
    final url = Uri.parse('${serverBackend}getUserInfo?id=$userId');
    try {
      final response = await http.get(url, headers: {
        "Content-Type": "application/json",
        // Puedes agregar autorización si es necesario, por ejemplo:
        // "Authorization": "Bearer $token"
      });
      if (response.statusCode == 200) {
        // Se espera que el backend retorne un JSON que incluya "NombreUser"
        final data = jsonDecode(response.body);
        setState(() {
          playerName = data['NombreUser'];
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
              CircleAvatar(
                radius: 35,
                backgroundImage: AssetImage("assets/fotoPerfil.png"),
              ),
              ElevatedButton.icon(
                onPressed: _showEditNameDialog,
                icon: Icon(Icons.edit),
                label: Text('Editar'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
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
        Text(value,
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
              Text(mode,
                  style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  void _showEditNameDialog() {
    // Lógica para editar nombre
  }
}
