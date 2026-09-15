import 'dart:ui';
import 'package:flutter/material.dart';
import 'models.dart';
import 'premium.dart';
import 'common_widgets.dart';
import 'dividend_models.dart';
import 'dividend_chart.dart';
import 'dividend_stock_list.dart';
import 'dividend_calendar.dart';
import 'dividend_ticker.dart';
import 'dividend_tax_safety_card.dart';

export 'dividend_models.dart';
export 'dividend_chart.dart';
export 'dividend_stock_list.dart';
export 'dividend_calendar.dart';

class DividendTab extends StatefulWidget {
  const DividendTab({
    super.key,
    required this.storage,
    required this.holdings,
    required this.onPremiumChanged,
    this.onDataRestored,
  });

  final StorageService storage;
  final List<Holding> holdings;
  final VoidCallback onPremiumChanged;
  final VoidCallback? onDataRestored;

  @override
  State<DividendTab> createState() => _DividendTabState();
}

class _DividendTabState extends State<DividendTab> {
  int? _selectedMonth;
  bool _showForeignInKrw = false;
  bool _applyTax = false;
  bool _showCalendar = false;
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  Widget _buildTabToggle(bool isDark) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF0EFEF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: _showCalendar ? Alignment.centerRight : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_showCalendar) setState(() => _showCalendar = false);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      '배당 현황',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: !_showCalendar ? FontWeight.bold : FontWeight.normal,
                        color: !_showCalendar 
                            ? (isDark ? Colors.white : Colors.black87)
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (!_showCalendar) setState(() => _showCalendar = true);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      '배당 달력',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: _showCalendar ? FontWeight.bold : FontWeight.normal,
                        color: _showCalendar
                            ? (isDark ? Colors.white : Colors.black87)
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // 계산 엔진 호출
    final data = calculateDividendData(
      holdings: widget.holdings,
      lastExchangeRate: widget.storage.lastExchangeRate,
      applyTax: _applyTax,
    );

    final double monthlyAverage = data.annualTotal / 12;
    final double dividendYield = data.totalStockValuation > 0 
        ? (data.annualTotal / data.totalStockValuation) * 100 
        : 0.0;

    final filteredDividends = _selectedMonth == null 
        ? data.allDividends.take(15).toList() 
        : data.allDividends.where((d) => d.paymentDate.month == _selectedMonth).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // 공통 상단 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF176B5B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.calendar_month_outlined, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '배당 분석',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '월별 현금 흐름 및 지급 일정',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  HeaderActionButtons(
                    storage: widget.storage,
                    onNotificationChanged: widget.onPremiumChanged,
                    onDataRestored: widget.onDataRestored,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: _buildTabToggle(isDark),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Stack(
                children: [
                  if (!_showCalendar)
                    SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DividendSummaryHeader(
                            annualTotal: data.annualTotal,
                            monthlyAverage: monthlyAverage,
                            dividendYield: dividendYield,
                            applyTax: _applyTax,
                            onApplyTaxChanged: (val) => setState(() => _applyTax = val),
                          ),
                          const SizedBox(height: 16),
                          DividendFlowBarChart(
                            monthlyDividends: data.monthlyDividends,
                            selectedMonth: _selectedMonth,
                            onMonthSelected: (m) => setState(() => _selectedMonth = m),
                          ),
                          const SizedBox(height: 16),
                          DividendTaxSafetyCard(
                            taxableGrossAnnualTotal: data.taxableGrossAnnualTotal,
                            taxFreeGrossAnnualTotal: data.taxFreeGrossAnnualTotal,
                          ),
                          const SizedBox(height: 16),
                          DividendPortfolioList(
                            allDividends: data.allDividends,
                            stockSummaries: data.stockSummaries,
                            filteredDividends: filteredDividends,
                            selectedMonth: _selectedMonth,
                            showForeignInKrw: _showForeignInKrw,
                            onShowForeignInKrwChanged: (val) => setState(() => _showForeignInKrw = val),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2C2C2C).withValues(alpha: 0.5) : const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '본 배당 정보는 금융 공시 데이터 기반의 실지급 및 예상 일정입니다. 종목별 주총/운용사 공시 및 영업일에 따라 실제 입금일과 1~2일 차이가 있을 수 있으며, 연금저축/IRP 계좌는 세법상 배당소득세(15.4%)가 과세이연(비과세) 반영됩니다.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  if (_showCalendar)
                    DividendCalendarView(
                      allDividends: data.allDividends,
                      focusedMonth: _focusedMonth,
                      selectedDay: _selectedDay,
                      showForeignInKrw: _showForeignInKrw,
                      onFocusedMonthChanged: (m) => setState(() => _focusedMonth = m),
                      onSelectedDayChanged: (d) => setState(() => _selectedDay = d),
                      onShowForeignInKrwChanged: (val) => setState(() => _showForeignInKrw = val),
                    ),
                  
                  // 프리미엄 블러 오버레이
                  if (!widget.storage.isPremium)
                    Positioned.fill(
                      child: ClipRRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
                            child: Center(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 32),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEAA622).withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.stars,
                                        color: Color(0xFFEAA622),
                                        size: 40,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    const Text(
                                      '👑 프리미엄 배당 분석',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '월별 배당금 캘린더와 포트폴리오의 연간 배당 흐름을 한눈에 관리해 보세요.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark ? Colors.white70 : Colors.black54,
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 52,
                                      child: FilledButton(
                                        onPressed: () async {
                                          final result = await Navigator.push<bool>(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => PremiumSubscriptionScreen(storage: widget.storage),
                                            ),
                                          );
                                          if (result == true) {
                                            widget.onPremiumChanged();
                                          }
                                        },
                                        style: FilledButton.styleFrom(
                                          backgroundColor: const Color(0xFF176B5B),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                        ),
                                        child: const Text(
                                          '프리미엄 업그레이드',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
