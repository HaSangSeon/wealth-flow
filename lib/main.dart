import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:home_widget/home_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'formatters.dart';
import 'dividend.dart';
import 'models.dart';
import 'payment_service.dart';
import 'premium.dart';
import 'yahoo_finance_service.dart';
import 'ad_service.dart';
import 'stock_chart_sheet.dart';
import 'asset_tab.dart';
import 'simulation_tab.dart';
import 'pension_tax_tab.dart';
import 'holding_form_sheet.dart';
import 'profile_sheet.dart';
import 'portfolio_allocation_card.dart';
import 'portfolio_news_carousel.dart';

import 'stock_alert_service.dart';
import 'common_widgets.dart';

// ─── 앱 진입점 ────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  HomeWidget.setAppGroupId('group.com.hadoseo.wealthflow');
  await Hive.initFlutter();
  final storage = StorageService();
  await storage.init();
  
  try {
    await PaymentService.initialize(storage);
    await AdService.initialize();
    await StockAlertService.initialize(storage);
  } catch (e) {
    debugPrint("Failed to initialize services: $e");
  }
  
  themeNotifier = ValueNotifier<ThemeMode>(
    ThemeMode.values[storage.themeMode],
  );

  runApp(WealthFlowApp(storage: storage));
}

// ─── 앱 루트 ──────────────────────────────────────────────

class WealthFlowApp extends StatelessWidget {
  const WealthFlowApp({super.key, required this.storage});

  final StorageService storage;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: '웰스플로우',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF176B5B),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F4EF),
        fontFamily: 'Roboto',
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE5E0D7)),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF26A68A),
          brightness: Brightness.dark,
          surface: const Color(0xFF121212),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        fontFamily: 'Roboto',
        cardTheme: CardThemeData(
          elevation: 0,
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFF2C2C2C)),
          ),
        ),
      ),
      themeMode: currentMode,
      home: SplashScreen(storage: storage),
    ));
  }
}

// ─── 부드러운 스플래시 화면 ──────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.storage});

  final StorageService storage;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // 2초 동안 스플래시 유지 후 메인/온보딩 화면으로 부드럽게 페이드 전환
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                widget.storage.isOnboardingComplete
                    ? MainNavigationScreen(storage: widget.storage)
                    : OnboardingScreen(storage: widget.storage),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF084C3D), // 프리미엄 딥에메랄드 그린 매칭
      body: Center(
        child: Image.asset(
          'assets/launch_logo.png',
          width: 341,
          height: 341,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

// ─── 온보딩 화면 ──────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.storage});

  final StorageService storage;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardingPage(
      visual: _DividendMockVisual(),
      title: '잠든 사이에도\n돈이 들어오는 마법',
      description: '보유한 주식의 배당금이 언제, 얼마나 들어오는지 파악하세요.\n증권사 앱에선 볼 수 없는\n직관적인 배당 캘린더가 완성됩니다.',
    ),
    _OnboardingPage(
      visual: _CompoundMockVisual(),
      title: '복리의 마법으로\n미래 자산 미리보기',
      description: '매월 추가 투자금과 배당 재투자의 힘!\n주가 상승률에 따른 복리 성장 곡선으로\n10년, 20년 뒤 내 자산의 성장을 시뮬레이션하세요.',
    ),
    _OnboardingPage(
      visual: _PrivacyMockVisual(),
      title: '오직 나만을 위한\n프라이빗 자산관리',
      description: '불안하고 복잡한 마이데이터 연동은 그만.\n핵심 자산만 1분 만에 가볍게 입력하세요.\n모든 데이터는 내 기기에만 안전하게 저장됩니다.',
    ),
  ];

  void _finish() {
    widget.storage.isOnboardingComplete = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MainNavigationScreen(storage: widget.storage),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final dotColor = isDark ? const Color(0xFF3E3C3A) : const Color(0xFFD0C9BF);
    final skipColor = isDark ? Colors.grey[400] : const Color(0xFF8C847A);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF6F4EF),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: _pages,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _page == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _page == i ? primaryColor : dotColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _page < _pages.length - 1
                          ? () => _controller.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              )
                          : _finish,
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _page < _pages.length - 1 ? '다음' : '시작하기',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  if (_page < _pages.length - 1)
                    TextButton(
                      onPressed: _finish,
                      child: Text(
                        '건너뛰기',
                        style: TextStyle(color: skipColor),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.visual,
    required this.title,
    required this.description,
  });

  final Widget visual;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: Center(child: visual),
          ),
          const SizedBox(height: 50),
          Text(
            title,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF2C2A28),
              height: 1.3,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            description,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : const Color(0xFF6E675E),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DividendMockVisual extends StatelessWidget {
  const _DividendMockVisual();
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: 220,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF242424) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black45 : Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: isDark ? const Color(0xFF333333) : const Color(0xFFF0EBE1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.payments_rounded, color: primaryColor, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                '월 30만원 달성!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF2C2A28),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '이번 달 관리비 커버 완료',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : const Color(0xFF8C847A),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: -15,
          right: -20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.trending_up_rounded, size: 14, color: Color(0xFF78350F)),
                SizedBox(width: 4),
                Text(
                  '배당 인상 📈',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF78350F),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CompoundMockVisual extends StatelessWidget {
  const _CompoundMockVisual();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      width: 230,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242424) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF333333) : const Color(0xFFF0EBE1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '10년 후 예상 자산',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.grey[300] : const Color(0xFF5C5750),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_graph_rounded, size: 12, color: primaryColor),
                    const SizedBox(width: 3),
                    Text(
                      '복리 성장',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '₩ 5억 4,800만',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF2C2A28),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: CustomPaint(
              painter: _MiniCompoundChartPainter(
                color: primaryColor,
                isDark: isDark,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '월 투자금 + 배당금 전액 재투자',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[400] : const Color(0xFF8C847A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniCompoundChartPainter extends CustomPainter {
  final Color color;
  final bool isDark;

  const _MiniCompoundChartPainter({required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withValues(alpha: 0.28),
          color.withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.88);
    path.cubicTo(
      size.width * 0.35,
      size.height * 0.82,
      size.width * 0.65,
      size.height * 0.45,
      size.width,
      size.height * 0.08,
    );

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    final dotCenter = Offset(size.width, size.height * 0.08);
    final dotGlow = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final whiteDotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(dotCenter, 6, dotGlow);
    canvas.drawCircle(dotCenter, 4, dotPaint);
    canvas.drawCircle(dotCenter, 2, whiteDotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PrivacyMockVisual extends StatelessWidget {
  const _PrivacyMockVisual();
  
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor.withValues(alpha: 0.8), primaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.shield_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),
        Positioned(
          bottom: 30,
          right: 30,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF10B981),
              size: 16,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── 메인 탭 네비게이션 ───────────────────────────────────

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key, required this.storage});

  final StorageService storage;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  late List<Holding> _holdings;
  late SimulationSettings _settings;
  bool _isSyncing = false;
  bool _pendingResync = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    themeNotifier.addListener(_updateWidget);
    _holdings = widget.storage.loadHoldings();
    _settings = widget.storage.loadSettings();
    _updateWidget();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndSyncPrices();
    });
  }

  @override
  void dispose() {
    themeNotifier.removeListener(_updateWidget);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    _updateWidget();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndSyncPrices();
    }
  }

  void _loadDataForProfile() {
    setState(() {
      _holdings = widget.storage.loadHoldings();
      _settings = widget.storage.loadSettings();
    });
    _updateWidget();
    _checkAndSyncPrices();
  }

  void _switchProfile(String profileId) {
    widget.storage.activeProfileId = profileId;
    _loadDataForProfile();
  }

  void _openProfileSelectionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ProfileSelectionSheet(
          storage: widget.storage,
          onProfileSelected: (profileId) {
            Navigator.pop(context);
            _switchProfile(profileId);
          },
          onProfileAdded: () {
            Navigator.pop(context);
            _openAddProfileDialog();
          },
          onProfileEdited: () {
            setState(() {});
          },
        );
      },
    );
  }

  void _openAddProfileDialog() async {
    final newId = await showDialog<String>(
      context: context,
      builder: (context) => AddProfileDialog(storage: widget.storage),
    );
    if (newId != null) {
      _switchProfile(newId);
    }
  }

  Future<void> _checkAndSyncPrices() async {
    final lastSyncedAt = widget.storage.lastSyncedAt;
    if (lastSyncedAt == null || DateTime.now().difference(lastSyncedAt).inMinutes >= 5) {
      if (refreshIndicatorKey.currentState != null) {
        refreshIndicatorKey.currentState?.show();
      } else {
        await _syncPrices();
      }
    }
  }

  Future<void> _syncPrices() async {
    if (_isSyncing) {
      _pendingResync = true;
      return;
    }
    final syncProfileId = widget.storage.activeProfileId;
    setState(() => _isSyncing = true);

    try {
      final yahooService = YahooFinanceService();

      // Always fetch the latest USD-KRW exchange rate first on sync
      try {
        final double? usdRate = await yahooService.fetchExchangeRate('USD');
        if (usdRate != null && widget.storage.activeProfileId == syncProfileId) {
          widget.storage.lastExchangeRate = usdRate;
        }
      } catch (e) {
        debugPrint("Failed to fetch USD exchange rate: $e");
      }

      // 동기화 시작 시점의 고유 심볼 목록 추출 (중간에 자산 추가/수정/삭제 시 인덱스 밀림 방지)
      final symbolsToSync = _holdings
          .where((h) =>
              h.symbol != null &&
              h.symbol!.isNotEmpty &&
              (h.type == AssetType.usStock ||
                  h.type == AssetType.koreanStock ||
                  h.type == AssetType.etf))
          .map((h) => h.symbol!)
          .toSet();

      final Map<String, ({double price, double rawPrice, String currency, List<Map<String, dynamic>>? dividends})> syncedQuotes = {};

      for (final symbol in symbolsToSync) {
        if (!mounted || widget.storage.activeProfileId != syncProfileId) return;

        final details = await yahooService.fetchStockDetails(symbol);
        if (details != null && details['price'] != null) {
          final rawPrice = (details['price'] as num).toDouble();
          final currency = (details['currency'] as String?)?.toUpperCase() ?? 'USD';

          double price = rawPrice;
          if (currency != 'KRW') {
            double? exchangeRate = await yahooService.fetchExchangeRate(currency);
            exchangeRate ??= yahooService.getFallbackExchangeRate(currency);
            price = rawPrice * exchangeRate;
            if (currency == 'USD' && widget.storage.activeProfileId == syncProfileId) {
              widget.storage.lastExchangeRate = exchangeRate;
            }
          }

          final fetchedDividends = details['dividends'] as List<Map<String, dynamic>>?;
          syncedQuotes[symbol] = (
            price: price,
            rawPrice: rawPrice,
            currency: currency,
            dividends: fetchedDividends,
          );
        }
      }

      if (!mounted || widget.storage.activeProfileId != syncProfileId) return;

      bool hasUpdates = false;
      for (final holding in _holdings) {
        final symbol = holding.symbol;
        if (symbol == null || !syncedQuotes.containsKey(symbol)) continue;

        final quote = syncedQuotes[symbol]!;
        List<Map<String, dynamic>>? newDividends = quote.dividends;

        // API 오류나 일시적 통신 지연으로 빈 배열 반환 시 기존 배당 내역 유지
        if ((newDividends == null || newDividends.isEmpty) &&
            holding.dividends != null &&
            holding.dividends!.isNotEmpty) {
          newDividends = holding.dividends;
        }

        bool dividendsChanged = false;
        if (holding.dividends?.length != newDividends?.length) {
          dividendsChanged = true;
        } else if (holding.dividends != null && newDividends != null) {
          for (int j = 0; j < holding.dividends!.length; j++) {
            if (holding.dividends![j]['date'] != newDividends[j]['date'] ||
                holding.dividends![j]['amount'] != newDividends[j]['amount']) {
              dividendsChanged = true;
              break;
            }
          }
        }

        if (holding.price != quote.price ||
            holding.originalPrice != quote.rawPrice ||
            holding.currency != quote.currency ||
            dividendsChanged) {
          holding.price = quote.price;
          holding.originalPrice = quote.rawPrice;
          holding.currency = quote.currency;
          if (dividendsChanged) {
            holding.dividends = newDividends;
          }
          hasUpdates = true;
        }
      }

      if (hasUpdates && mounted) {
        setState(() {
          _holdings = List.from(_holdings);
        });
        _saveAll();
      }
      widget.storage.lastSyncedAt = DateTime.now();
      portfolioNewsKey.currentState?.fetchNews();
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      } else {
        _isSyncing = false;
      }
      if (_pendingResync && mounted) {
        _pendingResync = false;
        _syncPrices();
      }
    }
  }

  void _saveAll() {
    widget.storage.saveHoldings(_holdings);
    widget.storage.saveSettings(_settings);
    _updateWidget();
  }

  void _updateWidget() {
    final formattedTotal = formatCurrencyFull(_currentValue);
    double target = _settings.targetAmount;
    double percent = target > 0 ? (_currentValue / target * 100).clamp(0.0, 100.0) : 0.0;
    String percentStr = "은퇴 달성률 " + percent.toStringAsFixed(1) + "%";
    
    final currentMode = themeNotifier.value;
    final bool isDark = currentMode == ThemeMode.dark ||
        (currentMode == ThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);

    HomeWidget.saveWidgetData<String>('total_wealth', formattedTotal);
    HomeWidget.saveWidgetData<String>('progress_percent', percentStr);
    HomeWidget.saveWidgetData<bool>('is_dark_mode', isDark);
    HomeWidget.updateWidget(
      androidName: 'WealthWidgetProvider',
      iOSName: 'WealthWidget',
    );
    HomeWidget.updateWidget(
      androidName: 'WealthWidgetMiniProvider',
    );
  }

  double get _currentValue =>
      _holdings.fold(0, (previous, holding) => previous + holding.value);

  double get _actualDividendYield {
    if (_holdings.isEmpty) return 0.0;
    final divData = calculateDividendData(
      holdings: _holdings,
      lastExchangeRate: widget.storage.lastExchangeRate,
      applyTax: false,
    );
    if (divData.totalStockValuation > 0) {
      return (divData.annualTotal / divData.totalStockValuation) * 100;
    }
    return 0.0;
  }

  double get _effectiveDividendYield {
    if (_settings.dividendYield <= 0) return 0.0;
    final actual = _actualDividendYield;
    return actual > 0 ? actual : 3.0;
  }

  List<ProjectionPoint> _buildProjection(double dividendYieldPercent) =>
      calculateProjectionPoints(
        initialAsset: _currentValue,
        monthlyContribution: _settings.monthlyContribution,
        annualReturnPercent: _settings.annualReturn,
        dividendYieldPercent: dividendYieldPercent,
        contributionGrowthPercent: _settings.contributionGrowth,
        years: _settings.years,
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final effectiveDividendYield = _effectiveDividendYield;
    final projectionPoints = _buildProjection(effectiveDividendYield);
    final projectedValue = projectionPoints.isEmpty ? 0.0 : projectionPoints.last.total;
    final gain = projectedValue - _currentValue;

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: [
              AssetManagementTab(
                storage: widget.storage,
                holdings: _holdings,
                currentValue: _currentValue,
                lastSyncedAt: widget.storage.lastSyncedAt,
                lastExchangeRate: widget.storage.lastExchangeRate,
                isSyncing: _isSyncing,
                showForeignInKrw: widget.storage.displayUsd,
                onToggleForeignInKrw: (val) => setState(() {
                  widget.storage.displayUsd = val;
                }),
                onAdd: _openAddHoldingSheet,
                onEdit: _openEditHoldingSheet,
                onDelete: _confirmDelete,
                onRefresh: _syncPrices,
                onPremiumChanged: () => setState(() {}),
                onProfileTap: _openProfileSelectionSheet,
                onDataRestored: _loadDataForProfile,
              ),
              DividendTab(
                storage: widget.storage,
                holdings: _holdings,
                onPremiumChanged: () => setState(() {}),
                onDataRestored: _loadDataForProfile,
                isActive: _currentIndex == 1,
              ),
              SimulationTab(
                storage: widget.storage,
                holdings: _holdings,
                currentValue: _currentValue,
                projectedValue: projectedValue,
                years: _settings.years,
                gain: gain,
                annualReturn: _settings.annualReturn,
                dividendYield: effectiveDividendYield,
                monthlyContribution: _settings.monthlyContribution,
                contributionGrowth: _settings.contributionGrowth,
                projectionPoints: projectionPoints,
                targetAmount: _settings.targetAmount,
                targetYears: _settings.targetYears,
                onAnnualReturnChanged: (v) => setState(() {
                  _settings.annualReturn = v;
                  _saveAll();
                }),
                onDividendYieldChanged: (v) => setState(() {
                  _settings.dividendYield = v;
                  _saveAll();
                }),
                onMonthlyContributionChanged: (v) => setState(() {
                  _settings.monthlyContribution = v;
                  _saveAll();
                }),
                onContributionGrowthChanged: (v) => setState(() {
                  _settings.contributionGrowth = v;
                  _saveAll();
                }),
                onYearsChanged: (v) => setState(() {
                  _settings.years = v;
                  _saveAll();
                }),
                onTargetAmountChanged: (v) => setState(() {
                  _settings.targetAmount = v;
                  _saveAll();
                }),
                onTargetYearsChanged: (v) => setState(() {
                  _settings.targetYears = v;
                  _saveAll();
                }),
                onDataRestored: _loadDataForProfile,
              ),
              PensionTaxTab(
                holdings: _holdings,
                storage: widget.storage,
                onDataRestored: _loadDataForProfile,
              ),
            ],
          ),
          if (_isSyncing)
            Positioned(
              top: MediaQuery.of(context).padding.top,
              left: 0,
              right: 0,
              child: const LinearProgressIndicator(
                minHeight: 3,
                color: Color(0xFF176B5B),
                backgroundColor: Colors.transparent,
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(

        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161616) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF262626) : const Color(0xFFE8E4DC),
              width: 0.8,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AdBannerWidget(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      index: 0,
                      label: '내 자산',
                      icon: Icons.account_balance_wallet_outlined,
                      activeIcon: Icons.account_balance_wallet_rounded,
                      isDark: isDark,
                      primaryColor: primaryColor,
                    ),
                    _buildNavItem(
                      index: 1,
                      label: '배당',
                      icon: Icons.calendar_month_outlined,
                      activeIcon: Icons.calendar_month_rounded,
                      isDark: isDark,
                      primaryColor: primaryColor,
                    ),
                    _buildNavItem(
                      index: 2,
                      label: '시뮬레이션',
                      icon: Icons.auto_graph_outlined,
                      activeIcon: Icons.auto_graph_rounded,
                      isDark: isDark,
                      primaryColor: primaryColor,
                    ),
                    _buildNavItem(
                      index: 3,
                      label: '연금/절세',
                      icon: Icons.savings_outlined,
                      activeIcon: Icons.savings_rounded,
                      isDark: isDark,
                      primaryColor: primaryColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    required bool isDark,
    required Color primaryColor,
  }) {
    final isSelected = _currentIndex == index;
    final activeColor = isDark ? const Color(0xFF34D399) : primaryColor;
    final inactiveColor = isDark ? const Color(0xFF757575) : const Color(0xFF8F887D);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_currentIndex != index) {
            HapticFeedback.selectionClick();
            setState(() => _currentIndex = index);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? const Color(0xFF1E3A33) : const Color(0xFFE8F5F1))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  size: 22,
                  color: isSelected ? activeColor : inactiveColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? activeColor : inactiveColor,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Future<void> _showPremiumLimitDialog(String content) async {
    final upgrade = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1E1E1E) 
            : const Color(0xFFF9F8F6),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Color(0xFFEAA622)),
            SizedBox(width: 8),
            Text('👑 프리미엄 제한', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          content,
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              '나중에',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white54 
                    : Colors.black54
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF176B5B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('프리미엄 혜택 보기'),
          ),
        ],
      ),
    );

    if (upgrade == true && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PremiumSubscriptionScreen(storage: widget.storage),
        ),
      );
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _openAddHoldingSheet() async {

    final holding = await showModalBottomSheet<Holding>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (context) => const HoldingFormSheet(),
    );

    if (holding != null && mounted) {
      if (holding.currency == 'USD' &&
          holding.originalPrice != null &&
          holding.originalPrice! > 0 &&
          holding.price > 0) {
        widget.storage.lastExchangeRate = holding.price / holding.originalPrice!;
      }

      final existingIndex = _holdings.indexWhere((h) =>
          h.account == holding.account &&
          ((holding.symbol?.isNotEmpty == true && h.symbol == holding.symbol) ||
          ((holding.symbol?.isEmpty ?? true) && h.name == holding.name && h.type == holding.type)));

      String message;
      if (existingIndex != -1) {
        final existing = _holdings[existingIndex];
        final totalQuantity = existing.quantity + holding.quantity;

        // 최신 시장 시세(price / originalPrice)는 최신 단가로 유지하고 수량만 합산
        final latestPrice = holding.price > 0 ? holding.price : existing.price;
        final latestOriginalPrice = holding.originalPrice ?? existing.originalPrice;

        // 배당 데이터 보존: 새로 추가된 배당 데이터가 유효할 때만 갱신, 아니면 기존 데이터 유지
        final effectiveDividends = (holding.dividends != null && holding.dividends!.isNotEmpty)
            ? holding.dividends
            : existing.dividends;

        final updated = Holding(
          name: existing.name,
          symbol: existing.symbol,
          type: existing.type,
          account: existing.account,
          quantity: totalQuantity,
          price: latestPrice,
          originalPrice: latestOriginalPrice,
          currency: holding.currency ?? existing.currency,
          dividends: effectiveDividends,
        );

        setState(() => _holdings = List.from(_holdings)..[existingIndex] = updated);
        message = "'${holding.name}' 자산이 기존 수량에 합산되었습니다.";
      } else {
        setState(() => _holdings = List.from(_holdings)..add(holding));
        message = "'${holding.name}' 자산이 추가되었습니다.";
      }

      _saveAll();
      _syncPrices();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: const Color(0xFF176B5B),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        // 바텀시트가 닫힌 직후 자연스러운 작업 완료 시점에 전면광고 노출 (3분 쿨다운 적용)
        Future.delayed(const Duration(milliseconds: 300), () {
          AdService.showInterstitialAd();
        });
      }
    }
  }

  Future<void> _openEditHoldingSheet(Holding originalHolding) async {
    final index = _holdings.indexOf(originalHolding);
    if (index == -1) return;

    final holding = await showModalBottomSheet<Holding>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (context) =>
          HoldingFormSheet(initialHolding: originalHolding),
    );

    if (holding != null && mounted) {
      if (holding.currency == 'USD' &&
          holding.originalPrice != null &&
          holding.originalPrice! > 0 &&
          holding.price > 0) {
        widget.storage.lastExchangeRate = holding.price / holding.originalPrice!;
      }

      final duplicateIndex = _holdings.indexWhere((h) =>
          !identical(h, originalHolding) &&
          h.account == holding.account &&
          ((holding.symbol?.isNotEmpty == true && h.symbol == holding.symbol) ||
              ((holding.symbol?.isEmpty ?? true) &&
                  h.name == holding.name &&
                  h.type == holding.type)));

      String message;
      if (duplicateIndex != -1) {
        final existing = _holdings[duplicateIndex];
        final totalQuantity = existing.quantity + holding.quantity;
        final latestPrice = holding.price > 0 ? holding.price : existing.price;
        final latestOriginalPrice = holding.originalPrice ?? existing.originalPrice;
        final effectiveDividends =
            (holding.dividends != null && holding.dividends!.isNotEmpty)
                ? holding.dividends
                : existing.dividends;

        final merged = Holding(
          name: existing.name,
          symbol: existing.symbol,
          type: existing.type,
          account: existing.account,
          quantity: totalQuantity,
          price: latestPrice,
          originalPrice: latestOriginalPrice,
          currency: holding.currency ?? existing.currency,
          dividends: effectiveDividends,
        );

        final nextList = List<Holding>.from(_holdings);
        nextList[duplicateIndex] = merged;
        nextList.removeWhere((h) => identical(h, originalHolding));
        setState(() => _holdings = nextList);
        message = "'${holding.name}' 자산이 동일 계좌 기존 수량에 합산되었습니다.";
      } else {
        final currentIndex = _holdings.indexOf(originalHolding);
        final targetIndex = currentIndex != -1
            ? currentIndex
            : (index < _holdings.length ? index : -1);
        if (targetIndex == -1) return;

        setState(() => _holdings = List.from(_holdings)..[targetIndex] = holding);
        message = "'${holding.name}' 자산이 수정되었습니다.";
      }

      _saveAll();
      _syncPrices();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: const Color(0xFF176B5B),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        // 바텀시트가 닫힌 직후 자연스러운 작업 완료 시점에 전면광고 노출 (3분 쿨다운 적용)
        Future.delayed(const Duration(milliseconds: 300), () {
          AdService.showInterstitialAd();
        });
      }
    }
  }

  void _confirmDelete(Holding holding) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF202020) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: isDark ? const Color(0xFF333333) : const Color(0xFFEAE5DC),
              width: 1,
            ),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 경고 아이콘
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.15 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '자산 삭제',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '선택하신 자산을 목록에서 영구히 삭제할까요?',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : const Color(0xFF7A7265),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                // 대상 자산 요약 카드
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF282828) : const Color(0xFFF7F5F0),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF383838) : const Color(0xFFE5DFD5),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF333333) : const Color(0xFFEBE6DD),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          holding.type == AssetType.cash
                              ? Icons.attach_money_rounded
                              : Icons.show_chart_rounded,
                          size: 20,
                          color: const Color(0xFF176B5B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              holding.name,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${holding.account.label} · ${holding.type == AssetType.cash ? '₩${formatNumber(holding.quantity)}' : '${formatQuantity(holding.quantity)}주'}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.grey[400] : const Color(0xFF8A8275),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 13,
                      color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '삭제된 자산 데이터는 복구할 수 없습니다.',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                // 취소 / 삭제 액션 버튼
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark ? const Color(0xFF444444) : const Color(0xFFDDD8CE),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            foregroundColor: isDark ? Colors.grey[300] : const Color(0xFF4A443D),
                          ),
                          child: const Text(
                            '취소',
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            setState(() => _holdings = List.from(_holdings)..remove(holding));
                            _saveAll();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("'${holding.name}' 자산이 삭제되었습니다."),
                                backgroundColor: const Color(0xFFE53935),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            '삭제하기',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── 자산 관리 탭 ─────────────────────────────────────────

