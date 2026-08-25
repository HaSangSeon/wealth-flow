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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              const Text('🔥 ', style: TextStyle(fontSize: 16)),
              Text(
                '오늘의 종목 브리핑',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              if (_isLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 130,
          child: _isLoading 
            ? ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                itemBuilder: (context, index) {
                  return Container(
                    width: 260,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
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
                        } else {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      } catch (e) {
                        debugPrint('Error launching url: $e');
                      }
                    },
                    child: Container(
                      width: 260,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
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
                                    color: const Color(0xFF176B5B).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    news['symbol'].isNotEmpty ? '${news['holdingName']} (${news['symbol']})' : news['holdingName'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                    style: const TextStyle(
                                      color: Color(0xFF176B5B),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatTime(news['providerPublishTime']),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: Text(
                              news['title'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            news['publisher'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
