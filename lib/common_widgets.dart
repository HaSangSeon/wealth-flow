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
    backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final primaryColor = Theme.of(context).colorScheme.primary;
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.notifications_active_outlined, color: primaryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('급등/급락 및 자산 변동 알림', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('종목 변동 알림 받기', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('보유 종목의 주요 가격 변동 시 알림을 받습니다.'),
                value: storage.stockAlertEnabled,
                onChanged: (val) {
                  setSheetState(() => storage.stockAlertEnabled = val);
                  onNotificationChanged?.call();
                },
              ),
            ],
          ),
        );
      },
    ),
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
