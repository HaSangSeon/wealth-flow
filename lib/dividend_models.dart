import 'models.dart';

class UpcomingDividend {
  final String name;
  final String symbol;
  final double amountPerShare;
  final double totalAmount;
  final String currency;
  final DateTime date;
  final DateTime paymentDate;
  final double krwAmount;
  final bool isHistorical;
  final bool isTaxFree;

  UpcomingDividend({
    required this.name,
    required this.symbol,
    required this.amountPerShare,
    required this.totalAmount,
    required this.currency,
    required this.date,
    required this.paymentDate,
    required this.krwAmount,
    this.isHistorical = false,
    this.isTaxFree = false,
  });
}

class StockDividendSummary {
  final String name;
  final String symbol;
  final double totalAnnualAmount;
  final String currency;
  final double totalKrwAmount;
  final List<int> paymentMonths;
  final String frequencyLabel;
  final List<UpcomingDividend> dividends;

  StockDividendSummary({
    required this.name,
    required this.symbol,
    required this.totalAnnualAmount,
    required this.currency,
    required this.totalKrwAmount,
    required this.paymentMonths,
    required this.frequencyLabel,
    required this.dividends,
  });
}

class DividendCalculationResult {
  final Map<int, double> monthlyDividends;
  final double annualTotal;
  final double totalStockValuation;
  final List<UpcomingDividend> allDividends;
  final List<StockDividendSummary> stockSummaries;

  DividendCalculationResult({
    required this.monthlyDividends,
    required this.annualTotal,
    required this.totalStockValuation,
    required this.allDividends,
    required this.stockSummaries,
  });
}

DividendCalculationResult calculateDividendData({
  required List<Holding> holdings,
  required double lastExchangeRate,
  required bool applyTax,
}) {
  final Map<int, double> monthlyDividends = {for (var i = 1; i <= 12; i++) i: 0.0};
  double annualTotal = 0.0;
  double totalStockValuation = 0.0;
  
  final List<UpcomingDividend> allDividends = [];
  final List<StockDividendSummary> stockSummaries = [];

  final now = DateTime.now();
  final oneYearAgo = now.subtract(const Duration(days: 365));

  DateTime addMonths(DateTime date, int months) {
    int newYear = date.year + (date.month + months - 1) ~/ 12;
    int newMonth = (date.month + months - 1) % 12 + 1;
    int newDay = date.day;
    int maxDays = DateTime(newYear, newMonth + 1, 0).day;
    if (newDay > maxDays) newDay = maxDays;
    return DateTime(newYear, newMonth, newDay);
  }

  bool isWeekend(DateTime dt) =>
      dt.weekday == DateTime.saturday || dt.weekday == DateTime.sunday;

  // 한국 주요 고정 공휴일 (신정, 삼일절, 근로자의날, 어린이날, 현충일, 광복절, 개천절, 한글날, 성탄절)
  bool isKoreanHoliday(DateTime dt) {
    if (isWeekend(dt)) return true;
    final m = dt.month;
    final d = dt.day;
    if (m == 1 && d == 1) return true;
    if (m == 3 && d == 1) return true;
    if (m == 5 && (d == 1 || d == 5)) return true;
    if (m == 6 && d == 6) return true;
    if (m == 8 && d == 15) return true;
    if (m == 10 && (d == 3 || d == 9)) return true;
    if (m == 12 && d == 25) return true;
    return false;
  }

  DateTime getPrevBusinessDay(DateTime dt) {
    var cur = dt;
    while (isKoreanHoliday(cur)) {
      cur = cur.subtract(const Duration(days: 1));
    }
    return cur;
  }

  // 해당 월의 N번째 영업일 계산 (ETF 분배금 익월 제2영업일 지급 규칙)
  DateTime getNthBusinessDayOfMonth(int year, int month, int nth) {
    var cur = DateTime(year, month, 1);
    int count = 0;
    while (true) {
      if (!isKoreanHoliday(cur)) {
        count++;
        if (count == nth) return cur;
      }
      cur = cur.add(const Duration(days: 1));
    }
  }

  DateTime adjustWeekend(DateTime dt) {
    if (dt.weekday == DateTime.saturday) {
      return dt.subtract(const Duration(days: 1));
    } else if (dt.weekday == DateTime.sunday) {
      return dt.add(const Duration(days: 1));
    }
    return dt;
  }

  bool isKoreanEtf(Holding h) {
    final name = h.name.toUpperCase();
    if (h.type == AssetType.etf) return true;
    const etfPrefixes = [
      'KODEX', 'TIGER', 'ACE', 'SOL', 'RISE', 'PLUS',
      'KOSEF', 'TIMEFOLIO', 'WOORI', 'HANARO', '1Q', 'HERO',
      '코덱스', '타이거', '에이스', '솔'
    ];
    for (final prefix in etfPrefixes) {
      if (name.startsWith(prefix) || name.contains(prefix)) return true;
    }
    return name.contains('ETF');
  }

  // 실제 공시 배당기준일(Record Date) 보정 (배당락일 -> 말일 기준일)
  DateTime calculateRecordDate(DateTime exDate, bool isKoreanStock) {
    if (isKoreanStock) {
      if (exDate.day >= 24) {
        return DateTime(exDate.year, exDate.month + 1, 0);
      }
      return exDate.add(const Duration(days: 1));
    }
    return exDate;
  }

  DateTime calculatePaymentDate({
    required Holding holding,
    required DateTime baseDate,
    required bool isKoreanStock,
    required bool isEtf,
    required int frequencyCount,
  }) {
    if (isKoreanStock) {
      if (isEtf) {
        // 국내 ETF: 분배락일 익월 제2영업일(익월 2~5일경) 지급 (KODEX, TIGER, ACE, SOL 등 공통)
        int payYear = baseDate.year;
        int payMonth = baseDate.month + 1;
        if (payMonth > 12) {
          payYear++;
          payMonth = 1;
        }
        return getNthBusinessDayOfMonth(payYear, payMonth, 2);
      } else {
        // 국내 일반 주식 (배당락월에 따른 8대 배당 사이클 표준 분류)
        final month = baseDate.month;

        if (month == 12 || month == 1) {
          // [전통 결산배당] 12월 말 락 -> 이듬해 4월 주총 후 지급 (4월 17~20일경)
          final payYear = month == 1 ? baseDate.year : baseDate.year + 1;
          return getPrevBusinessDay(DateTime(payYear, 4, 18));
        } else if (month == 2) {
          // [선진화 결산배당] 2월 말 락 (현대차, SK하이닉스 등) -> 4월 24일경 주총 승인 직후 지급
          return getPrevBusinessDay(DateTime(baseDate.year, 4, 24));
        } else if (month == 3 || month == 4) {
          // [전통 1분기배당] 3월 말 락 (삼성전자 등) -> 5월 말(20~29일경) 지급
          final symbol = (holding.symbol ?? '').toUpperCase();
          final name = holding.name.toUpperCase();
          if (symbol.contains('005930') || symbol.contains('005935') || name.contains('삼성전자')) {
            if (baseDate.year == 2026) return DateTime(2026, 5, 29);
            return getPrevBusinessDay(DateTime(baseDate.year, 5, 20));
          }
          return getPrevBusinessDay(DateTime(baseDate.year, 5, 20));
        } else if (month == 5) {
          // [선진화 1분기배당] 5월 말 락 (현대차, SK하이닉스 등) -> 6월 30일경 말일 지급
          return getPrevBusinessDay(DateTime(baseDate.year, 6, 30));
        } else if (month == 6 || month == 7) {
          // [전통 2분기배당] 6월 말 락 (삼성전자, 금융지주 등) -> 8월 하순(20~28일경) 지급
          final symbol = (holding.symbol ?? '').toUpperCase();
          final name = holding.name.toUpperCase();
          final isSamsungOrFin = symbol.contains('005930') || symbol.contains('005935') || name.contains('삼성전자')
              || symbol.contains('105560') || symbol.contains('055550') || symbol.contains('086790')
              || name.contains('KB금융') || name.contains('신한지주') || name.contains('하나금융');
          if (isSamsungOrFin && baseDate.year == 2026) {
            return DateTime(2026, 8, 28);
          }
          return getPrevBusinessDay(DateTime(baseDate.year, 8, 21));
        } else if (month == 8) {
          // [선진화 2분기배당] 8월 말 락 (현대차, SK하이닉스 등) -> 9월 30일경 말일 지급
          return getPrevBusinessDay(DateTime(baseDate.year, 9, 30));
        } else if (month == 9 || month == 10) {
          // [전통 3분기배당] 9월 말 락 (삼성전자 등) -> 11월 20일경 지급
          return getPrevBusinessDay(DateTime(baseDate.year, 11, 20));
        } else if (month == 11) {
          // [선진화 3분기배당] 11월 말 락 (현대차, SK하이닉스 등) -> 12월 30일경 말일 지급
          return getPrevBusinessDay(DateTime(baseDate.year, 12, 30));
        } else {
          return getPrevBusinessDay(baseDate.add(const Duration(days: 45)));
        }
      }
    } else {
      // 해외 주식 / ETF
      if (frequencyCount == 12) {
        // 월배당 종목 (O, JEPI 등): 기준월 익월 15일경
        int newYear = baseDate.year;
        int newMonth = baseDate.month + 1;
        if (newMonth > 12) {
          newYear++;
          newMonth = 1;
        }
        return adjustWeekend(DateTime(newYear, newMonth, 15));
      } else {
        // 분기/반기/연배당: 배당락일 기준 통상 15~18일 후 (영업일)
        return adjustWeekend(baseDate.add(const Duration(days: 18)));
      }
    }
  }

  for (var h in holdings) {
    if (h.type == AssetType.cash) continue;
    
    totalStockValuation += (h.quantity * h.price);
    if (h.dividends == null || h.dividends!.isEmpty) continue;

    double exchangeRate = 1.0;
    if (h.currency != 'KRW') {
      exchangeRate = (h.originalPrice != null && h.originalPrice! > 0) 
          ? (h.price / h.originalPrice!) : lastExchangeRate;
    }

    final isKoreanStock = h.symbol != null && (h.symbol!.endsWith('.KS') || h.symbol!.endsWith('.KQ'));
    final isEtf = isKoreanEtf(h);
    final isTaxFreeAccount = (h.account == AccountType.pension || h.account == AccountType.irp);

    double stockAnnualKrw = 0.0;
    double stockAnnualForeign = 0.0;
    final Set<int> paymentMonths = {};
    
    final sortedDivs = List<Map<String, dynamic>>.from(h.dividends!)
      ..sort((a, b) => (b['date'] as int).compareTo(a['date'] as int));
    
    final latestTimestamp = sortedDivs.first['date'] as int;
    final currentTimestamp = now.millisecondsSinceEpoch ~/ 1000;
    
    // 배당 중단/무배당 종목 필터링 (450일 여유)
    const maxAllowedElapsed = 450 * 86400;
    if ((currentTimestamp - latestTimestamp) > maxAllowedElapsed) continue;

    String freqLabel = '연배당';
    int frequencyCount = 1;
    if (sortedDivs.length > 1) {
      final List<int> intervals = [];
      for (int i = 0; i < sortedDivs.length - 1; i++) {
        final d1 = DateTime.fromMillisecondsSinceEpoch((sortedDivs[i+1]['date'] as int) * 1000);
        final d2 = DateTime.fromMillisecondsSinceEpoch((sortedDivs[i]['date'] as int) * 1000);
        intervals.add(d2.difference(d1).inDays);
      }
      final double avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
      
      if (avgInterval <= 45) { freqLabel = '월배당'; frequencyCount = 12; }
      else if (avgInterval <= 120) { freqLabel = '분기배당'; frequencyCount = 4; }
      else if (avgInterval <= 240) { freqLabel = '반기배당'; frequencyCount = 2; }
    }

    final latestDiv = sortedDivs.first;
    final latestExDate = DateTime.fromMillisecondsSinceEpoch((latestDiv['date'] as int) * 1000);
    final double latestAmount = (latestDiv['amount'] as num).toDouble();

    // ── 1. 야후 파이낸스 실 공시 배당 분류 ──
    final List<UpcomingDividend> pastStockDividends = [];
    UpcomingDividend? pendingDeclaredDividend;

    for (final divItem in sortedDivs) {
      final exDate = DateTime.fromMillisecondsSinceEpoch((divItem['date'] as int) * 1000);
      if (exDate.isBefore(oneYearAgo)) continue;

      double rawAmount = (divItem['amount'] as num).toDouble();
      if (applyTax && !isTaxFreeAccount) rawAmount = rawAmount * 0.846;
      
      final krwVal = h.quantity * rawAmount * exchangeRate;
      final paymentDate = calculatePaymentDate(
        holding: h,
        baseDate: exDate,
        isKoreanStock: isKoreanStock,
        isEtf: isEtf,
        frequencyCount: frequencyCount,
      );
      final recordDate = calculateRecordDate(exDate, isKoreanStock);

      final bool isPaid = paymentDate.isBefore(now);
      final divObj = UpcomingDividend(
        name: h.name,
        symbol: h.symbol ?? '',
        amountPerShare: rawAmount,
        totalAmount: h.quantity * rawAmount,
        currency: h.effectiveCurrency,
        date: recordDate,
        paymentDate: paymentDate,
        krwAmount: krwVal,
        isHistorical: isPaid,
        isTaxFree: isTaxFreeAccount,
      );

      if (isPaid) {
        allDividends.add(divObj);
        pastStockDividends.add(divObj);
      } else {
        pendingDeclaredDividend = divObj;
      }
    }

    // ── 2. 미래 1년 치 (frequencyCount 횟수) 예상 배당 연속 투영 ──
    final List<UpcomingDividend> futureStockDividends = [];
    final int monthStep = 12 ~/ frequencyCount;

    double projectedRawAmount = latestAmount;
    if (applyTax && !isTaxFreeAccount) projectedRawAmount = projectedRawAmount * 0.846;
    final futureKrwAmount = h.quantity * projectedRawAmount * exchangeRate;

    if (pendingDeclaredDividend != null) {
      allDividends.add(pendingDeclaredDividend);
      futureStockDividends.add(pendingDeclaredDividend);
      monthlyDividends[pendingDeclaredDividend.paymentDate.month] =
          (monthlyDividends[pendingDeclaredDividend.paymentDate.month] ?? 0.0) + pendingDeclaredDividend.krwAmount;
      annualTotal += pendingDeclaredDividend.krwAmount;
      stockAnnualKrw += pendingDeclaredDividend.krwAmount;
      stockAnnualForeign += (h.quantity * pendingDeclaredDividend.amountPerShare);
      paymentMonths.add(pendingDeclaredDividend.paymentDate.month);
    }

    final remainingCount = frequencyCount - futureStockDividends.length;
    final nextBaseDate = addMonths(latestExDate, monthStep);

    for (int i = 0; i < remainingCount; i++) {
      final currentProjectedExDate = addMonths(nextBaseDate, monthStep * i);
      final paymentDate = calculatePaymentDate(
        holding: h,
        baseDate: currentProjectedExDate,
        isKoreanStock: isKoreanStock,
        isEtf: isEtf,
        frequencyCount: frequencyCount,
      );
      final recordDate = calculateRecordDate(currentProjectedExDate, isKoreanStock);

      monthlyDividends[paymentDate.month] = (monthlyDividends[paymentDate.month] ?? 0.0) + futureKrwAmount;
      annualTotal += futureKrwAmount;

      stockAnnualKrw += futureKrwAmount;
      stockAnnualForeign += (h.quantity * projectedRawAmount);
      paymentMonths.add(paymentDate.month);

      final upcomingDiv = UpcomingDividend(
        name: h.name,
        symbol: h.symbol ?? '',
        amountPerShare: projectedRawAmount,
        totalAmount: h.quantity * projectedRawAmount,
        currency: h.effectiveCurrency,
        date: recordDate,
        paymentDate: paymentDate,
        krwAmount: futureKrwAmount,
        isHistorical: false,
        isTaxFree: isTaxFreeAccount,
      );

      allDividends.add(upcomingDiv);
      futureStockDividends.add(upcomingDiv);
    }

    if (stockAnnualKrw > 0) {
      final monthsList = paymentMonths.toList()..sort();
      final combinedDividends = <UpcomingDividend>[
        ...futureStockDividends,
        ...pastStockDividends.take(2),
      ];
      combinedDividends.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

      stockSummaries.add(StockDividendSummary(
        name: h.name,
        symbol: h.symbol ?? '',
        totalAnnualAmount: stockAnnualForeign,
        currency: h.effectiveCurrency,
        totalKrwAmount: stockAnnualKrw,
        paymentMonths: monthsList,
        frequencyLabel: freqLabel,
        dividends: combinedDividends,
      ));
    }
  }

  stockSummaries.sort((a, b) => b.totalKrwAmount.compareTo(a.totalKrwAmount));
  allDividends.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

  return DividendCalculationResult(
    monthlyDividends: monthlyDividends,
    annualTotal: annualTotal,
    totalStockValuation: totalStockValuation,
    allDividends: allDividends,
    stockSummaries: stockSummaries,
  );
}

String formatDividendNumber(int number) {
  final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
  return number.toString().replaceAllMapped(reg, (Match match) => '${match[1]},');
}
