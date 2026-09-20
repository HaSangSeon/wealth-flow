import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
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

// ─── 통합 설정 (알림 + 데이터 백업/복원) 바텀시트 헬퍼 ──────────────────
void openSettingsSheet(
  BuildContext context,
  StorageService storage, {
  VoidCallback? onNotificationChanged,
  VoidCallback? onDataRestored,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    showDragHandle: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final primaryColor = Theme.of(context).colorScheme.primary;

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
                      Icons.tune_rounded,
                      color: primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '데이터 관리 및 백업',
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

              // ── 1. 자산 데이터 백업 & 복원 섹션 (영구 보관) ──
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shield_outlined, size: 18, color: primaryColor),
                        const SizedBox(width: 6),
                        Text(
                          '자산 데이터 영구 보관',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '폰을 교체하거나 앱을 재설치할 때를 대비해 카카오톡(나에게 보내기)이나 구글 드라이브에 안전하게 백업하세요.\n(⚠️ 복원 시 현재 앱의 기존 자산 데이터는 완전히 삭제되고 백업 파일로 덮어씌워집니다)',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : const Color(0xFF7A7265),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        // 백업 내보내기 버튼
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              try {
                                final jsonStr = storage.exportBackupJson();
                                final tempDir = await getTemporaryDirectory();
                                final now = DateTime.now();
                                final dateStr =
                                    "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}";
                                final file = File('${tempDir.path}/wealthflow_backup_$dateStr.json');
                                await file.writeAsString(jsonStr);

                                final xFile = XFile(file.path, mimeType: 'application/json');
                                await SharePlus.instance.share(
                                  ShareParams(
                                    files: [xFile],
                                    subject: '웰스플로우 자산 데이터 백업 ($dateStr)',
                                    text: '웰스플로우 자산 백업 파일입니다. (카카오톡 나에게 보내기 또는 드라이브에 보관하세요)',
                                  ),
                                );
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('백업 파일 생성 실패: $e'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.upload_file_rounded, size: 17),
                            label: const Text('백업하기'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryColor,
                              side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // 복원 불러오기 버튼
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () async {
                              try {
                                final result = await FilePicker.pickFile(
                                  type: FileType.any,
                                );
                                if (result != null) {
                                  final content = await result.xFile.readAsString();
                                  if (content.trim().isEmpty) return;

                                  if (!context.mounted) return;
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: const Row(
                                        children: [
                                          Icon(Icons.warning_amber_rounded, color: Color(0xFFD32F2F), size: 24),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '데이터 완전 덮어쓰기 안내',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                                            ),
                                          ),
                                        ],
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFD32F2F).withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(
                                                color: const Color(0xFFD32F2F).withValues(alpha: 0.3),
                                              ),
                                            ),
                                            child: const Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Icon(Icons.error_outline_rounded, color: Color(0xFFD32F2F), size: 18),
                                                SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    '현재 앱에 등록된 모든 기존 자산 및 설정 데이터가 완전히 삭제되고, 백업 파일의 데이터로 대체됩니다.',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w700,
                                                      color: Color(0xFFD32F2F),
                                                      height: 1.4,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          const Text(
                                            '• 복원 후에는 이전 데이터를 되돌릴 수 없습니다.\n• 백업 시점의 자산과 설정으로 100% 교체됩니다.\n\n정말 복원을 진행하시겠습니까?',
                                            style: TextStyle(fontSize: 13, height: 1.5),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: const Text('취소'),
                                        ),
                                        FilledButton(
                                          onPressed: () => Navigator.pop(ctx, true),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: const Color(0xFFD32F2F),
                                          ),
                                          child: const Text('완전 덮어쓰기 복원'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    final success = storage.importBackupJson(content);
                                    if (!context.mounted) return;
                                    if (success) {
                                      Navigator.pop(context); // 바텀시트 닫기
                                      onDataRestored?.call();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('🎉 자산 데이터가 완벽하게 복원되었습니다!'),
                                          backgroundColor: Color(0xFF176B5B),
                                          behavior: SnackBarBehavior.floating,
                                          duration: Duration(seconds: 3),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('올바른 웰스플로우 백업 파일이 아닙니다.'),
                                          backgroundColor: Colors.redAccent,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('파일 불러오기 실패: $e'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.download_rounded, size: 17),
                            label: const Text('복원하기'),
                            style: FilledButton.styleFrom(
                              backgroundColor: primaryColor,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── 닫기 버튼 ──
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE8E4DC),
                    foregroundColor: isDark ? Colors.white : const Color(0xFF2C2A28),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '닫기',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
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

// 하위 호환용 래퍼
void openNotificationSettingsSheet(BuildContext context, StorageService storage, [VoidCallback? onNotificationChanged]) {
  openSettingsSheet(context, storage, onNotificationChanged: onNotificationChanged);
}

// ─── 공통 헤더 액션 버튼 (설정 + 다크/라이트모드) ─────────────────
class HeaderActionButtons extends StatelessWidget {
  const HeaderActionButtons({
    super.key,
    required this.storage,
    this.onNotificationChanged,
    this.onDataRestored,
  });

  final StorageService storage;
  final VoidCallback? onNotificationChanged;
  final VoidCallback? onDataRestored;

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
              openSettingsSheet(
                context,
                storage,
                onNotificationChanged: onNotificationChanged,
                onDataRestored: onDataRestored,
              );
            },
            icon: Icon(
              Icons.tune_rounded,
              color: primaryColor,
            ),
            tooltip: '설정 및 데이터 백업',
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

// ─── 공통 프리미엄 도움말 다이얼로그 (헤더, 내용, 버튼 통일 디자인) ───
Future<void> showModernHelpDialog({
  required BuildContext context,
  required String title,
  required String content,
  String? badge,
  IconData? icon,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => ModernHelpDialog(
      title: title,
      content: content,
      badge: badge,
      icon: icon,
    ),
  );
}

class ModernHelpDialog extends StatelessWidget {
  final String title;
  final String content;
  final String? badge;
  final IconData? icon;

  const ModernHelpDialog({
    super.key,
    required this.title,
    required this.content,
    this.badge,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    // 제목 및 본문 정돈
    String cleanTitle = title.replaceAll('💡', '').trim();
    String rawContent = content;

    // 본문 첫 줄에 '💡 ...' 형태의 제목/서브팁이 있는 경우 분리
    String? headerTip;
    List<String> rawLines = rawContent.split('\n');
    if (rawLines.isNotEmpty && rawLines.first.contains('💡')) {
      headerTip = rawLines.first.replaceAll('💡', '').trim();
      rawContent = rawLines.sublist(1).join('\n').trim();
    }

    // 불릿 항목 및 일반 문단 분류
    final bulletItems = <String>[];
    final generalParagraphs = <String>[];

    for (final line in rawContent.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.startsWith('•') || trimmed.startsWith('-')) {
        bulletItems.add(trimmed.substring(1).trim());
      } else {
        generalParagraphs.add(trimmed);
      }
    }

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      elevation: 16,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isDark ? const Color(0xFF333333) : const Color(0xFFEBE6DD),
          width: 1,
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. 헤더 (아이콘 배지 + 카테고리 칩 + 타이틀 + 닫기 버튼) ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon ?? Icons.lightbulb_outline_rounded,
                    color: primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        badge ?? '도움말 & 안내',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cleanTitle,
                        style: TextStyle(
                          fontSize: 17.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: isDark ? Colors.white : const Color(0xFF191816),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF2ECE2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: isDark ? Colors.grey[400] : const Color(0xFF7A7265),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── 2. 본문 내용 (카드 박스 + 불릿/키워드 볼드 처리 + 스크롤) ──
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.52,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF262626) : const Color(0xFFF8F6F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF383838) : const Color(0xFFEBE6DD),
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (headerTip != null) ...[
                        Row(
                          children: [
                            Icon(Icons.tips_and_updates_outlined, size: 15, color: primaryColor),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                headerTip,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 0.8,
                          color: isDark ? const Color(0xFF383838) : const Color(0xFFE5E0D6),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (bulletItems.isNotEmpty)
                        ...bulletItems.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final item = entry.value;
                          final isLast = idx == bulletItems.length - 1 && generalParagraphs.isEmpty;

                          // '키워드: 내용' 형태인 경우 키워드 볼드 처리
                          final colonIdx = item.indexOf(':');
                          Widget textWidget;
                          if (colonIdx != -1) {
                            final keyword = item.substring(0, colonIdx + 1);
                            final rest = item.substring(colonIdx + 1);
                            textWidget = RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.55,
                                  color: isDark ? Colors.grey[200] : const Color(0xFF2D2A26),
                                  fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                                ),
                                children: [
                                  TextSpan(
                                    text: keyword,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF141312),
                                    ),
                                  ),
                                  TextSpan(text: rest),
                                ],
                              ),
                            );
                          } else {
                            textWidget = Text(
                              item,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.55,
                                color: isDark ? Colors.grey[200] : const Color(0xFF2D2A26),
                              ),
                            );
                          }

                          return Padding(
                            padding: EdgeInsets.only(bottom: isLast ? 0 : 11),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 7, right: 9),
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Expanded(child: textWidget),
                              ],
                            ),
                          );
                        }),
                      if (generalParagraphs.isNotEmpty)
                        ...generalParagraphs.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final p = entry.value;
                          final isLast = idx == generalParagraphs.length - 1;
                          return Padding(
                            padding: EdgeInsets.only(
                              top: (bulletItems.isNotEmpty && idx == 0) ? 8 : 0,
                              bottom: isLast ? 0 : 8,
                            ),
                            child: Text(
                              p,
                              style: TextStyle(
                                fontSize: 13.2,
                                height: 1.55,
                                color: isDark ? Colors.grey[200] : const Color(0xFF2D2A26),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // ── 3. 하단 풀-위드 확인 버튼 ──
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_rounded, size: 18),
                    SizedBox(width: 6),
                    Text(
                      '확인했어요',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
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
