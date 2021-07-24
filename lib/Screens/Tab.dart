import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hitbabe/Screens/Profile/profile.dart';
import 'package:hitbabe/Screens/Splash.dart';
import 'package:hitbabe/Screens/blockUserByAdmin.dart';
import 'package:hitbabe/Screens/notifications.dart';
import 'package:hitbabe/Screens/nearby1.dart';
import 'package:hitbabe/ads/ads.dart';
import 'package:hitbabe/models/user_model.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'Calling/incomingCall.dart';
import 'Chat/home_screen.dart';
import 'Home.dart';
import 'package:hitbabe/util/color.dart';

List likedByList = [];

class Tabbar extends StatefulWidget {
  final bool isPaymentSuccess;
  final String plan;
  Tabbar(this.plan, this.isPaymentSuccess);
  @override
  TabbarState createState() => TabbarState();
}

// Future<dynamic> myBackgroundHandler(Map<String, dynamic> message) {
//   return TabbarState()._showNotification(message);
// }

//_
class TabbarState extends State<Tabbar> {
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  CollectionReference docRef = Firestore.instance.collection('Users');
  FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  User currentUser;
  List<User> matches = [];
  List<User> newmatches = [];

  List<User> users = [];

  /// Past purchases
  List<PurchaseDetails> purchases = [];
  InAppPurchaseConnection _iap = InAppPurchaseConnection.instance;
  bool isPuchased = false;
  // FlutterLocalNotificationsPlugin fltrNotification;
  @override
  void initState() {
    super.initState();
    // var androidInitializa = new AndroidInitializationSettings("hookup4ulogobp");
    // var iOSinitialize = new IOSInitializationSettings();
    // var initializationSettings =
    //     new InitializationSettings(androidInitializa, iOSinitialize);
    // fltrNotification = new FlutterLocalNotificationsPlugin();
    // fltrNotification.initialize(initializationSettings,
    //     onSelectNotification: null);

    // Show payment success alert.
    if (widget.isPaymentSuccess != null && widget.isPaymentSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Alert(
          context: context,
          type: AlertType.success,
          title: "Confirmation",
          desc: "You have successfully subscribed to our ${widget.plan} plan.",
          buttons: [
            DialogButton(
              child: Text(
                "Ok",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              onPressed: () => Navigator.pop(context),
              width: 120,
            )
          ],
        ).show();
      });
    }
    _getAccessItems();
    _getCurrentUser();
    _getMatches();
    _getpastPurchases();
  }

  Map items = {};
  _getAccessItems() async {
    Firestore.instance.collection("Item_access").snapshots().listen((doc) {
      if (doc.documents.length > 0) {
        items = doc.documents[0].data;
        print(doc.documents[0].data);
      }

      if (mounted) setState(() {});
    });
  }

  Future<void> _getpastPurchases() async {
    print('in past purchases');
    QueryPurchaseDetailsResponse response = await _iap.queryPastPurchases();
    print('response   ${response.pastPurchases}');
    for (PurchaseDetails purchase in response.pastPurchases) {
      // if (Platform.isIOS) {
      await _iap.completePurchase(purchase);
      // }
    }
    setState(() {
      purchases = response.pastPurchases;
    });
    if (response.pastPurchases.length > 0) {
      purchases.forEach((purchase) async {
        print('   ${purchase.productID}');
        await _verifyPuchase(purchase.productID);
      });
    }
  }

  /// check if user has pruchased
  PurchaseDetails _hasPurchased(String productId) {
    return purchases.firstWhere((purchase) => purchase.productID == productId,
        orElse: () => null);
  }

  ///verifying pourchase of user
  Future<void> _verifyPuchase(String id) async {
    PurchaseDetails purchase = _hasPurchased(id);

    if (purchase != null && purchase.status == PurchaseStatus.purchased) {
      print(purchase.productID);
      if (Platform.isIOS) {
        await _iap.completePurchase(purchase);
        print('Achats antérieurs........$purchase');
        isPuchased = true;
      }
      isPuchased = true;
    } else {
      isPuchased = false;
    }
  }

  int swipecount = 0;
  _getSwipedcount() {
    Firestore.instance
        .collection('/Users/${currentUser.id}/CheckedUser')
        .where(
          'timestamp',
          isGreaterThan: Timestamp.now().toDate().subtract(Duration(days: 1)),
        )
        .snapshots()
        .listen((event) {
      print(event.documents.length);
      setState(() {
        swipecount = event.documents.length;
      });
      return event.documents.length;
    });
  }

  configurePushNotification(User user) async {
    await _firebaseMessaging.requestNotificationPermissions(
        IosNotificationSettings(
            alert: true, sound: true, provisional: false, badge: true));

    _firebaseMessaging.getToken().then((token) {
      print("token");
      print(token);
      docRef.document(user.id).updateData({
        'pushToken': token,
      });
    });

    _firebaseMessaging.configure(
      onLaunch: (Map<String, dynamic> message) async {
        print('===============onLaunch$message');
        if (Platform.isIOS && message['type'] == 'Call') {
          Map callInfo = {};
          callInfo['channel_id'] = message['channel_id'];
          callInfo['senderName'] = message['senderName'];
          callInfo['senderPicture'] = message['senderPicture'];
          bool iscallling = await _checkcallState(message['channel_id']);
          print("=================$iscallling");
          if (iscallling) {
            await Navigator.push(context,
                MaterialPageRoute(builder: (context) => Incoming(message)));
          }
        } else if (Platform.isAndroid && message['data']['type'] == 'Call') {
          bool iscallling =
              await _checkcallState(message['data']['channel_id']);
          print("=================$iscallling");
          if (iscallling) {
            await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Incoming(message['data'])));
          } else {
            print("Timeout");
          }
        }
      },
      // onBackgroundMessage: myBackgroundHandler,
      onMessage: (Map<String, dynamic> message) async {
        print("onmessage$message");
        if (Platform.isIOS && message['type'] == 'Call') {
          Map callInfo = {};
          callInfo['channel_id'] = message['channel_id'];
          callInfo['senderName'] = message['senderName'];
          callInfo['senderPicture'] = message['senderPicture'];

          await Navigator.push(context,
              MaterialPageRoute(builder: (context) => Incoming(callInfo)));
        } else if (Platform.isAndroid && message['data']['type'] == 'Call') {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => Incoming(message['data'])));
        } else
          print("object1");
        // _showNotification(message);
      },
      onResume: (Map<String, dynamic> message) async {
        print('onResume$message');
        if (Platform.isIOS && message['type'] == 'Call') {
          Map callInfo = {};
          callInfo['channel_id'] = message['channel_id'];
          callInfo['senderName'] = message['senderName'];
          callInfo['senderPicture'] = message['senderPicture'];
          bool iscallling = await _checkcallState(message['channel_id']);
          print("=================$iscallling");
          if (iscallling) {
            await Navigator.push(context,
                MaterialPageRoute(builder: (context) => Incoming(message)));
          }
        } else if (Platform.isAndroid && message['data']['type'] == 'Call') {
          bool iscallling =
              await _checkcallState(message['data']['channel_id']);
          print("=================$iscallling");
          if (iscallling) {
            await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Incoming(message['data'])));
          } else {
            print("Timeout");
          }
        }
      },
    );
  }

  _checkcallState(channelId) async {
    bool iscalling = await Firestore.instance
        .collection("calls")
        .document(channelId)
        .get()
        .then((value) {
      return value.data["calling"] ?? false;
    });
    return iscalling;
  }

  _getMatches() async {
    FirebaseUser user = await _firebaseAuth.currentUser();
    return Firestore.instance
        .collection('/Users/${user.uid}/Matches')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((ondata) {
      matches.clear();
      newmatches.clear();
      if (ondata.documents.length > 0) {
        ondata.documents.forEach((f) async {
          DocumentSnapshot doc = await docRef.document(f.data['Matches']).get();
          if (doc.exists) {
            User tempuser = User.fromDocument(doc);
            tempuser.distanceBW = calculateDistance(
                    currentUser.coordinates['latitude'],
                    currentUser.coordinates['longitude'],
                    tempuser.coordinates['latitude'],
                    tempuser.coordinates['longitude'])
                .round();

            matches.add(tempuser);
            newmatches.add(tempuser);
            if (mounted) setState(() {});
          }
        });
      }
    });
  }

  _getCurrentUser() async {
    FirebaseUser user = await _firebaseAuth.currentUser();
    return docRef.document("${user.uid}").snapshots().listen((data) async {
      currentUser = User.fromDocument(data);
      if (mounted) setState(() {});
      users.clear();
      userRemoved.clear();
      getUserList();
      getLikedByList();
      configurePushNotification(currentUser);
      if (!isPuchased) {
        _getSwipedcount();
      }
      return currentUser;
    });
  }

  query() {
    if (currentUser.showGender == 'everyone') {
      return docRef
          .where(
            'age',
            isGreaterThanOrEqualTo: int.parse(currentUser.ageRange['min']),
          )
          .where('age',
              isLessThanOrEqualTo: int.parse(currentUser.ageRange['max']))
          .orderBy('age', descending: false);
    } else {
      return docRef
          .where('editInfo.userGender', isEqualTo: currentUser.showGender)
          .where(
            'age',
            isGreaterThanOrEqualTo: int.parse(currentUser.ageRange['min']),
          )
          .where('age',
              isLessThanOrEqualTo: int.parse(currentUser.ageRange['max']))
          //FOR FETCH USER WHO MATCH WITH USER SEXUAL ORIENTAION
          // .where('sexualOrientation.orientation',
          //     arrayContainsAny: currentUser.sexualOrientation)
          .orderBy('age', descending: false);
    }
  }

  Future getUserList() async {
    List checkedUser = [];
    Firestore.instance
        .collection('/Users/${currentUser.id}/CheckedUser')
        .getDocuments()
        .then((data) {
      checkedUser.addAll(data.documents.map((f) => f['DislikedUser']));
      checkedUser.addAll(data.documents.map((f) => f['LikedUser']));
    }).then((_) {
      query().getDocuments().then((data) async {
        if (data.documents.length < 1) {
          print("no more data");
          return;
        }
        users.clear();
        userRemoved.clear();
        for (var doc in data.documents) {
          User temp = User.fromDocument(doc);
          var distance = calculateDistance(
              currentUser.coordinates['latitude'],
              currentUser.coordinates['longitude'],
              temp.coordinates['latitude'],
              temp.coordinates['longitude']);
          temp.distanceBW = distance.round();
          if (checkedUser.any(
            (value) => value == temp.id,
          )) {
          } else {
            if (distance <= currentUser.maxDistance &&
                temp.id != currentUser.id &&
                !temp.isBlocked) {
              users.add(temp);
            }
          }
        }
        if (mounted) setState(() {});
      });
    });
  }

  getLikedByList() {
    docRef
        .document(currentUser.id)
        .collection("LikedBy")
        .snapshots()
        .listen((data) async {
      likedByList.addAll(data.documents.map((f) => f['LikedBy']));
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        return showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Exit'),
              content: Text('Do you want to exit the app?'),
              actions: <Widget>[
                FlatButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('No'),
                ),
                FlatButton(
                  onPressed: () => SystemChannels.platform
                      .invokeMethod('SystemNavigator.pop'),
                  child: Text('Yes'),
                ),
              ],
            );
          },
        );
      },
      child: Scaffold(
        body: currentUser == null
            ? Center(child: Splash())
            : currentUser.isBlocked
                ? BlockUser()
                : DefaultTabController(
                    length: 5,
                    initialIndex: widget.isPaymentSuccess != null
                        ? widget.isPaymentSuccess
                            ? 0
                            : 1
                        : 1,
                    child: Scaffold(
                        bottomNavigationBar: BottomAppBar(
                          color: primaryColor,
                          elevation: 0,
                          // backgroundColor: primaryColor,
                          // automaticallyImplyLeading: false,
                          child: TabBar(
                              labelColor: Colors.white,
                              indicatorColor: Colors.white,
                              unselectedLabelColor: Colors.black,
                              isScrollable: false,
                              indicatorSize: TabBarIndicatorSize.label,
                              tabs: [
                                Tab(
                                  icon: Icon(
                                    Icons.person,
                                    size: 30,
                                  ),
                                ),
                                Tab(
                                  icon: Icon(
                                    Icons.whatshot,
                                  ),
                                ),
                                Tab(
                                  icon: Icon(
                                    Icons.notifications,
                                  ),
                                ),
                                Tab(
                                  icon: Icon(Icons.pin_drop_rounded),
                                ),
                                Tab(
                                  icon: Icon(
                                    Icons.mail,
                                  ),
                                )
                              ]),
                        ),
                        body: TabBarView(
                          children: [
                            Center(
                                child: Profile(
                                    currentUser, isPuchased, purchases, items)),
                            Center(
                                child: CardPictures(
                                    currentUser, users, swipecount, items)),
                            Center(child: Notifications(currentUser)),
                            Center(child: Nearby1(currentUser)),
                            Center(
                                child: HomeScreen(
                                    currentUser, matches, newmatches)),
                          ],
                          physics: NeverScrollableScrollPhysics(),
                        )),
                  ),
      ),
    );
  }

  // Future _showNotification(Map<String, dynamic> message) async {
  //   print("show notification is called");
  //   var androidDetails = new AndroidNotificationDetails(
  //       "channel ID", "channelName", "channelDescription",
  //       playSound: true,
  //       visibility: NotificationVisibility.Public,
  //       priority: Priority.High,
  //       importance: Importance.High);
  //   var iOSDetails = new IOSNotificationDetails();
  //   var generalNotificationDetails =
  //       new NotificationDetails(androidDetails, iOSDetails);
  //   await fltrNotification.show(0, "title", "body", generalNotificationDetails);
  // }
}

double calculateDistance(lat1, lon1, lat2, lon2) {
  var p = 0.017453292519943295;
  var c = cos;
  var a = 0.5 -
      c((lat2 - lat1) * p) / 2 +
      c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
  return 12742 * asin(sqrt(a));
}
