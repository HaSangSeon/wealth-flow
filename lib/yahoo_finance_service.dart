import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

class YahooFinanceSearchResult {
  final String symbol;
  final String shortname;
  final String exchange;
  final String quoteType;

  YahooFinanceSearchResult({
    required this.symbol,
    required this.shortname,
    required this.exchange,
    required this.quoteType,
  });
}

class YahooFinanceService {
  static const String _userAgent =
      'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
      'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 '
      'Mobile/15E148 Safari/604.1';

  List<YahooFinanceSearchResult>? _localKoreanStocks;

  static const Map<String, List<String>> _synonyms = {
    '네이버': ['NAVER', '035420.KS'],
    'naver': ['NAVER', '035420.KS'],
    '포스코': ['POSCO홀딩스', '포스코퓨처엠', '포스코DX', '포스코인터내셔널', '포스코스틸리온'],
    '포스코홀딩스': ['POSCO홀딩스', '005490.KS'],
    'posco': ['POSCO홀딩스', '005490.KS'],
    '현대차': ['현대차', '현대자동차', '005380.KS', '현대차우', '현대차2우B', '현대차3우B'],
    '현대자동차': ['현대차', '현대자동차', '005380.KS'],
    '삼전': ['삼성전자', '005930.KS'],
    '삼전우': ['삼성전자우', '005935.KS'],
    '삼성': [
      '삼성전자',
      '삼성전자우',
      '삼성바이오로직스',
      '삼성SDI',
      '삼성물산',
      '삼성생명',
      '삼성전기',
      '삼성에스디에스',
      '삼성화재',
      '삼성중공업',
      '삼성증권',
      '삼성카드',
      '삼성E&A',
    ],
    '하닉': ['SK하이닉스', '000660.KS'],
    '하이닉스': ['SK하이닉스', '000660.KS'],
    '엔솔': ['LG에너지솔루션', '373220.KS'],
    '엘지엔솔': ['LG에너지솔루션', '373220.KS'],
    '한전': ['한국전력', '한국전력공사', '015760.KS'],
    '한국전력': ['한국전력', '한국전력공사', '015760.KS'],
    '카뱅': ['카카오뱅크', '323410.KS'],
    '카페': ['카카오페이', '377300.KS'],
    '기아차': ['기아', '000270.KS'],
    'kia': ['기아', '000270.KS'],
    '케이티': ['KT', '030200.KS'],
    '케이티앤지': ['KT&G', '033780.KS'],
    '담배인삼공사': ['KT&G', '033780.KS'],
    '에스케이': [
      'SK',
      'SK하이닉스',
      'SK스퀘어',
      'SK이노베이션',
      'SK텔레콤',
      'SK바이오팜',
      'SK아이이테크놀로지',
    ],
    '엘지': [
      'LG',
      'LG에너지솔루션',
      'LG화학',
      'LG전자',
      'LG생활건강',
      'LG디스플레이',
      'LG이노텍',
      'LG유플러스',
    ],
    '씨제이': ['CJ', 'CJ제일제당', 'CJ ENM', 'CJ대한통운'],
    '와이지': ['와이지엔터테인먼트', '122870.KQ'],
    '제이와이피': ['JYP Ent.', '035900.KQ'],
    '에스엠': ['에스엠', '041510.KQ'],
    '크래프톤': ['크래프톤', '259960.KS'],
    '하이브': ['하이브', '352820.KS'],
  };

  Future<void> _loadKoreanStocks() async {
    if (_localKoreanStocks != null) return;
    try {
      final jsonString = await rootBundle.loadString('assets/korean_stocks.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      _localKoreanStocks = jsonList.map((item) {
        final String symbol = item['symbol'] ?? '';
        final String name = item['name'] ?? '';
        final String type = item['type'] ?? '';

        return YahooFinanceSearchResult(
          symbol: symbol,
          shortname: name,
          exchange: symbol.endsWith('.KS') ? 'KSE' : 'KSC',
          quoteType: type == 'etf' ? 'ETF' : 'EQUITY',
        );
      }).toList();
    } catch (e) {
      _localKoreanStocks = [];
    }
  }

  String _buildRelevanceQuery(String query) {
    final hasKorean = RegExp(r'[\uac00-\ud7a3]').hasMatch(query);
    if (hasKorean) {
      return '$query (주가 OR 실적 OR 전망 OR 공시 OR 특허 OR 인수 OR 소송 OR 사업 OR 시장 OR 투자 OR 분석)';
    } else {
      return '$query (stock OR earnings OR outlook OR "share price" OR "target price" OR acquisition OR lawsuit OR business OR market OR investment OR analysis)';
    }
  }

  /// 사용자가 보유한 종목들의 최신 뉴스를 가져옵니다 (Google News RSS).
  Future<List<Map<String, dynamic>>> fetchPortfolioNews(List<String> queries) async {
    final List<Map<String, dynamic>> allNews = [];
    final Set<String> seenUrls = {};

    final targetQueries = queries.take(5).toList();

    for (final query in targetQueries) {
      try {
        final refinedQuery = _buildRelevanceQuery(query);
        final encodedQuery = Uri.encodeComponent(refinedQuery);
        final url = Uri.parse('https://news.google.com/rss/search?q=$encodedQuery&hl=ko&gl=KR&ceid=KR:ko');
        final response = await http.get(url, headers: {'User-Agent': _userAgent});

        if (response.statusCode == 200) {
          final document = xml.XmlDocument.parse(response.body);
          final items = document.findAllElements('item').take(2);

          for (final item in items) {
            final title = item.findElements('title').firstOrNull?.innerText ?? '';
            final link = item.findElements('link').firstOrNull?.innerText ?? '';
            final pubDateStr = item.findElements('pubDate').firstOrNull?.innerText ?? '';
            final source = item.findElements('source').firstOrNull?.innerText ?? 'Google News';

            if (link.isEmpty || seenUrls.contains(link)) continue;

            seenUrls.add(link);

            int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
            try {
              timestamp = HttpDate.parse(pubDateStr).millisecondsSinceEpoch ~/ 1000;
            } catch (_) {}

            allNews.add({
              'query': query,
              'title': title,
              'publisher': source,
              'link': link,
              'providerPublishTime': timestamp,
            });
          }
        }
      } catch (_) {}
    }

    allNews.sort((a, b) => (b['providerPublishTime'] as int).compareTo(a['providerPublishTime'] as int));
    return allNews;
  }

  bool _isChoseongOnly(String text) {
    if (text.isEmpty) return false;
    final regExp = RegExp(r'^[ㄱ-ㅎ\s]+$');
    return regExp.hasMatch(text);
  }

  String _getChoseong(String text) {
    const choseongList = [
      'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ'
    ];
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      if (code >= 0xAC00 && code <= 0xD7A3) {
        final choseongIndex = ((code - 0xAC00) / 28 / 21).floor();
        buffer.write(choseongList[choseongIndex]);
      } else {
        buffer.write(text[i]);
      }
    }
    return buffer.toString();
  }

  Future<List<YahooFinanceSearchResult>> _searchLocalKoreanStocks(String query) async {
    await _loadKoreanStocks();
    if (_localKoreanStocks == null || _localKoreanStocks!.isEmpty) {
      return [];
    }

    final cleanQuery = query.trim();
    final lowerQuery = cleanQuery.toLowerCase();
    final normQuery = lowerQuery.replaceAll(RegExp(r'\s+'), '');
    final queryIsChoseong = _isChoseongOnly(lowerQuery);

    final List<String> synonymTargets = [
      ...?_synonyms[lowerQuery],
      ...?_synonyms[normQuery],
    ];

    final List<MapEntry<int, YahooFinanceSearchResult>> scored = [];

    for (int rank = 0; rank < _localKoreanStocks!.length; rank++) {
      final item = _localKoreanStocks![rank];
      final name = item.shortname;
      final symbol = item.symbol;
      final code = symbol.split('.').first.toLowerCase();
      final lowerName = name.toLowerCase();
      final normName = lowerName.replaceAll(RegExp(r'\s+'), '');

      int score = 0;

      // 1. 정확 일치 (종목코드 또는 종목명)
      if (code == lowerQuery || code == normQuery) {
        score = 1000;
      } else if (lowerName == lowerQuery || normName == normQuery) {
        score = 950;
      } else if (synonymTargets.any((t) =>
          t.toLowerCase() == lowerName ||
          t.toLowerCase() == normName ||
          t == symbol ||
          t.toLowerCase() == code)) {
        score = 900;
      }
      // 2. 접두사 일치 (Starts with)
      else if (normName.startsWith(normQuery)) {
        score = 800 - normName.length;
      } else if (queryIsChoseong) {
        final nameChoseong = _getChoseong(lowerName);
        final normChoseong = nameChoseong.replaceAll(RegExp(r'\s+'), '');
        if (normChoseong == normQuery) {
          score = 750;
        } else if (normChoseong.startsWith(normQuery)) {
          score = 700 - normName.length;
        } else if (normChoseong.contains(normQuery)) {
          score = 450;
        }
      }
      // 3. 부분 포함 일치 (Contains)
      else if (normName.contains(normQuery)) {
        score = 500 - normName.length;
      } else if (code.contains(normQuery) || symbol.toLowerCase().contains(normQuery)) {
        score = 300;
      }

      if (score > 0) {
        // 시가총액 순위(초기 인덱스)에 따른 가산점 부여 (상위 대형주일수록 동점 시 우선)
        score += max(0, 50 - (rank ~/ 25));
        scored.add(MapEntry(score, item));
      }
    }

    scored.sort((a, b) => b.key.compareTo(a.key));
    return scored.take(20).map((e) => e.value).toList();
  }

  Future<List<YahooFinanceSearchResult>> _searchYahooStocks(String query) async {
    try {
      final url = Uri.parse(
        'https://query2.finance.yahoo.com/v1/finance/search'
        '?q=${Uri.encodeComponent(query)}&quotesCount=10&newsCount=0',
      );
      final response =
          await http.get(url, headers: {'User-Agent': _userAgent}).timeout(
        const Duration(seconds: 3),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final quotes = data['quotes'] as List<dynamic>? ?? [];
        return quotes
            .map(
              (q) => YahooFinanceSearchResult(
                symbol: q['symbol'] ?? '',
                shortname: q['shortname'] ?? q['longname'] ?? '',
                exchange: q['exchange'] ?? '',
                quoteType: q['quoteType'] ?? '',
              ),
            )
            .where((item) => item.shortname.isNotEmpty)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<YahooFinanceSearchResult>> searchStocks(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    final hasKorean = RegExp(r'[\uac00-\ud7a3ㄱ-ㅎ]').hasMatch(cleanQuery);

    // 한글 검색 시 야후 파이낸스는 400 Bad Request를 반환하므로 로컬 검색을 즉시 수행합니다
    if (hasKorean) {
      return await _searchLocalKoreanStocks(cleanQuery);
    }

    // 영문/티커 검색의 경우 로컬과 야후 동시 검색
    final localFuture = _searchLocalKoreanStocks(cleanQuery);
    final yahooFuture = _searchYahooStocks(cleanQuery);

    final results = await Future.wait([localFuture, yahooFuture]);
    final localResults = results[0];
    final yahooResults = results[1];

    final merged = <String, YahooFinanceSearchResult>{};

    // 로컬 매칭 결과를 우선적으로 추가
    for (final item in localResults) {
      merged[item.symbol] = item;
    }

    // 야후 매칭 결과를 중복되지 않게 추가
    for (final item in yahooResults) {
      if (!merged.containsKey(item.symbol)) {
        String finalName = item.shortname;
        if (_localKoreanStocks != null) {
          for (final k in _localKoreanStocks!) {
            if (k.symbol == item.symbol) {
              finalName = k.shortname;
              break;
            }
          }
        }
        merged[item.symbol] = YahooFinanceSearchResult(
          symbol: item.symbol,
          shortname: finalName,
          exchange: item.exchange,
          quoteType: item.quoteType,
        );
      }
    }

    return merged.values.toList();
  }

  double? _cachedExchangeRate;
  DateTime? _lastExchangeRateTime;

  Future<double?> fetchExchangeRate([String base = 'USD']) async {
    final cleanBase = base.toUpperCase().trim();
    if (cleanBase == 'KRW') return 1.0;

    if (cleanBase == 'USD' && _cachedExchangeRate != null && _lastExchangeRateTime != null) {
      if (DateTime.now().difference(_lastExchangeRateTime!).inMinutes < 10) {
        return _cachedExchangeRate;
      }
    }

    // 1. 네이버 금융 환율 API 시도
    try {
      final naverUrl = Uri.parse(
        'https://m.stock.naver.com/front-api/marketIndex/prices?category=exchange&reutersCode=FX_${cleanBase}KRW',
      );
      final response = await http.get(naverUrl, headers: {'User-Agent': _userAgent}).timeout(
        const Duration(seconds: 3),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['isSuccess'] == true && data['result'] != null && (data['result'] as List).isNotEmpty) {
          final first = data['result'][0];
          final closePriceStr = (first['closePrice'] as String?)?.replaceAll(',', '');
          if (closePriceStr != null) {
            double rate = double.parse(closePriceStr);
            if (cleanBase == 'JPY') {
              // 100엔 기준이므로 1엔으로 환산
              rate = rate / 100.0;
            }
            if (cleanBase == 'USD') {
              _cachedExchangeRate = rate;
              _lastExchangeRateTime = DateTime.now();
            }
            return rate;
          }
        }
      }
    } catch (_) {}

    // 2. 야후 파이낸스 차트 환율 시도
    try {
      final url = Uri.parse(
        'https://query2.finance.yahoo.com/v8/finance/chart/${cleanBase}KRW=X',
      );
      final response =
          await http.get(url, headers: {'User-Agent': _userAgent}).timeout(
        const Duration(seconds: 3),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['chart']?['result'] as List<dynamic>?;
        if (result != null && result.isNotEmpty) {
          final meta = result[0]['meta'];
          final rate = (meta['regularMarketPrice'] as num?)?.toDouble();
          if (rate != null) {
            if (cleanBase == 'USD') {
              _cachedExchangeRate = rate;
              _lastExchangeRateTime = DateTime.now();
            }
            return rate;
          }
        }
      }
    } catch (_) {}

    return getFallbackExchangeRate(cleanBase);
  }

  /// 실시간 주가 및 배당 정보 가져오기 (국내 주식은 네이버 금융 1순위, 글로벌은 야후/네이버)
  Future<Map<String, dynamic>?> fetchStockDetails(String symbol) async {
    final cleanSymbol = symbol.trim();
    final isKoreanStock = cleanSymbol.endsWith('.KS') || cleanSymbol.endsWith('.KQ');

    // 1. 국내 주식의 경우 네이버 금융 실시간 시세 API 우선 호출 (100% 안정적, 초고속)
    if (isKoreanStock) {
      final code = cleanSymbol.split('.').first;
      double? naverPrice;
      try {
        final naverUrl = Uri.parse('https://m.stock.naver.com/api/stock/$code/basic');
        final response = await http.get(naverUrl, headers: {'User-Agent': _userAgent}).timeout(
          const Duration(seconds: 3),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final closePriceStr = (data['closePrice'] as String?)?.replaceAll(',', '');
          if (closePriceStr != null) {
            naverPrice = double.tryParse(closePriceStr);
          }
        }
      } catch (_) {}

      // 국내 주식 배당 내역을 야후 파이낸스에서 조회
      List<Map<String, dynamic>> dividends = [];
      try {
        final url = Uri.parse(
          'https://query2.finance.yahoo.com/v8/finance/chart/$cleanSymbol?range=2y&interval=1d&events=div',
        );
        final response = await http.get(url, headers: {'User-Agent': _userAgent}).timeout(
          const Duration(seconds: 4),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final result = data['chart']?['result'] as List<dynamic>?;
          if (result != null && result.isNotEmpty) {
            final chartData = result[0];
            if (chartData.containsKey('events') && chartData['events'].containsKey('dividends')) {
              final divMap = chartData['events']['dividends'] as Map<String, dynamic>;
              divMap.forEach((key, val) {
                dividends.add({
                  'amount': (val['amount'] as num).toDouble(),
                  'date': val['date'] as int,
                });
              });

              if (dividends.isNotEmpty) {
                dividends.sort((a, b) => (b['date'] as int).compareTo(a['date'] as int));
              }
            }
            naverPrice ??= (chartData['meta']?['regularMarketPrice'] as num?)?.toDouble();
          }
        }
      } catch (_) {}

      if (naverPrice != null) {
        return {
          'price': naverPrice,
          'currency': 'KRW',
          'dividends': dividends,
        };
      }
    }

    // 2. 해외 주식 또는 네이버 실패 시 야후 파이낸스 차트 시도
    try {
      final url = Uri.parse(
        'https://query2.finance.yahoo.com/v8/finance/chart/$cleanSymbol'
        '?range=2y&interval=1d&events=div',
      );
      final response =
          await http.get(url, headers: {'User-Agent': _userAgent}).timeout(
        const Duration(seconds: 4),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['chart']?['result'] as List<dynamic>?;
        if (result != null && result.isNotEmpty) {
          final meta = result[0]['meta'];
          final chartData = result[0];

          List<Map<String, dynamic>> dividends = [];
          if (chartData.containsKey('events') && chartData['events'].containsKey('dividends')) {
            final divMap = chartData['events']['dividends'] as Map<String, dynamic>;
            divMap.forEach((key, val) {
              dividends.add({
                'amount': (val['amount'] as num).toDouble(),
                'date': val['date'] as int,
              });
            });

            if (dividends.isNotEmpty) {
              dividends.sort((a, b) => (b['date'] as int).compareTo(a['date'] as int));
            }
          }

          return {
            'price': meta['regularMarketPrice'],
            'currency': meta['currency'],
            'dividends': dividends,
          };
        }
      }
    } catch (_) {}

    // 3. 해외 주식의 경우 네이버 해외주식 API 시도
    if (!isKoreanStock) {
      for (final suffix in ['.O', '.N', '']) {
        try {
          final naverWorldUrl = Uri.parse('https://api.stock.naver.com/stock/$cleanSymbol$suffix/basic');
          final response = await http.get(naverWorldUrl, headers: {'User-Agent': _userAgent}).timeout(
            const Duration(seconds: 3),
          );
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final closePriceStr = (data['closePrice'] as String?)?.replaceAll(',', '');
            if (closePriceStr != null) {
              final double price = double.parse(closePriceStr);
              return {
                'price': price,
                'currency': 'USD',
                'dividends': <Map<String, dynamic>>[],
              };
            }
          }
        } catch (_) {}
      }
    }

    return null;
  }

  /// 실시간 주가, 전일대비 등락률(%) 및 변동 금액 조회
  Future<StockQuote?> fetchStockQuote(String symbol) async {
    final cleanSymbol = symbol.trim();
    if (cleanSymbol.isEmpty) return null;
    final isKoreanStock = cleanSymbol.endsWith('.KS') || cleanSymbol.endsWith('.KQ');

    // 1. 국내 주식 네이버 API
    if (isKoreanStock) {
      final code = cleanSymbol.split('.').first;
      try {
        final naverUrl = Uri.parse('https://m.stock.naver.com/api/stock/$code/basic');
        final response = await http.get(naverUrl, headers: {'User-Agent': _userAgent}).timeout(
          const Duration(seconds: 3),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final closePriceStr = (data['closePrice'] as String?)?.replaceAll(',', '');
          final ratioStr = (data['fluctuationsRatio'] as String?)?.replaceAll(',', '') ?? '0';
          final diffStr = (data['compareToPreviousClosePrice'] as String?)?.replaceAll(',', '') ?? '0';
          final compareToPreviousPrice = data['compareToPreviousPrice'] as Map<String, dynamic>?;
          
          if (closePriceStr != null) {
            final price = double.parse(closePriceStr);
            double ratio = double.tryParse(ratioStr) ?? 0.0;
            double diff = double.tryParse(diffStr) ?? 0.0;
            
            // 하락인 경우 음수 처리
            final cvCode = compareToPreviousPrice?['code']?.toString() ?? data['compareToPreviousPriceCode']?.toString() ?? '';
            if (cvCode == '5' || cvCode == '4') { // 5: 하락, 4: 하한가
              if (ratio > 0) ratio = -ratio;
              if (diff > 0) diff = -diff;
            }

            return StockQuote(
              symbol: cleanSymbol,
              price: price,
              changePercent: ratio,
              changeAmount: diff,
              currency: 'KRW',
            );
          }
        }
      } catch (_) {}
    }

    // 2. 해외 주식 또는 네이버 실패 시 야후 파이낸스 차트 API
    try {
      final url = Uri.parse(
        'https://query2.finance.yahoo.com/v8/finance/chart/$cleanSymbol?range=1d&interval=1d',
      );
      final response = await http.get(url, headers: {'User-Agent': _userAgent}).timeout(
        const Duration(seconds: 4),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['chart']?['result'] as List<dynamic>?;
        if (result != null && result.isNotEmpty) {
          final meta = result[0]['meta'];
          final price = (meta['regularMarketPrice'] as num?)?.toDouble();
          final prevClose = (meta['chartPreviousClose'] as num?)?.toDouble() ?? 
                            (meta['previousClose'] as num?)?.toDouble() ?? 
                            price;
          final currency = (meta['currency'] as String?) ?? 'USD';

          if (price != null) {
            final diff = prevClose != null ? price - prevClose : 0.0;
            final ratio = (prevClose != null && prevClose > 0) ? (diff / prevClose) * 100 : 0.0;
            return StockQuote(
              symbol: cleanSymbol,
              price: price,
              changePercent: ratio,
              changeAmount: diff,
              currency: currency,
            );
          }
        }
      }
    } catch (_) {}

    // 3. 해외 주식 네이버 API 폴백
    if (!isKoreanStock) {
      for (final suffix in ['.O', '.N', '']) {
        try {
          final naverWorldUrl = Uri.parse('https://api.stock.naver.com/stock/$cleanSymbol$suffix/basic');
          final response = await http.get(naverWorldUrl, headers: {'User-Agent': _userAgent}).timeout(
            const Duration(seconds: 3),
          );
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final closePriceStr = (data['closePrice'] as String?)?.replaceAll(',', '');
            final ratioStr = (data['fluctuationsRatio'] as String?)?.replaceAll(',', '') ?? '0';
            final diffStr = (data['compareToPreviousClosePrice'] as String?)?.replaceAll(',', '') ?? '0';
            final compareToPreviousPrice = data['compareToPreviousPrice'] as Map<String, dynamic>?;

            if (closePriceStr != null) {
              final price = double.parse(closePriceStr);
              double ratio = double.tryParse(ratioStr) ?? 0.0;
              double diff = double.tryParse(diffStr) ?? 0.0;

              final cvCode = compareToPreviousPrice?['code']?.toString() ?? '';
              if (cvCode == '5' || cvCode == '4') {
                if (ratio > 0) ratio = -ratio;
                if (diff > 0) diff = -diff;
              }

              return StockQuote(
                symbol: cleanSymbol,
                price: price,
                changePercent: ratio,
                changeAmount: diff,
                currency: 'USD',
              );
            }
          }
        } catch (_) {}
      }
    }

    return null;
  }

  double getFallbackExchangeRate(String currency) {
    final cur = currency.toUpperCase().trim();
    switch (cur) {
      case 'USD':
        return 1420.0;
      case 'JPY':
        return 8.9; // 1 JPY = ~8.9 KRW
      case 'CAD':
        return 1020.0;
      case 'EUR':
        return 1640.0;
      case 'GBP':
        return 1850.0;
      case 'AUD':
        return 920.0;
      case 'CNY':
        return 195.0;
      case 'HKD':
        return 182.0;
      default:
        return 1.0;
    }
  }

  /// 종목 기간별 시세 히스토리 데이터 조회 (1mo, 3mo, 1y, 5y)
  Future<List<StockHistoryPoint>> fetchStockHistory(String symbol, {String range = '1mo'}) async {
    final cleanSymbol = symbol.trim();
    if (cleanSymbol.isEmpty) return [];

    String interval = '1d';
    if (range == '5y') {
      interval = '1wk';
    }

    try {
      final url = Uri.parse(
        'https://query2.finance.yahoo.com/v8/finance/chart/$cleanSymbol'
        '?range=$range&interval=$interval',
      );
      final response = await http.get(url, headers: {'User-Agent': _userAgent}).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['chart']?['result'] as List<dynamic>?;
        if (result != null && result.isNotEmpty) {
          final timestamps = (result[0]['timestamp'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList();
          final indicators = result[0]['indicators']?['quote'] as List<dynamic>?;

          if (timestamps != null && indicators != null && indicators.isNotEmpty) {
            final quote = indicators[0];
            final closes = quote['close'] as List<dynamic>?;
            final highs = quote['high'] as List<dynamic>?;
            final lows = quote['low'] as List<dynamic>?;

            if (closes != null) {
              final List<StockHistoryPoint> points = [];
              for (int i = 0; i < timestamps.length; i++) {
                final closeVal = (closes[i] as num?)?.toDouble();
                if (closeVal != null && closeVal > 0) {
                  final highVal = (highs != null && i < highs.length ? (highs[i] as num?)?.toDouble() : null) ?? closeVal;
                  final lowVal = (lows != null && i < lows.length ? (lows[i] as num?)?.toDouble() : null) ?? closeVal;
                  final date = DateTime.fromMillisecondsSinceEpoch(timestamps[i] * 1000);

                  points.add(
                    StockHistoryPoint(
                      date: date,
                      close: closeVal,
                      high: highVal,
                      low: lowVal,
                    ),
                  );
                }
              }
              return points;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch stock history for $symbol: $e');
    }

    return [];
  }
}

class StockHistoryPoint {
  final DateTime date;
  final double close;
  final double high;
  final double low;

  const StockHistoryPoint({
    required this.date,
    required this.close,
    required this.high,
    required this.low,
  });
}

class StockQuote {
  final String symbol;
  final double price;
  final double changePercent; // 전일 대비 등락률 (%)
  final double changeAmount;  // 전일 대비 변동 금액
  final String currency;

  const StockQuote({
    required this.symbol,
    required this.price,
    required this.changePercent,
    required this.changeAmount,
    required this.currency,
  });
}

