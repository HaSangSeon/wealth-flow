import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models.dart';
import 'formatters.dart';
import 'premium.dart';
import 'profile_sheet.dart';
import 'stock_alert_service.dart';
import 'common_widgets.dart';

class SimulationTab extends StatefulWidget {
  const SimulationTab({
    super.key,
    required this.storage,
    required this.currentValue,
    required this.projectedValue,
    required this.years,
    required this.gain,
    required this.annualReturn,
    required this.monthlyContribution,
    required this.contributionGrowth,
    required this.projectionPoints,
    required this.targetAmount,
    required this.targetYears,
    required this.onAnnualReturnChanged,
    required this.onMonthlyContributionChanged,
    required this.onContributionGrowthChanged,
    required this.onYearsChanged,
    required this.onTargetAmountChanged,
    required this.onTargetYearsChanged,
  });

  final StorageService storage;
  final double currentValue;
  final double projectedValue;
  final int years;
  final double gain;
  final double annualReturn;
  final double monthlyContribution;
  final double contributionGrowth;
  final List<ProjectionPoint> projectionPoints;
  final double targetAmount;
  final int targetYears;
  final ValueChanged<double> onAnnualReturnChanged;
  final ValueChanged<double> onMonthlyContributionChanged;
  final ValueChanged<double> onContributionGrowthChanged;
  final ValueChanged<int> onYearsChanged;
  final ValueChanged<double> onTargetAmountChanged;
  final ValueChanged<int> onTargetYearsChanged;

  @override
  State<SimulationTab> createState() => _SimulationTabState();
}

class _SimulationTabState extends State<SimulationTab> {
  bool _showGoalPlanner = false;

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
    double low = widget.monthlyContribution;
    double high = widget.monthlyContribution + (widget.targetAmount / 12);
    for (int i = 0; i < 50; i++) {
      double mid = (low + high) / 2;
      double fv = _calculateFutureValue(widget.currentValue, mid, widget.annualReturn, widget.contributionGrowth, remainingYears);
      if (fv < widget.targetAmount) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return high;
  }

  double _calculateMinimumMonthlyContribution(int remainingYears) {
    double low = 0.0;
    double high = widget.monthlyContribution;
    for (int i = 0; i < 50; i++) {
      double mid = (low + high) / 2;
      double fv = _calculateFutureValue(widget.currentValue, mid, widget.annualReturn, widget.contributionGrowth, remainingYears);
      if (fv < widget.targetAmount) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return high;
  }

  int _calculateRequiredYears(int remainingYears) {
    for (int y = remainingYears; y <= 100; y++) {
      double fv = _calculateFutureValue(widget.currentValue, widget.monthlyContribution, widget.annualReturn, widget.contributionGrowth, y);
      if (fv >= widget.targetAmount) {
        return y;
      }
    }
    return remainingYears + 10;
  }

  int _calculateMinimumYears(int remainingYears) {
    for (int y = 1; y <= remainingYears; y++) {
      double fv = _calculateFutureValue(widget.currentValue, widget.monthlyContribution, widget.annualReturn, widget.contributionGrowth, y);
      if (fv >= widget.targetAmount) {
        return y;
      }
    }
    return remainingYears;
  }

  double _calculateRequiredReturn(int remainingYears) {
    double low = widget.annualReturn;
    double high = 100.0;
    for (int i = 0; i < 50; i++) {
      double mid = (low + high) / 2;
      double fv = _calculateFutureValue(widget.currentValue, widget.monthlyContribution, mid, widget.contributionGrowth, remainingYears);
      if (fv < widget.targetAmount) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return high;
  }

  Widget _buildTabToggle(bool isDark) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: _showGoalPlanner ? Alignment.centerRight : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
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
                    setState(() {
                      _showGoalPlanner = false;
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      '자산 예측',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: !_showGoalPlanner ? FontWeight.bold : FontWeight.normal,
                        color: !_showGoalPlanner
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
                    setState(() {
                      _showGoalPlanner = true;
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      '은퇴·목표 플래너',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _showGoalPlanner ? FontWeight.bold : FontWeight.normal,
                        color: _showGoalPlanner
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

  Widget _buildGoalPlannerView(BuildContext context, bool isDark) {
    final int currentYear = DateTime.now().year;
    final int targetYear = widget.targetYears <= 100 ? currentYear + widget.targetYears : widget.targetYears;
    final int remainingYears = (targetYear - currentYear).clamp(1, 100);

    final futureValue = _calculateFutureValue(
      widget.currentValue,
      widget.monthlyContribution,
      widget.annualReturn,
      widget.contributionGrowth,
      remainingYears,
    );

    final isGoalMet = futureValue >= widget.targetAmount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _GoalProgressGauge(
          currentValue: widget.currentValue,
          targetAmount: widget.targetAmount,
          isDark: isDark,
        ),
        const SizedBox(height: 24),

        // Sliders card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '목표 설정',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              // Target Amount Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('목표 금액', style: TextStyle(fontSize: 13)),
                  Text(
                    _formatKoreanAmount(widget.targetAmount),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF176B5B),
                    ),
                  ),
                ],
              ),
              Slider(
                value: widget.targetAmount,
                min: 10000000.0,
                max: 5000000000.0,
                divisions: 499,
                activeColor: const Color(0xFF176B5B),
                inactiveColor: isDark ? Colors.grey[850] : Colors.grey[200],
                onChanged: (val) {
                  widget.onTargetAmountChanged(val);
                },
              ),
              const SizedBox(height: 12),
              // Target Years Slider (Absolute Year)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('목표 연도', style: TextStyle(fontSize: 13)),
                  Text(
                    '$targetYear년 (남은 기간: $remainingYears년)',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF176B5B),
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
                inactiveColor: isDark ? Colors.grey[850] : Colors.grey[200],
                onChanged: (val) {
                  widget.onTargetYearsChanged(val.toInt());
                },
              ),
              const SizedBox(height: 16),
              // 현재 시뮬레이션 기본 설정 요약 표시
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAssumptionItem('연동 월 저축액', _formatKoreanAmount(widget.monthlyContribution), isDark),
                    _buildAssumptionItem('연동 수익률', '${widget.annualReturn.toStringAsFixed(1)}%', isDark),
                    _buildAssumptionItem('연동 저축 증액률', '연 ${widget.contributionGrowth.toStringAsFixed(1)}%', isDark),
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
                ? (isDark ? const Color(0xFF1B5E20).withValues(alpha: 0.15) : const Color(0xFFE8F5E9))
                : (isDark ? const Color(0xFFE65100).withValues(alpha: 0.15) : const Color(0xFFFFF3E0)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isGoalMet ? const Color(0xFF2E7D32) : const Color(0xFFEF6C00),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isGoalMet ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                    color: isGoalMet ? const Color(0xFF2E7D32) : const Color(0xFFEF6C00),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isGoalMet ? '목표 달성 성공 예측' : '목표 달성 미달 예측',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isGoalMet ? const Color(0xFF2E7D32) : const Color(0xFFEF6C00),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '$targetYear년 ($remainingYears년 후) 예상 은퇴 자산: ${_formatKoreanAmount(futureValue)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[300] : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isGoalMet
                    ? '목표 금액 대비 ${_formatKoreanAmount(futureValue - widget.targetAmount)} 초과 달성될 것으로 예상됩니다.'
                    : '목표 금액 대비 ${_formatKoreanAmount(widget.targetAmount - futureValue)} 부족할 것으로 예상됩니다.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
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
              final diff = reqContrib - widget.monthlyContribution;
              return _buildAdvisorCard(
                context,
                isDark,
                title: '월 저축액 증액안',
                icon: Icons.savings_outlined,
                description: '매월 추가로 ${_formatKoreanAmount(diff)}을 더 납입하여 월 저축액을 ${_formatKoreanAmount(reqContrib)}으로 올려보세요.',
                buttonText: '적용',
                onTap: () {
                  widget.onMonthlyContributionChanged(reqContrib);
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
                  widget.onTargetYearsChanged(currentYear + reqYears);
                },
              );
            },
          ),
          Builder(
            builder: (context) {
              final reqReturn = _calculateRequiredReturn(remainingYears);
              final diff = reqReturn - widget.annualReturn;
              if (reqReturn > 30.0) {
                return const SizedBox.shrink(); // Hide unrealistic return advice (>30%)
              }
              return _buildAdvisorCard(
                context,
                isDark,
                title: '수익률 향상안',
                icon: Icons.trending_up,
                description: '연 목표 수익률을 ${diff.toStringAsFixed(1)}% 더 올려서 ${reqReturn.toStringAsFixed(1)}%로 포트폴리오를 조정해보세요.',
                buttonText: '적용',
                onTap: () {
                  widget.onAnnualReturnChanged(reqReturn);
                },
              );
            },
          ),
        ] else ...[
          // Met Goal Advisor Cards (Optimizations)
          Builder(
            builder: (context) {
              final minContrib = _calculateMinimumMonthlyContribution(remainingYears);
              final savings = widget.monthlyContribution - minContrib;
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
                  widget.onMonthlyContributionChanged(minContrib);
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
                  widget.onTargetYearsChanged(currentYear + minYears);
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF176B5B).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF176B5B), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF176B5B),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.stacked_line_chart, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '웰스플로우',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                              ),
                              Text(
                                _showGoalPlanner ? '은퇴·목표 플래너' : '미래 자산 시뮬레이션',
                                style: TextStyle(
                                  color: isDark ? Colors.grey[400] : const Color(0xFF6E675E),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        HeaderActionButtons(storage: widget.storage),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildTabToggle(isDark),
                    const SizedBox(height: 16),

                    if (!_showGoalPlanner) ...[
                      _Header(
                        currentValue: widget.currentValue,
                        projectedValue: widget.projectedValue,
                        years: widget.years,
                        gain: widget.gain,
                      ),
                      const SizedBox(height: 16),
                      _ScenarioPanel(
                        annualReturn: widget.annualReturn,
                        monthlyContribution: widget.monthlyContribution,
                        contributionGrowth: widget.contributionGrowth,
                        years: widget.years,
                        onAnnualReturnChanged: widget.onAnnualReturnChanged,
                        onMonthlyContributionChanged: widget.onMonthlyContributionChanged,
                        onContributionGrowthChanged: widget.onContributionGrowthChanged,
                        onYearsChanged: widget.onYearsChanged,
                      ),
                      const SizedBox(height: 16),
                      _ProjectionChart(points: widget.projectionPoints),
                      const SizedBox(height: 16),
                      _ProjectionTable(points: widget.projectionPoints),
                      const SizedBox(height: 28),
                    ] else ...[
                      _buildGoalPlannerView(context, isDark),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalProgressGauge extends StatelessWidget {
  final double currentValue;
  final double targetAmount;
  final bool isDark;

  const _GoalProgressGauge({
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
    final double percent = targetAmount > 0 
        ? (currentValue / targetAmount * 100).clamp(0.0, 100.0) 
        : 0.0;

    return Center(
      child: Column(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? const Color(0xFF2C2C2C) : Colors.grey[200]!,
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
                        strokeWidth: 12,
                        strokeCap: StrokeCap.round,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF176B5B),
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
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${percent.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '현재 자산 ${_formatKoreanAmount(currentValue)} / 목표 ${_formatKoreanAmount(targetAmount)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 시뮬레이션 하위 위젯들 ───────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.currentValue,
    required this.projectedValue,
    required this.years,
    required this.gain,
  });

  final double currentValue;
  final double projectedValue;
  final int years;
  final double gain;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF13584B), Color(0xFF1A7A68)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF176B5B).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '예상 미래 자산',
              style: TextStyle(color: Color(0xFFD6E8E4)),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatCurrencyFull(projectedValue),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _PremiumMetricTile(
                    label: '현재 자산',
                    value: formatCurrencyFull(currentValue),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PremiumMetricTile(
                    label: '$years년 증가분',
                    value: formatCurrencyFull(gain),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumMetricTile extends StatelessWidget {
  const _PremiumMetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFFD6E8E4), fontSize: 12)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScenarioPanel extends StatelessWidget {
  const _ScenarioPanel({
    required this.annualReturn,
    required this.monthlyContribution,
    required this.contributionGrowth,
    required this.years,
    required this.onAnnualReturnChanged,
    required this.onMonthlyContributionChanged,
    required this.onContributionGrowthChanged,
    required this.onYearsChanged,
  });

  final double annualReturn;
  final double monthlyContribution;
  final double contributionGrowth;
  final int years;
  final ValueChanged<double> onAnnualReturnChanged;
  final ValueChanged<double> onMonthlyContributionChanged;
  final ValueChanged<double> onContributionGrowthChanged;
  final ValueChanged<int> onYearsChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '시나리오',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            SliderField(
              label: '연평균 수익률',
              valueLabel: '${annualReturn.toStringAsFixed(1)}%',
              value: annualReturn,
              min: -10,
              max: 20,
              divisions: 60,
              onChanged: onAnnualReturnChanged,
              helpText: '자산이 매년 굴러가며 창출하는 평균 수익률입니다.\n\n물가상승률(인플레이션)을 감안한 실질 수익률을 입력하시면 더욱 정교한 시뮬레이션 결과를 볼 수 있습니다.',
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
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [10, 15, 20, 25].map((option) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                final isSelected = years == option;
                return ChoiceChip(
                  label: Text('$option년'),
                  selected: isSelected,
                  selectedColor: isDark ? const Color(0xFF1A3D36) : const Color(0xFFE8F0EA),
                  backgroundColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEFECE6),
                  labelStyle: TextStyle(
                    color: isSelected 
                       ? (isDark ? const Color(0xFF26A68A) : const Color(0xFF176B5B))
                       : (isDark ? Colors.grey[400] : const Color(0xFF8C847A)),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                  ),
                  side: BorderSide.none,
                  onSelected: (_) => onYearsChanged(option),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class SliderField extends StatelessWidget {
  const SliderField({
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
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(child: Text(label)),
            if (helpText != null) ...[
              const SizedBox(width: 4),
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
                          Text(
                            label,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                          ),
                        ],
                      ),
                      content: Text(
                        helpText!,
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
                  Icons.help_outline_rounded,
                  size: 16,
                  color: isDark ? Colors.grey[400] : const Color(0xFF8E867C),
                ),
              ),
            ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              valueLabel,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// ─── 차트 ─────────────────────────────────────────────────

class _ProjectionChart extends StatefulWidget {
  const _ProjectionChart({required this.points});

  final List<ProjectionPoint> points;

  @override
  State<_ProjectionChart> createState() => _ProjectionChartState();
}

class _ProjectionChartState extends State<_ProjectionChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '복리 성장 흐름',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                if (_selectedIndex != null && _selectedIndex! < widget.points.length)
                  Text(
                    '${widget.points[_selectedIndex!].year}년차 상세',
                    style: TextStyle(
                      fontSize: 12,
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
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
                        child: CustomPaint(
                          painter: _ProjectionChartPainter(
                            widget.points,
                            primaryColor,
                            isDark,
                            _selectedIndex,
                          ),
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
      ),
    );
  }

  void _updateSelectedIndex(Offset localPosition, double width) {
    if (widget.points.isEmpty) return;
    final chartWidth = width;
    final chartX = localPosition.dx;
    
    if (chartX < 0 || chartX > chartWidth) return;
    
    final double step = chartWidth / (widget.points.length - 1);
    final int index = (chartX / step).round().clamp(0, widget.points.length - 1);
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Widget _buildTooltip(ProjectionPoint point) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initialAsset = widget.points.first.total;
    final totalInvested = initialAsset + point.cumulativeContribution;
    final profit = point.total - totalInvested;
    final returnRate = totalInvested > 0 ? (profit / totalInvested) * 100 : 0.0;

    return Positioned(
      top: 10,
      left: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${point.year}년차 시뮬레이션',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              '누적 투자: ${formatCurrency(totalInvested)}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            Text(
              '총 자산: ${formatCurrency(point.total)}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text(
              '수익: ${formatCurrency(profit)} (${returnRate >= 0 ? '+' : ''}${returnRate.toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: profit >= 0 ? const Color(0xFF176B5B) : Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectionChartPainter extends CustomPainter {
  _ProjectionChartPainter(this.points, this.primaryColor, this.isDark, this.selectedIndex);

  final List<ProjectionPoint> points;
  final Color primaryColor;
  final bool isDark;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final chartWidth = size.width;
    final chartHeight = size.height - 25.0;
    const topMargin = 10.0;
    final actualGraphHeight = chartHeight - topMargin;

    final axisColor = isDark ? const Color(0xFF333333) : const Color(0xFFE5E0D7);
    final gridPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1;

    final maxValue = points.map((point) => point.total).reduce(math.max);
    final minValue = points.map((point) => point.total).reduce(math.min);
    final range = math.max(maxValue - minValue, 1.0);

    Offset mapPoint(ProjectionPoint point, int index) {
      final x = chartWidth * index / (points.length - 1);
      final y = chartHeight - ((point.total - minValue) / range * actualGraphHeight);
      return Offset(x, y);
    }

    // 1. Horizontal grid lines and Y-axis labels
    for (var i = 0; i <= 4; i++) {
      final y = topMargin + actualGraphHeight * i / 4;
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);

      final val = maxValue - (maxValue - minValue) * i / 4;
      final textPainter = TextPainter(
        text: TextSpan(
          text: _formatCompactValue(val),
          style: TextStyle(
            color: isDark ? Colors.grey[500] : const Color(0xFF8E867C),
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      // Y축 텍스트를 차트 내부 왼쪽(0), 그리드 선 위로 배치
      textPainter.paint(
        canvas,
        Offset(0, y - textPainter.height - 2),
      );
    }

    // 2. X-axis labels (bottom)
    final interval = math.max(1, points.length ~/ 4);
    for (var i = 0; i < points.length; i++) {
      bool shouldDraw = false;
      if (i == 0 || i == points.length - 1) {
        shouldDraw = true;
      } else if (i % interval == 0) {
        // 마지막 연도 텍스트와의 겹침 방지 (거리가 interval의 절반 이하로 가까우면 생략)
        if ((points.length - 1 - i) > (interval / 2.0)) {
          shouldDraw = true;
        }
      }

      if (shouldDraw) {
        final offset = mapPoint(points[i], i);
        final yearText = '${points[i].year}년';
        final textPainter = TextPainter(
          text: TextSpan(
            text: yearText,
            style: TextStyle(
              color: isDark ? Colors.grey[500] : const Color(0xFF8E867C),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        // 0년 라벨이 왼쪽으로 짤리지 않게 방어, 마지막 연도 라벨이 오른쪽으로 짤리지 않게 방어
        double labelX = offset.dx - textPainter.width / 2;
        if (i == 0) labelX = 0;
        if (i == points.length - 1) labelX = chartWidth - textPainter.width;

        textPainter.paint(
          canvas,
          Offset(labelX, chartHeight + 6),
        );
      }
    }

    // 3. Gradient fill path
    final linePath = Path();
    final fillPath = Path();
    for (var i = 0; i < points.length; i++) {
      final offset = mapPoint(points[i], i);
      if (i == 0) {
        linePath.moveTo(offset.dx, offset.dy);
        fillPath.moveTo(offset.dx, chartHeight);
        fillPath.lineTo(offset.dx, offset.dy);
      } else {
        linePath.lineTo(offset.dx, offset.dy);
        fillPath.lineTo(offset.dx, offset.dy);
      }
    }
    fillPath.lineTo(chartWidth, chartHeight);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(chartWidth / 2, topMargin),
        Offset(chartWidth / 2, chartHeight),
        [
          primaryColor.withValues(alpha: 0.35),
          primaryColor.withValues(alpha: 0.0),
        ],
      );
    canvas.drawPath(fillPath, fillPaint);

    // 4. Line path
    canvas.drawPath(
      linePath,
      Paint()
        ..color = primaryColor
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // 5. Selection indicator OR static dots
    if (selectedIndex != null && selectedIndex! < points.length) {
      final selectedPoint = points[selectedIndex!];
      final offset = mapPoint(selectedPoint, selectedIndex!);

      // Vertical line
      final trackerPaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.4)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      
      canvas.drawLine(
        Offset(offset.dx, topMargin),
        Offset(offset.dx, chartHeight),
        trackerPaint,
      );

      // Glow dot
      final outerGlowPaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(offset, 9, outerGlowPaint);

      final innerDotPaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(offset, 4.5, innerDotPaint);
    } else {
      final dotPaint = Paint()..color = isDark ? primaryColor : const Color(0xFF0F3D35);
      final step = math.max(1, points.length ~/ 5);
      for (var i = 0; i < points.length; i += step) {
        canvas.drawCircle(mapPoint(points[i], i), 4, dotPaint);
      }
      canvas.drawCircle(mapPoint(points.last, points.length - 1), 4, dotPaint);
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
  bool shouldRepaint(covariant _ProjectionChartPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.selectedIndex != selectedIndex;
  }
}

// ─── 연도별 상세표 ────────────────────────────────────────

class _ProjectionTable extends StatefulWidget {
  const _ProjectionTable({required this.points});

  final List<ProjectionPoint> points;

  @override
  State<_ProjectionTable> createState() => _ProjectionTableState();
}

class _ProjectionTableState extends State<_ProjectionTable> {
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
    
    // Hide hint if scrolled to the end (or very close to it)
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
    if (widget.points.length < 2) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '연도별 자산 상세',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                AnimatedOpacity(
                  opacity: _showSwipeHint ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.swipe_left_rounded, 
                        size: 14, 
                        color: isDark ? Colors.grey[500] : const Color(0xFF8E867C),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '밀어서 더 보기',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[500] : const Color(0xFF8E867C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(isDark ? const Color(0xFF1A3D36) : const Color(0xFFF3F6F1)),
                columnSpacing: 16,
                horizontalMargin: 12,
                columns: const [
                  DataColumn(label: Text('연차', style: TextStyle(fontWeight: FontWeight.w700))),
                  DataColumn(label: Text('누적 투자금', style: TextStyle(fontWeight: FontWeight.w700))),
                  DataColumn(label: Text('총 자산', style: TextStyle(fontWeight: FontWeight.w700))),
                  DataColumn(label: Text('수익 (수익률)', style: TextStyle(fontWeight: FontWeight.w700))),
                ],
                rows: widget.points.where((p) => p.year > 0).map((p) {
                  final initialAsset = widget.points.first.total;
                  final totalInvested =
                      initialAsset + p.cumulativeContribution;
                  final profit = p.total - totalInvested;
                  final returnRate = totalInvested > 0 ? (profit / totalInvested) * 100 : 0.0;
                  return DataRow(
                    cells: [
                      DataCell(Text('${p.year}년')),
                      DataCell(Text(formatCurrency(totalInvested))),
                      DataCell(Text(
                        formatCurrency(p.total),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      )),
                      DataCell(Text(
                        '${formatCurrency(profit)} (${returnRate >= 0 ? '+' : ''}${returnRate.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          color: profit >= 0
                              ? (isDark ? const Color(0xFF26A68A) : const Color(0xFF176B5B))
                              : Colors.redAccent,
                          fontWeight: FontWeight.w700,
                        ),
                      )),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 자산 입력 폼 ─────────────────────────────────────────

