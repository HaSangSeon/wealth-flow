import 'package:flutter/material.dart';

class GoalPlannerView extends StatelessWidget {
  const GoalPlannerView({
    super.key,
    required this.currentValue,
    required this.targetAmount,
    required this.targetYears,
    required this.annualReturn,
    required this.monthlyContribution,
    required this.contributionGrowth,
    required this.onTargetAmountChanged,
    required this.onTargetYearsChanged,
    required this.onMonthlyContributionChanged,
    required this.onAnnualReturnChanged,
  });

  final double currentValue;
  final double targetAmount;
  final int targetYears;
  final double annualReturn;
  final double monthlyContribution;
  final double contributionGrowth;
  final ValueChanged<double> onTargetAmountChanged;
  final ValueChanged<int> onTargetYearsChanged;
  final ValueChanged<double> onMonthlyContributionChanged;
  final ValueChanged<double> onAnnualReturnChanged;

  String _formatKoreanAmount(double amount) {
    if (amount >= 100000000) {
      final double eok = amount / 100000000;
      final int eokInt = eok.floor();
      final double man = (amount % 100000000) / 10000;
      if (man > 0) {
        return '$eokInt억 ${man.round()}만 원';
      } else {
        return '$eokInt억 원';
      }
    } else {
      final double man = amount / 10000;
      return '${man.round()}만 원';
    }
  }

  double _calculateFutureValue(double start, double monthly, double rate, double growth, int yearsCount) {
    double total = start;
    double monthlyContrib = monthly;
    for (var year = 1; year <= yearsCount; year++) {
      final annualContribution = monthlyContrib * 12;
      total = (total + annualContribution) * (1 + rate / 100);
      monthlyContrib *= 1 + growth / 100;
    }
    return total;
  }

  double _calculateRequiredMonthlyContribution(int remainingYears) {
    double low = monthlyContribution;
    double high = monthlyContribution + (targetAmount / 12);
    for (int i = 0; i < 50; i++) {
      double mid = (low + high) / 2;
      double fv = _calculateFutureValue(currentValue, mid, annualReturn, contributionGrowth, remainingYears);
      if (fv < targetAmount) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return high;
  }

  double _calculateMinimumMonthlyContribution(int remainingYears) {
    double low = 0.0;
    double high = monthlyContribution;
    for (int i = 0; i < 50; i++) {
      double mid = (low + high) / 2;
      double fv = _calculateFutureValue(currentValue, mid, annualReturn, contributionGrowth, remainingYears);
      if (fv < targetAmount) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return high;
  }

  int _calculateRequiredYears(int remainingYears) {
    for (int y = remainingYears; y <= 100; y++) {
      double fv = _calculateFutureValue(currentValue, monthlyContribution, annualReturn, contributionGrowth, y);
      if (fv >= targetAmount) {
        return y;
      }
    }
    return remainingYears + 10;
  }

  int _calculateMinimumYears(int remainingYears) {
    for (int y = 1; y <= remainingYears; y++) {
      double fv = _calculateFutureValue(currentValue, monthlyContribution, annualReturn, contributionGrowth, y);
      if (fv >= targetAmount) {
        return y;
      }
    }
    return remainingYears;
  }

  double _calculateRequiredReturn(int remainingYears) {
    double low = annualReturn;
    double high = 100.0;
    for (int i = 0; i < 50; i++) {
      double mid = (low + high) / 2;
      double fv = _calculateFutureValue(currentValue, monthlyContribution, mid, contributionGrowth, remainingYears);
      if (fv < targetAmount) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return high;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final int currentYear = DateTime.now().year;
    final int targetYear = targetYears <= 100 ? currentYear + targetYears : targetYears;
    final int remainingYears = (targetYear - currentYear).clamp(1, 100);

    final futureValue = _calculateFutureValue(
      currentValue,
      monthlyContribution,
      annualReturn,
      contributionGrowth,
      remainingYears,
    );

    final isGoalMet = futureValue >= targetAmount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        GoalProgressGauge(
          currentValue: currentValue,
          targetAmount: targetAmount,
          isDark: isDark,
        ),
        const SizedBox(height: 16),

        // Sliders card
        Container(
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF176B5B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.flag_rounded,
                      size: 16,
                      color: Color(0xFF176B5B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '은퇴 목표 설정',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Target Amount Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '목표 금액',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.grey[300] : const Color(0xFF5E574E),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E3A33) : const Color(0xFFE8F5F1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _formatKoreanAmount(targetAmount),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF176B5B),
                      ),
                    ),
                  ),
                ],
              ),
              Slider(
                value: targetAmount,
                min: 10000000.0,
                max: 5000000000.0,
                divisions: 499,
                activeColor: const Color(0xFF176B5B),
                inactiveColor: isDark ? const Color(0xFF333333) : const Color(0xFFECE7DF),
                onChanged: onTargetAmountChanged,
              ),
              const SizedBox(height: 12),
              // Target Years Slider (Absolute Year)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '목표 연도',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.grey[300] : const Color(0xFF5E574E),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0EBE1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$targetYear년 ($remainingYears년 남음)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                ],
              ),
              Slider(
                value: targetYear.toDouble(),
                min: (currentYear + 1).toDouble(),
                max: (currentYear + 50).toDouble(),
                divisions: 49,
                activeColor: const Color(0xFF176B5B),
                inactiveColor: isDark ? const Color(0xFF333333) : const Color(0xFFECE7DF),
                onChanged: (val) {
                  onTargetYearsChanged(val.toInt());
                },
              ),
              const SizedBox(height: 16),
              // 현재 시뮬레이션 기본 설정 요약 표시
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF262626) : const Color(0xFFF7F5F0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF333333) : const Color(0xFFEBE6DD),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAssumptionItem('연동 월 저축액', _formatKoreanAmount(monthlyContribution), isDark),
                    _buildAssumptionItem('연동 수익률', '${annualReturn.toStringAsFixed(1)}%', isDark),
                    _buildAssumptionItem('연동 저축 증액률', '연 ${contributionGrowth.toStringAsFixed(1)}%', isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Forecast status card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isGoalMet
                ? (isDark ? const Color(0xFF1E3A2B) : const Color(0xFFE8F5E9))
                : (isDark ? const Color(0xFF3A281E) : const Color(0xFFFFF3E0)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isGoalMet
                  ? (isDark ? const Color(0xFF2E7D32) : const Color(0xFF81C784))
                  : (isDark ? const Color(0xFFEF6C00) : const Color(0xFFFFB74D)),
              width: 0.8,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isGoalMet ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                    color: isGoalMet ? const Color(0xFF2E7D32) : const Color(0xFFEF6C00),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isGoalMet ? '목표 달성 성공 예측' : '목표 달성 미달 예측',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: isGoalMet ? const Color(0xFF2E7D32) : const Color(0xFFEF6C00),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '$targetYear년 ($remainingYears년 후) 예상 은퇴 자산: ${_formatKoreanAmount(futureValue)}',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isGoalMet
                    ? '목표 금액 대비 ${_formatKoreanAmount(futureValue - targetAmount)} 초과 달성될 것으로 예상됩니다.'
                    : '목표 금액 대비 ${_formatKoreanAmount(targetAmount - futureValue)} 부족할 것으로 예상됩니다.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : const Color(0xFF7A7265),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Pacemaker AI Advisor
        Text(
          '🎯 페이스메이커 AI 조언',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),

        if (!isGoalMet) ...[
          // Missed Goal Advisor Cards
          Builder(
            builder: (context) {
              final reqContrib = _calculateRequiredMonthlyContribution(remainingYears);
              final diff = reqContrib - monthlyContribution;
              return _buildAdvisorCard(
                context,
                isDark,
                title: '월 저축액 증액안',
                icon: Icons.savings_outlined,
                description: '매월 추가로 ${_formatKoreanAmount(diff)}을 더 납입하여 월 저축액을 ${_formatKoreanAmount(reqContrib)}으로 올려보세요.',
                buttonText: '적용',
                onTap: () {
                  onMonthlyContributionChanged(reqContrib);
                },
              );
            },
          ),
          Builder(
            builder: (context) {
              final reqYears = _calculateRequiredYears(remainingYears);
              final diff = reqYears - remainingYears;
              return _buildAdvisorCard(
                context,
                isDark,
                title: '목표 기간 연장안',
                icon: Icons.update,
                description: '은퇴/목표 시점을 $diff년 더 늘려서 목표 연도를 ${currentYear + reqYears}년으로 설정해보세요.',
                buttonText: '적용',
                onTap: () {
                  onTargetYearsChanged(currentYear + reqYears);
                },
              );
            },
          ),
          Builder(
            builder: (context) {
              final reqReturn = _calculateRequiredReturn(remainingYears);
              final diff = reqReturn - annualReturn;
              if (reqReturn > 30.0) {
                return const SizedBox.shrink();
              }
              return _buildAdvisorCard(
                context,
                isDark,
                title: '수익률 향상안',
                icon: Icons.trending_up,
                description: '연 목표 수익률을 ${diff.toStringAsFixed(1)}% 더 올려서 ${reqReturn.toStringAsFixed(1)}%로 포트폴리오를 조정해보세요.',
                buttonText: '적용',
                onTap: () {
                  onAnnualReturnChanged(reqReturn);
                },
              );
            },
          ),
        ] else ...[
          // Met Goal Advisor Cards (Optimizations)
          Builder(
            builder: (context) {
              final minContrib = _calculateMinimumMonthlyContribution(remainingYears);
              final savings = monthlyContribution - minContrib;
              if (savings < 50000.0) {
                return const SizedBox.shrink();
              }
              return _buildAdvisorCard(
                context,
                isDark,
                title: '지출 및 저축 최적화 (월 저축액 감액)',
                icon: Icons.savings_outlined,
                description: '매월 저축액을 ${_formatKoreanAmount(savings)} 아끼고 ${_formatKoreanAmount(minContrib)}만 저축해도 목표를 달성할 수 있습니다.',
                buttonText: '조정',
                onTap: () {
                  onMonthlyContributionChanged(minContrib);
                },
              );
            },
          ),
          Builder(
            builder: (context) {
              final minYears = _calculateMinimumYears(remainingYears);
              final diff = remainingYears - minYears;
              if (diff <= 0) {
                return const SizedBox.shrink();
              }
              return _buildAdvisorCard(
                context,
                isDark,
                title: '은퇴 조기 달성안 (기간 단축)',
                icon: Icons.speed,
                description: '현재 자산 납입 페이스로는 목표를 $diff년 단축하여 ${currentYear + minYears}년에 조기 달성할 수 있습니다.',
                buttonText: '조정',
                onTap: () {
                  onTargetYearsChanged(currentYear + minYears);
                },
              );
            },
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '현재 자산 운용 페이스가 매우 훌륭합니다. 현 상태를 잘 유지해 보세요!',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[300] : Colors.grey[850],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAdvisorCard(
    BuildContext context,
    bool isDark, {
    required String title,
    required IconData icon,
    required String description,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242424) : const Color(0xFFF9F7F3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E0D7),
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.grey[400] : const Color(0xFF7A7265),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: const Size(54, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssumptionItem(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }
}

class GoalProgressGauge extends StatelessWidget {
  final double currentValue;
  final double targetAmount;
  final bool isDark;

  const GoalProgressGauge({
    super.key,
    required this.currentValue,
    required this.targetAmount,
    required this.isDark,
  });

  String _formatKoreanAmount(double amount) {
    if (amount >= 100000000) {
      final double eok = amount / 100000000;
      final int eokInt = eok.floor();
      final double man = (amount % 100000000) / 10000;
      if (man > 0) {
        return '$eokInt억 ${man.round()}만 원';
      } else {
        return '$eokInt억 원';
      }
    } else {
      final double man = amount / 10000;
      return '${man.round()}만 원';
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final double percent = targetAmount > 0 
        ? (currentValue / targetAmount * 100).clamp(0.0, 100.0) 
        : 0.0;

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
                      Icons.track_changes_rounded,
                      size: 16,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '은퇴 목표 달성률',
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
                  color: isDark ? const Color(0xFF1E3A33) : const Color(0xFFE8F5F1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${percent.toStringAsFixed(1)}% 달성',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFF34D399) : primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: 130,
            height: 130,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 10,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? const Color(0xFF2C2C2C) : const Color(0xFFECE7DF),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: percent / 100),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return CircularProgressIndicator(
                        value: value,
                        strokeWidth: 10,
                        strokeCap: StrokeCap.round,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? const Color(0xFF34D399) : primaryColor,
                        ),
                      );
                    },
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '현재 자산 대비',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.grey[400] : const Color(0xFF7A7265),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${percent.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF262626) : const Color(0xFFF7F5F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '현재 자산 ${_formatKoreanAmount(currentValue)}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.grey[300] : const Color(0xFF5E574E),
                  ),
                ),
                Text(
                  ' / ',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[600] : const Color(0xFFCBC5BC),
                  ),
                ),
                Text(
                  '목표 ${_formatKoreanAmount(targetAmount)}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFF34D399) : primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
