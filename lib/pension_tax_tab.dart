import 'package:flutter/material.dart';
import 'models.dart';
import 'formatters.dart';
import 'common_widgets.dart';
import 'simulation_scenario_panel.dart';

class PensionTaxTab extends StatefulWidget {
  const PensionTaxTab({
    super.key,
    required this.holdings,
    required this.storage,
    this.onDataRestored,
  });

  final List<Holding> holdings;
  final StorageService storage;
  final VoidCallback? onDataRestored;

  @override
  State<PensionTaxTab> createState() => _PensionTaxTabState();
}

class _PensionTaxTabState extends State<PensionTaxTab> {
  // 세액공제 계산기 상태
  bool _incomeUnder55 = true; // true: 연봉 5500만원 이하 (16.5%), false: 5500만원 초과 (13.2%)
  double _annualContributionPension = 6000000;
  double _annualContributionIRP = 3000000;

  // ISA 전환 상태
  double _isaMaturityAmount = 30000000;

  // 연금 수령 전략 상태
  double _targetPensionTotal = 300000000;
  int _payoutYears = 20;

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
  }

  @override
  void didUpdateWidget(covariant PensionTaxTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 프로필 전환 등 부모 위젯 리빌드 시 최신 세팅을 다시 불러오기 위함
    _loadSavedSettings();
  }

  void _loadSavedSettings() {
    final settings = widget.storage.loadPensionSettings();
    _incomeUnder55 = settings.incomeUnder55;
    _annualContributionPension = settings.annualContributionPension;
    _annualContributionIRP = settings.annualContributionIRP;
    _isaMaturityAmount = settings.isaMaturityAmount;
    _targetPensionTotal = settings.targetPensionTotal;
    _payoutYears = settings.payoutYears;
  }

  void _saveSettings() {
    final settings = PensionTaxSettings(
      incomeUnder55: _incomeUnder55,
      annualContributionPension: _annualContributionPension,
      annualContributionIRP: _annualContributionIRP,
      isaMaturityAmount: _isaMaturityAmount,
      targetPensionTotal: _targetPensionTotal,
      payoutYears: _payoutYears,
    );
    widget.storage.savePensionSettings(settings);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    // 1. 절세 자산 현황 계산
    final pensionHoldings = widget.holdings.where((h) => h.account == AccountType.pension);
    final irpHoldings = widget.holdings.where((h) => h.account == AccountType.irp);
    final isaHoldings = widget.holdings.where((h) => h.account == AccountType.isa);

    final pensionSum = pensionHoldings.fold(0.0, (sum, h) => sum + h.value);
    final irpSum = irpHoldings.fold(0.0, (sum, h) => sum + h.value);
    final isaSum = isaHoldings.fold(0.0, (sum, h) => sum + h.value);
    final totalTaxSavingAssets = pensionSum + irpSum + isaSum;

    final totalAssets = widget.holdings.fold(0.0, (sum, h) => sum + h.value);
    final taxSavingRatio = totalAssets > 0 ? (totalTaxSavingAssets / totalAssets) * 100 : 0.0;

    // 2. 세액공제 예상 환급금 계산
    final taxRate = _incomeUnder55 ? 0.165 : 0.132;
    final pensionCreditBase = _annualContributionPension.clamp(0.0, 6000000.0);
    final irpLimit = 9000000.0 - pensionCreditBase;
    final irpCreditBase = _annualContributionIRP.clamp(0.0, irpLimit);
    final totalCreditBase = pensionCreditBase + irpCreditBase;
    final calculatedRefund = totalCreditBase * taxRate;

    final double remainingToMaximize = 9000000.0 - totalCreditBase;
    final double additionalRefundPossible = remainingToMaximize * taxRate;

    // 3. ISA 만기 전환 혜택 계산
    final isaRolloverCredit = (_isaMaturityAmount * 0.1).clamp(0.0, 3000000.0);
    final isaRolloverRefund = isaRolloverCredit * taxRate;
    final totalAnnualRefund = calculatedRefund + isaRolloverRefund;

    // 4. 은퇴 연금 수령 계산 (세법상 10년 이상 분할 수령 + 연 1,500만 원 이하 저율과세 요건)
    final annualPayout = _payoutYears > 0 ? _targetPensionTotal / _payoutYears : 0.0;
    final monthlyPayout = annualPayout / 12;
    final meetsMinYears = _payoutYears >= 10;
    final meetsAmountLimit = annualPayout <= 15000000;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 헤더
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFF176B5B),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.savings_outlined, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '연금 & 절세 매니저',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                              ),
                              Text(
                                '절세 계좌 분석 및 환급 시뮬레이터',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        HeaderActionButtons(
                          storage: widget.storage,
                          onDataRestored: () {
                            setState(() {
                              _loadSavedSettings();
                            });
                            widget.onDataRestored?.call();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── 1. 절세 자산 현황 요약 배너 ──
                    Container(
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
                            color: const Color(0xFF176B5B).withValues(alpha: 0.25),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '총 절세 자산 (연금저축/IRP/ISA)',
                                  style: TextStyle(
                                    color: Color(0xFFD6E8E4),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (totalAssets > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '비중 ${taxSavingRatio.toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                formatCurrencyFull(totalTaxSavingAssets),
                                style: const TextStyle(
                                  fontSize: 34,
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
                                  child: _MiniMetricTile(
                                    label: '연금저축',
                                    value: formatCurrencyFull(pensionSum),
                                    icon: Icons.account_balance_outlined,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _MiniMetricTile(
                                    label: 'IRP',
                                    value: formatCurrencyFull(irpSum),
                                    icon: Icons.security_outlined,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _MiniMetricTile(
                                    label: 'ISA',
                                    value: formatCurrencyFull(isaSum),
                                    icon: Icons.trending_up_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── 2. 세액공제 계산기 카드 ──
                    _buildSectionContainer(
                      context,
                      isDark,
                      icon: Icons.calculate_rounded,
                      title: '올해 세액공제 계산기',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 소득 구간 토글 (안드로이드 기기 대응 50:50 풀위드 세그먼트)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '연봉(소득) 구간',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.grey[300] : const Color(0xFF5E574E),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
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
                                  children: [
                                    Expanded(
                                      child: _buildIncomeTab(
                                        isSelected: _incomeUnder55,
                                        label: '5,500만 이하 (16.5%)',
                                        onTap: () => setState(() {
                                          _incomeUnder55 = true;
                                          _saveSettings();
                                        }),
                                        isDark: isDark,
                                        primaryColor: primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: _buildIncomeTab(
                                        isSelected: !_incomeUnder55,
                                        label: '5,500만 초과 (13.2%)',
                                        onTap: () => setState(() {
                                          _incomeUnder55 = false;
                                          _saveSettings();
                                        }),
                                        isDark: isDark,
                                        primaryColor: primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          SliderField(
                            label: '올해 연금저축 납입 예정액',
                            helpBadge: '연금/절세 가이드',
                            helpIcon: Icons.savings_outlined,
                            helpText: '💡 연금저축계좌 꿀팁\n\n• 세액공제 한도: 연간 최대 600만 원 (급여 5,500만 원 초과 13.2%, 이하 16.5% 환급)\n• 최고 납입 한도: 연 최대 1,800만 원 (IRP와 합산)\n• 세금 이연 효과: 일반 계좌에서 배당/수익 시 15.4%를 떼지만, 연금계좌는 세금 없이 온전하게 재투자되며 나중에 5.5%로 정산합니다!',
                            valueLabel: formatCurrencyFull(_annualContributionPension),
                            value: _annualContributionPension,
                            min: 0,
                            max: 18000000,
                            divisions: 180,
                            onChanged: (v) => setState(() {
                              _annualContributionPension = v;
                              _saveSettings();
                            }),
                          ),
                          SliderField(
                            label: '올해 IRP 납입 예정액',
                            helpBadge: '연금/절세 가이드',
                            helpIcon: Icons.account_balance_outlined,
                            helpText: '💡 IRP (개인형 퇴직연금) 꿀팁\n\n• 세액공제 한도: 연금저축(600) 외에 추가로 300만 원 납입 시 혜택! (연금저축 합산 총 900만 원 세액공제)\n• 투자 제한: 위험자산(주식형) 70%, 안전자산(채권/예금 등) 30% 투자 룰이 있습니다.\n• 혜택: 역시 수익과 배당에 대한 세금을 떼지 않고 과세가 이연됩니다.',
                            valueLabel: formatCurrencyFull(_annualContributionIRP),
                            value: _annualContributionIRP,
                            min: 0,
                            max: 18000000,
                            divisions: 180,
                            onChanged: (v) => setState(() {
                              _annualContributionIRP = v;
                              _saveSettings();
                            }),
                          ),
                          const SizedBox(height: 12),
                          // 환급금 결과 박스
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF242424) : const Color(0xFFF7F5F0),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark ? const Color(0xFF333333) : const Color(0xFFEBE6DD),
                                width: 0.8,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '예상 세액공제 환급금',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.grey[400] : const Color(0xFF6E675E),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  formatCurrencyFull(calculatedRefund),
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? const Color(0xFF34D399) : primaryColor,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                // 가이드 박스
                                if (remainingToMaximize > 0)
                                  Builder(
                                    builder: (context) {
                                      final pensionRemaining = 6000000.0 - pensionCreditBase;
                                      String guideMsg;
                                      if (pensionRemaining > 0 && pensionRemaining < remainingToMaximize) {
                                        guideMsg = '연금저축(최대 ${formatCurrencyFull(pensionRemaining)}) 또는 IRP 계좌에 총 ${formatCurrencyFull(remainingToMaximize)}을 추가 납입하시면 세금 ${formatCurrencyFull(additionalRefundPossible)}을 더 돌려받을 수 있어요!';
                                      } else if (pensionRemaining >= remainingToMaximize) {
                                        guideMsg = '연금저축 또는 IRP 계좌에 ${formatCurrencyFull(remainingToMaximize)}을 추가 납입하시면 세금 ${formatCurrencyFull(additionalRefundPossible)}을 더 돌려받을 수 있어요!';
                                      } else {
                                        guideMsg = '올해 IRP 계좌에 ${formatCurrencyFull(remainingToMaximize)}을 추가 납입하시면 세금 ${formatCurrencyFull(additionalRefundPossible)}을 더 돌려받을 수 있어요!';
                                      }
                                      return Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.lightbulb_outline_rounded, color: primaryColor, size: 18),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                guideMsg,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: isDark ? const Color(0xFF34D399) : primaryColor,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E3A2B) : const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.check_circle_outline_rounded, color: Color(0xFF2E7D32), size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '올해 세액공제 한도(₩9,000,000)를 가득 채우셨습니다! 최고의 절세를 실천 중이시네요. 🎉',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF2E7D32),
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── 3. ISA 만기 전환 혜택 카드 ──
                    _buildSectionContainer(
                      context,
                      isDark,
                      icon: Icons.published_with_changes_rounded,
                      title: 'ISA 만기 전환 혜택',
                      badge: '최대 300만 추가 공제',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '3년 만기된 ISA 자금을 연금계좌로 전환하면, 전환금액의 10% (최대 300만 원)가 추가로 세액공제 대상에 산입됩니다.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark ? Colors.grey[400] : const Color(0xFF6E675E),
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 18),
                          SliderField(
                            label: 'ISA 만기 자금 전환 예정액',
                            helpBadge: 'ISA 만기 전환 혜택',
                            helpIcon: Icons.currency_exchange_rounded,
                            helpText: '💡 ISA (개인종합자산관리계좌) 꿀팁\n\n• 비과세 혜택: 손익 통산 후 순이익 기준 200만 원 완전 비과세! 초과 수익은 9.9% 분리과세(정산 요금)로 다른 소득과 합산되지 않습니다.\n• 연금 전환: 3년 의무 가입 후 전액 현금화하여 연금계좌로 이전 가능 (연간 1,800만 원 한도를 다 채웠어도 한도 무관하게 이전됨!)\n• 추가 공제: 전환 금액의 10% (최대 300만 원) 추가 세액공제!\n• 이전 후에는 기존 ISA를 해지하고 같은 계좌로 다시 개설하여 무한 반복 운용이 가능합니다.',
                            valueLabel: formatCurrencyFull(_isaMaturityAmount),
                            value: _isaMaturityAmount,
                            min: 0,
                            max: 100000000,
                            divisions: 100,
                            onChanged: (v) => setState(() {
                              _isaMaturityAmount = v;
                              _saveSettings();
                            }),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _SecondaryMetricTile(
                                  label: '추가 세액공제 인정액',
                                  value: formatCurrencyFull(isaRolloverCredit),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _SecondaryMetricTile(
                                  label: '예상 추가 환급금',
                                  value: formatCurrencyFull(isaRolloverRefund),
                                  isHighlight: true,
                                ),
                              ),
                            ],
                          ),
                          if (isaRolloverCredit > 0) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF262626) : const Color(0xFFF3F0EA),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF383838) : const Color(0xFFE5DFD5),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFFE5A93C)),
                                      const SizedBox(width: 6),
                                      Text(
                                        '연간 총 환급액 (연금+ISA)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.grey[300] : const Color(0xFF5E574E),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    formatCurrencyFull(totalAnnualRefund),
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? const Color(0xFF34D399) : primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── 4. 은퇴 후 연금 수령 전략 카드 ──
                    _buildSectionContainer(
                      context,
                      isDark,
                      icon: Icons.account_tree_outlined,
                      title: '은퇴 후 연금 수령 전략',
                      badge: '연 1500만 한도 체크',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '만 55세 이후 연금 수령 시 사적연금(연금저축+IRP) 연간 수령액이 ₩15,000,000 이하이고 10년 이상 분할 수령 시 낮은 연금소득세율(3.3% ~ 5.5% 분리과세)만 내고 수령할 수 있습니다.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark ? Colors.grey[400] : const Color(0xFF6E675E),
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 18),
                          if (pensionSum + irpSum > 0) ...[
                            Align(
                              alignment: Alignment.centerRight,
                              child: InkWell(
                                onTap: () => setState(() {
                                  _targetPensionTotal = pensionSum + irpSum;
                                  _saveSettings();
                                }),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: primaryColor.withValues(alpha: 0.3),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.sync_rounded, size: 13, color: primaryColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        '내 보유 연금 반영 (${formatCurrencyFull(pensionSum + irpSum)})',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? const Color(0xFF34D399) : primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],
                          SliderField(
                            label: '은퇴 시 모인 총 연금 자산',
                            helpBadge: '연금 인출 가이드',
                            helpIcon: Icons.account_balance_wallet_outlined,
                            helpText: '💡 55세 이후 연금 인출 꿀팁\n\n• 법정 최소 수령 기간: 세법상 저율 연금소득세(3.3%~5.5%) 혜택을 받으려면 반드시 "최소 10년 이상" 분할 수령해야 합니다.\n• 1,500만 원 한도: 세액공제 받은 원금과 운용수익은 연 1,500만 원 이하 수령 시 저율 연금소득세(3.3%~5.5%)로 종결됩니다.\n• 1,500만 원 초과 시: 초과분은 내 근로/사업 소득과 합산하지 않고, 딱 16.5%만 떼고 끝나는 "16.5% 분리과세"를 선택할 수 있습니다!',
                            valueLabel: formatCurrencyFull(_targetPensionTotal),
                            value: _targetPensionTotal,
                            min: 0,
                            max: 1000000000,
                            divisions: 100,
                            onChanged: (v) => setState(() {
                              _targetPensionTotal = v;
                              _saveSettings();
                            }),
                          ),
                          SliderField(
                            label: '희망 연금 수령 기간',
                            helpBadge: '연금 인출 가이드',
                            helpIcon: Icons.schedule_rounded,
                            helpText: '• 법정 최소 기간: 저율 연금소득세(3.3%~5.5%) 혜택을 받으려면 법정 10년 이상 분할 수령해야 합니다.\n• 연간 1,500만 원 한도: 1년 수령액이 1,500만 원 이하가 되도록 수령 기간을 넉넉히 설정하시면 절세 혜택이 극대화됩니다.\n• 10년 이후 추가 감면: 연금 수령 11년 차부터는 연금소득세율이 추가로 10% 감면(지방세 포함 3.3% 수준)됩니다.',
                            valueLabel: '$_payoutYears년',
                            value: _payoutYears.toDouble(),
                            min: 5,
                            max: 30,
                            divisions: 25,
                            onChanged: (v) => setState(() {
                              _payoutYears = v.round();
                              _saveSettings();
                            }),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _SecondaryMetricTile(
                                  label: '예상 연간 수령액',
                                  value: formatCurrencyFull(annualPayout),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _SecondaryMetricTile(
                                  label: '예상 월 수령액',
                                  value: formatCurrencyFull(monthlyPayout),
                                  isHighlight: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // 연금 수령 안전도 판정 박스 (세법 요건 정밀 반영)
                          Builder(
                            builder: (context) {
                              final Color boxBg;
                              final Color borderColor;
                              final Color textColor;
                              final IconData icon;
                              final String message;

                              if (!meetsMinYears) {
                                boxBg = isDark ? const Color(0xFF3A281E) : const Color(0xFFFFF3E0);
                                borderColor = isDark ? const Color(0xFFEF6C00) : const Color(0xFFFFB74D);
                                textColor = isDark ? const Color(0xFFFFB74D) : const Color(0xFFEF6C00);
                                icon = Icons.warning_amber_rounded;
                                message = '법정 최소 분할 수령 기간(10년) 미충족! 10년 미만으로 인출 시 연금수령한도를 초과하여 저율 과세(3.3%~5.5%) 대신 기타소득세(16.5%)가 부과될 수 있습니다.';
                              } else if (!meetsAmountLimit) {
                                boxBg = isDark ? const Color(0xFF3A281E) : const Color(0xFFFFF3E0);
                                borderColor = isDark ? const Color(0xFFEF6C00) : const Color(0xFFFFB74D);
                                textColor = isDark ? const Color(0xFFFFB74D) : const Color(0xFFEF6C00);
                                icon = Icons.info_outline_rounded;
                                message = '연간 수령액이 ₩15,000,000을 초과하여 종합과세 또는 16.5% 분리과세 대상이 될 우려가 있습니다. 수령 기간을 늘려 한도를 조절하는 것을 추천합니다.';
                              } else {
                                boxBg = isDark ? const Color(0xFF1E3A2B) : const Color(0xFFE8F5E9);
                                borderColor = isDark ? const Color(0xFF2E7D32) : const Color(0xFF81C784);
                                textColor = isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
                                icon = Icons.check_circle_rounded;
                                message = '연간 ₩15,000,000 이하 및 10년 이상 분할 수령 요건 만족! 저율 연금소득세(3.3%~5.5%) 혜택 대상입니다.';
                              }

                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: boxBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderColor, width: 0.8),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(icon, color: textColor, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        message,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: textColor,
                                          height: 1.45,
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
                    ),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionContainer(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String title,
    String? badge,
    required Widget child,
  }) {
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
                    child: Icon(icon, size: 16, color: primaryColor),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0EBE1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.grey[300] : const Color(0xFF5E574E),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildIncomeTab({
    required bool isSelected,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    required Color primaryColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
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
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? (isDark ? const Color(0xFF34D399) : primaryColor)
                : (isDark ? Colors.grey[400] : const Color(0xFF7A7265)),
          ),
        ),
      ),
    );
  }
}

class _MiniMetricTile extends StatelessWidget {
  const _MiniMetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: const Color(0xFFD6E8E4)),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFD6E8E4),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondaryMetricTile extends StatelessWidget {
  const _SecondaryMetricTile({
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  final String label;
  final String value;
  final bool isHighlight;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242424) : const Color(0xFFF7F5F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF333333) : const Color(0xFFEBE6DD),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : const Color(0xFF6E675E),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: isHighlight
                    ? (isDark ? const Color(0xFF34D399) : primaryColor)
                    : (isDark ? Colors.white : const Color(0xFF1A1A1A)),
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
