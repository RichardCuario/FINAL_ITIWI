import 'package:flutter/material.dart';

import 'shared_widgets.dart';

class TransparencyPage extends StatelessWidget {
  const TransparencyPage({super.key});

  static const List<_TransparencyItem> _items = [
    _TransparencyItem(
      title: 'Program and Projects',
      icon: Icons.account_balance_wallet_rounded,
      iconColor: Color(0xFFF3C746),
    ),
    _TransparencyItem(
      title: 'Bids and Projects',
      icon: Icons.work_rounded,
      iconColor: Color(0xFF6F46D9),
    ),
    _TransparencyItem(
      title: 'Financial Reports',
      icon: Icons.show_chart_rounded,
      iconColor: Color(0xFF78D8E6),
    ),
    _TransparencyItem(
      title: 'Annual Budget',
      icon: Icons.account_balance_rounded,
      iconColor: Color(0xFFF26A45),
    ),
    _TransparencyItem(
      title: 'Legislative Ordinances',
      icon: Icons.location_city_rounded,
      iconColor: Color(0xFFF15B3D),
    ),
    _TransparencyItem(
      title: 'Executive Orders',
      icon: Icons.checkroom_rounded,
      iconColor: Color(0xFFF3C746),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? theme.scaffoldBackgroundColor : const Color(0xFFEAEAEA);
    final topGradient = isDark
        ? const [
            Color(0xFF0F172A),
            Color(0xFF172554),
            Color(0xFF111827),
          ]
        : const [
            Color(0xFF1E88E5),
            Color(0xFF90CAF9),
            Color(0xFFEAEAEA),
          ];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          Container(
            height: 210,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: topGradient,
                stops: const [0.0, 0.58, 1.0],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 14, 20, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Transparency',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.08,
                        ),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return _TransparencyCard(item: item);
                    },
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

class _TransparencyCard extends StatelessWidget {
  const _TransparencyCard({required this.item});

  final _TransparencyItem item;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${item.plainTitle} is coming soon.')),
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF262631) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: isDark ? Colors.white10 : const Color(0xFFE3E6EB),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 36,
                  child: Icon(
                    item.icon,
                    color: item.iconColor,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 3,
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF20242C),
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TransparencyItem {
  const _TransparencyItem({
    required this.title,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final IconData icon;
  final Color iconColor;

  String get plainTitle => title;
}
