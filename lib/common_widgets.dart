import 'package:flutter/material.dart';
import 'models.dart';
import 'portfolio_news_carousel.dart';

late final ValueNotifier<ThemeMode> themeNotifier;
final GlobalKey<PortfolioNewsCarouselState> portfolioNewsKey = GlobalKey<PortfolioNewsCarouselState>();
final GlobalKey<RefreshIndicatorState> refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

// ─── 전역 테마 토글 헬퍼 ──────────────────────────────────
void toggleTheme(BuildContext context, StorageService storage) {
  final current = themeNotifier.value;
  ThemeMode nextMode;
  if (current == ThemeMode.system) {
    nextMode = Theme.of(context).brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
  } else if (current == ThemeMode.light) {
    nextMode = ThemeMode.dark;
  } else {
    nextMode = ThemeMode.light;
  }
  themeNotifier.value = nextMode;
  storage.themeMode = nextMode.index;
}

// ─── 알림 설정 바텀시트 헬퍼 ──────────────────────────────
void openNotificationSettingsSheet(BuildContext context, StorageService storage, [VoidCallback? onNotificationChanged]) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    showDragHandle: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final primaryColor = Theme.of(context).colorScheme.primary;
        final isEnabled = storage.stockAlertEnabled;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(context).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 상단 드래그 핸들 ──
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : const Color(0xFFDDD8CE),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── 헤더 (아이콘 + 타이틀 + 닫기 버튼) ──
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.notifications_active_rounded,
                      color: primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '알림 설정',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                      letterSpacing: -0.4,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    iconSize: 20,
                    color: isDark ? Colors.grey[400] : const Color(0xFF8C847A),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // ── 메인 스위치 카드 ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF242424) : const Color(0xFFF9F7F3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E0D7),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '종목 급등/급락 변동 알림',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isEnabled
                                      ? (isDark ? const Color(0xFF1E3A33) : const Color(0xFFE8F5F1))
                                      : (isDark ? const Color(0xFF333333) : const Color(0xFFECE7DF)),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  isEnabled ? 'ON' : 'OFF',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: isEnabled ? primaryColor : (isDark ? Colors.grey[400] : const Color(0xFF8C847A)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '보유 중인 종목의 주요 가격 변동 및 시세 소식을 실시간 푸시로 받습니다.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : const Color(0xFF7A7265),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Switch.adaptive(
                      value: isEnabled,
                      activeTrackColor: primaryColor,
                      onChanged: (val) {
                        setSheetState(() => storage.stockAlertEnabled = val);
                        onNotificationChanged?.call();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── 안내 가이드 리스트 ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F3EE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      context,
                      icon: Icons.bolt_rounded,
                      text: '등록된 보유 종목에 맞춤화된 주요 시세 변동을 감지합니다.',
                      isDark: isDark,
                      primaryColor: primaryColor,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      context,
                      icon: Icons.battery_charging_full_rounded,
                      text: '배터리 소모를 최소화한 효율적인 스마트 백그라운드 방식을 사용합니다.',
                      isDark: isDark,
                      primaryColor: primaryColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── 확인 완료 버튼 ──
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '확인',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

Widget _buildInfoRow(BuildContext context, {required IconData icon, required String text, required bool isDark, required Color primaryColor}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 15, color: primaryColor),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11.5,
            color: isDark ? Colors.grey[400] : const Color(0xFF7A7265),
            height: 1.35,
          ),
        ),
      ),
    ],
  );
}

// ─── 공통 헤더 액션 버튼 (알림 + 다크/라이트모드) ─────────────────
class HeaderActionButtons extends StatelessWidget {
  const HeaderActionButtons({
    super.key,
    required this.storage,
    this.onNotificationChanged,
  });

  final StorageService storage;
  final VoidCallback? onNotificationChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E0D7),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            iconSize: 19,
            onPressed: () {
              openNotificationSettingsSheet(context, storage, onNotificationChanged);
            },
            icon: Icon(
              storage.stockAlertEnabled
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_off_outlined,
              color: storage.stockAlertEnabled
                  ? primaryColor
                  : (isDark ? Colors.grey[400] : const Color(0xFF8C847A)),
            ),
            tooltip: '급등/급락 알림 설정',
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E0D7),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, currentMode, _) {
              final isCurrentlyDark = currentMode == ThemeMode.dark ||
                  (currentMode == ThemeMode.system && Theme.of(context).brightness == Brightness.dark);
              return IconButton(
                padding: EdgeInsets.zero,
                iconSize: 19,
                onPressed: () => toggleTheme(context, storage),
                icon: Icon(
                  isCurrentlyDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  color: primaryColor,
                ),
                tooltip: isCurrentlyDark ? '라이트 모드로 전환' : '다크 모드로 전환',
              );
            },
          ),
        ),
      ],
    );
  }
}
