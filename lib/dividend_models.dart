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
  final String accountLabel;
  final double totalAnnualAmount;
  final String currency;
  final double totalKrwAmount;
  final List<int> paymentMonths;
  final String frequencyLabel;
  final List<UpcomingDividend> dividends;
  final double? dividendGrowthRate;

  StockDividendSummary({
    required this.name,
    required this.symbol,
    this.accountLabel = '일반',
    required this.totalAnnualAmount,
    required this.currency,
    required this.totalKrwAmount,
    required this.paymentMonths,
    required this.frequencyLabel,
    required this.dividends,
    this.dividendGrowthRate,
  });
}

class DividendCalculationResult {
  final Map<int, double> monthlyDividends;
  final double annualTotal;
  final double totalStockValuation;
  final List<UpcomingDividend> allDividends;
  final List<StockDividendSummary> stockSummaries;

  final double taxableGrossAnnualTotal;
  final double taxFreeGrossAnnualTotal;

  DividendCalculationResult({
    required this.monthlyDividends,
    required this.annualTotal,
    required this.totalStockValuation,
    required this.allDividends,
    required this.stockSummaries,
    this.taxableGrossAnnualTotal = 0.0,
    this.taxFreeGrossAnnualTotal = 0.0,
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
  double taxableGrossAnnualTotal = 0.0;
  double taxFreeGrossAnnualTotal = 0.0;
  
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
    if (h.type == AssetType.etf) return true;
    final name = h.name.toUpperCase().trim();
    if (name.contains('ETF')) return true;

    // 일반 상장사 오탐 제외 (BNK금융지주, 키움증권, 우리금융지주, 솔브레인, 에이스침대 등)
    const corpExclusions = [
      '금융지주', '증권', '은행', '캐피탈', '생명', '화재', '손해보험',
      '솔브레인', '솔루엠', '솔루스', '솔트룩스', '솔본', '솔디펜스',
      '에이스침대', '에이스테크', '에이스토리', '에이스엔지니어링',
    ];
    if (!name.contains('액티브') && corpExclusions.any((w) => name.contains(w))) {
      return false;
    }

    const strictSpacePrefixes = ['솔 ', '에이스 ', '키움 ', '하나로 ', '우리 ', 'BNK ', 'WON '];
    for (final sp in strictSpacePrefixes) {
      if (name.startsWith(sp)) return true;
    }

    const brandPrefixes = [
      'KODEX', 'TIGER', 'ACE', 'SOL', 'RISE', 'PLUS',
      'KIWOOM', 'KOACT', 'KOSEF', 'TIMEFOLIO', 'HANARO',
      'ARIRANG', 'KBSTAR', 'FOCUS', 'WOORI', '1Q', 'HERO',
      '코덱스', '타이거',
    ];
    for (final prefix in brandPrefixes) {
      if (name.startsWith(prefix)) return true;
      if (name.contains('$prefix ') || name.contains('$prefix(') || name.contains('${prefix}_')) {
        return true;
      }
    }
    return false;
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
        } else if (month == 3) {
          // [배당선진화 3월 결산배당 vs 전통 1분기배당 구분]
          // 연/반기배당주이거나 3월 중순~25일 이전 배당락인 경우 4월 하순 지급, 분기배당 3월 말 락은 5월 20일경 지급
          if (frequencyCount <= 2 || baseDate.day <= 25) {
            return getPrevBusinessDay(DateTime(baseDate.year, 4, 22));
          }
          return getPrevBusinessDay(DateTime(baseDate.year, 5, 20));
        } else if (month == 4) {
          return getPrevBusinessDay(DateTime(baseDate.year, 5, 20));
        } else if (month == 5) {
          // [선진화 1분기배당] 5월 말 락 (현대차, SK하이닉스 등) -> 6월 30일경 말일 지급
          return getPrevBusinessDay(DateTime(baseDate.year, 6, 30));
        } else if (month == 6 || month == 7) {
          // [전통 2분기배당] 6월 말 락 (삼성전자, 금융지주 등) -> 8월 하순(20~28일경) 지급
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
      final ticker = (holding.symbol ?? '').toUpperCase().split('.').first;
      if (frequencyCount == 12) {
        // JEPI, JEPQ, TLTW: 월초(1~5일) 배당락 -> 같은 달 5~6일경 지급
        if (ticker == 'JEPI' || ticker == 'JEPQ' || ticker.contains('TLTW')) {
          if (baseDate.day <= 5) {
            return adjustWeekend(DateTime(baseDate.year, baseDate.month, 6));
          }
          return adjustWeekend(baseDate.add(const Duration(days: 4)));
        }
        // 일드맥스 등 배당락 직후 지급 월배당 ETF
        if (ticker == 'CONY' || ticker == 'MSTY' || ticker == 'NVDY' || ticker == 'TSLY') {
          return adjustWeekend(baseDate.add(const Duration(days: 2)));
        }

        int newYear = baseDate.year;
        int newMonth = baseDate.month + 1;
        if (newMonth > 12) {
          newYear++;
          newMonth = 1;
        }
        if (ticker == 'O') {
          // 리얼티인컴(O): 월초(1~10일) 락이면 당월 15일, 월말 락이면 익월 15일 지급
          if (baseDate.day <= 10) {
            return adjustWeekend(DateTime(baseDate.year, baseDate.month, 15));
          }
          return adjustWeekend(DateTime(newYear, newMonth, 15));
        }
        if (baseDate.day <= 16) {
          return adjustWeekend(baseDate.add(const Duration(days: 14)));
        }
        return adjustWeekend(DateTime(newYear, newMonth, 10));
      } else {
        // 미국 분기배당 ETF (SCHD, VOO, SPY, QQQ: 분기말 락 후 4~6일 내 지급)
        if (ticker == 'SCHD' || ticker == 'VOO' || ticker == 'SPY' || ticker == 'QQQ') {
          return adjustWeekend(baseDate.add(const Duration(days: 5)));
        }
        // 일반 해외 주식: 배당락일 기준 통상 15~20일 후
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
    final isTaxFreeAccount = (h.account == AccountType.pension || h.account == AccountType.irp || h.account == AccountType.isa);
    final double taxMultiplier = isKoreanStock ? 0.846 : 0.850; // 국내 15.4% vs 미국 15.0% 원천징수

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
    } else if (isEtf || h.type == AssetType.etf) {
      // 신규 상장 월배당 ETF가 첫 1회만 분배한 경우 연배당(1/12)으로 축소되는 현상 방지
      final upperName = h.name.toUpperCase();
      const monthlyHints = [
        '월배당', '배당다우존스', '커버드콜', '프리미엄', '타겟위클리', '타겟데일리',
        '미국배당', '리츠', '채권', '머니마켓', 'CD', 'KOFR',
      ];
      if (monthlyHints.any((k) => upperName.contains(k))) {
        freqLabel = '월배당';
        frequencyCount = 12;
      }
    }

    final latestDiv = sortedDivs.first;
    final latestExDate = DateTime.fromMillisecondsSinceEpoch((latestDiv['date'] as int) * 1000);
    final double latestAmount = (latestDiv['amount'] as num).toDouble();

    // 차등배당/변동배당 여부 판별 (직전 1년 사이클 내 최대/최소 배당 편차가 35% 이상이면 계절별 실제 배당 적용)
    bool isSeasonalDividend = false;
    List<double> cycleAmounts = [];
    if (frequencyCount > 1 && sortedDivs.length >= frequencyCount) {
      cycleAmounts = sortedDivs
          .take(frequencyCount)
          .map((d) => (d['amount'] as num).toDouble())
          .toList();
      double minAmt = cycleAmounts.first;
      double maxAmt = cycleAmounts.first;
      for (final a in cycleAmounts) {
        if (a < minAmt) minAmt = a;
        if (a > maxAmt) maxAmt = a;
      }
      if (minAmt > 0 && (maxAmt / minAmt) >= 1.35) {
        isSeasonalDividend = true;
      }
    }

    // 배당 성장률(Dividend Growth Rate) 계산 (차등배당 종목은 전년 동기 배당과 비교)
    double? growthRate;
    final int compareIdx = isSeasonalDividend ? frequencyCount : 1;
    if (sortedDivs.length > compareIdx) {
      final double prevAmount = (sortedDivs[compareIdx]['amount'] as num).toDouble();
      if (prevAmount > 0 && latestAmount > prevAmount * 1.001) {
        growthRate = ((latestAmount - prevAmount) / prevAmount) * 100;
      }
    }

    final double cycleRawSum = isSeasonalDividend
        ? cycleAmounts.fold(0.0, (a, b) => a + b)
        : (latestAmount * frequencyCount);
    final double grossAnnualForStock = h.quantity * cycleRawSum * exchangeRate;
    if (h.account == AccountType.general) {
      taxableGrossAnnualTotal += grossAnnualForStock;
    } else {
      taxFreeGrossAnnualTotal += grossAnnualForStock;
    }

    // ── 1. 야후 파이낸스 실 공시 배당 분류 ──
    final List<UpcomingDividend> pastStockDividends = [];
    final List<UpcomingDividend> pendingDeclaredDividends = [];

    for (final divItem in sortedDivs) {
      final exDate = DateTime.fromMillisecondsSinceEpoch((divItem['date'] as int) * 1000);
      if (exDate.isBefore(oneYearAgo)) continue;

      double rawAmount = (divItem['amount'] as num).toDouble();
      if (applyTax && !isTaxFreeAccount) rawAmount = rawAmount * taxMultiplier;
      
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
        pendingDeclaredDividends.add(divObj);
      }
    }

    // ── 2. 미래 1년 치 (frequencyCount 횟수) 예상 배당 연속 투영 ──
    final List<UpcomingDividend> futureStockDividends = [];
    final int monthStep = 12 ~/ frequencyCount;

    for (final pending in pendingDeclaredDividends.take(frequencyCount)) {
      allDividends.add(pending);
      futureStockDividends.add(pending);
      monthlyDividends[pending.paymentDate.month] =
          (monthlyDividends[pending.paymentDate.month] ?? 0.0) + pending.krwAmount;
      annualTotal += pending.krwAmount;
      stockAnnualKrw += pending.krwAmount;
      stockAnnualForeign += (h.quantity * pending.amountPerShare);
      paymentMonths.add(pending.paymentDate.month);
    }

    final remainingCount = frequencyCount - futureStockDividends.length;
    final nextBaseDate = addMonths(latestExDate, monthStep);

    for (int i = 0; i < remainingCount; i++) {
      final double basePayoutAmount = isSeasonalDividend
          ? cycleAmounts[frequencyCount - 1 - (i % frequencyCount)]
          : latestAmount;
      double projectedRawAmount = basePayoutAmount;
      if (applyTax && !isTaxFreeAccount) projectedRawAmount = projectedRawAmount * taxMultiplier;
      final futureKrwAmount = h.quantity * projectedRawAmount * exchangeRate;

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
        accountLabel: h.account.label,
        totalAnnualAmount: stockAnnualForeign,
        currency: h.effectiveCurrency,
        totalKrwAmount: stockAnnualKrw,
        paymentMonths: monthsList,
        frequencyLabel: freqLabel,
        dividends: combinedDividends,
        dividendGrowthRate: growthRate,
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
    taxableGrossAnnualTotal: taxableGrossAnnualTotal,
    taxFreeGrossAnnualTotal: taxFreeGrossAnnualTotal,
  );
}

String formatDividendNumber(int number) {
  final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
  return number.toString().replaceAllMapped(reg, (Match match) => '${match[1]},');
}
