import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/app_top_bar.dart';
import '../data/database_helper.dart';
import '../data/models.dart';
import '../utils/global_sync.dart';

class KasirPage extends StatefulWidget {
  const KasirPage({super.key});

  @override
  State<KasirPage> createState() => _KasirPageState();
}

class _KasirPageState extends State<KasirPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  List<Product> _products = [];
  bool _isLoading = true;

  // Now cart maps Product ID -> quantity
  final Map<int, int> _cart = {};

  // Customer name controller
  final TextEditingController _customerNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    GlobalSync.instance.addListener(_loadProducts);
  }

  @override
  void dispose() {
    GlobalSync.instance.removeListener(_loadProducts);
    _customerNameController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final products = await DatabaseHelper().getProducts();
    setState(() {
      _products = products;
      // Remove items from cart if they no longer exist or are out of stock
      // For simplicity, we just keep the cart, but realistically we should validate stock.
      _isLoading = false;
    });
  }

  String _formatCurrency(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  int get _subtotal {
    int total = 0;
    _cart.forEach((productId, qty) {
      final product = _products.firstWhere(
        (p) => p.id == productId,
        orElse: () => Product(name: '', price: 0, stock: 0),
      );
      total += product.price * qty;
    });
    return total;
  }

  void _showProsesPesananPopup() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Keranjang masih kosong!')));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Detail Pesanan',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              // Items List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _cart.length,
                itemBuilder: (context, index) {
                  final productId = _cart.keys.elementAt(index);
                  final qty = _cart[productId]!;
                  final product = _products.firstWhere(
                    (p) => p.id == productId,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${product.name} x$qty',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          _formatCurrency(product.price * qty),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Tagihan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    _formatCurrency(_subtotal),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _prosesPesananSelesai,
                  child: const Text(
                    'Pesanan Selesai',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _prosesPesananSelesai() async {
    Navigator.pop(context); // Close bottom sheet

    final dbHelper = DatabaseHelper();

    // Create sale
    final sale = Sale(
      totalAmount: _subtotal,
      paymentMethod: 'Cash', // Could be dynamic
      createdAt: DateTime.now().toIso8601String(),
    );

    // Create sale items
    final saleItems = <SaleItem>[];
    final List<String> itemDescriptions = [];

    _cart.forEach((productId, qty) {
      final product = _products.firstWhere((p) => p.id == productId);
      itemDescriptions.add('${qty}x ${product.name}');

      saleItems.add(
        SaleItem(
          saleId: 0, // Assigned by db
          productId: productId,
          productName: product.name,
          price: product.price,
          quantity: qty,
        ),
      );
    });

    // Insert sale and items (this also decreases product stock in DB)
    await dbHelper.insertSale(sale, saleItems);

    final String detailedDesc = itemDescriptions.isNotEmpty
        ? 'Penjualan: ${itemDescriptions.join(", ")}'
        : 'Penjualan otomatis dari menu Kasir';

    // Auto record as Income
    await dbHelper.insertIncome(
      Income(
        amount: _subtotal,
        source: 'Penjualan POS',
        description: detailedDesc,
        date: DateTime.now().toIso8601String(),
      ),
    );

    // Clear cart and reload products to update stock limits locally
    setState(() {
      _cart.clear();
    });

    await _loadProducts();
    GlobalSync.instance.notify();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesanan berhasil diproses!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppTopBar(title: 'BiteTimes'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // Header
                Text(
                  'Pilih Menu',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w800,
                    fontSize: 32,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Klik cookie untuk menambah ke keranjang',
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),

                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_products.isEmpty)
                  const Center(child: Text("Belum ada produk dari Katalog"))
                else ...[
                  // Product Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.0,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: _products.length,
                    itemBuilder: (context, index) =>
                        _buildProductCard(_products[index]),
                  ),
                  const SizedBox(height: 24),

                  // Cart Section
                  _buildCartSection(),
                  const SizedBox(height: 20),

                  // Proses Pesanan Button
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _cart.isEmpty
                              ? [Colors.grey, Colors.grey]
                              : [AppTheme.primary, AppTheme.primaryContainer],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          if (_cart.isNotEmpty)
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: _cart.isEmpty ? null : _showProsesPesananPopup,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.receipt_long,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Proses Pesanan',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 17,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    if (product.id == null) return const SizedBox.shrink();

    final int inCartQty = _cart[product.id] ?? 0;
    final bool available = product.stock > 0;

    // We can only add more if stock > currently in cart
    final bool canAdd = product.stock > inCartQty;

    return GestureDetector(
      onTap: canAdd
          ? () {
              setState(() {
                _cart[product.id!] = inCartQty + 1;
              });
            }
          : null,
      child: Opacity(
        opacity: available ? 1.0 : 0.5,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppTheme.surfaceContainerLow,
          ),
          child: Stack(
            children: [
              // 1. Image Background
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child:
                      (product.imagePath != null &&
                          product.imagePath!.isNotEmpty)
                      ? Image.file(File(product.imagePath!), fit: BoxFit.cover)
                      : Icon(
                          Icons.cookie_outlined,
                          size: 48,
                          color: AppTheme.onSurfaceVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                ),
              ),
              // 2. Gradient Overlay for Text Readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                ),
              ),
              // 3. Text & Details at bottom
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatCurrency(product.price),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: Colors.amberAccent,
                      ),
                    ),
                  ],
                ),
              ),
              // 4. Badges (Habis / InCart / Stock)
              if (!available)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.error,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: const Text(
                      'Habis',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              if (inCartQty > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$inCartQty',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              if (available)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Sisa ${product.stock - inCartQty}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartSection() {
    final cartEntries = _cart.entries.where((e) => e.value > 0).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF564338).withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cart Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.shopping_basket, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Keranjang',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: AppTheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0x19DDC1B3)),

          // Cart Items
          if (cartEntries.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Keranjang kosong',
                  style: TextStyle(color: AppTheme.onSurfaceVariant),
                ),
              ),
            )
          else
            ...cartEntries.map(
              (entry) => _buildCartItem(entry.key, entry.value),
            ),

          // Totals & Pay
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subtotal',
                      style: TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _formatCurrency(_subtotal),
                      style: TextStyle(color: AppTheme.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total Tagihan',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    Text(
                      _formatCurrency(_subtotal),
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onSurface,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(int productId, int qty) {
    if (!_products.any((p) => p.id == productId))
      return const SizedBox.shrink();
    final product = _products.firstWhere((p) => p.id == productId);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppTheme.surfaceContainer,
            ),
            child: Icon(
              Icons.cookie,
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.onSurface,
                  ),
                ),
                Text(
                  _formatCurrency(product.price * qty),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (qty > 1) {
                        _cart[productId] = qty - 1;
                      } else {
                        _cart.remove(productId);
                      }
                    });
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: const Icon(Icons.remove, size: 16),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '$qty',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (product.stock > qty) {
                      setState(() {
                        _cart[productId] = qty + 1;
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Stok tidak mencukupi!')),
                      );
                    }
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: Icon(
                      Icons.add,
                      size: 16,
                      color: product.stock > qty
                          ? AppTheme.primary
                          : AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
