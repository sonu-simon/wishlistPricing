class Product {
  String productName;
  String productASIN;
  String productPrice;
  String productUrl;
  String priceHistory;
  String lastUpdated;

  Product({
    this.productASIN,
    this.productName,
    this.productPrice,
    this.productUrl,
    this.priceHistory,
    this.lastUpdated,
  });

  String get getProductASIN => productASIN;

  set setProductASIN(String productASIN) => this.productASIN = productASIN;

  String get getProductPrice => productPrice;

  set setProductPrice(String productPrice) => this.productPrice = productPrice;

  String get getProductUrl => productUrl;

  set setProductUrl(String productUrl) => this.productUrl = productUrl;

  String get getPriceHistory => priceHistory;

  set setPriceHistory(String priceHistory) => this.priceHistory = priceHistory;

  String get getLastUpdated => lastUpdated;

  set setLastUpdated(String lastUpdated) => this.lastUpdated = lastUpdated;

  Map<String, dynamic> toMap() {
    var map = Map<String, dynamic>();
    map['productName'] = productName;
    map['productASIN'] = productASIN;
    map['productUrl'] = productUrl;
    map['productPrice'] = productPrice;
    map['priceHistory'] = priceHistory;
    map['lastUpdated'] = lastUpdated;

    return map;
  }

  Product.fromMapObject(Map<String, dynamic> map) {
    this.productASIN = map['productASIN'];
    this.productName = map['productName'];
    this.productPrice = map['productPrice'];
    this.productUrl = map['productUrl'];
    this.priceHistory = map['priceHistory'];
    this.lastUpdated = map['lastUpdated'];
  }
}
