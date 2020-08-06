import 'dart:async';

import 'package:amazon_sqlite/database.dart';
import 'package:amazon_sqlite/model.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: MyHomePage(),
    );
  }
}

// ignore: unused_element
StreamSubscription _intentDataStreamSubscription;

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DatabaseHelper helper = DatabaseHelper();
  List<Product> productList = [];
  bool _isLoading = false;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  initFn(DatabaseHelper helper) {
    // For sharing or opening urls/text coming from outside the app while the app is in the memory
    _intentDataStreamSubscription =
        ReceiveSharingIntent.getTextStream().listen((String value) {
      if (value != null) registerASIN(value, helper);
    }, onError: (err) {
      print("getLinkStream error: $err");
    });

    // For sharing or opening urls/text coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialText().then((String value) {
      if (value != null) registerASIN(value, helper);
    });
  }

  registerASIN(String url, DatabaseHelper helper) async {
    print('==============================');
    print('extractASIN');
    print('==============================');

    String amazonASIN = 'not yet initialised';

    //Extract ASIN from the URL.
    RegExp regASIN = new RegExp("dp/([A-Z0-9]{10})/");
    amazonASIN = regASIN.stringMatch(url);
    amazonASIN = amazonASIN.substring(3, 13);
    print(amazonASIN);

    var asinList = await helper.getAsinList();
    // print('asinList : $asinList');

    if (asinList.contains(amazonASIN)) {
      // TODO - implement ASIN already exists.
      Fluttertoast.showToast(
          msg: 'Looks like this product already exist here !');

      print('Abort insert. ASIN already exists');
    } else {
      processProduct(amazonASIN, helper, 'insertASIN', '5');
    }
  }

  processProduct(String asin, DatabaseHelper helper, String type,
      String priceHistoryFromDB) {
    print('==============================');
    print('processASIN');
    print('==============================');

    setState(() {
      _isLoading = true;
    });

    String amazonASIN = asin;
    String responseBody = '';
    String amazonPrice;
    String amazonName;
    String amazonURL;

    //Set Amazon URL.
    amazonURL = 'https://www.amazon.in/dp/$amazonASIN';
    print(amazonURL);

    //Get response from Amazon with the provided URL.
    http.get(amazonURL).then((response) {
      // print('response.statusCode : ${response.statusCode}');

      //If the http request is successful the statusCode will be 200
      if (response.statusCode == 200) {
        responseBody = response.body;
        if (responseBody.indexOf('data-asin-price') != -1) {
          int indexOfPrice = 0;
          int indexOfTitle = 0;

          //Extract price of the product from the response from Amazon
          indexOfPrice = responseBody.indexOf('data-asin-price') + 17;
          // print(indexOfPrice);
          String asinPriceTemp =
              responseBody.substring(indexOfPrice, indexOfPrice + 10);
          amazonPrice = asinPriceTemp.substring(0, asinPriceTemp.indexOf("\""));
          print('amazonPrice: $amazonPrice');

          //Extract name of the product from the response from Amazon
          indexOfTitle =
              responseBody.indexOf('a-size-large product-title-word-brea') + 47;
          String asinTitleTemp =
              responseBody.substring(indexOfTitle, indexOfTitle + 150);
          amazonName = asinTitleTemp.substring(0, asinTitleTemp.indexOf("\n"));
          // print('processing: $amazonName');

          // print(product);
          // addProduct(product, helper, type);

          // ====== addProduct stuff ======

          print('==============================');
          print('add/updateASINdb');
          print('==============================');
          var result;
          if (type == 'insertASIN') {
            Product product = Product(
                productASIN: amazonASIN,
                productName: amazonName,
                productPrice: amazonPrice,
                productUrl: amazonURL,
                priceHistory: amazonPrice,
                lastUpdated: DateFormat.MMMd().add_jm().format(DateTime.now()));
            result = helper.insertProduct(product);
            rebuildList();
          } else if (type == 'updateASIN') {
            print('amazonPrice: $amazonPrice');
            print('priceHistoryFromDB : $priceHistoryFromDB');
            String updatedHistory;
            if (amazonPrice != priceHistoryFromDB) {
              updatedHistory = priceHistoryFromDB;
            } else {
              print('enetering else');
              // TODO - check logic, change to updatedHistory = amazonPrice
              updatedHistory = priceHistoryFromDB;
            }
            Product product = Product(
                productASIN: amazonASIN,
                productName: amazonName,
                productPrice: amazonPrice,
                productUrl: amazonURL,
                priceHistory: updatedHistory,
                lastUpdated: DateFormat.MMMd().add_jm().format(DateTime.now()));

            result = helper.updateProduct(product);
            rebuildList();
            Fluttertoast.showToast(
                msg: 'Successfully updated products !',
                toastLength: Toast.LENGTH_SHORT);
          }

          if (result != 0) {
            // TODO - implement insert SUCCESS
            print('insert/update SUCCESS');
            // Fluttertoast.showToast(msg: 'Successfully updated products !');
            setState(() {
              _isLoading = false;
            });
            _scaffoldKey.currentState.showSnackBar(SnackBar(
              content: Text(
                'Successfully updated !',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Theme.of(context).backgroundColor,
              duration: Duration(seconds: 3),
            ));
          } else {
            //TODO - implement insert FAIL
            print('insert/update FAIL');
            if (type == 'insertASIN') {
              int tryCount = int.parse(priceHistoryFromDB);
              if (tryCount >= 0) {
                --tryCount;
                _showSnackBar('database Error occurred!', amazonASIN, tryCount);
              } else
                Fluttertoast.showToast(msg: 'Error! please try again later');
            } else
              Fluttertoast.showToast(msg: 'update failed (database) !');
          }
          // print('exit add/updateASIN');
        } else {
          print('amazon refused scraping.');
          if (type == 'insertASIN') {
            int tryCount = int.parse(priceHistoryFromDB);
            if (tryCount >= 0) {
              --tryCount;
              _showSnackBar('Amazon error occurred!', amazonASIN, tryCount);
            } else
              Fluttertoast.showToast(msg: 'Error! please try again later');
          } else
            Fluttertoast.showToast(msg: 'update failed (Amazon) !');
        }
      } else {
        print('HTTP did not respond with 200');
        if (type == 'insertASIN') {
          int tryCount = int.parse(priceHistoryFromDB);
          if (tryCount >= 0) {
            --tryCount;
            _showSnackBar('HTTP error occurred!', amazonASIN, tryCount);
          } else
            Fluttertoast.showToast(msg: 'Error! please try again later');
        } else
          Fluttertoast.showToast(msg: 'update failed (HTTP) !');
      }
    });
  }

  deleteProduct(String asin, DatabaseHelper helper) async {
    print('==============================');
    print('deleteASINdb');
    print('==============================');

    var result;
    result = helper.deleteProduct(asin);
    if (result != 0) {
      // TODO - implement delete SUCCESS
      print('delete SUCCESS');
      Fluttertoast.showToast(msg: 'Successfully deleted product !');
    } else {
      //TODO - implement delete FAIL
      print('delete FAIL');
      Fluttertoast.showToast(msg: 'Error deleting this product !');
    }
  }

  Future<void> updateProducts(DatabaseHelper helper) async {
    var asinList = await helper.getAsinList();
    print('asinList : $asinList');
    asinList.forEach((asin) async {
      var priceHistoryFromDB = await helper.getPriceHistory(asin);
      print('priceHistoryFromDB : $priceHistoryFromDB');
      processProduct(asin, helper, 'updateASIN', priceHistoryFromDB);
    });
  }

  _showSnackBar(String message, String amazonASIN, int tryCount) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(
        message,
        style: TextStyle(color: Colors.white),
      ),
      action: SnackBarAction(
        label: 'Try Again',
        onPressed: () => processProduct(
            amazonASIN, helper, 'insertASIN', tryCount.toString()),
      ),
      backgroundColor: Theme.of(context).backgroundColor,
      duration: Duration(seconds: 3),
    ));
  }

  updateProductsFnCall() async {
    // setState(() {
    //   _isLoading = true;
    // });
    updateProducts(helper).then((_) {
      print('rebuilding now');
      rebuildList();
    });
  }

  getTrailingWidget(String price, String history) {
    print('history : $history - price : $price');
    double doublePrice = double.parse(price);
    double doubleHistory = double.parse(history);

    double difference = doublePrice - doubleHistory;
    if (difference < 0) {
      return Text(
        '₹ ${difference.toString()}',
        style: TextStyle(
            color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold),
      );
    } else if (difference > 0) {
      return Text(
        '₹ ${difference.toString()}',
        style: TextStyle(
            color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold),
      );
    }
  }

  showCircularProgressIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CircularProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text('Hang on...'),
          )
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    initFn(helper);
    rebuildList();
    print('initialized');
  }

  rebuildList() {
    helper.getProductList().then((list) {
      setState(() {
        productList = list;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Amazon Prices'),
        backgroundColor: Colors.green,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: updateProductsFnCall,
          ),
        ],
      ),
      body: _isLoading
          ? showCircularProgressIndicator()
          : (productList != null)
              ? ListView.builder(
                  itemBuilder: (context, index) {
                    return Card(
                      elevation: 20,
                      margin: EdgeInsets.all(10),
                      child: ListTile(
                        title: RichText(
                          text: TextSpan(children: <TextSpan>[
                            TextSpan(
                              text: '₹ ${productList[index].productPrice}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: '   ${productList[index].lastUpdated}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w300,
                              ),
                            )
                          ]),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            productList[index].productName,
                            style: TextStyle(fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        trailing: getTrailingWidget(
                            productList[index].productPrice,
                            productList[index].priceHistory),
                        onTap: () {
                          launch(productList[index].productUrl);
                        },
                        onLongPress: () {
                          helper
                              .deleteProduct(productList[index].getProductASIN)
                              .then((value) {
                            print('deleted');
                            productList.removeAt(index);
                            rebuildList();
                          });
                        },
                      ),
                    );
                  },
                  itemCount: productList.length,
                )
              : showCircularProgressIndicator(),
    );
  }
}
