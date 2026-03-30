import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models.dart';
import 'package:intl/intl.dart';

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
    final path = join(dbPath, 'bitetimes_clean.db');

    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE products ADD COLUMN imagePath TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE pre_orders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          customerName TEXT NOT NULL,
          items TEXT NOT NULL,
          totalAmount INTEGER NOT NULL,
          createdAt TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'pending'
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE pre_orders ADD COLUMN completedAt TEXT NOT NULL DEFAULT \'\'');
      await db.execute('ALTER TABLE pre_orders ADD COLUMN paymentMethod TEXT NOT NULL DEFAULT \'Cash\'');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price INTEGER NOT NULL,
        stock INTEGER NOT NULL DEFAULT 0,
        isFavorite INTEGER NOT NULL DEFAULT 0,
        imagePath TEXT
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

    await db.execute('''
      CREATE TABLE pre_orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerName TEXT NOT NULL,
        items TEXT NOT NULL,
        totalAmount INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        completedAt TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL DEFAULT 'pending',
        paymentMethod TEXT NOT NULL DEFAULT 'Cash'
      )
    ''');
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
    await db.update(
      'products',
      {'stock': newStock},
      where: 'id = ?',
      whereArgs: [productId],
    );
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
      await db.rawUpdate('UPDATE products SET stock = stock - ? WHERE id = ?', [
        item.quantity,
        item.productId,
      ]);
    }

    return saleId;
  }

  /// Complete a PreOrder by creating a sale record with items
  /// Returns the sale ID on success
  Future<int> completePreOrder(PreOrder preOrder, String paymentMethod) async {
    final db = await database;
    final items = _parsePreOrderItems(preOrder.itemsJson);

    // Create sale record
    final sale = Sale(
      totalAmount: preOrder.totalAmount,
      paymentMethod: paymentMethod,
      createdAt: DateTime.now().toIso8601String(),
    );

    final saleId = await db.insert('sales', sale.toMap()..remove('id'));

    // Insert sale items and decrease stock
    for (final item in items) {
      await db.insert('sale_items', {
        'saleId': saleId,
        'productId': item['productId'] as int,
        'productName': item['name'] as String,
        'price': item['price'] as int,
        'quantity': item['quantity'] as int,
      });

      // Decrease stock
      await db.rawUpdate('UPDATE products SET stock = stock - ? WHERE id = ?', [
        item['quantity'] as int,
        item['productId'] as int,
      ]);
    }

    // Update pre-order status to completed
    await db.update(
      'pre_orders',
      {'status': 'completed'},
      where: 'id = ?',
      whereArgs: [preOrder.id],
    );

    return saleId;
  }

  /// Complete a PreOrder by ID (legacy signature for backward compatibility)
  /// This creates a sale record with items from the pre-order
  Future<void> completePreOrderById(int id, String completedAt) async {
    final db = await database;

    // Get the pre-order
    final preOrders = await db.query(
      'pre_orders',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (preOrders.isEmpty) return;

    final preOrder = PreOrder.fromMap(preOrders.first);
    final items = _parsePreOrderItems(preOrder.itemsJson);

    // Create sale record
    final sale = Sale(
      totalAmount: preOrder.totalAmount,
      paymentMethod: 'PreOrder',
      createdAt: DateTime.now().toIso8601String(),
    );

    final saleId = await db.insert('sales', sale.toMap()..remove('id'));

    // Insert sale items and decrease stock
    for (final item in items) {
      await db.insert('sale_items', {
        'saleId': saleId,
        'productId': item['productId'] as int,
        'productName': item['name'] as String,
        'price': item['price'] as int,
        'quantity': item['quantity'] as int,
      });

      // Decrease stock
      await db.rawUpdate('UPDATE products SET stock = stock - ? WHERE id = ?', [
        item['quantity'] as int,
        item['productId'] as int,
      ]);
    }

    // Update pre-order status to completed
    await db.update(
      'pre_orders',
      {'status': 'completed'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Parse PreOrder items from JSON string
  List<Map<String, dynamic>> _parsePreOrderItems(String itemsJson) {
    try {
      return List<Map<String, dynamic>>.from(
        json.decode(itemsJson) as List<dynamic>,
      );
    } catch (e) {
      return [];
    }
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

  Future<void> updateIncome(Income income) async {
    final db = await database;
    await db.update(
      'incomes',
      income.toMap(),
      where: 'id = ?',
      whereArgs: [income.id!],
    );
  }

  Future<void> deleteIncome(int incomeId) async {
    final db = await database;
    await db.delete('incomes', where: 'id = ?', whereArgs: [incomeId]);
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

  Future<void> updateExpense(Expense expense) async {
    final db = await database;
    await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id!],
    );
  }

  Future<void> deleteExpense(int expenseId) async {
    final db = await database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [expenseId]);
  }

  Future<int> getTotalExpense() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM expenses',
    );
    return (result.first['total'] as int?) ?? 0;
  }

  // ── Dashboard Aggregates ──────────────────────────────────────────────

  Future<Map<String, int>> getDashboardStats({DateTime? startDate}) async {
    final startStr = startDate?.toIso8601String() ?? '';

    final db = await database;

    // Total Sales Count
    var saleItemsResult = await db.rawQuery(
      startDate == null
          ? 'SELECT COALESCE(SUM(quantity), 0) as total FROM sale_items'
          : 'SELECT COALESCE(SUM(si.quantity), 0) as total FROM sale_items si JOIN sales s ON si.saleId = s.id WHERE s.createdAt >= ?',
      startDate == null ? [] : [startStr],
    );
    final totalSold = (saleItemsResult.first['total'] as int?) ?? 0;

    // Total Income
    var incomeResult = await db.rawQuery(
      startDate == null
          ? 'SELECT COALESCE(SUM(amount), 0) as total FROM incomes'
          : 'SELECT COALESCE(SUM(amount), 0) as total FROM incomes WHERE date >= ?',
      startDate == null ? [] : [startStr],
    );
    final totalIncome = (incomeResult.first['total'] as int?) ?? 0;

    // Total Expense
    var expenseResult = await db.rawQuery(
      startDate == null
          ? 'SELECT COALESCE(SUM(amount), 0) as total FROM expenses'
          : 'SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE date >= ?',
      startDate == null ? [] : [startStr],
    );
    final totalExpense = (expenseResult.first['total'] as int?) ?? 0;

    final profit = totalIncome - totalExpense;

    return {
      'totalSold': totalSold,
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'profit': profit,
    };
  }

  Future<Map<String, dynamic>> getDynamicChartData({
    DateTime? startDate,
  }) async {
    final startStr = startDate?.toIso8601String() ?? '';
    final db = await database;

    final incomes = await db.query(
      'incomes',
      where: startDate == null ? null : 'date >= ?',
      whereArgs: startDate == null ? [] : [startStr],
    );

    final expenses = await db.query(
      'expenses',
      where: startDate == null ? null : 'date >= ?',
      whereArgs: startDate == null ? [] : [startStr],
    );

    Map<String, double> incomeMap = {};
    Map<String, double> expenseMap = {};
    Set<String> uniqueDates = {};

    for (var m in incomes) {
      final dateStr = (m['date'] as String).substring(0, 10);
      uniqueDates.add(dateStr);
      incomeMap[dateStr] =
          (incomeMap[dateStr] ?? 0) + (m['amount'] as int).toDouble();
    }

    for (var m in expenses) {
      final dateStr = (m['date'] as String).substring(0, 10);
      uniqueDates.add(dateStr);
      expenseMap[dateStr] =
          (expenseMap[dateStr] ?? 0) + (m['amount'] as int).toDouble();
    }

    final sortedDates = uniqueDates.toList()..sort();

    List<double> incomeSpots = [];
    List<double> expenseSpots = [];
    List<String> labels = [];

    for (var date in sortedDates) {
      final parsedDate = DateTime.parse(date);
      labels.add(DateFormat('dd/MM').format(parsedDate));
      incomeSpots.add(incomeMap[date] ?? 0.0);
      expenseSpots.add(expenseMap[date] ?? 0.0);
    }

    return {'income': incomeSpots, 'expense': expenseSpots, 'labels': labels};
  }

  Future<Map<String, int>> getVariantSales({DateTime? startDate}) async {
    final startStr = startDate?.toIso8601String() ?? '';
    final db = await database;

    final result = await db.rawQuery(
      startDate == null
          ? '''
      SELECT productName, COALESCE(SUM(quantity), 0) as totalQty
      FROM sale_items
      GROUP BY productName
      ORDER BY totalQty DESC
      LIMIT 5
      '''
          : '''
      SELECT si.productName, COALESCE(SUM(si.quantity), 0) as totalQty
      FROM sale_items si
      JOIN sales s ON si.saleId = s.id
      WHERE s.createdAt >= ?
      GROUP BY si.productName
      ORDER BY totalQty DESC
      LIMIT 5
      ''',
      startDate == null ? [] : [startStr],
    );

    final map = <String, int>{};
    for (final row in result) {
      map[row['productName'] as String] = (row['totalQty'] as int?) ?? 0;
    }
    return map;
  }

  // ── Previous Period Comparison ─────────────────────────────────────────

  /// Calculate the start date of the previous period based on the current filter
  DateTime? getPreviousPeriodStartDate(DateTime? currentStartDate) {
    if (currentStartDate == null) return null;

    final now = DateTime.now();
    final currentStart = currentStartDate;

    // Calculate period duration
    Duration periodDuration;
    if (currentStart.year == now.year &&
        currentStart.month == now.month &&
        currentStart.day == now.day) {
      // Hari Ini -> previous is yesterday
      return DateTime(now.year, now.month, now.day - 1);
    } else if (currentStart.weekday == 1 &&
        currentStart.day == now.day - (now.weekday - 1)) {
      // Minggu Ini -> previous is last week
      periodDuration = Duration(days: 7);
      return currentStart.subtract(periodDuration);
    } else if (currentStart.day == 1) {
      // Bulan Ini -> previous is last month
      if (currentStart.month == 1) {
        return DateTime(currentStart.year - 1, 12, 1);
      } else {
        return DateTime(currentStart.year, currentStart.month - 1, 1);
      }
    } else if (currentStart.month == 1 && currentStart.day == 1) {
      // Tahun Ini -> previous is last year
      return DateTime(currentStart.year - 1, 1, 1);
    }

    // Default: subtract same duration
    periodDuration = now.difference(currentStart);
    return currentStart.subtract(periodDuration);
  }

  /// Get end date for previous period (one day before current start, or equivalent period end)
  DateTime? getPreviousPeriodEndDate(DateTime? currentStartDate) {
    if (currentStartDate == null) return null;

    final now = DateTime.now();
    final currentStart = currentStartDate;

    if (currentStart.year == now.year &&
        currentStart.month == now.month &&
        currentStart.day == now.day) {
      // Hari Ini -> previous ends yesterday
      return DateTime(now.year, now.month, now.day - 1, 23, 59, 59);
    } else if (currentStart.day == 1 &&
        currentStart.month == now.month &&
        currentStart.year == now.year) {
      // Bulan Ini -> previous is last month end
      return currentStart.subtract(const Duration(days: 1));
    } else if (currentStart.month == 1 && currentStart.day == 1) {
      // Tahun Ini -> previous is last year end
      return DateTime(currentStart.year - 1, 12, 31, 23, 59, 59);
    }

    // For week or custom periods
    return currentStart.subtract(const Duration(days: 1));
  }

  /// Get dashboard stats for previous period
  Future<Map<String, int>> getPreviousPeriodDashboardStats({
    DateTime? previousStartDate,
    DateTime? previousEndDate,
  }) async {
    final db = await database;

    if (previousStartDate == null || previousEndDate == null) {
      return {'totalSold': 0, 'totalIncome': 0, 'totalExpense': 0, 'profit': 0};
    }

    final startStr = previousStartDate.toIso8601String();
    final endStr = previousEndDate.toIso8601String();

    // Total Sales Count
    var saleItemsResult = await db.rawQuery(
      'SELECT COALESCE(SUM(si.quantity), 0) as total FROM sale_items si JOIN sales s ON si.saleId = s.id WHERE s.createdAt >= ? AND s.createdAt <= ?',
      [startStr, endStr],
    );
    final totalSold = (saleItemsResult.first['total'] as int?) ?? 0;

    // Total Income
    var incomeResult = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM incomes WHERE date >= ? AND date <= ?',
      [startStr, endStr],
    );
    final totalIncome = (incomeResult.first['total'] as int?) ?? 0;

    // Total Expense
    var expenseResult = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE date >= ? AND date <= ?',
      [startStr, endStr],
    );
    final totalExpense = (expenseResult.first['total'] as int?) ?? 0;

    final profit = totalIncome - totalExpense;

    return {
      'totalSold': totalSold,
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'profit': profit,
    };
  }

  /// Get total income for a specific period
  Future<int> getTotalIncomeForPeriod({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;

    if (startDate == null || endDate == null) {
      final result = await db.rawQuery(
        'SELECT COALESCE(SUM(amount), 0) as total FROM incomes',
      );
      return (result.first['total'] as int?) ?? 0;
    }

    final startStr = startDate.toIso8601String();
    final endStr = endDate.toIso8601String();

    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM incomes WHERE date >= ? AND date <= ?',
      [startStr, endStr],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  /// Get total expense for a specific period
  Future<int> getTotalExpenseForPeriod({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;

    if (startDate == null || endDate == null) {
      final result = await db.rawQuery(
        'SELECT COALESCE(SUM(amount), 0) as total FROM expenses',
      );
      return (result.first['total'] as int?) ?? 0;
    }

    final startStr = startDate.toIso8601String();
    final endStr = endDate.toIso8601String();

    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE date >= ? AND date <= ?',
      [startStr, endStr],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  /// Get incomes for a specific period
  Future<List<Income>> getIncomesForPeriod({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;

    if (startDate == null || endDate == null) {
      final maps = await db.query('incomes', orderBy: 'date DESC');
      return maps.map((m) => Income.fromMap(m)).toList();
    }

    final startStr = startDate.toIso8601String();
    final endStr = endDate.toIso8601String();

    final maps = await db.query(
      'incomes',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startStr, endStr],
      orderBy: 'date DESC',
    );
    return maps.map((m) => Income.fromMap(m)).toList();
  }

  /// Get expenses for a specific period
  Future<List<Expense>> getExpensesForPeriod({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;

    if (startDate == null || endDate == null) {
      final maps = await db.query('expenses', orderBy: 'date DESC');
      return maps.map((m) => Expense.fromMap(m)).toList();
    }

    final startStr = startDate.toIso8601String();
    final endStr = endDate.toIso8601String();

    final maps = await db.query(
      'expenses',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startStr, endStr],
      orderBy: 'date DESC',
    );
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  // ── PreOrders ──────────────────────────────────────────────────────────

  Future<List<PreOrder>> getPreOrders({String? status}) async {
    final db = await database;
    final maps = await db.query(
      'pre_orders',
      where: status != null ? 'status = ?' : null,
      whereArgs: status != null ? [status] : null,
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) => PreOrder.fromMap(m)).toList();
  }

  Future<int> insertPreOrder(PreOrder preOrder) async {
    final db = await database;
    return await db.insert('pre_orders', preOrder.toMap()..remove('id'));
  }

  Future<void> updatePreOrderStatus(int id, String status) async {
    final db = await database;
    await db.update(
      'pre_orders',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deletePreOrder(int id) async {
    final db = await database;
    await db.delete('pre_orders', where: 'id = ?', whereArgs: [id]);
  }

  // ── Reset All Data ─────────────────────────────────────────────────────

  Future<void> resetAllData() async {
    final db = await database;

    // Start a transaction to ensure all operations succeed or fail together
    await db.transaction((txn) async {
      // Delete all sale items first (foreign key constraint)
      await txn.delete('sale_items');

      // Delete all sales
      await txn.delete('sales');

      // Delete all pre_orders
      await txn.delete('pre_orders');

      // Delete all incomes
      await txn.delete('incomes');

      // Delete all expenses
      await txn.delete('expenses');

      // Delete all products
      await txn.delete('products');
    });
  }
}
