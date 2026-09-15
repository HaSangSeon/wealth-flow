import 'package:flutter/material.dart';
import 'formatters.dart';

class ScenarioPanel extends StatelessWidget {
  const ScenarioPanel({
    super.key,
    required this.annualReturn,
    required this.dividendYield,
    required this.monthlyContribution,
    required this.contributionGrowth,
    required this.years,
    required this.onAnnualReturnChanged,
    required this.onDividendYieldChanged,
    required this.onMonthlyContributionChanged,
    required this.onContributionGrowthChanged,
    required this.onYearsChanged,
  });

  final double annualReturn;
  final double dividendYield;
  final double monthlyContribution;
  final double contributionGrowth;
  final int years;
  final ValueChanged<double> onAnnualReturnChanged;
  final ValueChanged<double> onDividendYieldChanged;
  final ValueChanged<double> onMonthlyContributionChanged;
  final ValueChanged<double> onContributionGrowthChanged;
  final ValueChanged<int> onYearsChanged;

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
          const SizedBox(height: 18),
          SliderField(
            label: '연평균 주가성장(시세차익)',
            valueLabel: '${annualReturn.toStringAsFixed(1)}%',
            value: annualReturn,
            min: -10,
            max: 20,
            divisions: 60,
            onChanged: onAnnualReturnChanged,
            helpText: '보유 자산의 매매 가격(시세)이 1년 동안 상승/하락하는 평균 비율입니다.\n\n물가상승률(인플레이션)을 감안한 실질 주가 상승률을 입력하시면 더욱 정교한 시뮬레이션 결과를 볼 수 있습니다.',
          ),
          SliderField(
            label: '연평균 배당수익률',
            valueLabel: '${dividendYield.toStringAsFixed(1)}%',
            value: dividendYield,
            min: 0,
            max: 15,
            divisions: 30,
            onChanged: onDividendYieldChanged,
            helpText: '자산에서 매년 발생하는 배당금(분배금, 이자 등)의 비율입니다.\n\n이 금액은 단리 차트에서는 "현금"으로 누적되며, 복리 차트에서는 매번 "재투자"되는 것으로 계산됩니다.\n(성장주 등 배당이 없는 자산이라면 0%로 설정하세요.)',
          ),
          SliderField(
            label: '월 추가 투자금',
            valueLabel: formatCurrencyFull(monthlyContribution),
            value: monthlyContribution,
            min: 0,
            max: 5000000,
            divisions: 50,
            onChanged: onMonthlyContributionChanged,
            helpText: '매월 새롭게 저축하거나 주식/계좌 등에 직접 추가하여 납입할 신규 원금 액수입니다.',
          ),
          SliderField(
            label: '투자금 연 증가율',
            valueLabel: '${contributionGrowth.toStringAsFixed(1)}%',
            value: contributionGrowth,
            min: 0,
            max: 10,
            divisions: 20,
            onChanged: onContributionGrowthChanged,
            helpText: '연봉 상승이나 소득 증가에 맞추어, 매년 월 투자 저축액을 늘려가는 비율입니다.\n\n예를 들어 월 적립금이 100만 원이고 연 증가율이 5%라면, 2년 차에는 월 105만 원, 3년 차에는 월 110.2만 원으로 증액 납입되어 장기 복리 효과를 더욱 사실적으로 예측해 줍니다.',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                '시뮬레이션 기간',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.grey[300] : const Color(0xFF5E574E),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF262626) : const Color(0xFFF5F3EE),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E0D7),
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
          ),
        ],
      ),
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
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final String? helpText;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.grey[300] : const Color(0xFF5E574E),
                      ),
                    ),
                    if (helpText != null) ...[
                      const SizedBox(width: 5),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: Row(
                                children: [
                                  Icon(Icons.info_outline_rounded, color: primaryColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    label,
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                                  ),
                                ],
                              ),
                              content: Text(
                                helpText!,
                                style: TextStyle(
                                  height: 1.45,
                                  fontSize: 13.5,
                                  color: isDark ? Colors.grey[300] : const Color(0xFF333333),
                                ),
                              ),
                              actions: [
                                FilledButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('확인', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Icon(
                          Icons.help_outline_rounded,
                          size: 15,
                          color: isDark ? Colors.grey[400] : const Color(0xFF8E867C),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF262626) : const Color(0xFFF4F0E8),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  valueLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: isDark ? Colors.grey[200] : const Color(0xFF1A1A1A),
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
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
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
