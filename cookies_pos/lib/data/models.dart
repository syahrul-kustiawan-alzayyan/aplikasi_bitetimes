class Product {
  final int? id;
  final String name;
  final int price;
  final int stock;
  final bool isFavorite;
  final String? imagePath;

  Product({
    this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.isFavorite = false,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'stock': stock,
      'isFavorite': isFavorite ? 1 : 0,
      'imagePath': imagePath,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      price: map['price'] as int,
      stock: map['stock'] as int,
      isFavorite: (map['isFavorite'] as int) == 1,
      imagePath: map['imagePath'] as String?,
    );
  }

  Product copyWith({
    int? id,
    String? name,
    int? price,
    int? stock,
    bool? isFavorite,
    String? imagePath,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      isFavorite: isFavorite ?? this.isFavorite,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

class Sale {
  final int? id;
  final int totalAmount;
  final String paymentMethod;
  final String createdAt;
  final List<SaleItem> items;

  Sale({
    this.id,
    required this.totalAmount,
    required this.paymentMethod,
    required this.createdAt,
    this.items = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] as int?,
      totalAmount: map['totalAmount'] as int,
      paymentMethod: map['paymentMethod'] as String,
      createdAt: map['createdAt'] as String,
    );
  }
}

class SaleItem {
  final int? id;
  final int saleId;
  final int productId;
  final String productName;
  final int price;
  final int quantity;

  SaleItem({
    this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'saleId': saleId,
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'] as int?,
      saleId: map['saleId'] as int,
      productId: map['productId'] as int,
      productName: map['productName'] as String,
      price: map['price'] as int,
      quantity: map['quantity'] as int,
    );
  }
}

class Income {
  final int? id;
  final int amount;
  final String source;
  final String description;
  final String date;

  Income({
    this.id,
    required this.amount,
    required this.source,
    required this.description,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'source': source,
      'description': description,
      'date': date,
    };
  }

  factory Income.fromMap(Map<String, dynamic> map) {
    return Income(
      id: map['id'] as int?,
      amount: map['amount'] as int,
      source: map['source'] as String,
      description: map['description'] as String,
      date: map['date'] as String,
    );
  }
}

class Expense {
  final int? id;
  final int amount;
  final String category;
  final String description;
  final String date;

  Expense({
    this.id,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'description': description,
      'date': date,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      amount: map['amount'] as int,
      category: map['category'] as String,
      description: map['description'] as String,
      date: map['date'] as String,
    );
  }
}
