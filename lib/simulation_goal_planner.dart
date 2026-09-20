import 'package:flutter/material.dart';
import 'models.dart';

class GoalPlannerView extends StatelessWidget {
  const GoalPlannerView({
    super.key,
    required this.currentValue,
    required this.targetAmount,
    this.years = 15,
    this.targetYears = 15,
    required this.annualReturn,
    required this.dividendYield,
    required this.monthlyContribution,
    required this.contributionGrowth,
    required this.onTargetAmountChanged,
    required this.onMonthlyContributionChanged,
    required this.onAnnualReturnChanged,
    this.onTargetYearsChanged,
    this.onDividendYieldChanged,
    this.onContributionGrowthChanged,
    this.actualMonthlyDividend = 0.0,
  });

  final double currentValue;
  final double targetAmount;
  final int years;
  final int targetYears;
  final double annualReturn;
  final double dividendYield;
  final double monthlyContribution;
  final double contributionGrowth;
  final double actualMonthlyDividend;
  final ValueChanged<double> onTargetAmountChanged;
  final ValueChanged<double> onMonthlyContributionChanged;
  final ValueChanged<double> onAnnualReturnChanged;
  final ValueChanged<int>? onTargetYearsChanged;
  final ValueChanged<double>? onDividendYieldChanged;
  final ValueChanged<double>? onContributionGrowthChanged;

  String _formatWithComma(num n) {
    return n.round().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  String _formatKoreanAmount(double amount) {
    if (amount >= 100000000) {
      final double eok = amount / 100000000;
      final int eokInt = eok.floor();
      final double man = (amount % 100000000) / 10000;
      final int manRound = man.round();
      final eokStr = _formatWithComma(eokInt);
      if (manRound > 0) {
        return '$eokStr억 ${_formatWithComma(manRound)}만 원';
      } else {
        return '$eokStr억 원';
      }
    } else if (amount >= 10000) {
      final double man = amount / 10000;
      return '${_formatWithComma(man)}만 원';
    } else {
      return '${_formatWithComma(amount)}원';
    }
  }

  double _calculateFutureValue(double start, double monthly, double rate, double growth, int yearsCount) {
    return calculateCompoundFutureValue(
      initialAsset: start,
      monthlyContribution: monthly,
      annualReturnPercent: rate,
      dividendYieldPercent: dividendYield,
      contributionGrowthPercent: growth,
      years: yearsCount,
    );
  }

  double _calculateRequiredMonthlyContribution(int remainingYears) {
    double low = 0.0;
    double high = (targetAmount / (remainingYears * 12).clamp(1, 1200)) * 2.5;
    if (high < monthlyContribution * 2) {
      high = monthlyContribution * 2;
    }
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
    // 복리 시뮬레이션 기간 years를 단일 기준으로 사용
    final int remainingYears = years > 0 ? years : (targetYears <= 100 ? targetYears : targetYears - currentYear).clamp(1, 100);
    final int targetYear = currentYear + remainingYears;

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
          annualReturn: annualReturn,
          dividendYield: dividendYield,
          actualMonthlyDividend: actualMonthlyDividend,
          futureValue: futureValue,
          years: remainingYears,
          isDark: isDark,
        ),
        const SizedBox(height: 16),

        // 은퇴 목표 설정 (목표 금액 단일 슬라이더로 심플화)
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        '은퇴 목표 금액 설정',
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
              const SizedBox(height: 12),
              Slider(
                value: targetAmount,
                min: 10000000.0,
                max: 5000000000.0,
                divisions: 499,
                activeColor: const Color(0xFF176B5B),
                inactiveColor: isDark ? const Color(0xFF333333) : const Color(0xFFECE7DF),
                onChanged: onTargetAmountChanged,
              ),
              const SizedBox(height: 10),
              // 복리 시뮬레이션 설정 기준 안내 바
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF262626) : const Color(0xFFF7F5F0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF333333) : const Color(0xFFEBE6DD),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.sync_rounded,
                      size: 14,
                      color: isDark ? const Color(0xFF34D399) : const Color(0xFF176B5B),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '시뮬레이션 조건: $remainingYears년 뒤 ($targetYear년) 은퇴 · 월 ${_formatKoreanAmount(monthlyContribution)} 추가 투자',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[300] : const Color(0xFF5E574E),
                        ),
                      ),
                    ),
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
              const SizedBox(height: 3),
              Builder(
                builder: (context) {
                  final effectiveDivRate = dividendYield > 0 ? dividendYield : (annualReturn > 0 ? annualReturn : 4.0);
                  final futureMonthlyDiv = (futureValue * (effectiveDivRate / 100)) / 12;
                  return Text(
                    '은퇴 예상 월 배당금: 약 ${_formatKoreanAmount(futureMonthlyDiv)} (배당률 ${effectiveDivRate.toStringAsFixed(1)}% 기준)',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isGoalMet
                          ? (isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32))
                          : (isDark ? const Color(0xFFFFB74D) : const Color(0xFFEF6C00)),
                    ),
                  );
                },
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
                  onTargetYearsChanged?.call(currentYear + reqYears);
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
                  onTargetYearsChanged?.call(currentYear + minYears);
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
}

class GoalProgressGauge extends StatelessWidget {
  final double currentValue;
  final double targetAmount;
  final double annualReturn;
  final double dividendYield;
  final double actualMonthlyDividend;
  final double futureValue;
  final int years;
  final bool isDark;

  const GoalProgressGauge({
    super.key,
    required this.currentValue,
    required this.targetAmount,
    required this.annualReturn,
    this.dividendYield = 3.0,
    this.actualMonthlyDividend = 0.0,
    required this.futureValue,
    required this.years,
    required this.isDark,
  });

  String _formatWithComma(num n) {
    return n.round().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  String _formatKoreanAmount(double amount) {
    if (amount >= 100000000) {
      final double eok = amount / 100000000;
      final int eokInt = eok.floor();
      final double man = (amount % 100000000) / 10000;
      final int manRound = man.round();
      final eokStr = _formatWithComma(eokInt);
      if (manRound > 0) {
        return '$eokStr억 ${_formatWithComma(manRound)}만 원';
      } else {
        return '$eokStr억 원';
      }
    } else if (amount >= 1000000) {
      final double man = amount / 10000;
      return '${_formatWithComma(man)}만 원';
    } else if (amount >= 10000) {
      final double man = amount / 10000;
      final manStr = man.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
      return '$manStr만 원';
    } else {
      return '${_formatWithComma(amount)}원';
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    // 복리 투자 미래 예상 자산 기준 달성률
    final double percent = targetAmount > 0 
        ? (futureValue / targetAmount * 100).clamp(0.0, 100.0) 
        : 0.0;
        
    final double targetRate = dividendYield > 0 ? dividendYield : (annualReturn > 0 ? annualReturn : 4.0);
    final double targetMonthlyDividend = (targetAmount * (targetRate / 100)) / 12;
    // 은퇴 시점 미래 예상 월 배당금
    final double futureMonthlyDividend = (futureValue * (targetRate / 100)) / 12;

    ({String title, String desc}) getMilestoneInfo(double monthly) {
      if (monthly < 10000) {
        return (
          title: "커피 한 잔의 여유 ☕️",
          desc: "매달 배당금으로 소소한 기호식품과 티타임을 즐겨요",
        );
      }
      if (monthly < 50000) {
        return (
          title: "OTT 구독료 자립 🍿",
          desc: "넷플릭스·유튜브 등 월간 고정 구독료를 배당금으로 해결해요",
        );
      }
      if (monthly < 150000) {
        return (
          title: "스마트폰 통신비 커버 📱",
          desc: "매달 나가는 통신요금을 배당금만으로 전액 충당해요",
        );
      }
      if (monthly < 500000) {
        return (
          title: "식비 & 교통비 커버 🚌",
          desc: "일상적인 기본 식비와 대중교통비를 배당금으로 자립했어요",
        );
      }
      if (monthly < 1500000) {
        return (
          title: "주거비 & 관리비 커버 🏠",
          desc: "월세나 관리비·공과금을 배당금으로 해결할 수 있어요",
        );
      }
      if (monthly < 3000000) {
        return (
          title: "미니멀 조기 은퇴 🏝️",
          desc: "기본 생활비가 충당되어 소박한 은퇴(Lean FIRE)가 가능해요",
        );
      }
      return (
        title: "완벽한 경제적 자유 🚀",
        desc: "배당 소득만으로 풍요롭고 여유로운 완전 은퇴를 누려요",
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
              ? [const Color(0xFF1E1E1E), const Color(0xFF262626)]
              : [Colors.white, const Color(0xFFF9F9F9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E0D7),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.local_fire_department_rounded,
                      size: 20,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'FIRE 은퇴 시계',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E3A33) : const Color(0xFFE8F5F1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${percent.toStringAsFixed(1)}% 달성',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFF34D399) : primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // 게이지와 중앙 텍스트
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 14,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? const Color(0xFF2C2C2C) : const Color(0xFFECE7DF),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: percent / 100),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutCirc,
                    builder: (context, value, child) {
                      return CircularProgressIndicator(
                        value: value,
                        strokeWidth: 14,
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
                        '$years년 뒤 예상 월 배당금',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.grey[400] : const Color(0xFF7A7265),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatKoreanAmount(futureMonthlyDividend),
                        style: TextStyle(
                          fontSize: 22,
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
          
          const SizedBox(height: 24),
          
          // 배당 커버리지 마일스톤 뱃지
          Builder(
            builder: (context) {
              final milestone = getMilestoneInfo(futureMonthlyDividend);
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF222B27) : const Color(0xFFF2F7F4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF33423B) : const Color(0xFFD8E8E0),
                    width: 0.9,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3.5),
                          decoration: BoxDecoration(
                            color: (isDark ? const Color(0xFFFFD700) : const Color(0xFFF59E0B))
                                .withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            size: 13,
                            color: isDark ? const Color(0xFFFFD700) : const Color(0xFFD97706),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          milestone.title,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF1B3D34),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      milestone.desc,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                        color: isDark ? const Color(0xFF98ACA2) : const Color(0xFF4D635A),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // 목표 자산 요약
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '목표 자산 ${_formatKoreanAmount(targetAmount)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.grey[400] : const Color(0xFF6B655D),
                    ),
                  ),
                  Text(
                    '  |  ',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[700] : const Color(0xFFD6D1C9),
                    ),
                  ),
                  Text(
                    '은퇴 목표 월배당 ${_formatKoreanAmount(targetMonthlyDividend)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isDark ? const Color(0xFF34D399) : primaryColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${dividendYield > 0 ? "배당률" : "수익률"} ${targetRate.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[400] : const Color(0xFF6B655D),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
