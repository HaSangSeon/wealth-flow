import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

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

    final lowerQuery = query.toLowerCase();
    final queryIsChoseong = _isChoseongOnly(lowerQuery);

    final List<YahooFinanceSearchResult> matches = [];

    for (final item in _localKoreanStocks!) {
      // 1. 심볼 매칭 (예: 005930 또는 005930.KS)
      final code = item.symbol.split('.').first;
      if (code.contains(lowerQuery) || item.symbol.toLowerCase().contains(lowerQuery)) {
        matches.add(item);
        if (matches.length >= 5) break;
        continue;
      }

      // 2. 한글 초성 매칭
      if (queryIsChoseong) {
        final nameChoseong = _getChoseong(item.shortname);
        if (nameChoseong.contains(lowerQuery)) {
          matches.add(item);
          if (matches.length >= 5) break;
          continue;
        }
      }

      // 3. 종목명 매칭
      if (item.shortname.toLowerCase().contains(lowerQuery)) {
        matches.add(item);
        if (matches.length >= 5) break;
        continue;
      }
    }

    return matches;
  }

  Future<List<YahooFinanceSearchResult>> _searchYahooStocks(String query) async {
    try {
      final url = Uri.parse(
        'https://query2.finance.yahoo.com/v1/finance/search'
        '?q=$query&quotesCount=5&newsCount=0',
      );
      final response =
          await http.get(url, headers: {'User-Agent': _userAgent});
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

    final yahooFuture = _searchYahooStocks(cleanQuery);
    final localFuture = _searchLocalKoreanStocks(cleanQuery);

    final results = await Future.wait([yahooFuture, localFuture]);
    final yahooResults = results[0];
    final localResults = results[1];

    final merged = <String, YahooFinanceSearchResult>{};

    // 로컬 매칭 결과를 우선적으로 추가
    for (final item in localResults) {
      merged[item.symbol] = item;
    }
    
    // 야후 매칭 결과를 중복되지 않게 추가하되, 한국어 이름이 있다면 무조건 한국어 이름으로 덮어씌움 (통일성 유지)
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
    if (base == 'USD' && _cachedExchangeRate != null && _lastExchangeRateTime != null) {
      if (DateTime.now().difference(_lastExchangeRateTime!).inMinutes < 10) {
        return _cachedExchangeRate;
      }
    }
    try {
      final url = Uri.parse(
        'https://query2.finance.yahoo.com/v8/finance/chart/${base}KRW=X',
      );
      final response =
          await http.get(url, headers: {'User-Agent': _userAgent});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['chart']?['result'] as List<dynamic>?;
        if (result != null && result.isNotEmpty) {
          final meta = result[0]['meta'];
          final rate = (meta['regularMarketPrice'] as num?)?.toDouble();
          if (rate != null && base == 'USD') {
            _cachedExchangeRate = rate;
            _lastExchangeRateTime = DateTime.now();
          }
          return rate;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> fetchStockDetails(String symbol) async {
    try {
      final url = Uri.parse(
        'https://query2.finance.yahoo.com/v8/finance/chart/$symbol'
        '?range=2y&interval=1d&events=div',
      );
      final response =
          await http.get(url, headers: {'User-Agent': _userAgent});
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
    return null;
  }

  double getFallbackExchangeRate(String currency) {
    final cur = currency.toUpperCase().trim();
    switch (cur) {
      case 'USD':
        return 1380.0;
      case 'JPY':
        return 8.8; // 1 JPY = ~8.8 KRW
      case 'CAD':
        return 1000.0;
      case 'EUR':
        return 1500.0;
      case 'GBP':
        return 1780.0;
      case 'AUD':
        return 900.0;
      case 'CNY':
        return 190.0;
      case 'HKD':
        return 175.0;
      default:
        return 1.0;
    }
  }
}
