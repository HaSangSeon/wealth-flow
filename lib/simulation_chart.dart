import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'models.dart';
import 'formatters.dart';

class ProjectionChart extends StatefulWidget {
  const ProjectionChart({super.key, required this.points});

  final List<ProjectionPoint> points;

  @override
  State<ProjectionChart> createState() => _ProjectionChartState();
}

class _ProjectionChartState extends State<ProjectionChart> with SingleTickerProviderStateMixin {
  int? _selectedIndex;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    _animationController.forward();
  }

  @override
  void didUpdateWidget(ProjectionChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.points != widget.points) {
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (widget.points.length < 2) return const SizedBox.shrink();

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
                      Icons.auto_graph_rounded,
                      size: 16,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '복리 성장 흐름',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              if (_selectedIndex != null && _selectedIndex! < widget.points.length)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E3A33) : const Color(0xFFE8F5F1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${widget.points[_selectedIndex!].year}년차 상세',
                    style: TextStyle(
                      fontSize: 11,
                      color: primaryColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return GestureDetector(
                onPanStart: (details) => _updateSelectedIndex(details.localPosition, width),
                onPanUpdate: (details) => _updateSelectedIndex(details.localPosition, width),
                onPanEnd: (_) => setState(() => _selectedIndex = null),
                onTapDown: (details) => _updateSelectedIndex(details.localPosition, width),
                onTapUp: (_) => setState(() => _selectedIndex = null),
                onTapCancel: () => setState(() => _selectedIndex = null),
                child: Stack(
                  children: [
                    SizedBox(
                      height: 240,
                      width: double.infinity,
                      child: AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: ProjectionChartPainter(
                              widget.points,
                              primaryColor,
                              isDark,
                              _selectedIndex,
                              _animation.value,
                            ),
                          );
                        },
                      ),
                    ),
                    if (_selectedIndex != null && _selectedIndex! < widget.points.length)
                      _buildTooltip(widget.points[_selectedIndex!]),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _updateSelectedIndex(Offset localPosition, double width) {
    if (widget.points.isEmpty) return;
    final chartWidth = width;
    final chartX = localPosition.dx;
    
    if (chartX < 0 || chartX > chartWidth) return;
    
    final pointsCount = widget.points.length;
    final step = chartWidth / (pointsCount - 1);
    
    int index = (chartX / step).round();
    index = index.clamp(0, pointsCount - 1);
    
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Widget _buildTooltip(ProjectionPoint point) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Positioned(
      top: 10,
      left: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${point.year}년차 (${DateTime.now().year + point.year}년)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '총 예상 자산: ${formatCurrency(point.total)}',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 2),
            Builder(
              builder: (context) {
                final initialAsset = widget.points.isNotEmpty ? widget.points.first.total : 0.0;
                final totalInvested = initialAsset + point.cumulativeContribution;
                final profit = point.total - totalInvested;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '누적 투자원금: ${formatCurrency(totalInvested)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '예상 수익: ${profit >= 0 ? '+' : ''}${formatCurrency(profit)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: profit >= 0
                            ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                            : const Color(0xFFE57373),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ProjectionChartPainter extends CustomPainter {
  ProjectionChartPainter(this.points, this.primaryColor, this.isDark, this.selectedIndex, this.animationValue);

  final List<ProjectionPoint> points;
  final Color primaryColor;
  final bool isDark;
  final int? selectedIndex;
  final double animationValue;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final maxY = points.map((p) => p.total).reduce(math.max);
    final minY = points.map((p) => p.total).reduce(math.min);
    final effectiveMinY = math.min(minY, 0.0);
    final rangeY = (maxY - effectiveMinY) <= 0 ? 1.0 : (maxY - effectiveMinY);

    const padding = EdgeInsets.only(left: 45, right: 16, top: 20, bottom: 24);
    final chartWidth = size.width - padding.horizontal;
    final chartHeight = size.height - padding.vertical;

    final gridPaint = Paint()
      ..color = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF0EBE1)
      ..strokeWidth = 0.8;

    final textStyle = TextStyle(
      fontSize: 10,
      color: isDark ? Colors.grey[500] : const Color(0xFF8E867C),
    );

    // Y축 가이드선 및 라벨 (4단계)
    for (int i = 0; i <= 3; i++) {
      final yValue = effectiveMinY + (rangeY * (i / 3));
      final y = padding.top + chartHeight - (chartHeight * (i / 3));

      canvas.drawLine(
        Offset(padding.left, y),
        Offset(size.width - padding.right, y),
        gridPaint,
      );

      final textSpan = TextSpan(text: _formatCompactValue(yValue), style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(padding.left - textPainter.width - 6, y - textPainter.height / 2),
      );
    }

    Offset mapPoint(ProjectionPoint p, int index) {
      final x = padding.left + (chartWidth * (index / (points.length - 1)));
      final y = padding.top + chartHeight - ((p.total - effectiveMinY) / rangeY * chartHeight);
      return Offset(x, y);
    }

    // X축 연도 라벨
    for (int i = 0; i < points.length; i += math.max(1, (points.length / 5).floor())) {
      final pt = mapPoint(points[i], i);
      final textSpan = TextSpan(text: '${points[i].year}년', style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(pt.dx - textPainter.width / 2, size.height - padding.bottom + 6),
      );
    }

    // 곡선 경로 및 그라데이션 채우기
    final path = Path();
    final fillPath = Path();

    final firstPt = mapPoint(points[0], 0);
    path.moveTo(firstPt.dx, firstPt.dy);
    
    fillPath.moveTo(firstPt.dx, padding.top + chartHeight);
    fillPath.lineTo(firstPt.dx, firstPt.dy);

    for (int i = 1; i < points.length; i++) {
      final pt = mapPoint(points[i], i);
      final prevPt = mapPoint(points[i - 1], i - 1);
      final midX = (prevPt.dx + pt.dx) / 2;
      
      path.cubicTo(midX, prevPt.dy, midX, pt.dy, pt.dx, pt.dy);
      fillPath.cubicTo(midX, prevPt.dy, midX, pt.dy, pt.dx, pt.dy);
    }

    final lastPt = mapPoint(points.last, points.length - 1);
    fillPath.lineTo(lastPt.dx, padding.top + chartHeight);
    fillPath.close();

    // 애니메이션 적용 (가로로 서서히 나타나는 효과)
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(padding.left, 0, chartWidth * animationValue, size.height));

    // 그라데이션 영역 채우기
    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, padding.top),
        Offset(0, padding.top + chartHeight),
        [
          primaryColor.withValues(alpha: isDark ? 0.35 : 0.18),
          primaryColor.withValues(alpha: 0.0),
        ],
      );
    canvas.drawPath(fillPath, fillPaint);

    // 단일 메인 성장 곡선 (1줄)
    final linePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    canvas.restore();

    // 터치/선택된 인덱스 하이라이트
    if (selectedIndex != null && selectedIndex! < points.length) {
      final selPt = mapPoint(points[selectedIndex!], selectedIndex!);

      final selectLinePaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.5)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(selPt.dx, padding.top),
        Offset(selPt.dx, padding.top + chartHeight),
        selectLinePaint,
      );

      final outerDot = Paint()..color = isDark ? const Color(0xFF1E1E1E) : Colors.white;
      final innerDot = Paint()..color = primaryColor;
      canvas.drawCircle(selPt, 6, outerDot);
      canvas.drawCircle(selPt, 4, innerDot);
    }
  }

  String _formatCompactValue(double value) {
    final abs = value.abs();
    if (abs >= 100000000) {
      return '${(value / 100000000).toStringAsFixed(1)}억';
    }
    if (abs >= 10000) {
      return '${(value / 10000).toStringAsFixed(0)}만';
    }
    return value.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant ProjectionChartPainter oldDelegate) {
    return oldDelegate.points != points || 
           oldDelegate.selectedIndex != selectedIndex ||
           oldDelegate.animationValue != animationValue;
  }
}
