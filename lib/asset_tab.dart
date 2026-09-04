import 'dart:io';
import 'package:flutter/material.dart';
import 'models.dart';
import 'formatters.dart';
import 'premium.dart';
import 'stock_chart_sheet.dart';
import 'portfolio_allocation_card.dart';
import 'portfolio_news_carousel.dart';
import 'profile_sheet.dart';
import 'holding_form_sheet.dart';
import 'stock_alert_service.dart';
import 'common_widgets.dart';

class AssetManagementTab extends StatelessWidget {
  const AssetManagementTab({
    super.key,
    required this.storage,
    required this.holdings,
    required this.currentValue,
    this.lastSyncedAt,
    required this.lastExchangeRate,
    required this.isSyncing,
    required this.showForeignInKrw,
    required this.onToggleForeignInKrw,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onRefresh,
    required this.onPremiumChanged,
    required this.onProfileTap,
    this.onDataRestored,
  });

  final StorageService storage;
  final List<Holding> holdings;
  final double currentValue;
  final DateTime? lastSyncedAt;
  final double lastExchangeRate;
  final bool isSyncing;
  final bool showForeignInKrw;
  final ValueChanged<bool> onToggleForeignInKrw;
  final VoidCallback onAdd;
  final ValueChanged<Holding> onEdit;
  final ValueChanged<Holding> onDelete;
  final Future<void> Function() onRefresh;
  final VoidCallback onPremiumChanged;
  final VoidCallback onProfileTap;
  final VoidCallback? onDataRestored;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          key: refreshIndicatorKey,
          onRefresh: onRefresh,
          color: const Color(0xFF176B5B),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. 헤더 (프로필 + 액션 버튼)
                      Row(
                        children: [
                          GestureDetector(
                            onTap: onProfileTap,
                            child: Builder(
                              builder: (context) {
                                final activeProfile = storage.profiles.firstWhere(
                                  (p) => p.id == storage.activeProfileId,
                                  orElse: () => storage.profiles.first,
                                );
                                final avatarPath = activeProfile.avatarPath;
                                final avatarAbsPath = storage.getAvatarAbsolutePath(avatarPath);
                                final hasAvatar = avatarAbsPath != null && File(avatarAbsPath).existsSync();
                                return Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(8),
                                    image: hasAvatar
                                        ? DecorationImage(
                                            image: FileImage(File(avatarAbsPath)),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: !hasAvatar
                                      ? const Icon(Icons.account_balance_wallet,
                                          color: Colors.white)
                                      : null,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: onProfileTap,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        storage.profiles.firstWhere((p) => p.id == storage.activeProfileId, orElse: () => storage.profiles.first).name,
                                        style: const TextStyle(
                                            fontSize: 20, fontWeight: FontWeight.w800),
                                      ),
                                      const Icon(Icons.arrow_drop_down),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    '내 자산 입력 및 관리',
                                    style: TextStyle(color: Colors.grey, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          HeaderActionButtons(
                            storage: storage,
                            onNotificationChanged: () {},
                            onDataRestored: onDataRestored,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 2. 총 자산 요약 배너 카드
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
                                '총 자산',
                                style: TextStyle(color: Color(0xFFD6E8E4)),
                              ),
                              const SizedBox(height: 6),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  holdings.isEmpty
                                      ? '₩0'
                                      : formatCurrencyFull(currentValue),
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              if (lastSyncedAt != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.sync, color: Color(0xFFB0D4CD), size: 14),
                                            const SizedBox(width: 4),
                                            Text(
                                              '마지막 동기화: ${formatTime(lastSyncedAt!)}',
                                              style: const TextStyle(
                                                color: Color(0xFFB0D4CD),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.currency_exchange, color: Color(0xFFB0D4CD), size: 14),
                                            const SizedBox(width: 4),
                                            Text(
                                              '적용 환율: 1 USD = ${formatCurrency(lastExchangeRate)}',
                                              style: const TextStyle(
                                                color: Color(0xFFB0D4CD),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      onPressed: isSyncing ? null : () => onRefresh(),
                                      icon: isSyncing
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(Icons.refresh, color: Colors.white, size: 20),
                                      tooltip: '지금 새로고침',
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 16),
                              Container(height: 1, color: const Color(0xFF2A8B79)),
                              const SizedBox(height: 12),
                              const Text(
                                '보유 자산을 등록하시면 연금 절세, 은퇴 시뮬레이션, 월별 배당 분석에 실시간으로 자동 연동됩니다.',
                                style: TextStyle(
                                    fontSize: 13, color: Color(0xFFB0D4CD), height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 3. 포트폴리오 뉴스 캐러셀
                      PortfolioNewsCarousel(key: portfolioNewsKey, holdings: holdings),
                      const SizedBox(height: 16),

                      // 4. 자산 비중 분석 (자산군별 / 계좌별 분석 통합 카드)
                      PortfolioAllocationCard(
                        holdings: holdings,
                        lastExchangeRate: lastExchangeRate,
                      ),
                      const SizedBox(height: 16),

                      // 6. 자산 목록 통합 카드 (헤더 + N개 뱃지 + 원화환산 + 자산추가 버튼 + 내부 종목 타일 리스트)
// ── 자산 목록 통합 카드 ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
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
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 카드 내부 헤더
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      Icons.format_list_bulleted_rounded,
                                      size: 16,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    '자산 목록',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E4DC),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${holdings.length}개',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.grey[300] : const Color(0xFF5E574E),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    '원화 환산',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.grey[400] : const Color(0xFF6E675E),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  SizedBox(
                                    height: 26,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Switch(
                                        value: showForeignInKrw,
                                        onChanged: onToggleForeignInKrw,
                                        activeThumbColor: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: onAdd,
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.add, size: 13, color: Colors.white),
                                          SizedBox(width: 2),
                                          Text(
                                            '자산 추가',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // 카드 내부 콘텐츠 (종목 목록 또는 빈 상태)
                          if (holdings.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                              child: Center(
                                child: Column(
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.add_chart,
                                        size: 28,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      '아직 등록된 자산이 없습니다',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      '자산 추가 버튼을 눌러 첫 종목을 등록해 보세요.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: holdings.length,
                              itemBuilder: (context, index) {
                                final holding = holdings[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF262626) : const Color(0xFFF8F6F2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF383838) : const Color(0xFFEBE6DD),
                                      width: 0.9,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => onEdit(holding),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(
                                                      color: isDark ? const Color(0xFF404040) : const Color(0xFFDDD8CE),
                                                      width: 0.6,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    holding.account.label,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                      color: isDark ? const Color(0xFF2E9E82) : const Color(0xFF176B5B),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        holding.name,
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.w800,
                                                          fontSize: 14.5,
                                                          color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      if (holding.symbol != null && holding.symbol!.isNotEmpty) ...[
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          holding.symbol!,
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w500,
                                                            color: isDark ? Colors.grey[400] : const Color(0xFF8E867C),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    if (holding.symbol != null && holding.symbol!.isNotEmpty)
                                                      IconButton(
                                                        tooltip: '시세 차트',
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                                        visualDensity: VisualDensity.compact,
                                                        onPressed: () => _openStockChartSheet(context, holding),
                                                        icon: const Icon(Icons.show_chart_rounded, size: 18, color: Color(0xFF176B5B)),
                                                      ),
                                                    IconButton(
                                                      tooltip: '수정',
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                                      visualDensity: VisualDensity.compact,
                                                      onPressed: () => onEdit(holding),
                                                      icon: Icon(Icons.edit_outlined, size: 16, color: isDark ? Colors.grey[400] : const Color(0xFF8E867C)),
                                                    ),
                                                    IconButton(
                                                      tooltip: '삭제',
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                                      visualDensity: VisualDensity.compact,
                                                      onPressed: () => onDelete(holding),
                                                      icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFE57373)),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    if (holding.type != AssetType.cash) ...[
                                                      Text(
                                                        '${formatNumber(holding.quantity)}주 · 주당 ${holding.formatOriginalPrice()}',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w500,
                                                          color: isDark ? Colors.grey[400] : const Color(0xFF7A7265),
                                                        ),
                                                      ),
                                                    ] else ...[
                                                      Text(
                                                        '현금 자산',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w500,
                                                          color: isDark ? Colors.grey[400] : const Color(0xFF7A7265),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                Text(
                                                  showForeignInKrw
                                                      ? holding.formatValueInKrw()
                                                      : holding.formatOriginalValue(),
                                                  style: TextStyle(
                                                    color: isDark ? const Color(0xFF2E9E82) : Theme.of(context).colorScheme.primary,
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 15.5,
                                                    letterSpacing: -0.2,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
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
      ),
    );
  }

  void _openStockChartSheet(BuildContext context, Holding holding) {
    if (holding.symbol == null || holding.symbol!.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StockHistoryChartSheet(
        holding: holding,
      ),
    );
  }
}

// ─── 시뮬레이션 탭 ────────────────────────────────────────

