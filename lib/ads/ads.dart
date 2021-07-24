import 'dart:io';
import 'package:firebase_admob/firebase_admob.dart';

// You can also test with your own ad unit IDs by registering your device as a
// test device. Check the logs for your device's ID value.
const String testDevice = 'YOUR_DEVICE_ID';

//Admob App id's with '~' sign
String androidAdAppId = 'ca-app-pub-9717693213344214~8262650473';
String iosAdAppId = FirebaseAdMob.testAppId;
//Banner unit id's with '/' sign
String androidBannerAdUnitId = 'ca-app-pub-9717693213344214/3243678966';
String iosBannerAdUnitId = 'ca-app-pub-9717693213344214/3243678966';
//Interstitial unit id's with '/' sign
String androidInterstitialAdUnitId = 'ca-app-pub-9717693213344214/6566425425';
String iosInterstitialAdUnitId = 'ca-app-pub-9717693213344214/6566425425';

class Ads {
  MobileAdTargetingInfo targetingInfo() => MobileAdTargetingInfo(
        contentUrl: 'https://flutter.io',
        childDirected: false,
        testDevices: testDevice != null
            ? <String>[testDevice]
            : null, // Android emulators are considered test devices
      );

  BannerAd myBanner() => BannerAd(
        adUnitId: Platform.isIOS ? iosBannerAdUnitId : androidBannerAdUnitId,
        size: AdSize.smartBanner,
        targetingInfo: targetingInfo(),
        listener: (MobileAdEvent event) {
          print("BannerAd event is $event");
        },
      );
  InterstitialAd myInterstitial() => InterstitialAd(
        adUnitId: Platform.isAndroid
            ? androidInterstitialAdUnitId
            : iosInterstitialAdUnitId,
        targetingInfo: targetingInfo(),
        listener: (MobileAdEvent event) {
          // adEvent = event;
          print("------------------------------InterstitialAd event is $event");
        },
      );

  void disable(ad) {
    try {
      ad?.dispose();
    } catch (e) {
      print("no ad found");
    }
  }
}
