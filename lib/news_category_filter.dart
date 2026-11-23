import 'package:flutter/material.dart';

class NewsCategoryFilter extends StatelessWidget {
  const NewsCategoryFilter({
    super.key,
    required this.items,
    required this.selectedCategory,
    required this.resultCount,
    required this.onChanged,
  });

  final List<Map<String, dynamic>> items;
  final String? selectedCategory;
  final int resultCount;
  final ValueChanged<String?> onChanged;

  static String categoryOf(Map<String, dynamic> item) {
    final value = item['category']?.toString().trim() ?? '';
    return value.isEmpty ? 'General' : value;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final counts = <String, int>{};
    for (final item in items) {
      final category = categoryOf(item);
      counts.update(category, (count) => count + 1, ifAbsent: () => 1);
    }
    final categories = counts.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final options = <String?>[null, ...categories];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.outline.withValues(alpha: 0.14)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.tune_rounded, size: 18, color: colors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Browse categories',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '$resultCount ${resultCount == 1 ? 'article' : 'articles'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: options.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = options[index];
                  final selected = selectedCategory == category;
                  final label = category ?? 'All';
                  final count = category == null ? items.length : counts[category]!;
                  final foreground = selected ? colors.onPrimary : colors.onSurface;

                  return Semantics(
                    button: true,
                    selected: selected,
                    label: '$label, $count ${count == 1 ? 'article' : 'articles'}',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onChanged(category),
                        borderRadius: BorderRadius.circular(22),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 13),
                          decoration: BoxDecoration(
                            color: selected
                                ? colors.primary
                                : colors.primary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: selected
                                  ? colors.primary
                                  : colors.primary.withValues(alpha: 0.16),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                label,
                                style: TextStyle(
                                  color: foreground,
                                  fontSize: 13,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? colors.onPrimary.withValues(alpha: 0.18)
                                      : colors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$count',
                                  style: TextStyle(
                                    color: selected ? colors.onPrimary : colors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
