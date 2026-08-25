import 'package:flutter/material.dart';
import 'models.dart';
import 'formatters.dart';
import 'common_widgets.dart';
import 'simulation_tab.dart';

class PensionTaxTab extends StatefulWidget {
  const PensionTaxTab({
    super.key,
    required this.holdings,
    required this.storage,
  });

  final List<Holding> holdings;
  final StorageService storage;

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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
    // 연금저축 인정 한도: 최대 600만원
    final pensionCreditBase = _annualContributionPension.clamp(0.0, 6000000.0);
    // irp 인정 한도: 합산 최대 900만원 -> irp 단독 한도는 (900만원 - 연금저축 인정액)
    final irpLimit = 9000000.0 - pensionCreditBase;
    final irpCreditBase = _annualContributionIRP.clamp(0.0, irpLimit);
    final totalCreditBase = pensionCreditBase + irpCreditBase;
    final calculatedRefund = totalCreditBase * taxRate;

    // 추가 납입 가이드 계산
    final double remainingToMaximize = 9000000.0 - totalCreditBase;
    final double additionalRefundPossible = remainingToMaximize * taxRate;

    // 3. ISA 만기 전환 혜택 계산
    // 전환 금액의 10% (최대 300만원) 추가 세액공제
    final isaRolloverCredit = (_isaMaturityAmount * 0.1).clamp(0.0, 3000000.0);
    final isaRolloverRefund = isaRolloverCredit * taxRate;

    // 4. 은퇴 연금 수령 계산
    final annualPayout = _payoutYears > 0 ? _targetPensionTotal / _payoutYears : 0.0;
    final monthlyPayout = annualPayout / 12;
    final isPayoutSafe = annualPayout <= 15000000; // 연 1500만원 기준

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
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
                        HeaderActionButtons(storage: widget.storage),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 섹션 1: 절세 자산 현황
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
                              '총 절세 자산 (연금저축/IRP/ISA)',
                              style: TextStyle(color: Color(0xFFD6E8E4)),
                            ),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                formatCurrencyFull(totalTaxSavingAssets),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            if (totalAssets > 0) ...[
                              const SizedBox(height: 6),
                              Text(
                                '전체 자산 중 ${taxSavingRatio.toStringAsFixed(1)}%가 절세 계좌에서 운용 중입니다.',
                                style: const TextStyle(color: Color(0xFFB0D4CD), fontSize: 13),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Container(height: 1, color: const Color(0xFF2A8B79)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _MiniMetricTile(
                                    label: '연금저축',
                                    value: formatCurrencyFull(pensionSum),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _MiniMetricTile(
                                    label: 'IRP',
                                    value: formatCurrencyFull(irpSum),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _MiniMetricTile(
                                    label: 'ISA',
                                    value: formatCurrencyFull(isaSum),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 섹션 2: 세액공제 계산기
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '올해 세액공제 계산기',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 12),
                            // 소득 선택 토글
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('연봉(소득) 구간', style: TextStyle(fontWeight: FontWeight.w700)),
                                ToggleButtons(
                                  isSelected: [_incomeUnder55, !_incomeUnder55],
                                  onPressed: (index) {
                                    setState(() {
                                      _incomeUnder55 = index == 0;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  selectedColor: Colors.white,
                                  fillColor: Theme.of(context).colorScheme.primary,
                                  constraints: const BoxConstraints(minHeight: 36, minWidth: 100),
                                  children: const [
                                    Text('5.5천 이하\n(16.5% 공제)', style: TextStyle(fontSize: 11), textAlign: TextAlign.center),
                                    Text('5.5천 초과\n(13.2% 공제)', style: TextStyle(fontSize: 11), textAlign: TextAlign.center),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            SliderField(
                              label: '올해 연금저축 납입 예정액',
                              helpText: '💡 연금저축계좌 꿀팁\n\n• 세액공제 한도: 연간 최대 600만 원 (급여 5,500만 원 초과 13.2%, 이하 16.5% 환급)\n• 최고 납입 한도: 연 최대 1,800만 원 (IRP와 합산)\n• 세금 이연 효과: 일반 계좌에서 배당/수익 시 15.4%를 떼지만, 연금계좌는 세금 없이 온전하게 재투자되며 나중에 5.5%로 정산합니다!',
                              valueLabel: formatCurrencyFull(_annualContributionPension),
                              value: _annualContributionPension,
                              min: 0,
                              max: 18000000,
                              divisions: 180,
                              onChanged: (v) => setState(() => _annualContributionPension = v),
                            ),
                            SliderField(
                              label: '올해 IRP 납입 예정액',
                              helpText: '💡 IRP (개인형 퇴직연금) 꿀팁\n\n• 세액공제 한도: 연금저축(600) 외에 추가로 300만 원 납입 시 혜택! (연금저축 합산 총 900만 원 세액공제)\n• 투자 제한: 위험자산(주식형) 70%, 안전자산(채권/예금 등) 30% 투자 룰이 있습니다.\n• 혜택: 역시 수익과 배당에 대한 세금을 떼지 않고 과세가 이연됩니다.',
                              valueLabel: formatCurrencyFull(_annualContributionIRP),
                              value: _annualContributionIRP,
                              min: 0,
                              max: 18000000,
                              divisions: 180,
                              onChanged: (v) => setState(() => _annualContributionIRP = v),
                            ),
                            const SizedBox(height: 16),
                            // 환급금 결과 박스
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F6F1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE5E0D7)),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '예상 세액공제 환급금',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? Colors.grey[400] : const Color(0xFF6E675E),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    formatCurrencyFull(calculatedRefund),
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // 극대화 가이드
                                  if (remainingToMaximize > 0) ...[
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.lightbulb_outline, color: Theme.of(context).colorScheme.primary, size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '올해 IRP 계좌에 ${formatCurrencyFull(remainingToMaximize)}을 추가 납입하시면 세금 ${formatCurrencyFull(additionalRefundPossible)}을 더 돌려받을 수 있어요!',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(context).colorScheme.primary,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else ...[
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F0EA),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.check_circle_outline, color: Color(0xFF176B5B), size: 18),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '올해 세액공제 한도(₩9,000,000)를 가득 채우셨습니다! 최고의 세테크를 실천 중이시네요. 🎉',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF176B5B),
                                                height: 1.4,
                                              ),
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
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 섹션 3: ISA 만기 연금 전환 혜택
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ISA 만기 전환 혜택',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '3년 만기된 ISA 자금을 연금계좌로 전환하면, 전환금액의 10% (최대 300만 원 한도)가 추가로 세액공제 대상에 산입됩니다.',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.grey[400] : const Color(0xFF6E675E),
                                height: 1.4,
                              ),
                            ),
                            const Divider(height: 24),
                            SliderField(
                              label: 'ISA 만기 자금 전환 예정액',
                              helpText: '💡 ISA (개인종합자산관리계좌) 꿀팁\n\n• 비과세 혜택: 손익 통산 후 순이익 기준 200만 원 완전 비과세! 초과 수익은 9.9% 분리과세(정산 요금)로 다른 소득과 합산되지 않습니다.\n• 연금 전환: 3년 의무 가입 후 전액 현금화하여 연금계좌로 이전 가능 (연간 1,800만 원 한도를 다 채웠어도 한도 무관하게 이전됨!)\n• 추가 공제: 전환 금액의 10% (최대 300만 원) 추가 세액공제!\n• 이전 후에는 기존 ISA를 해지하고 같은 계좌로 다시 개설하여 무한 반복 운용이 가능합니다.',
                              valueLabel: formatCurrencyFull(_isaMaturityAmount),
                              value: _isaMaturityAmount,
                              min: 0,
                              max: 100000000,
                              divisions: 100,
                              onChanged: (v) => setState(() => _isaMaturityAmount = v),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _SecondaryMetricTile(
                                    label: '추가 세액공제 인정액',
                                    value: formatCurrencyFull(isaRolloverCredit),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _SecondaryMetricTile(
                                    label: '예상 추가 환급금',
                                    value: formatCurrencyFull(isaRolloverRefund),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 섹션 4: 연금 수령 전략
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '은퇴 후 연금 수령 전략',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '만 55세 이후 연금 수령 시 사적연금(연금저축+IRP) 연간 수령액이 ₩15,000,000 이하이면 낮은 연금소득세율(3.3% ~ 5.5% 분리과세)만 내고 수령할 수 있습니다.',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.grey[400] : const Color(0xFF6E675E),
                                height: 1.4,
                              ),
                            ),
                            const Divider(height: 24),
                            SliderField(
                              label: '은퇴 시 모인 총 연금 자산',
                              helpText: '💡 55세 이후 연금 인출 꿀팁\n\n나중에 연금 수령 시 세금 로직은 "꼬리표"에 따라 다릅니다.\n1순위: 세액공제 안 받은 원금 (한도 무관 100% 비과세)\n2순위: 퇴직금 (퇴직소득세)\n3순위: 세액공제 받은 원금 + 수익 (이 3순위만 1,500만 원 한도 체크!)\n\n📌 1,500만 원 한도 오버 시:\n• 1,500만 원 이하: 15년 동안 안 내고 모아둔 \'세금 이연분\'에 대한 정산 요금(3.3~5.5%)만 납부\n• 1,500만 원 초과: 초과분은 내 근로/사업 소득과 합치지 않고, 딱 16.5%만 떼고 깔끔하게 끝나는 \'16.5% 분리과세\'를 선택할 수 있습니다!',
                              valueLabel: formatCurrencyFull(_targetPensionTotal),
                              value: _targetPensionTotal,
                              min: 0,
                              max: 1000000000,
                              divisions: 100,
                              onChanged: (v) => setState(() => _targetPensionTotal = v),
                            ),
                            SliderField(
                              label: '희망 연금 수령 기간',
                              valueLabel: '$_payoutYears년',
                              value: _payoutYears.toDouble(),
                              min: 5,
                              max: 30,
                              divisions: 25,
                              onChanged: (v) => setState(() => _payoutYears = v.round()),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _SecondaryMetricTile(
                                    label: '예상 연간 수령액',
                                    value: formatCurrencyFull(annualPayout),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _SecondaryMetricTile(
                                    label: '예상 월 수령액',
                                    value: formatCurrencyFull(monthlyPayout),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // 연금 수령 안전도 판정 박스
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isPayoutSafe
                                    ? (isDark ? const Color(0xFF1A3D36) : const Color(0xFFE8F0EA))
                                    : (isDark ? const Color(0xFF422222) : const Color(0xFFFDF0F0)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isPayoutSafe ? Icons.check_circle : Icons.warning,
                                    color: isPayoutSafe
                                        ? (isDark ? const Color(0xFF26A68A) : const Color(0xFF176B5B))
                                        : Colors.redAccent,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      isPayoutSafe
                                          ? '연간 ₩15,000,000 이하 수령 조건 만족! 저율 연금소득세(3.3%~5.5%) 혜택 대상입니다.'
                                          : '연간 수령액이 ₩15,000,000을 초과하여 종합과세 또는 16.5% 분리과세 대상이 될 우려가 있습니다. 수령 기간을 늘려 한도를 조절하는 것을 추천합니다.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isPayoutSafe
                                            ? (isDark ? const Color(0xFF26A68A) : const Color(0xFF176B5B))
                                            : Colors.redAccent,
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
                    ),
                    const SizedBox(height: 40),
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

class _MiniMetricTile extends StatelessWidget {
  const _MiniMetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFFD6E8E4), fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondaryMetricTile extends StatelessWidget {
  const _SecondaryMetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F6F1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE5E0D7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: isDark ? Colors.grey[400] : const Color(0xFF6E675E), fontSize: 11)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 자산 비중 시각화 카드 & 도넛 차트 페인터 ─────────────────────

