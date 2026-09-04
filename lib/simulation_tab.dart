import 'package:flutter/material.dart';
import 'models.dart';
import 'formatters.dart';
import 'common_widgets.dart';
import 'simulation_chart.dart';
import 'simulation_table.dart';
import 'simulation_scenario_panel.dart';
import 'simulation_goal_planner.dart';

export 'simulation_scenario_panel.dart';
export 'simulation_chart.dart';
export 'simulation_table.dart';
export 'simulation_goal_planner.dart';

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
    this.onDataRestored,
  });

  final StorageService storage;
  final VoidCallback? onDataRestored;
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

  Widget _buildTabToggle(bool isDark) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEBE6DD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFDED8CE),
          width: 0.8,
        ),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: _showGoalPlanner ? Alignment.centerRight : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
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
                    if (_showGoalPlanner) setState(() => _showGoalPlanner = false);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      '복리 시뮬레이션',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: !_showGoalPlanner ? FontWeight.w800 : FontWeight.w600,
                        color: !_showGoalPlanner
                            ? (isDark ? Colors.white : const Color(0xFF1A1A1A))
                            : (isDark ? Colors.grey[400] : const Color(0xFF7A7265)),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (!_showGoalPlanner) setState(() => _showGoalPlanner = true);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      '은퇴·목표 플래너',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _showGoalPlanner ? FontWeight.w800 : FontWeight.w600,
                        color: _showGoalPlanner
                            ? (isDark ? const Color(0xFF34D399) : primaryColor)
                            : (isDark ? Colors.grey[400] : const Color(0xFF7A7265)),
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
                        HeaderActionButtons(
                          storage: widget.storage,
                          onDataRestored: widget.onDataRestored,
                        ),
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
                      ScenarioPanel(
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
                      ProjectionChart(points: widget.projectionPoints),
                      const SizedBox(height: 16),
                      ProjectionTable(points: widget.projectionPoints),
                      const SizedBox(height: 28),
                    ] else ...[
                      GoalPlannerView(
                        currentValue: widget.currentValue,
                        targetAmount: widget.targetAmount,
                        targetYears: widget.targetYears,
                        annualReturn: widget.annualReturn,
                        monthlyContribution: widget.monthlyContribution,
                        contributionGrowth: widget.contributionGrowth,
                        onTargetAmountChanged: widget.onTargetAmountChanged,
                        onTargetYearsChanged: widget.onTargetYearsChanged,
                        onMonthlyContributionChanged: widget.onMonthlyContributionChanged,
                        onAnnualReturnChanged: widget.onAnnualReturnChanged,
                      ),
                      const SizedBox(height: 28),
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
