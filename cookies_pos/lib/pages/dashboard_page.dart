import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/app_top_bar.dart';
import '../data/database_helper.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _totalSold = 0;
  int _totalIncome = 0;
  int _totalExpense = 0;
  int _profit = 0;
  Map<String, int> _variantSales = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final dbHelper = DatabaseHelper();
    
    final stats = await dbHelper.getDashboardStats();
    final variantSales = await dbHelper.getVariantSales();

    setState(() {
      _totalSold = stats['totalSold'] ?? 0;
      _totalIncome = stats['totalIncome'] ?? 0;
      _totalExpense = stats['totalExpense'] ?? 0;
      _profit = stats['profit'] ?? 0;
      _variantSales = variantSales;
      _isLoading = false;
    });
  }

  String _formatCurrency(int amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
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
                // Filter Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pusat Analisis',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '7 Hari Terakhir',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.expand_more, size: 16, color: AppTheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(48.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  // KPI Bento Grid
                  _buildKpiGrid(),
                  const SizedBox(height: 24),

                  // Tren Keuangan
                  _buildTrenKeuangan(),
                  const SizedBox(height: 24),

                  // Penjualan per Varian
                  _buildPenjualanPerVarian(),
                  const SizedBox(height: 16),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid() {
    return Column(
      children: [
        Row(
          children: [
            // Terjual
            Expanded(
              child: _buildGradientCard(
                title: 'TERJUAL',
                subtitle: 'Total Item',
                value: '$_totalSold',
                suffix: 'pcs',
                colors: [const Color(0xFF8D6E63), const Color(0xFF5D4037)],
                icon: Icons.shopping_bag_outlined,
              ),
            ),
            const SizedBox(width: 12),
            // Pemasukan
            Expanded(
              child: _buildGradientCard(
                title: 'PEMASUKAN',
                subtitle: 'Total IDR',
                value: _formatCurrency(_totalIncome),
                colors: [AppTheme.tertiary, const Color(0xFF004D40)],
                icon: Icons.account_balance_wallet_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Pengeluaran
            Expanded(
              child: _buildGradientCard(
                title: 'PENGELUARAN',
                subtitle: 'Total IDR',
                value: _formatCurrency(_totalExpense),
                colors: [AppTheme.error, const Color(0xFFB71C1C)],
                icon: Icons.money_off_csred_outlined,
              ),
            ),
            const SizedBox(width: 12),
            // Laba Bersih
            Expanded(
              child: _buildGradientCard(
                title: 'LABA BERSIH',
                subtitle: 'Profit IDR',
                value: _formatCurrency(_profit),
                colors: [AppTheme.primary, AppTheme.primaryContainer],
                icon: Icons.stars,
                badgeText: 'Target Tercapai',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGradientCard({
    required String title,
    required String subtitle,
    required String value,
    String? suffix,
    required List<Color> colors,
    required IconData icon,
    String? badgeText,
  }) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.8),
                  letterSpacing: 2,
                ),
              ),
              Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.8)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (suffix != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      suffix,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (badgeText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stars, size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    badgeText,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 18), // Spacer to balance height
        ],
      ),
    );
  }

  Widget _buildTrenKeuangan() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest, // Better contrast
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tren Keuangan',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppTheme.onSurface,
                ),
              ),
              Row(
                children: [
                  _legendDot(AppTheme.tertiary, 'Masuk'),
                  const SizedBox(width: 12),
                  _legendDot(AppTheme.error, 'Keluar'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppTheme.outlineVariant.withValues(alpha: 0.2),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            'Rp${value.toInt()}jt',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                            textAlign: TextAlign.right,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              days[value.toInt()],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 28,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Masuk (Pemasukan)
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 2),
                      FlSpot(1, 4),
                      FlSpot(2, 3.5),
                      FlSpot(3, 5),
                      FlSpot(4, 6),
                      FlSpot(5, 7),
                      FlSpot(6, 10), // E.g., 10 million on Sunday (Dummy data)
                    ],
                    isCurved: true,
                    color: AppTheme.tertiary,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: AppTheme.surfaceContainerLowest,
                        strokeWidth: 2,
                        strokeColor: AppTheme.tertiary,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.tertiary.withValues(alpha: 0.1),
                    ),
                  ),
                  // Keluar (Pengeluaran)
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 1),
                      FlSpot(1, 2.5),
                      FlSpot(2, 1.5),
                      FlSpot(3, 2),
                      FlSpot(4, 3),
                      FlSpot(5, 2.8),
                      FlSpot(6, 3.5),
                    ],
                    isCurved: true,
                    color: AppTheme.error,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: AppTheme.surfaceContainerLowest,
                        strokeWidth: 2,
                        strokeColor: AppTheme.error,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.error.withValues(alpha: 0.1),
                    ),
                  ),
                ],
                minY: 0,
                maxY: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPenjualanPerVarian() {
    if (_variantSales.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.outlineVariant.withValues(alpha: 0.1),
          ),
        ),
        child: const Center(child: Text("Belum ada data penjualan")),
      );
    }

    // Map variant sales to bars
    int maxSale = _variantSales.values.reduce((a, b) => a > b ? a : b);
    
    // Fallback colors for variations
    final colors = [
      const Color(0xFF564338),
      AppTheme.error,
      const Color(0xFF4A6741),
      AppTheme.secondary,
      AppTheme.tertiary,
    ];

    List<Widget> bars = [];
    int colorIdx = 0;
    _variantSales.forEach((name, qty) {
      double ratio = maxSale > 0 ? qty / maxSale : 0.0;
      bars.add(_varianBar(name, qty, ratio, colors[colorIdx % colors.length]));
      bars.add(const SizedBox(height: 20));
      colorIdx++;
    });

    // Remove last SizedBox
    if (bars.isNotEmpty) bars.removeLast();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Penjualan per Varian',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.outlineVariant.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: bars,
          ),
        ),
      ],
    );
  }

  Widget _varianBar(String name, int qty, double ratio, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$qty pcs',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(9999),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: AppTheme.surfaceContainer,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 16,
          ),
        ),
      ],
    );
  }
}
