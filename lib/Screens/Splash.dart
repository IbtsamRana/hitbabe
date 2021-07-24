import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Splash extends StatefulWidget {
  @override
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Container(
              height: 320,
              width: 400,
              child: Image.asset(
                "asset/HitBabe-Logo-BP.png",
                fit: BoxFit.contain,
              )),
        ));
  }
}
