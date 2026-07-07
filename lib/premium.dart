import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'models.dart';
import 'payment_service.dart';

class PremiumSubscriptionScreen extends StatefulWidget {
  const PremiumSubscriptionScreen({super.key, required this.storage});
  final StorageService storage;

  @override
  State<PremiumSubscriptionScreen> createState() => _PremiumSubscriptionScreenState();
}

class _PremiumSubscriptionScreenState extends State<PremiumSubscriptionScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF6F4EF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Gradient Orbs
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF176B5B).withValues(alpha: 0.3),
                backgroundBlendMode: BlendMode.screen,
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEAA622).withValues(alpha: 0.2),
                backgroundBlendMode: BlendMode.screen,
              ),
            ),
          ),
          // Blur Filter
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: const SizedBox(),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Developer Easter Egg: Long press to toggle premium status
                    GestureDetector(
                      onLongPress: kReleaseMode 
                          ? null 
                          : () {
                              setState(() {
                                widget.storage.isPremium = !widget.storage.isPremium;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    widget.storage.isPremium
                                        ? '👑 개발자 모드: 프리미엄 활성화'
                                        : '개발자 모드: 무료 버전 활성화',
                                  ),
                                  backgroundColor: const Color(0xFF176B5B),
                                ),
                              );
                              Navigator.pop(context, true);
                            },
                      child: const Text(
                        '👑 Wealth Flow\nPremium',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '한계를 넘어선 완벽한 자산 관리.\n지금 프리미엄으로 업그레이드 하세요.',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white70 : Colors.black54,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 36),
                    _buildFeatureItem(
                      context,
                      icon: Icons.all_inclusive,
                      title: '무제한 자산 추가',
                      subtitle: '무료 버전의 5개 등록 제한을 해제하고 모든 자산을 무제한으로 관리하세요.',
                    ),
                    const SizedBox(height: 20),
                    _buildFeatureItem(
                      context,
                      icon: Icons.calendar_month,
                      title: '배당 캘린더 & 심층 분석',
                      subtitle: '월별 배당금 현금흐름과 포트폴리오 예상 배당 수익률을 한눈에 파악하세요.',
                    ),
                    const SizedBox(height: 20),
                    InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => const _DividendPreviewDialog(),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF176B5B).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF176B5B).withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF176B5B).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.remove_red_eye_outlined,
                                color: Color(0xFF176B5B),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '실제 배당 분석 화면 미리보기',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF176B5B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    '터치하여 3단계 슬라이드 팝업으로 직접 확인해 보세요.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Color(0xFF176B5B),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    // Pricing Card
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF176B5B).withValues(alpha: 0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF176B5B).withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '평생 소장권 (추천)',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const Text(
                                '₩4,900 / 일시불',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF176B5B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '초기 버전 특별 할인가! 한 번 결제하고 추가 비용 없이 평생 무제한 사용',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: FilledButton(
                        onPressed: widget.storage.isPremium || _isLoading
                            ? null
                            : () async {
                                setState(() {
                                  _isLoading = true;
                                });
                                final success = await PaymentService.purchasePremium();
                                setState(() {
                                  _isLoading = false;
                                });
                                if (!context.mounted) return;
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('👑 프리미엄 결제가 완료되었습니다!'),
                                      backgroundColor: Color(0xFF176B5B),
                                    ),
                                  );
                                  Navigator.pop(context, true);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('결제에 실패했거나 취소되었습니다.'),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF176B5B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                widget.storage.isPremium ? '이미 프리미엄 멤버입니다' : '프리미엄 업그레이드',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: _isLoading
                            ? null
                            : () async {
                                setState(() {
                                  _isLoading = true;
                                });
                                final success = await PaymentService.restorePurchases(widget.storage);
                                setState(() {
                                  _isLoading = false;
                                });
                                if (!context.mounted) return;
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('👑 프리미엄 구매 정보가 성공적으로 복구되었습니다!'),
                                      backgroundColor: Color(0xFF176B5B),
                                    ),
                                  );
                                  Navigator.pop(context, true);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('복구 가능한 프리미엄 구매 정보가 없습니다.'),
                                      backgroundColor: Colors.grey,
                                    ),
                                  );
                                }
                              },
                        child: const Text(
                          '구매 복구하기 (Restore Purchases)',
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Full screen loading overlay
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF176B5B),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context,
      {required IconData icon, required String title, required String subtitle}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF176B5B).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF176B5B), size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

}

class _DividendPreviewDialog extends StatefulWidget {
  const _DividendPreviewDialog();

  @override
  State<_DividendPreviewDialog> createState() => _DividendPreviewDialogState();
}

class _DividendPreviewDialogState extends State<_DividendPreviewDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int? _selectedMonth;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFF176B5B);
    const highlightColor = Color(0xFFEAA622);

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 580),
        child: Column(
          children: [
            // Dialog Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: primaryColor, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    '배당 분석 기능 미리보기',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // PageView Content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildSlide1(isDark, primaryColor),
                  _buildSlide2(isDark, primaryColor, highlightColor),
                  _buildSlide3(context, isDark, primaryColor),
                ],
              ),
            ),
            const Divider(height: 1),
            // Dialog Footer (Dots Indicator & Buttons)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left Arrow
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 16),
                    onPressed: _currentPage > 0
                        ? () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                  ),
                  // Dots
                  Row(
                    children: List.generate(3, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? primaryColor : Colors.grey.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  // Right Arrow
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: _currentPage < 2
                        ? () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Slide 1: Dashboard Summary
  Widget _buildSlide1(bool isDark, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'SLIDE 1/3 : 내 배당 요약 대시보드',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '내 배당 요약',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMockSummaryCard(
                  title: '연간 예상 배당금',
                  value: '₩2,485,200',
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMockSummaryCard(
                  title: '월평균 배당금',
                  value: '₩207,100',
                  color: const Color(0xFFEAA622),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildMockSummaryCard(
            title: '포트폴리오 예상 배당수익률',
            value: '4.85%',
            color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            isFullWidth: true,
            isDark: isDark,
          ),
          const Spacer(),
          Center(
            child: Text(
              '💡 보유한 자산 데이터 기반으로 배당 현황을 한눈에 파악합니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey[400] : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Slide 2: Monthly Cashflow Chart
  Widget _buildSlide2(bool isDark, Color primaryColor, Color highlightColor) {
    final Map<int, double> mockMonthly = {
      1: 150000, 2: 100000, 3: 320000, 4: 400000, 5: 180000, 6: 220000,
      7: 80000, 8: 120000, 9: 450000, 10: 380000, 11: 150000, 12: 300000,
    };
    const maxVal = 450000.0;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'SLIDE 2/3 : 월별 배당금 현금흐름 차트',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedMonth == null ? '월별 예상 배당금 흐름' : '$_selectedMonth월 예상 배당금 흐름',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 160,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(12, (index) {
                final month = index + 1;
                final val = mockMonthly[month] ?? 0.0;
                final heightFactor = val / maxVal;
                final isSelected = _selectedMonth == month;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMonth = isSelected ? null : month;
                    });
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${(val / 10000).toStringAsFixed(0)}만',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? highlightColor : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: FractionallySizedBox(
                          heightFactor: (heightFactor * 0.85).clamp(0.08, 0.85),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 12,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isSelected
                                    ? [highlightColor, const Color(0xFFF3C461)]
                                    : [primaryColor, const Color(0xFF2E9E82)],
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
                        '$month월',
                        style: TextStyle(
                          fontSize: 9,
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
            ),
          ),
          const Spacer(),
          Center(
            child: Text(
              '💡 차트의 막대를 누르면 해당 월의 세부 배당 일정으로 필터링됩니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey[400] : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Slide 3: Upcoming List & Stock Summaries
  Widget _buildSlide3(BuildContext context, bool isDark, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'SLIDE 3/3 : 배당 포트폴리오 리스트',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '배당 포트폴리오',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildMockStockSummaryRow(
                  context: context,
                  isDark: isDark,
                  primaryColor: primaryColor,
                  name: '삼성전자',
                  symbol: '005930.KS',
                  frequencyLabel: '분기배당',
                  paymentMonths: [4, 5, 8, 11],
                  amountStr: '₩1,444,000',
                  onTap: () {
                    _showMockDividendDetails(
                      context: context,
                      name: '삼성전자',
                      symbol: '005930.KS',
                      frequencyLabel: '분기배당',
                      isDark: isDark,
                      primaryColor: primaryColor,
                      dividends: [
                        _MockDividendData('2026년 11월 배당', '주당 ₩361원', '₩361,000', '배당락일: 2026.09.29', '지급예정: 2026.11.20'),
                        _MockDividendData('2026년 8월 배당', '주당 ₩361원', '₩361,000', '배당락일: 2026.06.29', '지급예정: 2026.08.20'),
                        _MockDividendData('2026년 5월 배당', '주당 ₩361원', '₩361,000', '배당락일: 2026.03.30', '지급예정: 2026.05.20'),
                        _MockDividendData('2026년 4월 배당', '주당 ₩361원', '₩361,000', '배당락일: 2025.12.29', '지급예정: 2026.04.15'),
                      ],
                    );
                  },
                ),
                _buildMockStockSummaryRow(
                  context: context,
                  isDark: isDark,
                  primaryColor: primaryColor,
                  name: 'Realty Income',
                  symbol: 'O',
                  frequencyLabel: '월배당',
                  paymentMonths: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
                  amountStr: '₩150,000',
                  onTap: () {
                    _showMockDividendDetails(
                      context: context,
                      name: 'Realty Income',
                      symbol: 'O',
                      frequencyLabel: '월배당',
                      isDark: isDark,
                      primaryColor: primaryColor,
                      dividends: [
                        _MockDividendData('2026년 12월 배당', '주당 \$0.26', '₩12,500', '배당락일: 2026.11.30', '지급예정: 2026.12.15'),
                        _MockDividendData('2026년 11월 배당', '주당 \$0.26', '₩12,500', '배당락일: 2026.10.31', '지급예정: 2026.11.15'),
                        _MockDividendData('2026년 10월 배당', '주당 \$0.26', '₩12,500', '배당락일: 2026.09.30', '지급예정: 2026.10.15'),
                      ],
                    );
                  },
                ),
                _buildMockStockSummaryRow(
                  context: context,
                  isDark: isDark,
                  primaryColor: primaryColor,
                  name: '맥쿼리인프라',
                  symbol: '095570.KS',
                  frequencyLabel: '반기배당',
                  paymentMonths: [2, 8],
                  amountStr: '₩390,000',
                  onTap: () {
                    _showMockDividendDetails(
                      context: context,
                      name: '맥쿼리인프라',
                      symbol: '095570.KS',
                      frequencyLabel: '반기배당',
                      isDark: isDark,
                      primaryColor: primaryColor,
                      dividends: [
                        _MockDividendData('2026년 8월 배당', '주당 ₩390원', '₩195,000', '배당락일: 2026.06.29', '지급예정: 2026.08.28'),
                        _MockDividendData('2026년 2월 배당', '주당 ₩390원', '₩195,000', '배당락일: 2025.12.29', '지급예정: 2026.02.27'),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          Center(
            child: Text(
              '💡 종목을 누르면 상세 배당금 지급 일정 팝업을 확인하실 수 있습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey[400] : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Slide 1 Card Helper
  Widget _buildMockSummaryCard({
    required String title,
    required String value,
    required Color color,
    bool isFullWidth = false,
    bool isDark = false,
  }) {
    final isSpecialColor = color != Colors.white && color != const Color(0xFF2C2C2C);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (!isSpecialColor)
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 4,
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
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isSpecialColor
                  ? Colors.white.withValues(alpha: 0.7)
                  : (isDark ? Colors.white70 : Colors.black54),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: isFullWidth ? 18 : 15,
              fontWeight: FontWeight.w900,
              color: isSpecialColor
                  ? Colors.white
                  : (isDark ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // Stock Summary Card Row (Portfolio) Helper
  Widget _buildMockStockSummaryRow({
    required BuildContext context,
    required bool isDark,
    required Color primaryColor,
    required String name,
    required String symbol,
    required String frequencyLabel,
    required List<int> paymentMonths,
    required String amountStr,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
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
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2E9E82).withValues(alpha: 0.2) : const Color(0xFFE6F4F1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFF2E9E82).withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              frequencyLabel,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF176B5B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$symbol | 예상 지급월: ${paymentMonths.join(', ')}월',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                      amountStr,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF176B5B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '연간 예상',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Stock Details BottomSheet Helper
  void _showMockDividendDetails({
    required BuildContext context,
    required String name,
    required String symbol,
    required String frequencyLabel,
    required bool isDark,
    required Color primaryColor,
    required List<_MockDividendData> dividends,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.55,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAF9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$symbol · $frequencyLabel',
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: dividends.length,
                  itemBuilder: (context, index) {
                    final div = dividends[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  div.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  div.dateText,
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                div.total,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF176B5B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                div.amount,
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                              Text(
                                div.paymentDateText,
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MockDividendData {
  _MockDividendData(this.name, this.amount, this.total, this.dateText, this.paymentDateText);
  final String name;
  final String amount;
  final String total;
  final String dateText;
  final String paymentDateText;
}
