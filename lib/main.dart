import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: TestPage(),
    );
  }
}

class TestPage extends StatefulWidget {
  @override
  _TestPageState createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  String url =
      'https://www.flipkart.com/unibox-ultra-slim-lcd-led-tvs-wall-mount-stand-21-40-inch-bracket-specially-mi-tv-fixed/p/itm46a1f27b617f9?pid=TVMFJHVV5RAGRUAY&lid=LSTTVMFJHVV5RAGRUAYVCLBTT&marketplace=FLIPKART&fm=productRecommendation%2Fattach&iid=R%3Aa%3Bp%3ATVSFJRFFJVY3HG5R%3Bpt%3App%3Buid%3A9f207547-d553-8d24-7e1a-4006150fec7b%3B.TVMFJHVV5RAGRUAY.LSTTVMFJHVV5RAGRUAYVCLBTT&ssid=sj2ldi3yu80000001596815001436&otracker=pp_reco_Frequently%2BBought%2BTogether_1_Frequently%2BBought%2BTogether_TVMFJHVV5RAGRUAY.LSTTVMFJHVV5RAGRUAYVCLBTT_productRecommendation%2Fattach_1&otracker1=pp_reco_PINNED_productRecommendation%2Fattach_Frequently%2BBought%2BTogether_NA_productCard_cc_1_NA_view-all&cid=TVMFJHVV5RAGRUAY.LSTTVMFJHVV5RAGRUAYVCLBTT';
  processFlipkart(String url) {
    print('===== processFlipkart =====');
    String flipkartURL = url.substring(0, url.indexOf('/p/') + 19);

    http.get(flipkartURL).then((response) {
      int indexOfTitle;
      int indexOfPrice;
      String responseBody = response.body;
      // print(responseBody);
      print(flipkartURL);

      indexOfPrice = responseBody.indexOf('_1vC4OE _3qQ9m1') + 17;
      String flipkartPriceTemp =
          responseBody.substring(indexOfPrice, indexOfPrice + 10);
      String flipkartPrice =
          flipkartPriceTemp.substring(0, flipkartPriceTemp.indexOf('<'));
      print(flipkartPrice);

      indexOfTitle = responseBody.indexOf('_35KyD6') + 9;
      String flipkartTitleTemp =
          responseBody.substring(indexOfTitle, indexOfTitle + 250);
      String flipkartTitle =
          flipkartTitleTemp.substring(0, flipkartTitleTemp.indexOf('<'));
      print(flipkartTitle);
    });
  }

  @override
  void initState() {
    super.initState();
    processFlipkart(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Check debug console and not here!'),
      ),
    );
  }
}
