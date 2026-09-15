import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class DailyDividendTicker extends StatefulWidget {
  const DailyDividendTicker({
    super.key,
    required this.annualTotal,
  });

  final double annualTotal;

  @override
  State<DailyDividendTicker> createState() => _DailyDividendTickerState();
}

class _DailyDividendTickerState extends State<DailyDividendTicker>
    with TickerProviderStateMixin {
  late Ticker _ticker;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;
  
  double _currentEarned = 0.0;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _updateTick(); // 초기값 세팅

    // Ticker를 사용해 초당 60번(주사율에 맞춰) 부드럽게 화면 갱신
    _ticker = createTicker((elapsed) {
      _updateTick();
    });
    _ticker.start();

    // LIVE 점 및 상승 화살표 깜빡임 애니메이션 (크기 변화 없이 투명도만 선명하게 깜빡임)
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);

    _blinkAnimation = Tween<double>(begin: 0.05, end: 1.0).animate(
      CurvedAnimation(
        parent: _blinkController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _updateTick() {
    final now = DateTime.now();
    // 오늘 0시 정각
    final midnight = DateTime(now.year, now.month, now.day);

    // 1년 = 365일
    const double secondsInYear = 365.0 * 24.0 * 60.0 * 60.0;

    // 1초당 벌어들이는 금액
    final double earnPerSecond = widget.annualTotal / secondsInYear;

    // 오늘 자정부터 지금까지 흐른 밀리초 단위 시간
    final double elapsedSeconds =
        now.difference(midnight).inMilliseconds / 1000.0;

    // 현재까지 누적된 금액
    final newEarned = elapsedSeconds * earnPerSecond;

    if (mounted) {
      setState(() {
        _currentEarned = newEarned;
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  // 천 단위 콤마 포맷터
  String _formatNumber(num value, {int decimals = 0}) {
    final str = value.toStringAsFixed(decimals);
    final parts = str.split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    if (parts.length > 1) {
      return '$intPart.${parts[1]}';
    }
    return intPart;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    // 배당금이 0원이면 티커를 숨깁니다
    if (widget.annualTotal <= 0) {
      return const SizedBox.shrink();
    }

    const double secondsInYear = 365.0 * 24.0 * 60.0 * 60.0;
    final double earnPerSecond = widget.annualTotal / secondsInYear;
    final double earnPerHour = earnPerSecond * 3600.0;
    final double earnPerDay = widget.annualTotal / 365.0;

    // 실시간 누적 금액 분리 (정수부 / 소수점부)
    final earnedFixed = _currentEarned.toStringAsFixed(2);
    final earnedParts = earnedFixed.split('.');
    final intFormatted = earnedParts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    final decimalPart = earnedParts.length > 1 ? earnedParts[1] : '00';

    // 초당/분당 실시간 적립 텍스트
    String rateText;
    if (earnPerSecond >= 1.0) {
      rateText = '초당 +₩${_formatNumber(earnPerSecond, decimals: 2)}';
    } else if (earnPerSecond >= 0.01) {
      rateText = '초당 +₩${_formatNumber(earnPerSecond, decimals: 2)}';
    } else {
      rateText = '분당 +₩${_formatNumber(earnPerSecond * 60, decimals: 1)}';
    }

    // 카드 테두리 및 배경 색상
    final cardBgColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFAF9F6);
    final borderColor = isDark
        ? primaryColor.withValues(alpha: 0.3)
        : primaryColor.withValues(alpha: 0.2);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: isDark ? 0.12 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    // 좌측: 안정적으로 고정된 크기의 상승 아이콘 (흔들림 0%)
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  primaryColor.withValues(alpha: 0.3),
                                  primaryColor.withValues(alpha: 0.15),
                                ]
                              : [
                                  primaryColor.withValues(alpha: 0.18),
                                  primaryColor.withValues(alpha: 0.08),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.35),
                          width: 0.8,
                        ),
                      ),
                      child: Icon(
                        Icons.trending_up_rounded,
                        size: 20,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 11),
                    // 중앙: 타이틀 및 LIVE 뱃지 & 적립 속도
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '실시간 배당금',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF2C2A28),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // 실시간 LIVE 뱃지 (선명하게 깜빡이는 초록 램프)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981)
                                        .withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: const Color(0xFF10B981)
                                          .withValues(alpha: 0.3),
                                      width: 0.6,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AnimatedBuilder(
                                        animation: _blinkAnimation,
                                        builder: (context, child) {
                                          return Opacity(
                                            opacity: _blinkAnimation.value,
                                            child: Container(
                                              width: 6,
                                              height: 6,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF10B981),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'LIVE',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF10B981),
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 3),
                          // 서브 텍스트: 실시간 적립 속도 + 확장 힌트
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  rateText,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF10B981),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                Text(
                                  ' • 0시 누적',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : const Color(0xFF8C847A),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  _isExpanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  size: 14,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : const Color(0xFF8C847A),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 우측: 실시간 다이내믹 숫자 뱃지 (정수부 + 역동적인 소수점 분리 하이라이트)
                    Flexible(
                      flex: 0,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [
                                      primaryColor.withValues(alpha: 0.22),
                                      primaryColor.withValues(alpha: 0.12),
                                    ]
                                  : [
                                      primaryColor.withValues(alpha: 0.12),
                                      primaryColor.withValues(alpha: 0.05),
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: primaryColor.withValues(
                                  alpha: isDark ? 0.35 : 0.25),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              // 통화 기호 및 정수부
                              Text(
                                '+₩$intFormatted',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: primaryColor,
                                  letterSpacing: -0.4,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                              const SizedBox(width: 1.5),
                              // 소수점부 (실시간으로 빠르게 올라가는 포인트 하이라이트 칩)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 3.5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(
                                      alpha: isDark ? 0.3 : 0.18),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '.$decimalPart',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: primaryColor,
                                        letterSpacing: -0.2,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures()
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 1),
                                    // 실시간 상승 화살표 깜빡임
                                    AnimatedBuilder(
                                      animation: _blinkAnimation,
                                      builder: (context, child) {
                                        return Opacity(
                                          opacity: _blinkAnimation.value,
                                          child: const Icon(
                                            Icons.arrow_drop_up_rounded,
                                            size: 14,
                                            color: Color(0xFF10B981),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // 터치 시 펼쳐지는 실시간 배당 파이프라인 상세 통계 (포인트 기능)
                AnimatedSize(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOutCubic,
                  child: _isExpanded
                      ? Column(
                          children: [
                            const SizedBox(height: 12),
                            Divider(
                              height: 1,
                              thickness: 0.7,
                              color: isDark
                                  ? const Color(0xFF333333)
                                  : const Color(0xFFE8E3DA),
                            ),
                            const SizedBox(height: 12),
                            // 실시간 파이프라인 3단 메트릭
                            Row(
                              children: [
                                _buildMetricBox(
                                  context: context,
                                  isDark: isDark,
                                  primaryColor: primaryColor,
                                  icon: Icons.bolt_rounded,
                                  iconColor: const Color(0xFFEAB308), // Amber
                                  title: '초당 적립',
                                  value: '₩${_formatNumber(earnPerSecond, decimals: 2)}',
                                ),
                                const SizedBox(width: 8),
                                _buildMetricBox(
                                  context: context,
                                  isDark: isDark,
                                  primaryColor: primaryColor,
                                  icon: Icons.access_time_rounded,
                                  iconColor: const Color(0xFF3B82F6), // Blue
                                  title: '배당 시급',
                                  value: '₩${_formatNumber(earnPerHour, decimals: 0)}',
                                ),
                                const SizedBox(width: 8),
                                _buildMetricBox(
                                  context: context,
                                  isDark: isDark,
                                  primaryColor: primaryColor,
                                  icon: Icons.calendar_today_rounded,
                                  iconColor: const Color(0xFF10B981), // Green
                                  title: '오늘 예상',
                                  value: '₩${_formatNumber(earnPerDay, decimals: 0)}',
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // 하단 배당 패시브 인컴 모티베이션 칩
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF262626)
                                    : const Color(0xFFF0EDE6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.nightlight_round,
                                      size: 12,
                                      color: isDark ? Colors.amber[300] : const Color(0xFFB45309),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '잠자는 동안에도 배당 파이프라인이 쉬지 않고 일해요',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.grey[300]
                                            : const Color(0xFF6B6257),
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricBox({
    required BuildContext context,
    required bool isDark,
    required Color primaryColor,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF262626) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0xFF383838) : const Color(0xFFEBE6DD),
            width: 0.8,
          ),
        ),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 11, color: iconColor),
                  const SizedBox(width: 3),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[400] : const Color(0xFF7D756A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF2C2A28),
                  letterSpacing: -0.2,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

