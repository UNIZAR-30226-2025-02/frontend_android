import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend_android/widgets/app_layout.dart';
import 'package:frontend_android/pages/Game/botton_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../utils/photoUtils.dart';


class Ranking_page extends StatefulWidget {
  static const String id = "ranking_page";

  @override
  _RankingPageState createState() => _RankingPageState();
}

class _RankingPageState extends State<Ranking_page> {
  String? serverBackend;
  String? userId;
  String? userName;
  String? fotoPerfilLocal;

  final List<Map<String, dynamic>> modos = [
    {
      'icon': Icons.extension,
      'titulo': 'Clásica',
      'modo': 'Punt_10',
      'color': Colors.brown,
    },
    {
      'icon': Icons.verified,
      'titulo': 'Principiante',
      'modo': 'Punt_30',
      'color': Colors.green,
    },
    {
      'icon': Icons.timer_off,
      'titulo': 'Avanzado',
      'modo': 'Punt_5',
      'color': Colors.red,
    },
    {
      'icon': Icons.bolt,
      'titulo': 'Relámpago',
      'modo': 'Punt_3',
      'color': Colors.yellow,
    },
    {
      'icon': Icons.trending_up,
      'titulo': 'Incremento',
      'modo': 'Punt_5_10',
      'color': Colors.green,
    },
    {
      'icon': Icons.star,
      'titulo': 'Incremento exprés',
      'modo': 'Punt_3_2',
      'color': Colors.yellow,
    },
  ];

  @override
  void initState() {
    super.initState();
    initUserData();
  }

  Future<void> initUserData() async {
    final prefs = await SharedPreferences.getInstance();
    serverBackend = dotenv.env['SERVER_BACKEND'];
    userId = prefs.getString('idJugador');
    fotoPerfilLocal = prefs.getString('fotoPerfil');

    if (serverBackend != null && userId != null) {
      final res = await http.get(Uri.parse('${serverBackend}getUserInfo?id=$userId'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          userName = data['NombreUser'];
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> fetchRanking(String modo) async {
    final res = await http.get(Uri.parse('${serverBackend}rankingPorModo?modo=$modo'));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      print("🔍 Datos recibidos para modo $modo:");
      for (var jugador in data) {
        print(jugador); // imprime cada jugador individualmente
      }
      return data.cast<Map<String, dynamic>>();
    } else {
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchUserRank(String modo) async {
    if (userName == null) return null;
    final res = await http.get(Uri.parse('${serverBackend}rankingUserPorModo?modo=$modo&user=$userName'));
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      return null;
    }
  }

  String _formatearPuntuacion(dynamic valor) {
    if (valor == null || valor == 'NULL') return '0.00';

    final doubleValor = double.tryParse(valor.toString()) ?? 0.0;
    return doubleValor.toStringAsFixed(2);
  }

  Color getPodiumColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return Colors.white;
    }
  }

  void _mostrarRankingPopUp(BuildContext context, String modo, String titulo) async {
    final ranking = await fetchRanking(modo);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Top 10 - $titulo',
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              for (var player in ranking)
                ListTile(
                  leading: Text(
                    '${player['rank']}°',
                    style: TextStyle(
                      color: getPodiumColor(player['rank']),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  title: Text(
                    player['nombre'],
                    style: TextStyle(
                      color: getPodiumColor(player['rank']),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  trailing: Text(
                    _formatearPuntuacion(player['puntuacion']),
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      child: Container(
        color: Colors.grey[900],
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              color: Colors.grey[900],
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RANKING',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Colors.white,
                    ),
                  ),
                  Icon(Icons.emoji_events, color: Colors.white, size: 36),
                ],
              ),
            ),
            Expanded(
              child: userName == null
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: modos.length,
                itemBuilder: (context, index) {
                  final modo = modos[index];
                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: fetchRanking(modo['modo']),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return _loadingCard();
                      final ranking = snapshot.data!;
                      return FutureBuilder<Map<String, dynamic>?>(
                        future: fetchUserRank(modo['modo']),
                        builder: (context, userSnap) {
                          final userRank = userSnap.data;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: GestureDetector(
                              onTap: () {
                                _mostrarRankingPopUp(context, modo['modo'], modo['titulo']);
                              },
                              child: _buildRankingCard(
                                icon: modo['icon'],
                                titulo: modo['titulo'],
                                modo: modo['modo'],
                                ranking: ranking.take(4).toList(),
                                currentUser: userRank,
                              ),
                            ),

                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            BottomNavBar(currentIndex: 1),
          ],
        ),
      ),
    );
  }

  Widget _loadingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
    );
  }

  Widget _buildRankingCard({
    required IconData icon,
    required String titulo,
    required String modo,
    required List<Map<String, dynamic>> ranking,
    required Map<String, dynamic>? currentUser,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blueAccent, size: 30),
              const SizedBox(width: 12),
              Text(
                titulo,
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...ranking.map((player) => _buildPlayerRow(player, modo)),
          const SizedBox(height: 12),
          if (currentUser != null) _buildCurrentUserRow(currentUser),
        ],
      ),
    );
  }

  Widget _buildPlayerRow(Map<String, dynamic> player, String modo) {
    final pos = player['rank'];
    final color = pos == 1
        ? Colors.amber
        : pos == 2
        ? Colors.grey
        : pos == 3
        ? Colors.brown
        : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${pos}° ${player['nombre']}',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          Text(
            _formatearPuntuacion(player['puntuacion']),
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentUserRow(Map<String, dynamic> user) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: AssetImage(getRutaSeguraFoto(fotoPerfilLocal)),
            backgroundColor: Colors.blueAccent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['nombre'],
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '#${user['rank']}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Text(
            '${_formatearPuntuacion(user['puntuacion'])}',
            style: const TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}