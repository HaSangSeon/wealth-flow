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
    final primaryColor = Theme.of(context).colorScheme.primary;

    // 1. 데이터 집계
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
        const Color(0xFF176B5B), // 국내주식 (에메랄드)
        const Color(0xFF2563EB), // 해외주식 (로열블루)
        const Color(0xFFEAA622), // ETF (앰버골드)
        const Color(0xFF8E867C), // 현금/기타 (슬레이트)
      ];

      for (int i = 0; i < types.length; i++) {
        final val = assetValues[types[i]] ?? 0;
        categories.add(labels[i]);
        values.add(val);
        colors.add(palette[i]);
      }
    } else {
      final accounts = [AccountType.general, AccountType.isa, AccountType.pension, AccountType.irp];
      final labels = ['일반계좌', 'ISA', '연금저축', 'IRP'];
      final palette = [
        const Color(0xFF176B5B), // 일반계좌
        const Color(0xFF2563EB), // ISA
        const Color(0xFF7C3AED), // 연금저축
        const Color(0xFFDB2777), // IRP
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

    final topItem = displayData.isNotEmpty ? displayData.first : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE5E0D7),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. 헤더 (타이틀 + 세그먼트 토글 칩) ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.pie_chart_rounded,
                      size: 16,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '자산 비중 분석',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              Container(
                height: 32,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF2EFE9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF383838) : const Color(0xFFE5E0D7),
                    width: 0.7,
                  ),
                ),
                child: Row(
                  children: [
                    _buildToggleButton(
                      label: '자산군별',
                      isSelected: _showByAssetClass,
                      onTap: () => setState(() => _showByAssetClass = true),
                    ),
                    const SizedBox(width: 2),
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
          const SizedBox(height: 18),

          // ── 2. 도넛 차트 & 상세 리스트 ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 도넛 링 차트 (중앙에 1위 비중 및 라벨)
              SizedBox(
                width: 104,
                height: 104,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(96, 96),
                      painter: DonutChartPainter(
                        values: values,
                        colors: colors,
                        strokeWidth: 11,
                      ),
                    ),
                    if (topItem != null)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            topItem.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.grey[400] : const Color(0xFF7A7265),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '${topItem.percent.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: topItem.color,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 18),

              // 우측 레전드 리스트 (색상 바, 라벨, 비중%, 평가금액)
              Expanded(
                child: Column(
                  children: List.generate(displayData.length, (index) {
                    final item = displayData[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: item.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: item.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${item.percent.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: item.color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            formatCurrency(item.value),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.grey[400] : const Color(0xFF7A7265),
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
    final primaryColor = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF383838) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? (isDark ? const Color(0xFF34D399) : primaryColor)
                : (isDark ? Colors.grey[400] : const Color(0xFF7A7265)),
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
    this.strokeWidth = 11.0,
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

    double startAngle = -math.pi / 2; // -90 degrees from top
    final rect = Rect.fromCircle(center: center, radius: radius);

    for (int i = 0; i < values.length; i++) {
      if (values[i] == 0) continue;
      final sweepAngle = (values[i] / total) * 2 * math.pi;

      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;

      canvas.drawArc(rect, startAngle + 0.03, sweepAngle - 0.06, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.colors != colors;
  }
}
