import 'dart:async';
import 'dart:io';

import 'package:amazon_sqlite/model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static DatabaseHelper _databaseHelper; // Singleton DatabaseHelper
  static Database _database; // Singleton Database

  String productTable = 'productTable';
  String productName = 'productName';
  String productASIN = 'productASIN';
  String productPrice = 'productPrice';
  String productUrl = 'productUrl';
  String priceHistory = 'priceHistory';
  String lastUpdated = 'lastUpdated';

  DatabaseHelper._createInstance(); // Named constructor to create instance of DatabaseHelper

  factory DatabaseHelper() {
    if (_databaseHelper == null) {
      _databaseHelper = DatabaseHelper
          ._createInstance(); // This is executed only once, singleton object
    }
    return _databaseHelper;
  }

  Future<Database> get database async {
    if (_database == null) {
      _database = await initializeDatabase();
    }
    return _database;
  }

  Future<Database> initializeDatabase() async {
    // Get the directory path for both Android and iOS to store database.
    Directory directory = await getApplicationDocumentsDirectory();
    String path = directory.path + 'products.db';

    // Open/create the database at a given path
    var productsDatabase =
        await openDatabase(path, version: 1, onCreate: _createDb);
    return productsDatabase;
  }

  void _createDb(Database db, int newVersion) async {
    await db.execute(
        'CREATE TABLE $productTable( $productASIN TEXT, $productName TEXT,'
        '$productPrice TEXT, $productUrl TEXT, $priceHistory TEXT, $lastUpdated TEXT)');
  }

  // Fetch Operation: Get all todo objects from database
  Future<List<Map<String, dynamic>>> getProductMapList() async {
    Database db = await this.database;

    var result = await db.rawQuery('SELECT * FROM $productTable');
    // var result = await db.query(todoTable, orderBy: '$colTitle ASC');
    return result;
  }

  // Fetch Operation: Get all ASIN fields from database
  Future<List<Map<String, dynamic>>> getProductAsinMapList() async {
    Database db = await this.database;

    var result = await db.rawQuery('SELECT $productASIN FROM $productTable');
    // var result = await db.query(todoTable, orderBy: '$colTitle ASC');
    return result;
  }

  // Insert Operation: Insert a todo object to database
  Future<int> insertProduct(Product product) async {
    Database db = await this.database;
    var result = await db.insert(productTable, product.toMap());
    return result;
  }

  // Update Operation: Update a todo object and save it to database
  Future<int> updateProduct(Product product) async {
    var db = await this.database;
    var result = await db.update(productTable, product.toMap(),
        where: '$productASIN = ?', whereArgs: [product.productASIN]);
    return result;
  }

  // Delete Operation: Delete a todo object from database
  Future<int> deleteProduct(String asin) async {
    var db = await this.database;
    int result = await db
        .delete(productTable, where: '$productASIN = ?', whereArgs: [asin]);
    return result;
  }

  // Get number of todo objects in database
  Future<int> getCount() async {
    Database db = await this.database;
    List<Map<String, dynamic>> x =
        await db.rawQuery('SELECT COUNT (*) from $productTable');
    int result = Sqflite.firstIntValue(x);
    return result;
  }

  //Get priceHistory of ASIN
  Future<String> getPriceHistory(String asin) async {
    Database db = await this.database;
    List<Map<String, dynamic>> priceHistoryMap = await db.query(productTable,
        columns: [priceHistory], where: '$productASIN = ?', whereArgs: [asin]);
    String priceHistoryDB = fromPriceHistoryMapObject(priceHistoryMap[0]);
    // print('fnPrint : $priceHistoryDB');
    return priceHistoryDB;
  }

  // Get the 'Map List' [ List<Map> ] and convert it to 'todo List' [ List<Todo> ]
  Future<List<Product>> getProductList() async {
    var productMapList =
        await getProductMapList(); // Get 'Map List' from database
    int count =
        productMapList.length; // Count the number of map entries in db table

    List<Product> productList = List<Product>();
    // For loop to create a 'todo List' from a 'Map List'
    for (int i = 0; i < count; i++) {
      productList.add(Product.fromMapObject(productMapList[i]));
    }

    return productList;
  }

  // Get the 'ASIN Map List' [ List<Map> ] and convert it to 'ASIN List' [ List<Todo> ]
  Future<List<String>> getAsinList() async {
    var asinMapList =
        await getProductAsinMapList(); // Get 'Map List' from database
    int count =
        asinMapList.length; // Count the number of map entries in db table

    List<String> asinList = List<String>();
    // For loop to create a 'todo List' from a 'Map List'
    for (int i = 0; i < count; i++) {
      asinList.add(fromAsinMapObject(asinMapList[i]));
    }

    return asinList;
  }
}

fromAsinMapObject(Map<String, dynamic> map) {
  String productASIN = map['productASIN'];
  return productASIN;
}

fromPriceHistoryMapObject(Map<String, dynamic> map) {
  String priceHistoryFromDB = map['priceHistory'];
  return priceHistoryFromDB;
}
