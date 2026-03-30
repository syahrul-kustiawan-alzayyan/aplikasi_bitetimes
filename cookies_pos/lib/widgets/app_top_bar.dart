import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/global_sync.dart';
import '../data/database_helper.dart';
import '../pages/pre_order_page.dart';

class AppTopBar extends StatefulWidget {
  final String title;

  const AppTopBar({super.key, required this.title});

  @override
  State<AppTopBar> createState() => _AppTopBarState();
}

class _AppTopBarState extends State<AppTopBar> {
  int _pendingPreOrderCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPreOrderCount();
    GlobalSync.instance.addListener(_loadPreOrderCount);
  }

  @override
  void dispose() {
    GlobalSync.instance.removeListener(_loadPreOrderCount);
    super.dispose();
  }

  Future<void> _loadPreOrderCount() async {
    final preOrders = await DatabaseHelper().getPreOrders(status: 'pending');
    if (mounted) {
      setState(() {
        _pendingPreOrderCount = preOrders.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: AppTheme.surface,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primary.withOpacity( 0.2),
                width: 2,
              ),
            ),
            child: GestureDetector(
              onTap: () {
                GlobalSync.instance.notify();
              },
              child: ClipOval(
                child: Image.asset(
                  'lib/src/logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.cookie,
                    color: AppTheme.primary,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            widget.title,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: AppTheme.primary,
            ),
          ),
          const Spacer(),
          // Shopping Cart / PreOrder Button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PreOrderPage()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer.withOpacity( 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    color: AppTheme.primary,
                    size: 24,
                  ),
                  if (_pendingPreOrderCount > 0)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.surface, width: 2),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          _pendingPreOrderCount > 99
                              ? '99+'
                              : _pendingPreOrderCount.toString(),
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
