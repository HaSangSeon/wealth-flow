import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'dividend_models.dart';

class DividendPortfolioList extends StatelessWidget {
  const DividendPortfolioList({
    super.key,
    required this.allDividends,
    required this.stockSummaries,
    required this.filteredDividends,
    required this.selectedMonth,
    required this.showForeignInKrw,
    required this.onShowForeignInKrwChanged,
  });

  final List<UpcomingDividend> allDividends;
  final List<StockDividendSummary> stockSummaries;
  final List<UpcomingDividend> filteredDividends;
  final int? selectedMonth;
  final bool showForeignInKrw;
  final ValueChanged<bool> onShowForeignInKrwChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
            blurRadius: 8,
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
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.pie_chart_outline_rounded,
                      size: 16,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    selectedMonth == null ? '내 배당 포트폴리오' : '$selectedMonth월 배당금 지급 일정',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '원화 환산',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[400] : const Color(0xFF6E675E),
                    ),
                  ),
                  const SizedBox(width: 2),
                  SizedBox(
                    height: 26,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Switch(
                        value: showForeignInKrw,
                        onChanged: onShowForeignInKrwChanged,
                        activeThumbColor: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          
          if (allDividends.isEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '※ 등록된 주식 자산에 아직 배당 데이터가 동기화되지 않았습니다. (예시 화면)',
                style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 8),
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
            if (selectedMonth == null)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: stockSummaries.length,
                itemBuilder: (context, index) {
                  return _buildStockSummaryRow(context, stockSummaries[index], showForeignInKrw);
                },
              )
            else if (filteredDividends.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: Text(
                    '$selectedMonth월에는 지급된 배당금이 없습니다.',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: filteredDividends.length,
                itemBuilder: (context, index) {
                  final div = filteredDividends[index];
                  final formattedNativeTotal = div.currency == 'KRW'
                      ? '₩${formatDividendNumber(div.krwAmount.round())}'
                      : '${div.currency == 'USD' ? '\$' : '${div.currency} '}${div.totalAmount.toStringAsFixed(2)}';
                      
                  final displayTotal = (showForeignInKrw || div.currency == 'KRW')
                      ? '₩${formatDividendNumber(div.krwAmount.round())}'
                      : formattedNativeTotal;
                      
                  String displayAmountPerShare;
                  if (div.currency == 'KRW') {
                    displayAmountPerShare = '주당 ${formatDividendNumber(div.amountPerShare.round())}원';
                  } else if (showForeignInKrw) {
                    final double exchangeRate = div.totalAmount > 0 ? (div.krwAmount / div.totalAmount) : 1350.0;
                    final double krwPerShare = div.amountPerShare * exchangeRate;
                    displayAmountPerShare = '주당 ${formatDividendNumber(krwPerShare.round())}원';
                  } else {
                    displayAmountPerShare = '주당 ${div.currency == 'USD' ? '\$' : '${div.currency} '}${div.amountPerShare.toStringAsFixed(2)}';
                  }
                  
                  return _buildDividendRow(
                    context,
                    symbol: div.symbol,
                    name: div.name,
                    amount: displayAmountPerShare,
                    total: displayTotal,
                    dateText: '${div.isHistorical ? (div.isEstimated ? "추정지급" : "지급완료") : "예상지급"}: ${div.paymentDate.year}/${div.paymentDate.month}/${div.paymentDate.day} | 기준일: ${div.date.month}/${div.date.day}',
                    isHistorical: div.isHistorical,
                    isTaxFree: div.isTaxFree,
                    isEstimated: div.isEstimated,
                  );
                },
              ),
          ],
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
    bool isHistorical = false,
    bool isTaxFree = false,
    bool isEstimated = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262626) : const Color(0xFFF8F6F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF333333) : const Color(0xFFEDE9E1),
          width: 0.6,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isHistorical
                            ? const Color(0xFF2E7D32).withValues(alpha: isDark ? 0.25 : 0.12)
                            : const Color(0xFFEAA622).withValues(alpha: isDark ? 0.25 : 0.15),
                        borderRadius: BorderRadius.circular(3.5),
                      ),
                      child: Text(
                        isHistorical
                            ? (isEstimated ? '추정지급일 경과' : '지급완료')
                            : (isEstimated ? '지급예정(추정)' : '지급예정'),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isHistorical ? const Color(0xFF2E7D32) : const Color(0xFFC27B00),
                        ),
                      ),
                    ),
                    if (isTaxFree) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: isDark ? 0.25 : 0.12),
                          borderRadius: BorderRadius.circular(3.5),
                        ),
                        child: const Text(
                          '비과세',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  symbol,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                total,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14.5,
                  color: Color(0xFF176B5B),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                amount,
                style: const TextStyle(fontSize: 10.5, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                dateText,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockSummaryRow(BuildContext context, StockDividendSummary summary, bool showForeignInKrw) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final formattedNative = summary.currency == 'KRW'
        ? '₩${formatDividendNumber(summary.totalKrwAmount.round())}'
        : '${summary.currency == 'USD' ? '\$' : '${summary.currency} '}${summary.totalAnnualAmount.toStringAsFixed(2)}';
        
    final mainAmountStr = (showForeignInKrw || summary.currency == 'KRW') 
        ? '₩${formatDividendNumber(summary.totalKrwAmount.round())}' 
        : formattedNative;
        
    final secondaryAmountStr = (showForeignInKrw && summary.currency != 'KRW') 
        ? formattedNative 
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262626) : const Color(0xFFF8F6F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF333333) : const Color(0xFFEDE9E1),
          width: 0.6,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => showDividendDetailsSheet(context, summary, showForeignInKrw),
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
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2E9E82).withValues(alpha: 0.2) : const Color(0xFFE6F4F1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFF2E9E82).withValues(alpha: 0.3),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              summary.frequencyLabel.replaceAll('배당', ''),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF176B5B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    summary.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (summary.dividendGrowthRate != null) ...[
                                  const SizedBox(width: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isDark 
                                            ? [const Color(0xFFFDE68A).withValues(alpha: 0.15), const Color(0xFFF59E0B).withValues(alpha: 0.05)]
                                            : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.trending_up_rounded,
                                          size: 11,
                                          color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          '인상 +${summary.dividendGrowthRate!.toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${summary.symbol.isNotEmpty ? '${summary.symbol} · ' : ''}${summary.accountLabel} | 예상 지급월: ${summary.paymentMonths.join(', ')}월',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      mainAmountStr,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                        color: Color(0xFF176B5B),
                      ),
                    ),
                    if (secondaryAmountStr.isNotEmpty) ...[
                      const SizedBox(height: 3),
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
}

void showDividendDetailsSheet(BuildContext context, StockDividendSummary summary, bool showForeignInKrw) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final primaryColor = Theme.of(context).colorScheme.primary;
  final upcomingDividends = summary.dividends.where((d) => !d.isHistorical).toList();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    showDragHandle: false,
    builder: (context) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.72,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 14, bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : const Color(0xFFDDD8CE),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.calendar_month_rounded,
                      color: primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                summary.name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                                  letterSpacing: -0.4,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF2E9E82).withValues(alpha: 0.2) : const Color(0xFFE8F5F1),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                summary.frequencyLabel,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFF34D399) : primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          summary.symbol.isNotEmpty ? '${summary.symbol} · 연간 배당 일정' : '연간 배당 일정',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey[400] : const Color(0xFF8C847A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    iconSize: 20,
                    color: isDark ? Colors.grey[400] : const Color(0xFF8C847A),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 0.8,
              color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEDE9E1),
            ),
            Expanded(
              child: upcomingDividends.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.event_busy_rounded,
                            size: 40,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '등록된 배당 일정이 없습니다.',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.grey[400] : const Color(0xFF8C847A),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      physics: const BouncingScrollPhysics(),
                      itemCount: upcomingDividends.length,
                      itemBuilder: (context, index) {
                        final div = upcomingDividends[index];
                        final formattedNativeTotal = div.currency == 'KRW'
                            ? '₩${formatDividendNumber(div.krwAmount.round())}'
                            : '${div.currency == 'USD' ? '\$' : '${div.currency} '}${div.totalAmount.toStringAsFixed(2)}';
                            
                        final displayTotal = (showForeignInKrw || div.currency == 'KRW')
                            ? '₩${formatDividendNumber(div.krwAmount.round())}'
                            : formattedNativeTotal;

                        final unitAmount = div.currency == 'KRW'
                            ? '주당 ${formatDividendNumber(div.amountPerShare.round())}원'
                            : '주당 ${div.currency == 'USD' ? '\$' : '${div.currency} '}${div.amountPerShare.toStringAsFixed(2)}';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF242424) : const Color(0xFFF9F7F3),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E0D7),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '${div.paymentDate.year}년 ${div.paymentDate.month}월 배당',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14.5,
                                            color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: div.isHistorical
                                                ? const Color(0xFF2E7D32).withValues(alpha: isDark ? 0.25 : 0.12)
                                                : const Color(0xFFEAA622).withValues(alpha: isDark ? 0.25 : 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            div.isHistorical
                                                ? (div.isEstimated ? '추정지급일 경과' : '지급완료')
                                                : (div.isEstimated ? '지급예정(추정)' : '지급예정'),
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                              color: div.isHistorical ? const Color(0xFF2E7D32) : const Color(0xFFC27B00),
                                            ),
                                          ),
                                        ),
                                        if (div.isTaxFree) ...[
                                          const SizedBox(width: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withValues(alpha: isDark ? 0.25 : 0.12),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              '비과세',
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Icon(
                                          div.isHistorical ? Icons.check_circle_outline : Icons.event_available_outlined,
                                          size: 13,
                                          color: div.isHistorical ? const Color(0xFF2E7D32) : (isDark ? Colors.grey[500] : const Color(0xFF8C847A)),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${div.isHistorical ? (div.isEstimated ? "추정지급" : "실지급") : "예상지급"}: ${div.paymentDate.year}.${div.paymentDate.month.toString().padLeft(2, '0')}.${div.paymentDate.day.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w500,
                                            color: isDark ? Colors.grey[400] : const Color(0xFF7A7265),
                                          ),
                                        ),
                                        Text(
                                          '  ·  ',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isDark ? Colors.grey[600] : const Color(0xFFCBC5BC),
                                          ),
                                        ),
                                        Flexible(
                                          child: Text(
                                            '기준일: ${div.date.year}.${div.date.month.toString().padLeft(2, '0')}.${div.date.day.toString().padLeft(2, '0')}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark ? Colors.grey[500] : const Color(0xFF9E9790),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
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
                                    displayTotal,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15.5,
                                      color: div.isHistorical 
                                          ? const Color(0xFF2E7D32) 
                                          : (isDark ? const Color(0xFF34D399) : primaryColor),
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    unitAmount,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.grey[400] : const Color(0xFF7A7265),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            // 배당 정보 안내 문구
            Builder(
              builder: (context) {
                final mediaQuery = MediaQuery.of(context);
                final systemBottomPadding = math.max(mediaQuery.viewPadding.bottom, mediaQuery.padding.bottom);
                return Container(
                  margin: EdgeInsets.fromLTRB(16, 0, 16, 16 + systemBottomPadding),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1F2937).withValues(alpha: 0.8)
                        : const Color(0xFFF5F3EF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF374151)
                          : const Color(0xFFDDD8CE),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 13,
                        color: isDark ? Colors.grey[500] : const Color(0xFFAA9B8A),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '배당 지급일과 예상 금액은 현재 보유수량 및 배당락일 공시 기준 추정값입니다. 실제 증권사 입금일 및 과거 실제 수령액과는 보유 시점·결제 주기(T+2)에 따라 차이가 날 수 있습니다.',
                          style: TextStyle(
                            fontSize: 10.5,
                            height: 1.5,
                            color: isDark
                                ? Colors.grey[500]
                                : const Color(0xFF9E9790),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}
