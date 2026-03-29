import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../data/database_helper.dart';
import '../data/models.dart';
import '../utils/global_sync.dart';

class RiwayatPage extends StatefulWidget {
  final String title;
  final bool isIncome;

  const RiwayatPage({super.key, required this.title, required this.isIncome});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  List<dynamic> _transactions = [];
  bool _isLoading = true;

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
    if (widget.isIncome) {
      final data = await DatabaseHelper().getIncomes();
      setState(() {
        _transactions = data;
        _isLoading = false;
      });
    } else {
      final data = await DatabaseHelper().getExpenses();
      setState(() {
        _transactions = data;
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(int amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  String _formatDate(String isoString) {
    final date = DateTime.parse(isoString);
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.onSurface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? const Center(child: Text('Belum ada riwayat.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: _transactions.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _transactions.reversed.toList()[index];

                    String titleValue = '';
                    String tagValue = '';
                    int amountValue = 0;
                    String dateValue = '';
                    String descValue = '';

                    if (widget.isIncome) {
                      final inc = item as Income;
                      titleValue = inc.source;
                      tagValue = inc.source == 'Penjualan POS' ? 'OTOMATIS' : 'MANUAL';
                      amountValue = inc.amount;
                      dateValue = _formatDate(inc.date);
                      descValue = inc.description;
                    } else {
                      final exp = item as Expense;
                      titleValue = exp.category;
                      tagValue = exp.category == 'Penjualan POS' ? 'OTOMATIS' : 'MANUAL';
                      amountValue = exp.amount;
                      dateValue = _formatDate(exp.date);
                      descValue = exp.description;
                    }

                    final isManual = tagValue == 'MANUAL';
                    final icon = isManual ? Icons.handshake : Icons.point_of_sale;
                    final iconColor = isManual ? AppTheme.primary : AppTheme.secondary;
                    final iconBgColor = (isManual ? AppTheme.primaryFixedDim : AppTheme.secondaryContainer).withValues(alpha: 0.2);

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: iconBgColor,
                            ),
                            child: Icon(icon, color: iconColor, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  titleValue,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppTheme.onSurface,
                                  ),
                                ),
                                if (descValue.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    descValue,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.8),
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.access_time_filled, size: 12, color: AppTheme.onSurfaceVariant),
                                    const SizedBox(width: 4),
                                    Text(
                                      dateValue,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                (widget.isIncome ? '+' : '-') + _formatCurrency(amountValue),
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: widget.isIncome ? AppTheme.tertiary : AppTheme.error,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  tagValue,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.onSurfaceVariant,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
