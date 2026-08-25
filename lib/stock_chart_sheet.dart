import 'package:flutter/material.dart';
import 'formatters.dart';
import 'models.dart';
import 'yahoo_finance_service.dart';

// ─── 종목 시세 히스토리 차트 바텀시트 ───────────────────────────

class StockHistoryChartSheet extends StatefulWidget {
  const StockHistoryChartSheet({super.key, required this.holding});

  final Holding holding;

  @override
  State<StockHistoryChartSheet> createState() => _StockHistoryChartSheetState();
}

class _StockHistoryChartSheetState extends State<StockHistoryChartSheet> {
  final _yahooService = YahooFinanceService();
  String _selectedRange = '3mo'; // '1mo', '3mo', '1y', '5y'
  bool _isLoading = true;
  List<StockHistoryPoint> _historyPoints = [];
  StockHistoryPoint? _touchedPoint;

  final Map<String, String> _rangeLabels = {
    '1mo': '1개월',
    '3mo': '3개월',
    '1y': '1년',
    '5y': '5년',
  };

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final symbol = widget.holding.symbol;
    if (symbol == null || symbol.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _isLoading = true;
      _touchedPoint = null;
    });

    final points = await _yahooService.fetchStockHistory(symbol, range: _selectedRange);
    if (mounted) {
      setState(() {
        _historyPoints = points;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceBg = isDark ? const Color(0xFF141414) : const Color(0xFFF8F7F4);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE8E4DC);

    // 기간 내 등락률 및 최고/최저가 계산
    double periodChangePercent = 0.0;
    double periodChangeAmount = 0.0;
    double periodHigh = 0.0;
    double periodLow = 0.0;

    if (_historyPoints.isNotEmpty) {
      final firstClose = _historyPoints.first.close;
      final lastClose = _historyPoints.last.close;
      periodChangeAmount = lastClose - firstClose;
      periodChangePercent = firstClose > 0 ? (periodChangeAmount / firstClose) * 100 : 0.0;

      periodHigh = _historyPoints.map((p) => p.high).reduce((a, b) => a > b ? a : b);
      periodLow = _historyPoints.map((p) => p.low).reduce((a, b) => a < b ? a : b);
    }

    final isPositive = periodChangePercent >= 0;
    final trendColor = isPositive ? const Color(0xFF176B5B) : const Color(0xFF1E88E5);
    final currency = widget.holding.currency ?? 'KRW';
    final currencySymbol = currency == 'USD' ? '\$' : (currency == 'KRW' ? '₩' : '$currency ');

    // 툴팁에 표시할 현재 포인트
    final activePoint = _touchedPoint ?? (_historyPoints.isNotEmpty ? _historyPoints.last : null);

    return Container(
      decoration: BoxDecoration(
        color: surfaceBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 드래그 핸들
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // 헤더 영역 (종목명 & 현재가)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: trendColor.withValues(alpha: 0.3)),
                ),
                child: Icon(
                  Icons.show_chart_rounded,
                  color: trendColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.holding.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.holding.symbol ?? '',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          activePoint != null
                              ? '$currencySymbol${formatNumber(activePoint.close)}'
                              : '$currencySymbol${formatNumber(widget.holding.originalPrice ?? widget.holding.price)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                          ),
                        ),
                        if (currency != 'KRW' && activePoint == null) ...[
                          const SizedBox(width: 6),
                          Text(
                            '(₩${formatNumber(widget.holding.price)})',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 기간 선택 탭 (1M / 3M / 1Y / 5Y)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFECEAE4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: _rangeLabels.entries.map((entry) {
                final isSelected = _selectedRange == entry.key;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_selectedRange != entry.key) {
                        setState(() => _selectedRange = entry.key);
                        _loadHistory();
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? const Color(0xFF2C2C2C) : Colors.white)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 14),

          // 기간 통계 카드 (수익률, 최고, 최저)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  label: '${_rangeLabels[_selectedRange]} 수익률',
                  value: '${isPositive ? '+' : ''}${periodChangePercent.toStringAsFixed(2)}%',
                  valueColor: trendColor,
                  isBold: true,
                ),
                Container(width: 1, height: 26, color: borderColor),
                _buildStatItem(
                  label: '기간 최고가',
                  value: '$currencySymbol${formatNumber(periodHigh)}',
                  valueColor: isDark ? Colors.grey.shade300 : const Color(0xFF333333),
                ),
                Container(width: 1, height: 26, color: borderColor),
                _buildStatItem(
                  label: '기간 최저가',
                  value: '$currencySymbol${formatNumber(periodLow)}',
                  valueColor: isDark ? Colors.grey.shade300 : const Color(0xFF333333),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 날짜 툴팁 배너 (터치 시 활성화)
          if (activePoint != null) ...[
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '기준일: ${activePoint.date.year}.${activePoint.date.month.toString().padLeft(2, '0')}.${activePoint.date.day.toString().padLeft(2, '0')}  |  종가 $currencySymbol${formatNumber(activePoint.close)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: trendColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // 차트 캔버스 영역
          Container(
            height: 200,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                        SizedBox(height: 10),
                        Text(
                          '시세 히스토리 불러오는 중...',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : _historyPoints.isEmpty
                    ? const Center(
                        child: Text(
                          '시세 데이터를 불러올 수 없습니다.',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          return GestureDetector(
                            onPanDown: (details) => _handleTouch(details.localPosition.dx, constraints.maxWidth),
                            onPanUpdate: (details) => _handleTouch(details.localPosition.dx, constraints.maxWidth),
                            onPanEnd: (_) => setState(() => _touchedPoint = null),
                            onPanCancel: () => setState(() => _touchedPoint = null),
                            child: CustomPaint(
                              size: Size(constraints.maxWidth, constraints.maxHeight),
                              painter: _StockChartPainter(
                                points: _historyPoints,
                                trendColor: trendColor,
                                touchedPoint: _touchedPoint,
                                isDark: isDark,
                              ),
                            ),
                          );
                        },
                      ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '💡 차트를 손가락으로 드래그하면 날짜별 종가를 확인할 수 있습니다.',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleTouch(double dx, double width) {
    if (_historyPoints.isEmpty || width <= 0) return;
    final clampedX = dx.clamp(0.0, width);
    final ratio = clampedX / width;
    final index = (ratio * (_historyPoints.length - 1)).round().clamp(0, _historyPoints.length - 1);
    setState(() {
      _touchedPoint = _historyPoints[index];
    });
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color valueColor,
    bool isBold = false,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _StockChartPainter extends CustomPainter {
  final List<StockHistoryPoint> points;
  final Color trendColor;
  final StockHistoryPoint? touchedPoint;
  final bool isDark;

  _StockChartPainter({
    required this.points,
    required this.trendColor,
    required this.touchedPoint,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final double minPrice = points.map((p) => p.close).reduce((a, b) => a < b ? a : b);
    final double maxPrice = points.map((p) => p.close).reduce((a, b) => a > b ? a : b);
    final double range = maxPrice == minPrice ? 1.0 : (maxPrice - minPrice);

    const double paddingVertical = 16.0;
    const double paddingHorizontal = 12.0;
    final double usableWidth = size.width - (paddingHorizontal * 2);
    final double usableHeight = size.height - (paddingVertical * 2);

    final List<Offset> offsets = [];
    for (int i = 0; i < points.length; i++) {
      final x = paddingHorizontal + (i / (points.length - 1)) * usableWidth;
      final normalizedY = (points[i].close - minPrice) / range;
      final y = size.height - paddingVertical - (normalizedY * usableHeight);
      offsets.add(Offset(x, y));
    }

    // 1. 그라데이션 영역 채우기 (Fill Path)
    final fillPath = Path();
    fillPath.moveTo(offsets.first.dx, size.height);
    fillPath.lineTo(offsets.first.dx, offsets.first.dy);

    for (int i = 0; i < offsets.length - 1; i++) {
      final p0 = offsets[i];
      final p1 = offsets[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      fillPath.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }
    fillPath.lineTo(offsets.last.dx, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          trendColor.withValues(alpha: 0.28),
          trendColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    // 2. 부드러운 스플라인 선 그리기 (Line Path)
    final linePath = Path();
    linePath.moveTo(offsets.first.dx, offsets.first.dy);

    for (int i = 0; i < offsets.length - 1; i++) {
      final p0 = offsets[i];
      final p1 = offsets[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      linePath.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    final linePaint = Paint()
      ..color = trendColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);

    // 3. 터치된 인디케이터 (수직선 & 포인트)
    if (touchedPoint != null) {
      final touchIndex = points.indexOf(touchedPoint!);
      if (touchIndex != -1 && touchIndex < offsets.length) {
        final targetOffset = offsets[touchIndex];

        // 수직 대시 선
        final dashPaint = Paint()
          ..color = isDark ? Colors.white38 : Colors.black26
          ..strokeWidth = 1.2;

        double startY = 4.0;
        while (startY < size.height - 4.0) {
          canvas.drawLine(
            Offset(targetOffset.dx, startY),
            Offset(targetOffset.dx, (startY + 4).clamp(0.0, size.height - 4.0)),
            dashPaint,
          );
          startY += 8.0;
        }

        // 포인트 원형 닷 (Outer Ring + Inner Circle)
        final outerPaint = Paint()
          ..color = trendColor.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(targetOffset, 8.0, outerPaint);

        final innerPaint = Paint()
          ..color = trendColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(targetOffset, 4.5, innerPaint);

        final whitePaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(targetOffset, 2.0, whitePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StockChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.touchedPoint != touchedPoint ||
        oldDelegate.trendColor != trendColor ||
        oldDelegate.isDark != isDark;
  }
}
