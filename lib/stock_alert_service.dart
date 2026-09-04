import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';

import 'formatters.dart';
import 'models.dart';
import 'yahoo_finance_service.dart';

const String kStockAlertTask = 'com.hadoseo.wealthflow.stock_alert_task';
const String kNotificationChannelId = 'wealth_flow_stock_alerts';
const String kNotificationChannelName = '종목 급등/급락 및 자산 변동 알림';
const String kNotificationChannelDesc = '보유 종목의 큰 가격 변동과 내 자산 영향 금액을 알려줍니다.';

/// Workmanager 백그라운드 콜백 진입점 (최상위 함수여야 함)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await Hive.initFlutter();
      final storage = StorageService();
      await storage.init();

      if (!storage.stockAlertEnabled) {
        return Future.value(true);
      }

      await StockAlertService.checkAndNotify(storage);
    } catch (e) {
      debugPrint('[Workmanager] Error executing stock alert task: $e');
    }
    return Future.value(true);
  });
}

class StockAlertService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  /// 서비스 초기화 (알림 플러그인 및 Workmanager 스케줄러)
  static Future<void> initialize(StorageService storage) async {
    if (_isInitialized) return;

    try {
      // 1. Android 알림 초기화
      const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
      const darwinInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('Notification clicked: ${details.payload}');
        },
      );

      // Android 13+ 알림 권한 요청
      if (Platform.isAndroid) {
        final androidImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidImplementation?.requestNotificationsPermission();
      }

      _isInitialized = true;

      // 2. Workmanager 백그라운드 작업 등록
      if (Platform.isAndroid) {
        await Workmanager().initialize(
          callbackDispatcher,
        );

        if (storage.stockAlertEnabled) {
          await schedulePeriodicAlertTask();
        }
      }
    } catch (e) {
      debugPrint('Failed to initialize StockAlertService: $e');
    }
  }

  /// 백그라운드 주기 작업 스케줄링 (최소 15분 주기 또는 1시간 주기)
  static Future<void> schedulePeriodicAlertTask() async {
    if (!Platform.isAndroid) return;
    try {
      await Workmanager().registerPeriodicTask(
        kStockAlertTask,
        kStockAlertTask,
        frequency: const Duration(hours: 2), // 2시간마다 체크
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
        constraints: Constraints(
          networkType: NetworkType.connected, // 인터넷 연결 시에만
        ),
      );
      debugPrint('[StockAlertService] Periodic task registered.');
    } catch (e) {
      debugPrint('[StockAlertService] Failed to register periodic task: $e');
    }
  }

  /// 백그라운드 작업 취소
  static Future<void> cancelPeriodicAlertTask() async {
    if (!Platform.isAndroid) return;
    try {
      await Workmanager().cancelByUniqueName(kStockAlertTask);
      debugPrint('[StockAlertService] Periodic task cancelled.');
    } catch (e) {
      debugPrint('[StockAlertService] Failed to cancel periodic task: $e');
    }
  }

  /// 보유 종목 시세를 스캔하고 급등/급락 발생 시 알림 발송
  static Future<int> checkAndNotify(StorageService storage) async {
    final holdings = storage.loadHoldings();
    if (holdings.isEmpty) return 0;

    final threshold = storage.stockAlertThreshold;
    final yahoo = YahooFinanceService();
    double exchangeRate = storage.lastExchangeRate;

    // 최신 환율 시도
    try {
      final fetchedRate = await yahoo.fetchExchangeRate('USD');
      if (fetchedRate != null && fetchedRate > 0) {
        exchangeRate = fetchedRate;
      }
    } catch (_) {}

    int alertsSent = 0;
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    for (final holding in holdings) {
      final symbol = holding.symbol?.trim();
      if (symbol == null || symbol.isEmpty) continue;

      // ⚠️ 종목당 하루 1회 제한: 오늘 이미 알림을 보낸 종목은 스팸 방지를 위해 건너뜁니다
      if (storage.isAlertSentToday(symbol, todayStr)) {
        continue;
      }

      try {
        final quote = await yahoo.fetchStockQuote(symbol);
        if (quote == null) continue;

        final changePercent = quote.changePercent;
        if (changePercent.abs() >= threshold) {
          // 영향 금액(원화) 계산
          // 환율 적용: 종목 통화가 KRW가 아니면 USD/외화 환율 적용
          final isKrw = quote.currency.toUpperCase() == 'KRW';
          final effectiveRate = isKrw ? 1.0 : exchangeRate;
          
          final impactAmount = holding.quantity * quote.changeAmount * effectiveRate;
          
          await _sendStockAlertNotification(
            holding: holding,
            quote: quote,
            impactAmount: impactAmount,
          );
          await storage.markAlertSent(symbol, todayStr);
          alertsSent++;
        }
      } catch (e) {
        debugPrint('Error checking quote for ${holding.name}: $e');
      }
    }

    return alertsSent;
  }

  /// 실제 푸시 알림 표시
  static Future<void> _sendStockAlertNotification({
    required Holding holding,
    required StockQuote quote,
    required double impactAmount,
  }) async {
    final isSurge = quote.changePercent > 0;
    final signStr = isSurge ? '+' : '';
    final percentStr = '$signStr${quote.changePercent.toStringAsFixed(1)}%';
    final impactFormatted = formatCurrency(impactAmount.abs());
    final impactSign = impactAmount >= 0 ? '+' : '-';

    final title = isSurge
        ? '🚀 [보유 종목 급등] ${holding.name} $percentStr'
        : '🚨 [보유 종목 급락] ${holding.name} $percentStr';

    final body = isSurge
        ? '보유 중인 ${holding.name}이(가) 오늘 $percentStr 급등했습니다! 내 자산이 약 $impactSign$impactFormatted 증가했습니다.'
        : '보유 중인 ${holding.name}이(가) 오늘 $percentStr 급락했습니다. 내 자산에 약 $impactSign$impactFormatted의 영향이 발생했습니다.';

    const androidDetails = AndroidNotificationDetails(
      kNotificationChannelId,
      kNotificationChannelName,
      channelDescription: kNotificationChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      styleInformation: BigTextStyleInformation(''),
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final id = holding.name.hashCode.abs() % 100000;
    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
    );
  }

  /// 사용자가 설정 화면 등에서 직접 눌러볼 수 있는 테스트 알림 발송
  static Future<bool> sendTestNotification({
    required StorageService storage,
    bool isSurge = true,
  }) async {
    if (!_isInitialized) {
      await initialize(storage);
    }

    final holdings = storage.loadHoldings();
    final sampleHolding = holdings.isNotEmpty
        ? holdings.first
        : Holding(
            name: '삼성전자',
            symbol: '005930.KS',
            type: AssetType.koreanStock,
            account: AccountType.general,
            quantity: 50,
            price: 75000,
          );

    final testPercent = isSurge ? 6.8 : -5.4;
    final testChangeAmount = isSurge ? (sampleHolding.price * 0.068) : -(sampleHolding.price * 0.054);
    final quote = StockQuote(
      symbol: sampleHolding.symbol ?? '005930.KS',
      price: sampleHolding.price,
      changePercent: testPercent,
      changeAmount: testChangeAmount,
      currency: sampleHolding.currency ?? 'KRW',
    );

    final isKrw = quote.currency.toUpperCase() == 'KRW';
    final effectiveRate = isKrw ? 1.0 : storage.lastExchangeRate;
    final impactAmount = sampleHolding.quantity * quote.changeAmount * effectiveRate;

    await _sendStockAlertNotification(
      holding: sampleHolding,
      quote: quote,
      impactAmount: impactAmount,
    );
    return true;
  }
}
