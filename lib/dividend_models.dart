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

  UpcomingDividend({
    required this.name,
    required this.symbol,
    required this.amountPerShare,
    required this.totalAmount,
    required this.currency,
    required this.date,
    required this.paymentDate,
    required this.krwAmount,
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

  DateTime addMonths(DateTime date, int months) {
    int newYear = date.year + (date.month + months - 1) ~/ 12;
    int newMonth = (date.month + months - 1) % 12 + 1;
    int newDay = date.day;
    int maxDays = DateTime(newYear, newMonth + 1, 0).day;
    if (newDay > maxDays) newDay = maxDays;
    return DateTime(newYear, newMonth, newDay);
  }

  for (var h in holdings) {
    if (h.type == AssetType.cash) continue;
    
    totalStockValuation += (h.quantity * h.price);

    if (h.dividends == null || h.dividends!.isEmpty) continue;

    double exchangeRate = 1.0;
    if (h.currency != 'KRW') {
      if (h.originalPrice != null && h.originalPrice! > 0) {
        exchangeRate = h.price / h.originalPrice!;
      } else {
        exchangeRate = lastExchangeRate;
      }
    }

    double stockAnnualKrw = 0.0;
    double stockAnnualForeign = 0.0;
    final Set<int> paymentMonths = {};
    final List<UpcomingDividend> stockDividends = [];

    final sortedDivs = List<Map<String, dynamic>>.from(h.dividends!)
      ..sort((a, b) => (b['date'] as int).compareTo(a['date'] as int));
    
    final latestTimestamp = sortedDivs.first['date'] as int;
    final currentTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    if ((currentTimestamp - latestTimestamp) > 34560000) {
      continue;
    }

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
      
      if (avgInterval <= 45) {
        freqLabel = '월배당';
        frequencyCount = 12;
      } else if (avgInterval <= 120) {
        freqLabel = '분기배당';
        frequencyCount = 4;
      } else if (avgInterval <= 240) {
        freqLabel = '반기배당';
        frequencyCount = 2;
      } else {
        freqLabel = '연배당';
        frequencyCount = 1;
      }
    }

    final latestDiv = sortedDivs.first;
    final latestDate = DateTime.fromMillisecondsSinceEpoch((latestDiv['date'] as int) * 1000);
    double rawAmount = latestDiv['amount'] as double;
    
    if (applyTax) {
      rawAmount = rawAmount * 0.846;
    }
    
    final krwAmount = h.quantity * rawAmount * exchangeRate;
    
    final int monthStep = 12 ~/ frequencyCount;
    for (int i = 1; i <= frequencyCount; i++) {
      final projectedDate = addMonths(latestDate, monthStep * i);
      
      DateTime paymentDate;
      if (h.symbol != null && (h.symbol!.endsWith('.KS') || h.symbol!.endsWith('.KQ'))) {
        if (projectedDate.month == 12) {
          paymentDate = DateTime(projectedDate.year + 1, 4, 15);
        } else {
          paymentDate = projectedDate.add(const Duration(days: 60));
        }
      } else {
        paymentDate = projectedDate.add(const Duration(days: 15));
      }
      
      monthlyDividends[paymentDate.month] = (monthlyDividends[paymentDate.month] ?? 0.0) + krwAmount;
      annualTotal += krwAmount;

      stockAnnualKrw += krwAmount;
      stockAnnualForeign += (h.quantity * rawAmount);
      paymentMonths.add(paymentDate.month);

      final upcomingDiv = UpcomingDividend(
        name: h.name,
        symbol: h.symbol ?? '',
        amountPerShare: rawAmount,
        totalAmount: h.quantity * rawAmount,
        currency: h.effectiveCurrency,
        date: projectedDate,
        paymentDate: paymentDate,
        krwAmount: krwAmount,
      );
      
      allDividends.add(upcomingDiv);
      stockDividends.add(upcomingDiv);
    }

    if (stockAnnualKrw > 0) {
      final monthsList = paymentMonths.toList()..sort();
      stockDividends.sort((a, b) => b.date.compareTo(a.date));

      stockSummaries.add(StockDividendSummary(
        name: h.name,
        symbol: h.symbol ?? '',
        totalAnnualAmount: stockAnnualForeign,
        currency: h.effectiveCurrency,
        totalKrwAmount: stockAnnualKrw,
        paymentMonths: monthsList,
        frequencyLabel: freqLabel,
        dividends: stockDividends,
      ));
    }
  }

  stockSummaries.sort((a, b) => b.totalKrwAmount.compareTo(a.totalKrwAmount));
  allDividends.sort((a, b) => b.date.compareTo(a.date));

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
