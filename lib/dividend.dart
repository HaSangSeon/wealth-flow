import 'dart:ui';
import 'package:flutter/material.dart';
import 'models.dart';
import 'premium.dart';

class DividendTab extends StatefulWidget {
  const DividendTab({
    super.key,
    required this.storage,
    required this.holdings,
    required this.onPremiumChanged,
  });

  final StorageService storage;
  final List<Holding> holdings;
  final VoidCallback onPremiumChanged;

  @override
  State<DividendTab> createState() => _DividendTabState();
}

class _DividendTabState extends State<DividendTab> {
  int? _selectedMonth;
  bool _showForeignInKrw = false;
  bool _applyTax = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // 1. Calculate real expected dividends from holdings
    final Map<int, double> monthlyDividends = {for (var i = 1; i <= 12; i++) i: 0.0};
    double annualTotal = 0.0;
    double totalStockValuation = 0.0;
    
    final List<_UpcomingDividend> allDividends = [];
    final List<_StockDividendSummary> stockSummaries = [];

    DateTime addMonths(DateTime date, int months) {
      int newYear = date.year + (date.month + months - 1) ~/ 12;
      int newMonth = (date.month + months - 1) % 12 + 1;
      int newDay = date.day;
      int maxDays = DateTime(newYear, newMonth + 1, 0).day;
      if (newDay > maxDays) newDay = maxDays;
      return DateTime(newYear, newMonth, newDay);
    }

    for (var h in widget.holdings) {
      if (h.type == AssetType.cash) continue;
      
      // Calculate total valuation of stocks/ETFs
      totalStockValuation += (h.quantity * h.price);

      if (h.dividends == null || h.dividends!.isEmpty) continue;

      double exchangeRate = 1.0;
      if (h.currency != 'KRW') {
        if (h.originalPrice != null && h.originalPrice! > 0) {
          exchangeRate = h.price / h.originalPrice!;
        } else {
          exchangeRate = widget.storage.lastExchangeRate;
        }
      }

      double stockAnnualKrw = 0.0;
      double stockAnnualForeign = 0.0;
      final Set<int> paymentMonths = {};
      final List<_UpcomingDividend> stockDividends = [];

      // 전체 배당 내역을 날짜 내림차순(최신순) 정렬
      final sortedDivs = List<Map<String, dynamic>>.from(h.dividends!)
        ..sort((a, b) => (b['date'] as int).compareTo(a['date'] as int));
      
      final latestTimestamp = sortedDivs.first['date'] as int;
      final currentTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      // 배당 컷 방어: 마지막 배당락일이 400일(34560000초) 초과 시 배당 중단으로 간주
      if ((currentTimestamp - latestTimestamp) > 34560000) {
        continue;
      }

      // 배당 주기 감지 (Frequency Detection)
      String freqLabel = '연배당';
      int frequencyCount = 1;
      if (sortedDivs.length > 1) {
        final List<int> intervals = [];
        for (int i = 0; i < sortedDivs.length - 1; i++) {
          final d1 = DateTime.fromMillisecondsSinceEpoch((sortedDivs[i+1]['date'] as int) * 1000);
          final d2 = DateTime.fromMillisecondsSinceEpoch((sortedDivs[i]['date'] as int) * 1000);
          intervals.add(d2.difference(d1).inDays);
        }
        final double avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
        
        if (avgInterval <= 45) {
          freqLabel = '월배당';
          frequencyCount = 12;
        } else if (avgInterval <= 120) {
          freqLabel = '분기배당';
          frequencyCount = 4;
        } else if (avgInterval <= 240) {
          freqLabel = '반기배당';
          frequencyCount = 2;
        } else {
          freqLabel = '연배당';
          frequencyCount = 1;
        }
      }

      // 최신 배당금 1개 추출
      final latestDiv = sortedDivs.first;
      final latestDate = DateTime.fromMillisecondsSinceEpoch((latestDiv['date'] as int) * 1000);
      double rawAmount = latestDiv['amount'] as double;
      
      // 세후 전환 적용
      if (_applyTax) {
        rawAmount = rawAmount * 0.846;
      }
      
      final krwAmount = h.quantity * rawAmount * exchangeRate;
      
      // 미래 12개월(Forward Projection) 캘린더 생성
      final int monthStep = 12 ~/ frequencyCount;
      for (int i = 1; i <= frequencyCount; i++) {
        final projectedDate = addMonths(latestDate, monthStep * i);
        
        DateTime paymentDate;
        if (h.symbol != null && (h.symbol!.endsWith('.KS') || h.symbol!.endsWith('.KQ'))) {
          if (projectedDate.month == 12) {
            paymentDate = DateTime(projectedDate.year + 1, 4, 15);
          } else {
            paymentDate = projectedDate.add(const Duration(days: 60));
          }
        } else {
          paymentDate = projectedDate.add(const Duration(days: 15));
        }
        
        monthlyDividends[paymentDate.month] = (monthlyDividends[paymentDate.month] ?? 0.0) + krwAmount;
        annualTotal += krwAmount;

        stockAnnualKrw += krwAmount;
        stockAnnualForeign += (h.quantity * rawAmount);
        paymentMonths.add(paymentDate.month);

        final upcomingDiv = _UpcomingDividend(
          name: h.name,
          symbol: h.symbol ?? '',
          amountPerShare: rawAmount,
          totalAmount: h.quantity * rawAmount,
          currency: h.effectiveCurrency,
          date: projectedDate,
          paymentDate: paymentDate,
          krwAmount: krwAmount,
        );
        
        allDividends.add(upcomingDiv);
        stockDividends.add(upcomingDiv);
      }

      if (stockAnnualKrw > 0) {
        final monthsList = paymentMonths.toList()..sort();
        stockDividends.sort((a, b) => b.date.compareTo(a.date));

        stockSummaries.add(_StockDividendSummary(
          name: h.name,
          symbol: h.symbol ?? '',
          totalAnnualAmount: stockAnnualForeign,
          currency: h.effectiveCurrency,
          totalKrwAmount: stockAnnualKrw,
          paymentMonths: monthsList,
          frequencyLabel: freqLabel,
          dividends: stockDividends,
        ));
      }
    }

    // Sort summaries by totalKrwAmount descending
    stockSummaries.sort((a, b) => b.totalKrwAmount.compareTo(a.totalKrwAmount));

    // Sort dividends by date descending (most recent first)
    allDividends.sort((a, b) => b.date.compareTo(a.date));

    final double monthlyAverage = annualTotal / 12;
    final double dividendYield = totalStockValuation > 0 ? (annualTotal / totalStockValuation) * 100 : 0.0;

    // Filter dividends by selected month if active (by paymentDate.month!)
    final filteredDividends = _selectedMonth == null 
        ? allDividends.take(15).toList() 
        : allDividends.where((d) => d.paymentDate.month == _selectedMonth).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('배당 분석', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: Stack(
        children: [
          // 1. The Real Dashboard Content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '내 배당 요약',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '세후(15.4%) 적용',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : const Color(0xFF6E675E),
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          height: 30,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Switch(
                              value: _applyTax,
                              onChanged: (val) {
                                setState(() {
                                  _applyTax = val;
                                });
                              },
                              activeThumbColor: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Summary Cards Row
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        title: '연간 예상 배당금',
                        value: annualTotal > 0 
                            ? '₩${_formatNumber(annualTotal.round())}' 
                            : '₩0',
                        color: const Color(0xFF176B5B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        title: '월평균 배당금',
                        value: monthlyAverage > 0 
                            ? '₩${_formatNumber(monthlyAverage.round())}' 
                            : '₩0',
                        color: const Color(0xFFEAA622),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSummaryCard(
                  context,
                  title: '포트폴리오 예상 배당수익률',
                  value: '${dividendYield.toStringAsFixed(2)}%',
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                  isFullWidth: true,
                ),
                const SizedBox(height: 28),
                
                // Monthly Cashflow Chart Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          _selectedMonth == null ? '월별 예상 배당금 흐름' : '$_selectedMonth월 배당금 흐름',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                                    const SizedBox(width: 8),
                                    const Flexible(
                                      child: Text(
                                        '예상 배당금 산출 방식',
                                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                                      ),
                                    ),
                                  ],
                                ),
                                content: Text(
                                  '종목별로 가장 최근에 지급된 배당금을 기준으로, 각 배당 주기(월/분기/반기/연)에 맞춰 미래 1년 치 예상 배당액을 산출합니다.',
                                  style: TextStyle(
                                    height: 1.5,
                                    fontSize: 14,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('확인', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Icon(
                            Icons.help_outline,
                            size: 16,
                            color: isDark ? Colors.grey[400] : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    Visibility(
                      visible: _selectedMonth != null,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: TextButton(
                        onPressed: () => setState(() => _selectedMonth = null),
                        child: const Text('전체보기', style: TextStyle(color: Color(0xFF176B5B))),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                
                // Real Data Bar Chart
                Container(
                  height: 180,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Find max monthly value to scale bars
                      double maxVal = monthlyDividends.values.fold(0.0, (max, val) => val > max ? val : max);
                      if (maxVal == 0.0) maxVal = 1.0;

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(12, (index) {
                          final month = index + 1;
                          final monthName = '$month월';
                          final val = monthlyDividends[month] ?? 0.0;
                          final double heightFactor = val / maxVal;
                          final isSelected = _selectedMonth == month;

                          return GestureDetector(
                            onTap: () {
                              if (val > 0) {
                                setState(() {
                                  _selectedMonth = isSelected ? null : month;
                                });
                              }
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (val > 0)
                                  Text(
                                    val >= 10000 
                                        ? '${(val / 10000).toStringAsFixed(1)}만' 
                                        : _formatNumber(val.round()),
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? const Color(0xFFEAA622) : Colors.grey,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Expanded(
                                  child: FractionallySizedBox(
                                    heightFactor: val > 0 ? (heightFactor * 0.85).clamp(0.08, 0.85) : 0.02,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      width: 14,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: isSelected 
                                              ? [const Color(0xFFEAA622), const Color(0xFFF3C461)]
                                              : [const Color(0xFF176B5B), const Color(0xFF2E9E82)],
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  monthName,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected 
                                        ? (isDark ? Colors.white : Colors.black87) 
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      );
                    }
                  ),
                ),
                const SizedBox(height: 28),

                // Upcoming Dividend List
                // Upcoming Dividend List Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _selectedMonth == null ? '내 배당 포트폴리오' : '$_selectedMonth월 배당금 지급 일정 (예상)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        Text(
                          '해외자산 원화 환산',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : const Color(0xFF6E675E),
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          height: 30,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Switch(
                              value: _showForeignInKrw,
                              onChanged: (val) {
                                setState(() {
                                  _showForeignInKrw = val;
                                });
                              },
                              activeThumbColor: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Show actual dividends or placeholders if empty
                if (allDividends.isEmpty) ...[
                  // Note for placeholder demo data
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '※ 등록된 주식 자산에 아직 배당 데이터가 동기화되지 않았습니다. (예시 화면)',
                      style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  ),
                  _buildDividendRow(
                    context,
                    symbol: 'AAPL',
                    name: '애플 주식 (예시)',
                    amount: '주당 \$0.25',
                    total: '₩3,450',
                    dateText: '5월 15일 지급',
                  ),
                  _buildDividendRow(
                    context,
                    symbol: '005930',
                    name: '삼성전자 주식 (예시)',
                    amount: '주당 361원',
                    total: '₩36,100',
                    dateText: '5월 20일 지급',
                  ),
                  _buildDividendRow(
                    context,
                    symbol: 'O',
                    name: '리얼티인컴 주식 (예시)',
                    amount: '주당 \$0.26',
                    total: '₩17,940',
                    dateText: '매월 15일 지급',
                  ),
                ] else ...[
                  // List real dividends
                  if (_selectedMonth == null)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: stockSummaries.length,
                      itemBuilder: (context, index) {
                        return _buildStockSummaryRow(context, stockSummaries[index], _showForeignInKrw);
                      },
                    )
                  else if (filteredDividends.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      child: Center(
                        child: Text(
                          '$_selectedMonth월에는 지급된 배당금이 없습니다.',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredDividends.length,
                      itemBuilder: (context, index) {
                        final div = filteredDividends[index];
                        final formattedNativeTotal = div.currency == 'KRW'
                            ? '₩${_formatNumber(div.krwAmount.round())}'
                            : '${div.currency == 'USD' ? '\$' : '${div.currency} '}${div.totalAmount.toStringAsFixed(2)}';
                            
                        final displayTotal = (_showForeignInKrw || div.currency == 'KRW')
                            ? '₩${_formatNumber(div.krwAmount.round())}'
                            : formattedNativeTotal;
                            
                        String displayAmountPerShare;
                        if (div.currency == 'KRW') {
                          displayAmountPerShare = '주당 ${_formatNumber(div.amountPerShare.round())}원';
                        } else if (_showForeignInKrw) {
                          final double exchangeRate = div.totalAmount > 0 ? (div.krwAmount / div.totalAmount) : 1350.0;
                          final double krwPerShare = div.amountPerShare * exchangeRate;
                          displayAmountPerShare = '주당 ${_formatNumber(krwPerShare.round())}원';
                        } else {
                          displayAmountPerShare = '주당 ${div.currency == 'USD' ? '\$' : '${div.currency} '}${div.amountPerShare.toStringAsFixed(2)}';
                        }
                        
                        return _buildDividendRow(
                          context,
                          symbol: div.symbol,
                          name: div.name,
                          amount: displayAmountPerShare,
                          total: displayTotal,
                          dateText: '예상 지급: ${div.paymentDate.year}/${div.paymentDate.month}/${div.paymentDate.day} | 배당락: ${div.date.year}/${div.date.month}/${div.date.day}',
                        );
                      },
                    ),
                  const SizedBox(height: 24),
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
                            '본 배당 정보는 야후 파이낸스(Yahoo Finance)의 과거 1년간(TTM) 지급 내역을 바탕으로 산출된 예상 금액입니다. 신생 ETF나 최신 특별배당의 경우 실제 내역과 차이가 있거나 누락될 수 있습니다.',
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
              ],
            ),
          ),
          
          // 2. Premium Lock Blur Overlay (Visible if not premium)
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
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String value,
    required Color color,
    bool isFullWidth = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSpecialColor = color != Colors.white && color != const Color(0xFF2C2C2C);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isSpecialColor)
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSpecialColor 
                  ? Colors.white.withValues(alpha: 0.7) 
                  : (isDark ? Colors.white70 : Colors.black54),
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isFullWidth ? 22 : 18,
                fontWeight: FontWeight.w900,
                color: isSpecialColor 
                    ? Colors.white 
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDividendRow(
    BuildContext context, {
    required String symbol,
    required String name,
    required String amount,
    required String total,
    required String dateText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  symbol,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                total,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF176B5B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                amount,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                dateText,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockSummaryRow(BuildContext context, _StockDividendSummary summary, bool showForeignInKrw) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final formattedNative = summary.currency == 'KRW'
        ? '₩${_formatNumber(summary.totalKrwAmount.round())}'
        : '${summary.currency == 'USD' ? '\$' : '${summary.currency} '}${summary.totalAnnualAmount.toStringAsFixed(2)}';
        
    final mainAmountStr = (showForeignInKrw || summary.currency == 'KRW') 
        ? '₩${_formatNumber(summary.totalKrwAmount.round())}' 
        : formattedNative;
        
    final secondaryAmountStr = '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showDividendDetails(context, summary, showForeignInKrw),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2E9E82).withValues(alpha: 0.2) : const Color(0xFFE6F4F1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFF2E9E82).withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              summary.frequencyLabel,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF176B5B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              summary.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${summary.symbol} | 예상 지급월: ${summary.paymentMonths.join(', ')}월',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      mainAmountStr,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF176B5B),
                      ),
                    ),
                    if (secondaryAmountStr.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        secondaryAmountStr,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDividendDetails(BuildContext context, _StockDividendSummary summary, bool showForeignInKrw) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAF9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            summary.name,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${summary.symbol} · ${summary.frequencyLabel}',
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: summary.dividends.length,
                  itemBuilder: (context, index) {
                    final div = summary.dividends[index];
                    final formattedNativeTotal = div.currency == 'KRW'
                        ? '₩${_formatNumber(div.krwAmount.round())}'
                        : '${div.currency == 'USD' ? '\$' : '${div.currency} '}${div.totalAmount.toStringAsFixed(2)}';
                        
                    final displayTotal = (showForeignInKrw || div.currency == 'KRW')
                        ? '₩${_formatNumber(div.krwAmount.round())}'
                        : formattedNativeTotal;
                    
                    return _buildDividendRow(
                      context,
                      symbol: '배당락일: ${div.date.year}.${div.date.month.toString().padLeft(2, '0')}.${div.date.day.toString().padLeft(2, '0')}',
                      name: '${div.paymentDate.year}년 ${div.paymentDate.month}월 배당',
                      amount: div.currency == 'KRW' 
                          ? '주당 ${_formatNumber(div.amountPerShare.round())}원'
                          : '주당 ${div.currency == 'USD' ? '\$' : '${div.currency} '}${div.amountPerShare.toStringAsFixed(2)}',
                      total: displayTotal,
                      dateText: '지급예정: ${div.paymentDate.year}.${div.paymentDate.month.toString().padLeft(2, '0')}.${div.paymentDate.day.toString().padLeft(2, '0')}',
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatNumber(int number) {
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return number.toString().replaceAllMapped(reg, (Match match) => '${match[1]},');
  }
}

class _UpcomingDividend {
  final String name;
  final String symbol;
  final double amountPerShare;
  final double totalAmount;
  final String currency;
  final DateTime date;
  final DateTime paymentDate;
  final double krwAmount;

  _UpcomingDividend({
    required this.name,
    required this.symbol,
    required this.amountPerShare,
    required this.totalAmount,
    required this.currency,
    required this.date,
    required this.paymentDate,
    required this.krwAmount,
  });
}

class _StockDividendSummary {
  final String name;
  final String symbol;
  final double totalAnnualAmount;
  final String currency;
  final double totalKrwAmount;
  final List<int> paymentMonths;
  final String frequencyLabel;
  final List<_UpcomingDividend> dividends;

  _StockDividendSummary({
    required this.name,
    required this.symbol,
    required this.totalAnnualAmount,
    required this.currency,
    required this.totalKrwAmount,
    required this.paymentMonths,
    required this.frequencyLabel,
    required this.dividends,
  });
}
