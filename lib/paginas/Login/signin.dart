import 'package:flutter/material.dart';
import 'package:frontend_android/paginas/Login/login.dart';

class Signin_page extends StatefulWidget {
  static const String id = 'signin_page';

  @override
  _SigninPageState createState() => _SigninPageState();
}

class _SigninPageState extends State<Signin_page> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _mensajeError = '';

  void _registrarUsuario() {
    String name = _nameController.text;
    String surname = _surnameController.text;
    String user = _userController.text;
    String password = _passwordController.text;

    if (name.isEmpty || surname.isEmpty || user.isEmpty || password.isEmpty) {
      setState(() {
        _mensajeError = "Todos los campos son obligatorios";
      });
    } else {
      setState(() {
        _mensajeError = "";
      });
      print('Registro con: $name $surname ($user)');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xff3A3A3A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "CheckMates",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20.0),

              // Fila de botones (Login y Sign In)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Login_page()),
                      );
                    },
                    child: Text(
                      'Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    'Sign In',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 30),
              _textFieldName(),
              SizedBox(height: 15.0),
              _textFieldSurname(),
              SizedBox(height: 15.0),
              _textFieldUser(),
              SizedBox(height: 15.0),
              _textFieldPassword(),
              SizedBox(height: 10.0),

              if (_mensajeError.isNotEmpty)
                Text(
                  _mensajeError,
                  style: TextStyle(color: Colors.red),
                ),

              SizedBox(height: 15.0),
              _buttonLogin(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textFieldName() {
    return Container(
      color: Colors.white,
      margin: EdgeInsets.symmetric(horizontal: 30.0),
      child: TextField(
        controller: _nameController,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.text_fields),
          labelText: "Name",
        ),
      ),
    );
  }

  Widget _textFieldSurname() {
    return Container(
      color: Colors.white,
      margin: EdgeInsets.symmetric(horizontal: 30.0),
      child: TextField(
        controller: _surnameController,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.text_fields_outlined),
          labelText: "Surname",
        ),
      ),
    );
  }

  Widget _textFieldUser() {
    return Container(
      color: Colors.white,
      margin: EdgeInsets.symmetric(horizontal: 30.0),
      child: TextField(
        controller: _userController,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.person_outline),
          labelText: "User",
        ),
      ),
    );
  }

  Widget _textFieldPassword() {
    return Container(
      color: Colors.white,
      margin: EdgeInsets.symmetric(horizontal: 30.0),
      child: TextField(
        controller: _passwordController,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.lock),
          labelText: "Password",
        ),
        obscureText: true,
      ),
    );
  }

  Widget _buttonLogin() {
    return ElevatedButton(
      onPressed: _registrarUsuario,
      child: Text('Sign in'),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
