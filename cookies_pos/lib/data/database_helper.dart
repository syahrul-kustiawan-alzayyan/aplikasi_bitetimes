import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'bitetimes.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price INTEGER NOT NULL,
        stock INTEGER NOT NULL DEFAULT 0,
        isFavorite INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        totalAmount INTEGER NOT NULL,
        paymentMethod TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        saleId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        productName TEXT NOT NULL,
        price INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        FOREIGN KEY (saleId) REFERENCES sales(id),
        FOREIGN KEY (productId) REFERENCES products(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE incomes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount INTEGER NOT NULL,
        source TEXT NOT NULL,
        description TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount INTEGER NOT NULL,
        category TEXT NOT NULL,
        description TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    // Seed dummy data
    await _seedDummyData(db);
  }

  Future<void> _seedDummyData(Database db) async {
    // Products
    final products = [
      {'name': 'Choco Chip Classic', 'price': 15000, 'stock': 45, 'isFavorite': 0},
      {'name': 'Velvet Dream', 'price': 18000, 'stock': 32, 'isFavorite': 1},
      {'name': 'Matcha Zen', 'price': 20000, 'stock': 28, 'isFavorite': 0},
      {'name': 'Macadamia White', 'price': 22000, 'stock': 15, 'isFavorite': 0},
      {'name': 'Dark Sea Salt', 'price': 17000, 'stock': 0, 'isFavorite': 0},
      {'name': 'Oatmeal Raisin', 'price': 15000, 'stock': 50, 'isFavorite': 0},
    ];

    for (final p in products) {
      await db.insert('products', p);
    }

    // Sales (sample)
    await db.insert('sales', {
      'totalAmount': 48000,
      'paymentMethod': 'Cash',
      'createdAt': '2023-10-27 14:30:00',
    });
    await db.insert('sale_items', {
      'saleId': 1, 'productId': 1, 'productName': 'Choco Chip Classic',
      'price': 15000, 'quantity': 2,
    });
    await db.insert('sale_items', {
      'saleId': 1, 'productId': 2, 'productName': 'Velvet Dream',
      'price': 18000, 'quantity': 1,
    });

    // Incomes
    final incomes = [
      {'amount': 450000, 'source': 'Penjualan POS', 'description': 'Penjualan harian otomatis dari POS', 'date': '2023-10-27 14:30:00'},
      {'amount': 10000000, 'source': 'Modal Awal', 'description': 'Setoran modal usaha awal bulan', 'date': '2023-10-12 08:00:00'},
      {'amount': 2500000, 'source': 'Pembayaran Piutang', 'description': 'Pelunasan piutang Pak Budi', 'date': '2023-10-10 11:15:00'},
    ];

    for (final i in incomes) {
      await db.insert('incomes', i);
    }

    // Expenses
    final expenses = [
      {'amount': 450000, 'category': 'Bahan Baku', 'description': 'Belanja Mentega A2 5kg', 'date': '2023-10-27 09:00:00'},
      {'amount': 120000, 'category': 'Packaging', 'description': 'Box Cookie Premium 100pcs', 'date': '2023-10-26 10:00:00'},
      {'amount': 850000, 'category': 'Operasional', 'description': 'Listrik Toko Oktober', 'date': '2023-10-25 08:00:00'},
    ];

    for (final e in expenses) {
      await db.insert('expenses', e);
    }
  }

  // ── Products ──────────────────────────────────────────────────────────

  Future<List<Product>> getProducts() async {
    final db = await database;
    final maps = await db.query('products', orderBy: 'id ASC');
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<int> insertProduct(Product product) async {
    final db = await database;
    return await db.insert('products', product.toMap()..remove('id'));
  }

  Future<void> updateProductStock(int productId, int newStock) async {
    final db = await database;
    await db.update('products', {'stock': newStock},
        where: 'id = ?', whereArgs: [productId]);
  }

  Future<void> deleteProduct(int productId) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [productId]);
  }

  // ── Sales ─────────────────────────────────────────────────────────────

  Future<int> insertSale(Sale sale, List<SaleItem> items) async {
    final db = await database;
    final saleId = await db.insert('sales', sale.toMap()..remove('id'));

    for (final item in items) {
      await db.insert('sale_items', {
        'saleId': saleId,
        'productId': item.productId,
        'productName': item.productName,
        'price': item.price,
        'quantity': item.quantity,
      });

      // Decrease stock
      await db.rawUpdate(
        'UPDATE products SET stock = stock - ? WHERE id = ?',
        [item.quantity, item.productId],
      );
    }

    return saleId;
  }

  Future<List<Sale>> getSales() async {
    final db = await database;
    final maps = await db.query('sales', orderBy: 'createdAt DESC');
    return maps.map((m) => Sale.fromMap(m)).toList();
  }

  Future<int> getTotalSalesCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(quantity), 0) as total FROM sale_items',
    );
    return (result.first['total'] as int?) ?? 0;
  }

  Future<int> getTotalSalesAmount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(totalAmount), 0) as total FROM sales',
    );
    return (result.first['total'] as int?) ?? 0;
  }

  // ── Incomes ───────────────────────────────────────────────────────────

  Future<List<Income>> getIncomes() async {
    final db = await database;
    final maps = await db.query('incomes', orderBy: 'date DESC');
    return maps.map((m) => Income.fromMap(m)).toList();
  }

  Future<int> insertIncome(Income income) async {
    final db = await database;
    return await db.insert('incomes', income.toMap()..remove('id'));
  }

  Future<int> getTotalIncome() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM incomes',
    );
    return (result.first['total'] as int?) ?? 0;
  }

  // ── Expenses ──────────────────────────────────────────────────────────

  Future<List<Expense>> getExpenses() async {
    final db = await database;
    final maps = await db.query('expenses', orderBy: 'date DESC');
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return await db.insert('expenses', expense.toMap()..remove('id'));
  }

  Future<int> getTotalExpense() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM expenses',
    );
    return (result.first['total'] as int?) ?? 0;
  }

  // ── Dashboard Aggregates ──────────────────────────────────────────────

  Future<Map<String, int>> getDashboardStats() async {
    final totalSold = await getTotalSalesCount();
    final totalIncome = await getTotalIncome();
    final totalExpense = await getTotalExpense();
    final profit = totalIncome - totalExpense;

    return {
      'totalSold': totalSold,
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'profit': profit,
    };
  }

  Future<Map<String, int>> getVariantSales() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT productName, COALESCE(SUM(quantity), 0) as totalQty
      FROM sale_items
      GROUP BY productName
      ORDER BY totalQty DESC
      LIMIT 5
    ''');

    final map = <String, int>{};
    for (final row in result) {
      map[row['productName'] as String] = (row['totalQty'] as int?) ?? 0;
    }
    return map;
  }
}
