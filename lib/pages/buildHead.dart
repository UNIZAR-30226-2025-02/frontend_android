import 'package:flutter/material.dart';

class BuildHeadLogo extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions; // ✅ Se agrega este parámetro opcional

  BuildHeadLogo({super.key, this.actions});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black,
      title: Center(
        child: Image.asset(
          "assets/logoNombre.png",
          height: 40,
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.asset("assets/logo.png", height: 40),
      ),
      actions: actions, // ✅ Ahora puede recibir `actions`
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
      backgroundColor: Colors.grey[850],
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      title: Image.asset("assets/logoNombre.png", height: 40),
    actions: actions,);
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

