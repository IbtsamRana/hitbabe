import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hitbabe/Screens/Splash.dart';
import 'package:hitbabe/Screens/Tab.dart';
import 'package:hitbabe/Screens/Welcome.dart';
import 'package:hitbabe/Screens/auth/login.dart';
import 'package:hitbabe/ads/ads.dart';
import 'package:hitbabe/util/color.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitDown,
    DeviceOrientation.portraitUp,
  ]).then((_) {
    InAppPurchaseConnection.enablePendingPurchases();
    runApp(new MyApp());
  });
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isLoading = true;
  bool isAuth = false;
  bool isRegistered = false;

  @override
  void initState() {
    super.initState();

    _checkAuth();
    FirebaseAdMob.instance
        .initialize(appId: Platform.isAndroid ? androidAdAppId : iosAdAppId);
  }

  Future _checkAuth() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    _auth.currentUser().then((FirebaseUser user) async {
      print(user);
      if (user != null) {
        await Firestore.instance
            .collection('Users')
            .where('userId', isEqualTo: user.uid)
            .getDocuments()
            .then((QuerySnapshot snapshot) async {
          if (snapshot.documents.length > 0) {
            if (snapshot.documents[0].data['location'] != null) {
              setState(() {
                isRegistered = true;
                isLoading = false;
              });
            } else {
              setState(() {
                isAuth = true;
                isLoading = false;
              });
            }
            print("loggedin ${user.uid}");
          } else {
            setState(() {
              isLoading = false;
            });
          }
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  @override
  Future notificationSelected(String payload) async {}
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: primaryColor,
      ),
      home: isLoading
          ? Splash()
          : isRegistered
              ? Tabbar(null, null)
              : isAuth
                  ? Welcome()
                  : Login(),
    );
  }
}
