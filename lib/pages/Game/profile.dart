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
  // Nuevo valor por defecto usando la nueva ruta:
  String profileImage = "assets/fotosPerfil/fotoPerfil.png";
  int friends = 0;
  int gamesPlayed = 0;
  double winRate = 0.0;
  int maxStreak = 0;

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
    try {
      final response = await http.get(url, headers: {
        "Content-Type": "application/json",
        // Agrega autorización si fuera necesario, por ejemplo: "Authorization": "Bearer $token"
      });
      if (response.statusCode == 200) {
        // Se espera que el backend retorne un JSON que incluya las siguientes propiedades:
        // "NombreUser", "FotoPerfil", "friends", "gamesPlayed", "winRate" y "maxStreak"
        final data = jsonDecode(response.body);
        setState(() {
          playerName = data['NombreUser'] ?? playerName;
          // Si la foto de perfil es "none", usamos la imagen predeterminada con la nueva ruta.
          profileImage = (data['FotoPerfil'] != null && data['FotoPerfil'] != "none")
              ? data['FotoPerfil'] // Se espera solo el nombre del archivo
              : "assets/fotosPerfil/fotoPerfil.png";

          // Actualizamos las estadísticas si existen; de lo contrario, se mantiene el valor por defecto.
          friends = data['friends'] ?? friends;
          gamesPlayed = data['gamesPlayed'] ?? gamesPlayed;
          winRate = (data['winRate'] != null) ? (data['winRate'] as num).toDouble() : winRate;
          maxStreak = data['maxStreak'] ?? maxStreak;
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
              // Avatar: para mostrar la imagen en la UI, si profileImage es solo el nombre, concatenamos la ruta.
              CircleAvatar(
                radius: 35,
                backgroundImage: AssetImage("assets/fotosPerfil/$profileImage"),

              ),
              // Botones en una fila aparte
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _showEditPhotoDialog, // Función para editar foto
                    icon: Icon(Icons.image),
                    label: Text('Foto'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                  ),
                  SizedBox(width: 8), // Separación horizontal
                  ElevatedButton.icon(
                    onPressed: _showEditNameDialog, // Función para editar nombre
                    icon: Icon(Icons.edit),
                    label: Text('Nombre'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
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
