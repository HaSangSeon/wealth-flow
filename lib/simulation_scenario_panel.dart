import 'package:flutter/material.dart';
import 'formatters.dart';
import 'common_widgets.dart';

class ScenarioPanel extends StatelessWidget {
  final double annualReturn;
  final double dividendYield;
  final double actualDividendYield;
  final double monthlyContribution;
  final double contributionGrowth;
  final int years;
  final ValueChanged<double> onAnnualReturnChanged;
  final ValueChanged<double> onDividendYieldChanged;
  final ValueChanged<double> onMonthlyContributionChanged;
  final ValueChanged<double> onContributionGrowthChanged;
  final ValueChanged<int> onYearsChanged;

  const ScenarioPanel({
    super.key,
    required this.annualReturn,
    required this.dividendYield,
    this.actualDividendYield = 0.0,
    required this.monthlyContribution,
    required this.contributionGrowth,
    required this.years,
    required this.onAnnualReturnChanged,
    required this.onDividendYieldChanged,
    required this.onMonthlyContributionChanged,
    required this.onContributionGrowthChanged,
    required this.onYearsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

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
                      Icons.tune_rounded,
                      size: 16,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '시뮬레이션 시나리오',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0EBE1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$years년 복리 시뮬레이션',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.grey[300] : const Color(0xFF5E574E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 1. 슬라이더 영역 (연속 배치로 통일감 부여)
          SliderField(
            label: '연평균 주가 상승률',
            valueLabel: '${annualReturn.toStringAsFixed(1)}%',
            value: annualReturn.clamp(-10.0, 20.0),
            min: -10,
            max: 20,
            divisions: 60,
            onChanged: onAnnualReturnChanged,
            helpBadge: '시뮬레이션 가이드',
            helpIcon: Icons.trending_up_rounded,
            helpText: '• 실질 주가 상승률: 보유 종목의 매매 가격(시세)이 1년 동안 변동하는 연평균 상승/하락률입니다.\n'
                      '• 인플레이션 반영: 물가상승률을 감안한 실질 기대수익률을 입력하시면 현실에 더 가까운 미래 자산 추정치를 확인할 수 있습니다.\n'
                      '• 배당 수익 제외: 배당금은 하단의 "배당금 전액 재투자" 옵션에서 별도로 복리 계산됩니다.',
          ),
          const SizedBox(height: 4),
          SliderField(
            label: '월 추가 투자금',
            valueLabel: formatCurrencyFull(monthlyContribution),
            value: monthlyContribution.clamp(0.0, 5000000.0),
            min: 0,
            max: 5000000,
            divisions: 50,
            onChanged: onMonthlyContributionChanged,
            helpBadge: '시뮬레이션 가이드',
            helpIcon: Icons.savings_outlined,
            helpText: '• 정기 적립 투자: 매월 급여나 사업 소득에서 주식, ETF 등에 지속적으로 추가 납입할 신규 투자 원금입니다.\n'
                      '• 복리 엔진: 매달 꾸준히 유입되는 신규 자금은 주가 변동성을 낮추고 복리 스노우볼을 가속화합니다.',
          ),
          const SizedBox(height: 14),
          // 2. 하단 옵션 통합 컨테이너 (배당 재투자 + 기간 선택)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252525) : const Color(0xFFF7F5F0),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF333333) : const Color(0xFFE8E3DA),
                width: 0.8,
              ),
            ),
            child: Column(
              children: [
                _buildReinvestRow(context, isDark, primaryColor),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Divider(
                    height: 1,
                    thickness: 0.8,
                    color: isDark ? const Color(0xFF333333) : const Color(0xFFE8E3DA),
                  ),
                ),
                _buildYearsRow(context, isDark, primaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReinvestRow(BuildContext context, bool isDark, Color primaryColor) {
    final bool isReinvesting = dividendYield > 0;
    final effectiveYield = actualDividendYield > 0
        ? actualDividendYield
        : (dividendYield > 0 ? dividendYield : 3.0);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: (isReinvesting
                    ? (isDark ? const Color(0xFF34D399) : primaryColor)
                    : Colors.grey)
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.autorenew_rounded,
            size: 16,
            color: isReinvesting
                ? (isDark ? const Color(0xFF34D399) : primaryColor)
                : (isDark ? Colors.grey[500] : const Color(0xFF8C847A)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '배당금 전액 재투자',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: isReinvesting
                          ? (isDark
                              ? const Color(0xFF34D399).withValues(alpha: 0.15)
                              : primaryColor.withValues(alpha: 0.1))
                          : (isDark ? const Color(0xFF333333) : const Color(0xFFEBE6DD)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '연 ${effectiveYield.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: isReinvesting
                            ? (isDark ? const Color(0xFF34D399) : primaryColor)
                            : (isDark ? Colors.grey[400] : const Color(0xFF7A7265)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                isReinvesting
                    ? '내 보유자산 배당률로 복리 재투자'
                    : '배당금을 쓰거나 수령 (주가 상승만 반영)',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[400] : const Color(0xFF7A7265),
                ),
              ),
            ],
          ),
        ),
        Transform.scale(
          scale: 0.85,
          child: Switch.adaptive(
            value: isReinvesting,
            activeTrackColor: isDark ? const Color(0xFF34D399) : primaryColor,
            onChanged: (val) {
              if (val) {
                onDividendYieldChanged(effectiveYield);
              } else {
                onDividendYieldChanged(0.0);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildYearsRow(BuildContext context, bool isDark, Color primaryColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.schedule_rounded,
            size: 16,
            color: isDark ? Colors.grey[400] : const Color(0xFF6E675E),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '투자 기간',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1E1E1E),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? const Color(0xFF333333) : const Color(0xFFE2DCD2),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [10, 15, 20, 25].map((option) {
              final isSelected = years == option;
              return GestureDetector(
                onTap: () => onYearsChanged(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 8.5, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? const Color(0xFF333333) : const Color(0xFFF0EBE1))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$option년',
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
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class SliderField extends StatelessWidget {
  const SliderField({
    super.key,
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    this.helpText,
    this.helpBadge,
    this.helpIcon,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final String? helpText;
  final String? helpBadge;
  final IconData? helpIcon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.grey[300] : const Color(0xFF4A443B),
                      ),
                    ),
                    if (helpText != null) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          showModernHelpDialog(
                            context: context,
                            title: label,
                            badge: helpBadge ?? '시뮬레이션 가이드',
                            icon: helpIcon ?? Icons.auto_graph_rounded,
                            content: helpText!,
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
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF282828) : const Color(0xFFF2ECE2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  valueLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: primaryColor,
              inactiveTrackColor: isDark ? const Color(0xFF333333) : const Color(0xFFE5E0D7),
              thumbColor: primaryColor,
              overlayColor: primaryColor.withValues(alpha: 0.12),
              trackHeight: 3.5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.5),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
