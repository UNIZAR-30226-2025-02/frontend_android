import 'package:flutter/material.dart';


class BuildHeadLogo extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;

  BuildHeadLogo({super.key, this.actions});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.asset("assets/logo.png", height: 40),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center, // ✅ Asegura centrado
        children: [
          Expanded(
            child: Image.asset(
              "assets/logoNombre.png",
              height: 40,
            ),
          ),
        ],
      ),
      centerTitle: true, // ✅ Para refuerzo de centrado en algunos casos
      actions: actions ?? [const SizedBox(width: 48)], // ✅ Si no hay `actions`, deja un espacio fijo
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

