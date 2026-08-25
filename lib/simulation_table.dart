import 'package:flutter/material.dart';
import 'models.dart';
import 'formatters.dart';

class ProjectionTable extends StatefulWidget {
  const ProjectionTable({super.key, required this.points});

  final List<ProjectionPoint> points;

  @override
  State<ProjectionTable> createState() => _ProjectionTableState();
}

class _ProjectionTableState extends State<ProjectionTable> {
  final ScrollController _scrollController = ScrollController();
  bool _showSwipeHint = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _scrollController.position.maxScrollExtent <= 0) {
        if (mounted) setState(() => _showSwipeHint = false);
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    
    if (maxScroll > 0 && currentScroll >= maxScroll - 20) {
      if (_showSwipeHint) setState(() => _showSwipeHint = false);
    } else {
      if (!_showSwipeHint) setState(() => _showSwipeHint = true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
                      Icons.table_chart_rounded,
                      size: 16,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '연도별 자산 상세',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              AnimatedOpacity(
                opacity: _showSwipeHint ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0EBE1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.swipe_left_rounded, 
                        size: 13, 
                        color: isDark ? Colors.grey[400] : const Color(0xFF7A7265),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '밀어서 더 보기',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.grey[400] : const Color(0xFF7A7265),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  isDark ? const Color(0xFF262626) : const Color(0xFFF7F5F0),
                ),
                dataRowColor: WidgetStateProperty.resolveWith<Color?>((states) {
                  return isDark ? const Color(0xFF1E1E1E) : Colors.white;
                }),
                columnSpacing: 18,
                horizontalMargin: 14,
                columns: [
                  DataColumn(label: Text('연차', style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.grey[300] : const Color(0xFF1A1A1A)))),
                  DataColumn(label: Text('누적 투자금', style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.grey[300] : const Color(0xFF1A1A1A)))),
                  DataColumn(label: Text('총 자산', style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.grey[300] : const Color(0xFF1A1A1A)))),
                  DataColumn(label: Text('수익 (수익률)', style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.grey[300] : const Color(0xFF1A1A1A)))),
                ],
                rows: widget.points.where((p) => p.year > 0).map((p) {
                  final initialAsset = widget.points.first.total;
                  final totalInvested = initialAsset + p.cumulativeContribution;
                  final profit = p.total - totalInvested;
                  final returnRate = totalInvested > 0 ? (profit / totalInvested) * 100 : 0.0;
                  return DataRow(
                    cells: [
                      DataCell(Text('${p.year}년', style: const TextStyle(fontWeight: FontWeight.w700))),
                      DataCell(Text(formatCurrency(totalInvested))),
                      DataCell(Text(
                        formatCurrency(p.total),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                        ),
                      )),
                      DataCell(Text(
                        '${formatCurrency(profit)} (${returnRate >= 0 ? '+' : ''}${returnRate.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          color: profit >= 0
                              ? (isDark ? const Color(0xFF34D399) : primaryColor)
                              : const Color(0xFFE57373),
                          fontWeight: FontWeight.w800,
                        ),
                      )),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
