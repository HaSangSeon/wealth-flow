import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'models.dart';
import 'formatters.dart';

class _AllocationItem {
  final String label;
  final double value;
  final double percent;
  final Color color;

  _AllocationItem({
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
  });
}

class PortfolioAllocationCard extends StatefulWidget {
  const PortfolioAllocationCard({
    super.key,
    required this.holdings,
    required this.lastExchangeRate,
  });

  final List<Holding> holdings;
  final double lastExchangeRate;

  @override
  State<PortfolioAllocationCard> createState() => _PortfolioAllocationCardState();
}

class _PortfolioAllocationCardState extends State<PortfolioAllocationCard> {
  bool _showByAssetClass = true;

  @override
  Widget build(BuildContext context) {
    if (widget.holdings.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 데이터 집계
    final assetValues = <AssetType, double>{};
    final accountValues = <AccountType, double>{};

    for (final holding in widget.holdings) {
      double val = holding.quantity * holding.price;
      assetValues[holding.type] = (assetValues[holding.type] ?? 0) + val;
      accountValues[holding.account] = (accountValues[holding.account] ?? 0) + val;
    }

    final categories = <String>[];
    final values = <double>[];
    final colors = <Color>[];

    if (_showByAssetClass) {
      final types = [AssetType.koreanStock, AssetType.usStock, AssetType.etf, AssetType.cash];
      final labels = ['국내주식', '해외주식', 'ETF', '현금/기타'];
      final palette = [
        const Color(0xFF26A68A), // 국내주식
        const Color(0xFFEAA622), // 해외주식
        const Color(0xFF2A8B79), // ETF
        const Color(0xFF8E867C), // 현금/기타
      ];

      for (int i = 0; i < types.length; i++) {
        final val = assetValues[types[i]] ?? 0;
        categories.add(labels[i]);
        values.add(val);
        colors.add(palette[i]);
      }
    } else {
      final accounts = [AccountType.general, AccountType.pension, AccountType.irp, AccountType.isa];
      final labels = ['일반계좌', '연금저축', 'IRP', 'ISA'];
      final palette = [
        const Color(0xFF176B5B), // 일반계좌
        const Color(0xFFEAA622), // 연금저축
        const Color(0xFFD46A00), // IRP
        const Color(0xFF4A90E2), // ISA
      ];

      for (int i = 0; i < accounts.length; i++) {
        final val = accountValues[accounts[i]] ?? 0;
        categories.add(labels[i]);
        values.add(val);
        colors.add(palette[i]);
      }
    }

    final total = values.fold<double>(0, (sum, val) => sum + val);
    final displayData = <_AllocationItem>[];
    for (int i = 0; i < categories.length; i++) {
      if (values[i] > 0) {
        final percent = total > 0 ? (values[i] / total) * 100 : 0.0;
        displayData.add(
          _AllocationItem(
            label: categories[i],
            value: values[i],
            percent: percent,
            color: colors[i],
          ),
        );
      }
    }
    displayData.sort((a, b) => b.value.compareTo(a.value));

    final largestPercentText = displayData.isNotEmpty 
        ? '${displayData.first.percent.toStringAsFixed(0)}%' 
        : '0%';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEBE6DD),
          width: 1,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '자산 비중 분석',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                height: 32,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEFECE6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildToggleButton(
                      label: '자산군별',
                      isSelected: _showByAssetClass,
                      onTap: () => setState(() => _showByAssetClass = true),
                    ),
                    _buildToggleButton(
                      label: '계좌별',
                      isSelected: !_showByAssetClass,
                      onTap: () => setState(() => _showByAssetClass = false),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(90, 90),
                      painter: DonutChartPainter(
                        values: values,
                        colors: colors,
                        strokeWidth: 10,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _showByAssetClass ? '최대 비중' : '최대 계좌',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          largestPercentText,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: List.generate(displayData.length, (index) {
                    final item = displayData[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: item.color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.label,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '${item.percent.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.grey[300] : const Color(0xFF2C2C2C),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            formatCurrency(item.value),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF176B5B) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected && !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? (isDark ? Colors.white : const Color(0xFF176B5B))
                : (isDark ? Colors.grey[400] : const Color(0xFF6E675E)),
          ),
        ),
      ),
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final double strokeWidth;

  DonutChartPainter({
    required this.values,
    required this.colors,
    this.strokeWidth = 10.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    double total = values.fold(0, (sum, val) => sum + val);
    if (total == 0) {
      final paint = Paint()
        ..color = Colors.grey.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(center, radius, paint);
      return;
    }

    double startAngle = -1.57079632679; // Top start (-90 degrees)
    final rect = Rect.fromCircle(center: center, radius: radius);

    for (int i = 0; i < values.length; i++) {
      if (values[i] == 0) continue;
      final sweepAngle = (values[i] / total) * 6.28318530718;
      
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.colors != colors;
  }
}


