import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// 종목 뉴스 브리핑 전체보기 바텀시트
class PortfolioNewsSheet extends StatefulWidget {
  const PortfolioNewsSheet({
    super.key,
    required this.newsItems,
    this.onRefresh,
  });

  final List<Map<String, dynamic>> newsItems;
  final Future<void> Function()? onRefresh;

  static Future<void> show(
    BuildContext context, {
    required List<Map<String, dynamic>> newsItems,
    Future<void> Function()? onRefresh,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PortfolioNewsSheet(
        newsItems: newsItems,
        onRefresh: onRefresh,
      ),
    );
  }

  @override
  State<PortfolioNewsSheet> createState() => _PortfolioNewsSheetState();
}

class _PortfolioNewsSheetState extends State<PortfolioNewsSheet> {
  String _selectedHolding = '전체';
  bool _isRefreshing = false;

  List<String> get _holdingFilterList {
    final Set<String> holdings = {'전체'};
    for (final item in widget.newsItems) {
      final name = item['holdingName']?.toString();
      if (name != null && name.isNotEmpty) {
        holdings.add(name);
      }
    }
    return holdings.toList();
  }

  List<Map<String, dynamic>> get _filteredNews {
    if (_selectedHolding == '전체') {
      return widget.newsItems;
    }
    return widget.newsItems.where((item) => item['holdingName'] == _selectedHolding).toList();
  }

  int _countForHolding(String holding) {
    if (holding == '전체') return widget.newsItems.length;
    return widget.newsItems.where((item) => item['holdingName'] == holding).length;
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime dt;
    if (timestamp is int) {
      dt = DateTime.fromMillisecondsSinceEpoch(
        timestamp < 10000000000 ? timestamp * 1000 : timestamp,
      );
    } else {
      return '';
    }

    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${dt.month}월 ${dt.day}일';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final filterList = _holdingFilterList;
    final displayNews = _filteredNews;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 상단 핸들 바
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : const Color(0xFFD6D0C5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // 헤더 영역 (타이틀 + 새로고침 + 닫기)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.newspaper_rounded,
                        size: 18,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '종목 뉴스 브리핑',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          '보유 종목의 실시간 제도권 뉴스 피드',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? Colors.grey[400] : const Color(0xFF78716C),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (widget.onRefresh != null)
                      IconButton(
                        icon: _isRefreshing
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: primaryColor,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded, size: 21),
                        tooltip: '뉴스 새로고침',
                        onPressed: _isRefreshing
                            ? null
                            : () async {
                                setState(() => _isRefreshing = true);
                                try {
                                  await widget.onRefresh!();
                                } finally {
                                  if (mounted) setState(() => _isRefreshing = false);
                                }
                              },
                      ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22),
                      tooltip: '닫기',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 종목 필터 가로 스크롤 칩
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filterList.length,
              itemBuilder: (context, index) {
                final holding = filterList[index];
                final isSelected = holding == _selectedHolding;
                final count = _countForHolding(holding);

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    showCheckmark: false,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    label: Text(
                      '$holding $count',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.grey[300] : const Color(0xFF4A443D)),
                      ),
                    ),
                    backgroundColor: isDark ? const Color(0xFF2B2B2B) : const Color(0xFFF3EFE9),
                    selectedColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? primaryColor
                            : (isDark ? const Color(0xFF383838) : const Color(0xFFE5DFD5)),
                        width: 0.8,
                      ),
                    ),
                    onSelected: (_) {
                      setState(() {
                        _selectedHolding = holding;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),
          Divider(
            height: 1,
            thickness: 0.8,
            color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEBE6DD),
          ),

          // 세로 기사 피드 리스트
          Expanded(
            child: displayNews.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.feed_outlined,
                          size: 44,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '해당 종목의 최신 기사가 없습니다.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      18,
                      14,
                      18,
                      24 + math.max(
                        MediaQuery.of(context).viewPadding.bottom,
                        MediaQuery.of(context).padding.bottom,
                      ),
                    ),
                    itemCount: displayNews.length,
                    separatorBuilder: (_, __) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(
                        height: 1,
                        thickness: 0.8,
                        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEBE6DD),
                      ),
                    ),
                    itemBuilder: (context, index) {
                      final news = displayNews[index];
                      final hasImage =
                          news['imageUrl'] != null && news['imageUrl'].toString().isNotEmpty;
                      final hasSummary =
                          news['summary'] != null && news['summary'].toString().isNotEmpty;

                      return InkWell(
                        onTap: () async {
                          final url = Uri.parse(news['link']);
                          try {
                            if (await canLaunchUrl(url)) {
                              await launchUrl(
                                url,
                                mode: LaunchMode.inAppBrowserView,
                              );
                            }
                          } catch (e) {
                            debugPrint('Error launching news url: $e');
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. 상단 메타 (종목 뱃지 + 언론사 + 시간)
                              Row(
                                children: [
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      news['symbol'] != null &&
                                              news['symbol'].toString().isNotEmpty
                                          ? '${news['holdingName']} (${news['symbol']})'
                                          : news['holdingName'] ?? '',
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    news['publisher'] ?? '',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.grey[400] : const Color(0xFF7A7265),
                                    ),
                                  ),
                                  Text(
                                    ' • ',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: isDark ? Colors.grey[600] : const Color(0xFFA8A095),
                                    ),
                                  ),
                                  Text(
                                    _formatTime(news['providerPublishTime']),
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.grey[500] : const Color(0xFF8C847A),
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 10,
                                    color: isDark ? Colors.grey[600] : const Color(0xFFA8A095),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // 2. 중단 (제목 + 요약문 및 썸네일)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          news['title'] ?? '',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            height: 1.35,
                                            color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        if (hasSummary) ...[
                                          const SizedBox(height: 5),
                                          Text(
                                            news['summary'] ?? '',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                              color: isDark
                                                  ? Colors.grey[400]
                                                  : const Color(0xFF78716C),
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (hasImage) ...[
                                    const SizedBox(width: 12),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        news['imageUrl'],
                                        width: 62,
                                        height: 62,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
