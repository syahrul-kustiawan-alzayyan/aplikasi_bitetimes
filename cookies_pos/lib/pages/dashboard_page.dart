import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/app_top_bar.dart';
import '../data/database_helper.dart';
import '../utils/global_sync.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  int _totalSold = 0;
  int _totalIncome = 0;
  int _totalExpense = 0;
  int _profit = 0;
  Map<String, int> _variantSales = {};
  List<double> _incomeSpots = [];
  List<double> _expenseSpots = [];
  List<String> _chartLabels = [];
  bool _isLoading = true;
  String _selectedFilter = 'Semua Waktu';
  final List<String> _filterOptions = [
    'Hari Ini',
    'Minggu Ini',
    'Bulan Ini',
    'Tahun Ini',
    'Semua Waktu',
  ];

  // Previous period data for comparison
  int _prevTotalSold = 0;
  int _prevTotalIncome = 0;
  int _prevTotalExpense = 0;
  int _prevProfit = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    GlobalSync.instance.addListener(_loadData);
  }

  @override
  void dispose() {
    GlobalSync.instance.removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final dbHelper = DatabaseHelper();

    DateTime? startDate;
    final now = DateTime.now();
    if (_selectedFilter == 'Hari Ini') {
      startDate = DateTime(now.year, now.month, now.day);
    } else if (_selectedFilter == 'Minggu Ini') {
      DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      startDate = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day,
      );
    } else if (_selectedFilter == 'Bulan Ini') {
      startDate = DateTime(now.year, now.month, 1);
    } else if (_selectedFilter == 'Tahun Ini') {
      startDate = DateTime(now.year, 1, 1);
    }

    final stats = await dbHelper.getDashboardStats(startDate: startDate);
    final variantSales = await dbHelper.getVariantSales(startDate: startDate);
    final chartData = await dbHelper.getDynamicChartData(startDate: startDate);

    // Get previous period data for comparison
    final prevStartDate = dbHelper.getPreviousPeriodStartDate(startDate);
    final prevEndDate = dbHelper.getPreviousPeriodEndDate(startDate);
    final prevStats = await dbHelper.getPreviousPeriodDashboardStats(
      previousStartDate: prevStartDate,
      previousEndDate: prevEndDate,
    );

    setState(() {
      _totalSold = stats['totalSold'] ?? 0;
      _totalIncome = stats['totalIncome'] ?? 0;
      _totalExpense = stats['totalExpense'] ?? 0;
      _profit = stats['profit'] ?? 0;
      _variantSales = variantSales;
      _incomeSpots = chartData['income'] ?? [];
      _expenseSpots = chartData['expense'] ?? [];
      _chartLabels = chartData['labels'] ?? [];
      _prevTotalSold = prevStats['totalSold'] ?? 0;
      _prevTotalIncome = prevStats['totalIncome'] ?? 0;
      _prevTotalExpense = prevStats['totalExpense'] ?? 0;
      _prevProfit = prevStats['profit'] ?? 0;
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
                    PopupMenuButton<String>(
                      initialValue: _selectedFilter,
                      onSelected: (String newValue) {
                        setState(() {
                          _selectedFilter = newValue;
                        });
                        _loadData();
                      },
                      itemBuilder: (BuildContext context) {
                        return _filterOptions.map((String choice) {
                          return PopupMenuItem<String>(
                            value: choice,
                            child: Text(choice),
                          );
                        }).toList();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedFilter,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.expand_more,
                              size: 16,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ],
                        ),
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
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid() {
    // Calculate percentage changes
    final soldChange = _prevTotalSold > 0
        ? ((_totalSold - _prevTotalSold) / _prevTotalSold * 100)
        : (_totalSold > 0 ? 100.0 : 0.0);
    final incomeChange = _prevTotalIncome > 0
        ? ((_totalIncome - _prevTotalIncome) / _prevTotalIncome * 100)
        : (_totalIncome > 0 ? 100.0 : 0.0);
    final expenseChange = _prevTotalExpense > 0
        ? ((_totalExpense - _prevTotalExpense) / _prevTotalExpense * 100)
        : (_totalExpense > 0 ? 100.0 : 0.0);
    final profitChange = _prevProfit > 0
        ? ((_profit - _prevProfit) / _prevProfit * 100)
        : (_profit > 0 ? 100.0 : 0.0);

    final isFilterAllTime = _selectedFilter == 'Semua Waktu';

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
                colors: [const Color(0xFFD6BEA8), const Color(0xFFC4A88E)],
                icon: Icons.shopping_bag_outlined,
                badgeText: isFilterAllTime
                    ? null
                    : _formatChangePercent(soldChange),
                changePercent: isFilterAllTime ? 0 : soldChange,
                showComparison: !isFilterAllTime,
              ),
            ),
            const SizedBox(width: 12),
            // Pemasukan
            Expanded(
              child: _buildGradientCard(
                title: 'PEMASUKAN',
                subtitle: 'Total IDR',
                value: _formatCurrency(_totalIncome),
                colors: [const Color(0xFFEAC295), const Color(0xFFDEB079)],
                icon: Icons.account_balance_wallet_outlined,
                badgeText: isFilterAllTime
                    ? null
                    : _formatChangePercent(incomeChange),
                changePercent: isFilterAllTime ? 0 : incomeChange,
                showComparison: !isFilterAllTime,
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
                colors: [const Color(0xFFCF9A69), const Color(0xFFC08552)],
                icon: Icons.money_off_csred_outlined,
                badgeText: isFilterAllTime
                    ? null
                    : _formatChangePercent(expenseChange),
                changePercent: isFilterAllTime ? 0 : expenseChange,
                showComparison: !isFilterAllTime,
              ),
            ),
            const SizedBox(width: 12),
            // Laba Bersih
            Expanded(
              child: _buildGradientCard(
                title: 'LABA BERSIH',
                subtitle: 'Profit IDR',
                value: _formatCurrency(_profit),
                colors: [const Color(0xFF967054), const Color(0xFF7A563F)],
                icon: Icons.stars,
                badgeText: isFilterAllTime
                    ? null
                    : _formatChangePercent(profitChange),
                changePercent: isFilterAllTime ? 0 : profitChange,
                showComparison: !isFilterAllTime,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatChangePercent(double percent) {
    if (percent == 0) return '0%';
    final sign = percent > 0 ? '+' : '';
    return '$sign${percent.toStringAsFixed(1)}%';
  }

  Widget _buildGradientCard({
    required String title,
    required String subtitle,
    required String value,
    String? suffix,
    required List<Color> colors,
    required IconData icon,
    String? badgeText,
    double changePercent = 0,
    bool showComparison = false,
  }) {
    return Container(
      height: 160,
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
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.cookie,
              size: 110,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
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
                    Icon(
                      icon,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
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
                if (showComparison)
                  _buildComparisonBadge(changePercent)
                else
                  const SizedBox(height: 18), // Spacer to balance height
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonBadge(double changePercent) {
    // Determine if positive or negative change
    final isPositive = changePercent > 0;
    final isZero = changePercent == 0;

    // Colors with high contrast
    final positiveColor = const Color(
      0xFF2E7D32,
    ); // Dark green for better contrast
    final negativeColor = const Color(
      0xFFC62828,
    ); // Dark red for better contrast
    final neutralColor = const Color(0xFF9E9E9E); // Gray for no change

    // Select color based on change
    Color badgeColor;
    IconData badgeIcon;

    if (isZero) {
      badgeColor = neutralColor;
      badgeIcon = Icons.remove;
    } else if (isPositive) {
      badgeColor = positiveColor;
      badgeIcon = Icons.trending_up;
    } else {
      badgeColor = negativeColor;
      badgeIcon = Icons.trending_down;
    }

    // Format the percentage text
    String percentText;
    if (isZero) {
      percentText = '0%';
    } else {
      final sign = isPositive ? '+' : '-';
      final absPercent = changePercent.abs().toStringAsFixed(1);
      percentText = '$sign$absPercent%';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white, // White background for maximum contrast
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: badgeColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 12, color: badgeColor),
          const SizedBox(width: 5),
          Text(
            percentText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: badgeColor,
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _getSpots(List<double> data) {
    return List.generate(
      data.length,
      (index) => FlSpot(index.toDouble(), data[index] / 1000000),
    );
  }

  Widget _buildTrenKeuangan() {
    double maxVal = 0;
    for (var v in _incomeSpots) {
      if (v > maxVal) maxVal = v;
    }
    for (var v in _expenseSpots) {
      if (v > maxVal) maxVal = v;
    }

    double maxYChart = maxVal / 1000000;
    if (maxYChart < 1) maxYChart = 1;

    double interval = (maxYChart / 4).ceilToDouble();
    if (interval < 1) interval = 1;

    double calculatedMaxY = (maxYChart / interval).ceil() * interval;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
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
                maxY: calculatedMaxY > 0 ? calculatedMaxY : 1,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) =>
                        AppTheme.surfaceContainerHighest,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final value = spot.y * 1000000;
                        return LineTooltipItem(
                          _formatCurrency(value.toInt()),
                          TextStyle(
                            color: spot.bar.color ?? AppTheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppTheme.outlineVariant.withValues(alpha: 0.2),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
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
                              color: AppTheme.onSurfaceVariant.withValues(
                                alpha: 0.7,
                              ),
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
                        if (value.toInt() >= 0 &&
                            value.toInt() < _chartLabels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _chartLabels[value.toInt()],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.onSurfaceVariant.withValues(
                                  alpha: 0.7,
                                ),
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
                    spots: _getSpots(_incomeSpots),
                    isCurved: true,
                    color: AppTheme.tertiary,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
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
                    spots: _getSpots(_expenseSpots),
                    isCurved: true,
                    color: AppTheme.error,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
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
          child: Column(children: bars),
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
