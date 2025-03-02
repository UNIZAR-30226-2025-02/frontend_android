import 'package:flutter/material.dart';
import 'package:frontend_android/paginas/Login/signin.dart';

//Clase que implementa el inicio de sesion del usuario
class Login_page extends StatelessWidget {
  static const String id = "login_page";

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xff3A3A3A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("CheckMates",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,

                ),
              ),
              SizedBox(
                height: 20.0,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
                    onTap:(){
                      print('objet');
                    }
                    ,
                    child:Text('Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,)),),
                GestureDetector(
                  onTap:(){
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Signin_page()),  // Cambia HomePage() por la página a la que quieres ir
                    );

                  }
                    ,
                 child: Text('Sign In',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,)
                  )
                )
                ],
              ),
              SizedBox(
                height: 25.0,
              ),
              _textFieldUser(),
              SizedBox(
                height: 15.0,
              ),
              _textFieldPassword(),
              SizedBox(
                height: 15.0,
              ),
              _buttonLogin(),
            ],
          ),
        ),
      ),
    );
  }


  Widget _textFieldUser() {
    return Container(
      color: Colors.white,
      margin: EdgeInsets.symmetric(
        horizontal: 30.0,
      ),
      child: TextField(
        decoration: InputDecoration(
            prefixIcon: Icon(Icons.person_outline),
            labelText: "User"
        ),
      ),
    );
  }

  Widget _textFieldPassword() {
    return Container(
      color: Colors.white,
      margin: EdgeInsets.symmetric(
        horizontal: 30.0,
      ),
      child: TextField(
        decoration: InputDecoration(
            prefixIcon: Icon(Icons.lock),
            labelText: "Password"
        ),
      ),
    );
  }

  Widget _buttonLogin() {
    return ElevatedButton(
      onPressed: () {
        print('Botón presionado');
      },
      child: Text('Login'),
    );
  }
}