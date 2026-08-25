import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'models.dart';
import 'yahoo_finance_service.dart';

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
    final holdingMap = {for (var h in widget.holdings) if (h.name.isNotEmpty) h.name: h.symbol ?? ''};
    final names = widget.holdings.map((h) => h.name).where((n) => n.isNotEmpty && n != '현금').toSet().toList();
    if (names.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _newsItems = [];
        });
      }
      return;
    }

    final service = YahooFinanceService();
    final news = await service.fetchPortfolioNews(names);
    
    List<Map<String, dynamic>> finalNews = [];
    for (var item in news) {
      item['holdingName'] = item['query'];
      item['symbol'] = holdingMap[item['query']] ?? '';
      finalNews.add(item);
    }
    
    if (mounted) {
      setState(() {
        _newsItems = finalNews;
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
    if (!_isLoading && _newsItems.isEmpty) return const SizedBox.shrink();

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
          // ── 카드 내부 헤더 (아이콘 + 타이틀 + 뱃지/로딩) ──
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
                    child: Icon(
                      Icons.newspaper_rounded,
                      size: 16,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '오늘의 종목 브리핑',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0EBE1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_newsItems.length}건의 실시간 소식',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.grey[300] : const Color(0xFF5E574E),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // ── 카드 내부 가로 뉴스 캐러셀 ──
          SizedBox(
            height: 126,
            child: _isLoading
                ? ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 2,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 250,
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
                      return GestureDetector(
                        onTap: () async {
                          final url = Uri.parse(news['link']);
                          try {
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            }
                          } catch (e) {
                            debugPrint('Error launching url: $e');
                          }
                        },
                        child: Container(
                          width: 255,
                          margin: EdgeInsets.only(right: index == _newsItems.length - 1 ? 0 : 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF262626) : const Color(0xFFF9F7F3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF383838) : const Color(0xFFE5E0D7),
                              width: 0.8,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                        news['symbol'].isNotEmpty
                                            ? '${news['holdingName']} (${news['symbol']})'
                                            : news['holdingName'],
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
                                  Text(
                                    _formatTime(news['providerPublishTime']),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.grey[400] : const Color(0xFF8C847A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Text(
                                  news['title'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    height: 1.35,
                                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    news['publisher'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.grey[400] : const Color(0xFF7A7265),
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 10,
                                    color: isDark ? Colors.grey[500] : const Color(0xFFA8A095),
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
