import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models.dart';
import 'yahoo_finance_service.dart';
import 'portfolio_news_sheet.dart';

class PortfolioNewsCarousel extends StatefulWidget {
  final List<Holding> holdings;

  const PortfolioNewsCarousel({super.key, required this.holdings});

  @override
  State<PortfolioNewsCarousel> createState() => PortfolioNewsCarouselState();
}

class PortfolioNewsCarouselState extends State<PortfolioNewsCarousel> {
  List<Map<String, dynamic>> _newsItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNews();
  }

  @override
  void didUpdateWidget(PortfolioNewsCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldSymbols = oldWidget.holdings.map((h) => h.symbol ?? '').where((s) => s.isNotEmpty).toSet();
    final newSymbols = widget.holdings.map((h) => h.symbol ?? '').where((s) => s.isNotEmpty).toSet();
    if (oldSymbols.length != newSymbols.length || !oldSymbols.containsAll(newSymbols)) {
      fetchNews();
    }
  }

  Future<void> fetchNews() async {
    setState(() => _isLoading = true);
    final service = YahooFinanceService();
    final List<Map<String, dynamic>> news;
    if (widget.holdings.isEmpty) {
      // 등록된 자산이 없을 때는 국내/해외 대표 시장(코스피, S&P 500) 시황 뉴스를 제공합니다
      news = await service.fetchPortfolioNews(['코스피', 'S&P 500']);
    } else {
      news = await service.fetchPortfolioNews(widget.holdings);
    }

    if (mounted) {
      setState(() {
        _newsItems = news;
        _isLoading = false;
      });
    }
  }

  String _formatTime(int epochSeconds) {
    final diff = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000));
    if (diff.inDays > 0) return '${diff.inDays}일 전';
    if (diff.inHours > 0) return '${diff.inHours}시간 전';
    if (diff.inMinutes > 0) return '${diff.inMinutes}분 전';
    return '방금 전';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
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
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 카드 내부 헤더 (아이콘 + 타이틀 + 전체보기 버튼/로딩) ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _newsItems.isNotEmpty
                    ? () {
                        PortfolioNewsSheet.show(
                          context,
                          newsItems: _newsItems,
                          onRefresh: fetchNews,
                        );
                      }
                    : null,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.newspaper_rounded,
                        size: 16,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.holdings.isEmpty ? '오늘의 증시 브리핑' : '오늘의 종목 브리핑',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: primaryColor,
                  ),
                )
              else if (_newsItems.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    PortfolioNewsSheet.show(
                      context,
                      newsItems: _newsItems,
                      onRefresh: fetchNews,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0EBE1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? const Color(0xFF383838) : const Color(0xFFE5DFD5),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_newsItems.length}건 전체보기',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.grey[300] : const Color(0xFF5E574E),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 9,
                          color: isDark ? Colors.grey[400] : const Color(0xFF7A7265),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // ── 카드 내부 가로 뉴스 캐러셀 ──
          if (!_isLoading && _newsItems.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262626) : const Color(0xFFF9F7F3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF383838) : const Color(0xFFE5E0D7),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.newspaper_rounded,
                      size: 20,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '보유 종목 맞춤 브리핑',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '자산을 등록하시면 보유 종목의 실시간 시황과 배당 공시가 자동으로 모입니다.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? Colors.grey[400] : const Color(0xFF7A7265),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 126,
              child: _isLoading
                ? ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 2,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 285,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF262626) : const Color(0xFFF7F5F0),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xFF333333) : const Color(0xFFEBE6DD),
                            width: 0.8,
                          ),
                        ),
                      );
                    },
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _newsItems.length,
                    itemBuilder: (context, index) {
                      final news = _newsItems[index];
                      final hasImage = news['imageUrl'] != null && news['imageUrl'].toString().isNotEmpty;
                      final hasSummary = news['summary'] != null && news['summary'].toString().isNotEmpty;

                      return GestureDetector(
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
                            debugPrint('Error launching url: $e');
                          }
                        },
                        child: Container(
                          width: 285,
                          margin: EdgeInsets.only(right: index == _newsItems.length - 1 ? 0 : 10),
                          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF262626) : const Color(0xFFF9F7F3),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? const Color(0xFF383838) : const Color(0xFFE5E0D7),
                              width: 0.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // 1. 상단: 종목 뱃지 (좌) + 원문 읽기 힌트 (우)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        news['symbol'] != null && news['symbol'].toString().isNotEmpty
                                            ? '${news['holdingName']} (${news['symbol']})'
                                            : news['holdingName'] ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Row(
                                    children: [
                                      Text(
                                        '읽기',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.grey[400] : const Color(0xFF8C847A),
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 8.5,
                                        color: isDark ? Colors.grey[500] : const Color(0xFFA8A095),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              // 2. 중단: 제목 + 요약문 (좌) 및 썸네일 (우)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          news['title'] ?? '',
                                          maxLines: hasSummary ? 2 : 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            height: 1.3,
                                            color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        if (hasSummary) ...[
                                          const SizedBox(height: 3),
                                          Text(
                                            news['summary'] ?? '',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w400,
                                              color: isDark ? Colors.grey[400] : const Color(0xFF78716C),
                                              height: 1.2,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (hasImage) ...[
                                    const SizedBox(width: 10),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        news['imageUrl'],
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                      ),
                                    ),
                                  ],
                                ],
                              ),

                              // 3. 하단: 언론사 & 발행시간
                              Row(
                                children: [
                                  Icon(
                                    Icons.public_rounded,
                                    size: 11,
                                    color: isDark ? Colors.grey[500] : const Color(0xFFA8A095),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    news['publisher'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10.5,
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
                                    _formatTime(news['providerPublishTime'] ?? 0),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.grey[500] : const Color(0xFF8C847A),
                                    ),
                                  ),
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
