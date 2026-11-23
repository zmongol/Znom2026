import 'package:book_app/Component/MongolFonts.dart';
import 'package:book_app/Component/find_ctrls.dart';
import 'package:book_app/Component/app_theme.dart';
import 'package:book_app/consttants.dart';
import 'package:book_app/services/book_sync_service.dart';
// import 'package:book_app/global_controllers/ads_ctrl.dart';  // Disabled
import 'package:book_app/core/services/font_service.dart';
import 'package:book_app/global_controllers/books_ctrl.dart';
import 'package:book_app/screens/home_screen.dart';
import 'package:book_app/widgets/rounded_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';  // Disabled
import 'package:mongol/mongol.dart';

void main() async {
  await GetStorage.init();
  // MobileAds.instance.initialize();  // Disabled
  _putCtrls();
  runApp(MyApp());
  // Start the Mini FTP book sync once the app is on screen.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    BookSyncService.startAutoUpdate();
  });
}

final _book = FindCtrl.book;

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Obx(
      () => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Znom',
        theme: appLightTheme(fontFamily: _book.fontFamily.value).copyWith(
          textTheme: ThemeData(brightness: Brightness.light).textTheme.apply(
                displayColor: kBlackColor,
                fontSizeFactor: 1.0,
              ),
        ),
        darkTheme: appDarkTheme(fontFamily: _book.fontFamily.value).copyWith(
          textTheme: ThemeData(brightness: Brightness.dark).textTheme.apply(
                fontSizeFactor: 1.0,
              ),
        ),
        themeMode: _book.isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
        home: WelcomeScreen(),
      ),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light(),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/Bitmap.png"),
              fit: BoxFit.fill,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 24, color: Colors.black),
                      children: [
                        TextSpan(
                          text: "Znom-",
                        ),
                        TextSpan(
                          text: "CahimDorlal",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  MongolText(
                    "ᡯᡭᢍ ᡢ ᢚᡪᢊᡬᢍ ᢘᡭᢞᡪᢑᡪᢐ",
                    style: TextStyle(
                        fontFamily: MongolFonts.z52xanadutig, fontSize: 26),
                  ),
                  SizedBox(
                    height: 40,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: RoundedButton(
                      text: "уншиж эхлэх",
                      fontSize: 20,
                      press: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomeScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _putCtrls() {
  Get.put(FontService());
  Get.put(BookSyncService());
  Get.put(BookCtrl());
  // Get.put(AppAdsCtrl());  // Disabled
}
