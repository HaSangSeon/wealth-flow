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
      icon: Icons.account_balance_wallet,
      title: '내 자산을 한눈에',
      description: '보유한 주식, ETF, 연금, IRP, ISA 등\n모든 자산을 한 곳에서 관리하세요.',
    ),
    _OnboardingPage(
      icon: Icons.security,
      title: '내 폰에 안전하게 저장',
      description: '자산 정보는 외부 서버가 아닌 내 폰에만\n로컬 저장되어 유출 우려 없이 안전합니다.\n\n⚠️ 단, 앱 삭제 시 데이터도 함께 날아갑니다!',
    ),
    _OnboardingPage(
      icon: Icons.stacked_line_chart,
      title: '복리의 마법, 시뮬레이션',
      description: '연평균 수익률과 월 투자금을 설정하면\n미래 자산을 복리로 시뮬레이션 합니다.',
    ),
    _OnboardingPage(
      icon: Icons.trending_up,
      title: '나만의 투자 시나리오',
      description: '10년, 15년, 20년 후\n내 자산이 얼마나 불어날지 확인하세요.',
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
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: primaryColor),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF2C2A28),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[400] : const Color(0xFF6E675E),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _holdings = widget.storage.loadHoldings();
    _settings = widget.storage.loadSettings();
    _updateWidget();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndSyncPrices();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
    if (_isSyncing) return;
    setState(() => _isSyncing = true);

    final yahooService = YahooFinanceService();

    // Always fetch the latest USD-KRW exchange rate first on sync
    try {
      final double? usdRate = await yahooService.fetchExchangeRate('USD');
      if (usdRate != null) {
        widget.storage.lastExchangeRate = usdRate;
      }
    } catch (e) {
      debugPrint("Failed to fetch USD exchange rate: $e");
    }

    bool hasUpdates = false;
    
    for (int i = 0; i < _holdings.length; i++) {
      final holding = _holdings[i];
      if (holding.symbol != null && 
          (holding.type == AssetType.usStock || holding.type == AssetType.koreanStock || holding.type == AssetType.etf)) {
        final detailsFuture = yahooService.fetchStockDetails(holding.symbol!);
        
        final details = await detailsFuture;
        if (details != null && details['price'] != null) {
          final rawPrice = (details['price'] as num).toDouble();
          final currency = (details['currency'] as String?)?.toUpperCase() ?? 'USD';

          double price = rawPrice;
          if (currency != 'KRW') {
            double? exchangeRate = await yahooService.fetchExchangeRate(currency);
            exchangeRate ??= yahooService.getFallbackExchangeRate(currency);
            price = rawPrice * exchangeRate;
            if (currency == 'USD') {
              widget.storage.lastExchangeRate = exchangeRate;
            }
          }

          final dividends = details['dividends'] as List<Map<String, dynamic>>?;

          if (holding.price != price || 
              holding.originalPrice != rawPrice || 
              holding.currency != currency ||
              holding.dividends != dividends) {
            _holdings[i].price = price;
            _holdings[i].originalPrice = rawPrice;
            _holdings[i].currency = currency;
            _holdings[i].dividends = dividends;
            hasUpdates = true;
          }
        }
      }
    }
    
    if (hasUpdates && mounted) {
      _saveAll();
    }
    widget.storage.lastSyncedAt = DateTime.now();
    if (mounted) {
      setState(() => _isSyncing = false);
    }
    portfolioNewsKey.currentState?.fetchNews();
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
    
    HomeWidget.saveWidgetData<String>('total_wealth', formattedTotal);
    HomeWidget.saveWidgetData<String>('progress_percent', percentStr);
    HomeWidget.updateWidget(
      androidName: 'WealthWidgetProvider',
      iOSName: 'WealthWidget',
    );
  }

  double get _currentValue =>
      _holdings.fold(0, (previous, holding) => previous + holding.value);

  List<ProjectionPoint> get _projection => calculateProjectionPoints(
        initialAsset: _currentValue,
        monthlyContribution: _settings.monthlyContribution,
        annualReturnPercent: _settings.annualReturn,
        contributionGrowthPercent: _settings.contributionGrowth,
        years: _settings.years,
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final projectedValue = _projection.isEmpty ? 0.0 : _projection.last.total;
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
              PensionTaxTab(
                holdings: _holdings,
                storage: widget.storage,
                onDataRestored: _loadDataForProfile,
              ),
              SimulationTab(
                storage: widget.storage,
                currentValue: _currentValue,
                projectedValue: projectedValue,
                years: _settings.years,
                gain: gain,
                annualReturn: _settings.annualReturn,
                monthlyContribution: _settings.monthlyContribution,
                contributionGrowth: _settings.contributionGrowth,
                projectionPoints: _projection,
                targetAmount: _settings.targetAmount,
                targetYears: _settings.targetYears,
                onAnnualReturnChanged: (v) => setState(() {
                  _settings.annualReturn = v;
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
              DividendTab(
                storage: widget.storage,
                holdings: _holdings,
                onPremiumChanged: () => setState(() {}),
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
                      label: '연금/절세',
                      icon: Icons.savings_outlined,
                      activeIcon: Icons.savings_rounded,
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
                      label: '배당',
                      icon: Icons.calendar_month_outlined,
                      activeIcon: Icons.calendar_month_rounded,
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
      final existingIndex = _holdings.indexWhere((h) =>
          h.account == holding.account &&
          ((holding.symbol?.isNotEmpty == true && h.symbol == holding.symbol) ||
          ((holding.symbol?.isEmpty ?? true) && h.name == holding.name && h.type == holding.type)));

      String message;
      if (existingIndex != -1) {
        final existing = _holdings[existingIndex];
        final updated = Holding(
          name: existing.name,
          symbol: existing.symbol,
          type: existing.type,
          account: existing.account,
          quantity: existing.quantity + holding.quantity,
          price: holding.price,
          originalPrice: holding.originalPrice,
          currency: holding.currency,
          dividends: holding.dividends ?? existing.dividends,
        );
        setState(() => _holdings[existingIndex] = updated);
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
      setState(() => _holdings = List.from(_holdings)..[index] = holding);
      _saveAll();
      _syncPrices();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("'${holding.name}' 자산이 수정되었습니다."),
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
                              '${holding.account.label} · ${holding.type == AssetType.cash ? '₩${formatNumber(holding.quantity)}' : '${formatNumber(holding.quantity)}주'}',
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

