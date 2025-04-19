import 'package:flutter/material.dart';


class BuildHeadLogo extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;

  BuildHeadLogo({super.key, this.actions});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent, // Hacemos el fondo transparente
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black,
              Colors.grey[900]!,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.all(3.0),
        child: Image.asset("assets/logo.png", height: 70),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Image.asset(
              "assets/logoNombre.png",
              height: 50,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: actions ?? [const SizedBox(width: 48)],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class BuildHeadArrow extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;

  BuildHeadArrow({super.key, this.actions});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black,
              Colors.grey[900]!,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.pop(context, true); // ✅ devolvemos un "resultado"
        },
      ),
      title: Image.asset("assets/logoNombre.png", height: 50),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}


