import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hitbabe/Screens/Information.dart';
import 'package:hitbabe/models/user_model.dart';
import 'package:hitbabe/util/color.dart';

import 'Tab.dart';

class Nearby1 extends StatefulWidget {
  final User currentUser;
  Nearby1(this.currentUser);

  @override
  _Nearby1State createState() => _Nearby1State();
}

class _Nearby1State extends State<Nearby1> {
  final db = Firestore.instance;
  CollectionReference matchReference;

  @override
  void initState() {
    matchReference = db
        .collection("Users")
        .document(widget.currentUser.id)
        .collection("CheckedUser");

    super.initState();
    // Future.delayed(Duration(seconds: 1), () {
    //   if (widget.notification.length > 1) {
    //     widget.notification.sort((a, b) {
    //       var adate = a.time; //before -> var adate = a.expiry;
    //       var bdate = b.time; //before -> var bdate = b.expiry;
    //       return bdate.compareTo(
    //           adate); //to get the order other way just switch `adate & bdate`
    //     });
    //   }
    // });
    // if (mounted) setState(() {});
  }

  void abc(DocumentSnapshot doc) async {
    print(widget.currentUser.coordinates);
    showDialog(
        context: context,
        builder: (context) {
          return Center(
              child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ));
        });
    DocumentSnapshot userdoc = (db
        .collection('Users')
        .snapshots(includeMetadataChanges: true)) as DocumentSnapshot;

    print(userdoc.exists);
    if (userdoc.exists) {
      Navigator.pop(context);
      User tempuser = User.fromDocument(userdoc);
      print(tempuser);
      tempuser.distanceBW = calculateDistance(
              widget.currentUser.coordinates['latitude'],
              widget.currentUser.coordinates['longitude'],
              tempuser.coordinates['latitude'],
              tempuser.coordinates['longitude'])
          .round();

      await showDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) {
            return Info(tempuser, widget.currentUser, null);
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            'Nearby',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          elevation: 0,
        ),
        backgroundColor: primaryColor,
        body: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(50),
                topRight: Radius.circular(50),
              ),
              color: Colors.white),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(50),
              topRight: Radius.circular(50),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Padding(
                //   padding: const EdgeInsets.all(10),
                //   child: Text(
                //     'this week',
                //     style: TextStyle(
                //       color: primaryColor,
                //       fontSize: 18.0,
                //       fontWeight: FontWeight.bold,
                //       letterSpacing: 1.0,
                //     ),
                //   ),
                // ),
                StreamBuilder<QuerySnapshot>(
                    stream: db
                        .collection('Users')
                        .snapshots(includeMetadataChanges: true),
                    builder: (BuildContext context,
                        AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (!snapshot.hasData)
                        return Center(
                            child: Text(
                          "No Notification",
                          style: TextStyle(color: secondryColor, fontSize: 16),
                        ));
                      else if (snapshot.data.documents.length == 0) {
                        return Center(
                            child: Text(
                          "No Notification",
                          style: TextStyle(color: secondryColor, fontSize: 16),
                        ));
                      }
                      return Flexible(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: GridView.count(
                            scrollDirection: Axis.vertical,
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            padding: const EdgeInsets.all(8.0),
                            mainAxisSpacing: 10.0,
                            crossAxisSpacing: 25.0,
                            children: snapshot.data.documents.map((document) {
                              return InkWell(
                                onTap: () async {
                                  print(widget.currentUser.maxDistance);
                                  showDialog(
                                      context: context,
                                      builder: (context) {
                                        return Center(
                                            child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ));
                                      });

                                  if (document.exists) {
                                    Navigator.pop(context);
                                    User tempuser = User.fromDocument(document);
                                    print(tempuser);
                                    tempuser.distanceBW = calculateDistance(
                                            widget.currentUser
                                                .coordinates['latitude'],
                                            widget.currentUser
                                                .coordinates['longitude'],
                                            tempuser.coordinates['latitude'],
                                            tempuser.coordinates['longitude'])
                                        .round();

                                    await showDialog(
                                        barrierDismissible: false,
                                        context: context,
                                        builder: (context) {
                                          return Info(tempuser,
                                              widget.currentUser, null);
                                        });
                                  }
                                },
                                child: CachedNetworkImage(
                                  fit: BoxFit.cover,
                                  imageUrl: document.data['Pictures'][0] ?? '',
                                  useOldImageOnUrlChange: true,
                                  placeholder: (context, url) =>
                                      CupertinoActivityIndicator(
                                    radius: 5,
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                  imageBuilder: (context, imageProvider) =>
                                      Container(
                                    alignment: Alignment.bottomCenter,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(10),
                                      image: DecorationImage(
                                          image: imageProvider,
                                          fit: BoxFit.cover),
                                    ),
                                    child: Container(
                                      width: 170,
                                      height: 40,
                                      color: Colors.white.withOpacity(0.4),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: FittedBox(
                                          child: Column(
                                            children: [
                                              new Text(
                                                  document.data['UserName'] !=
                                                          null
                                                      ? document
                                                          .data['UserName']
                                                      : "User",
                                                  style: TextStyle(
                                                    fontSize: 30,
                                                    color: Colors.grey[800],
                                                    fontWeight: FontWeight.w900,
                                                  )),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    })
              ],
            ),
          ),
        ));
  }
}
