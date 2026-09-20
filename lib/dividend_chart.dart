import 'package:flutter/material.dart';
import 'dividend_models.dart';
import 'dividend_ticker.dart';
import 'common_widgets.dart';

class DividendSummaryHeader extends StatelessWidget {
  const DividendSummaryHeader({
    super.key,
    required this.annualTotal,
    required this.monthlyAverage,
    required this.dividendYield,
    required this.applyTax,
    required this.onApplyTaxChanged,
  });

  final double annualTotal;
  final double monthlyAverage;
  final double dividendYield;
  final bool applyTax;
  final ValueChanged<bool> onApplyTaxChanged;

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
                      Icons.monetization_on_outlined,
                      size: 16,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '내 배당 요약',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      showModernHelpDialog(
                        context: context,
                        title: '배당 요약 및 세금 안내',
                        badge: '배당 분석 가이드',
                        icon: Icons.monetization_on_outlined,
                        content: '• 연간/월평균 배당금: 보유 종목의 최근 공시 배당금을 기준으로 1년간 받게 될 배당 총액 및 12개월 평균값입니다.\n'
                                 '• 세후(15.4%) 적용: 토글 활성화 시 배당소득세(15.4%)를 차감한 실수령액 기준으로 계산됩니다.\n'
                                 '• 절세 계좌 혜택: 연금저축 및 IRP 계좌에 보관된 자산은 세법상 세금이 원천징수되지 않고 전액 비과세(과세이연) 처리됩니다.',
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.help_outline_rounded,
                        size: 15,
                        color: isDark ? Colors.grey[400] : const Color(0xFF8E867C),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '세후(15.4%) 적용',
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
                        value: applyTax,
                        onChanged: onApplyTaxChanged,
                        activeThumbColor: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: '연간 예상 배당금',
                  value: annualTotal > 0 
                      ? '₩${formatDividendNumber(annualTotal.round())}' 
                      : '₩0',
                  color: isDark ? const Color(0xFF13584B) : const Color(0xFF176B5B),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: '월평균 배당금',
                  value: monthlyAverage > 0 
                      ? '₩${formatDividendNumber(monthlyAverage.round())}' 
                      : '₩0',
                  color: isDark ? const Color(0xFF945200) : const Color(0xFFAD5E00),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // ── 포트폴리오 예상 배당수익률 (슬림 & 프리미엄 가로 바) ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF222222) : const Color(0xFFF9F7F3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF333333) : const Color(0xFFE8E3DA),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: isDark ? 0.22 : 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.percent_rounded,
                    size: 17,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '포트폴리오 예상 배당수익률',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF2C2A28),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '총 보유 자산 대비 연간 배당률',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey[400] : const Color(0xFF8C847A),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: isDark ? 0.18 : 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.25),
                      width: 0.6,
                    ),
                  ),
                  child: Text(
                    '${dividendYield.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                      color: primaryColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          DailyDividendTicker(annualTotal: annualTotal),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String title,
    required String value,
    required Color color,
    bool isFullWidth = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDarkBg = color.computeLuminance() < 0.35;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: !isDarkBg
            ? Border.all(
                color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E0D7),
                width: 0.8,
              )
            : null,
        boxShadow: [
          if (!isDarkBg)
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 1),
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
              color: isDarkBg 
                  ? Colors.white.withValues(alpha: 0.8) 
                  : (isDark ? Colors.grey[400] : const Color(0xFF6E675E)),
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
                color: isDarkBg 
                    ? Colors.white 
                    : (isDark ? Colors.white : const Color(0xFF1A1A1A)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DividendFlowBarChart extends StatelessWidget {
  const DividendFlowBarChart({
    super.key,
    required this.monthlyDividends,
    required this.selectedMonth,
    required this.onMonthSelected,
  });

  final Map<int, double> monthlyDividends;
  final int? selectedMonth;
  final ValueChanged<int?> onMonthSelected;

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
                      Icons.bar_chart_rounded,
                      size: 16,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    selectedMonth == null ? '월별 예상 배당금 흐름' : '$selectedMonth월 배당금 흐름',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      showModernHelpDialog(
                        context: context,
                        title: '예상 배당금 산출 방식',
                        badge: '배당 분석 가이드',
                        icon: Icons.bar_chart_rounded,
                        content: '• 최근 공시 기준: 종목별로 가장 최근에 실제 지급된 주당 배당금을 기준으로 계산합니다.\n'
                                 '• 배당 주기별 배분: 월/분기/반기/연 단위 지급 일정 공시에 맞춰 미래 1년 치 예상 배당액을 각 월별로 배분합니다.\n'
                                 '• 실지급일 차이: 기업 및 운용사 공시, 영업일, 결제 주기(T+2)에 따라 실제 증권사 입금일과 1~2영업일 차이가 발생할 수 있습니다.',
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.help_outline_rounded,
                        size: 15,
                        color: isDark ? Colors.grey[400] : const Color(0xFF8E867C),
                      ),
                    ),
                  ),
                ],
              ),
              Visibility(
                visible: selectedMonth != null,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: InkWell(
                  onTap: () => onMonthSelected(null),
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      '전체보기',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF176B5B),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: LayoutBuilder(
              builder: (context, constraints) {
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
                    final isSelected = selectedMonth == month;

                    return GestureDetector(
                      onTap: () {
                        if (val > 0) {
                          onMonthSelected(isSelected ? null : month);
                        }
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (val > 0)
                            Text(
                              val >= 10000 
                                  ? '${(val / 10000).toStringAsFixed(1)}만' 
                                  : formatDividendNumber(val.round()),
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
              },
            ),
          ),
        ],
      ),
    );
  }
}
