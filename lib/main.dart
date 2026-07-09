import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'formatters.dart';
import 'dividend.dart';
import 'models.dart';
import 'payment_service.dart';
import 'premium.dart';
import 'yahoo_finance_service.dart';

// ─── 앱 진ㄴㄴ입점 ────────────────────────────────────────────

late final ValueNotifier<ThemeMode> themeNotifier;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final storage = StorageService();
  await storage.init();
  
  try {
    await PaymentService.initialize(storage);
  } catch (e) {
    debugPrint("Failed to initialize PaymentService: $e");
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
      title: 'Wealth Flow',
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

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  late List<Holding> _holdings;
  late SimulationSettings _settings;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _holdings = widget.storage.loadHoldings();
    _settings = widget.storage.loadSettings();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndSyncPrices();
    });
  }

  void _loadDataForProfile() {
    setState(() {
      _holdings = widget.storage.loadHoldings();
      _settings = widget.storage.loadSettings();
    });
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
          onProfileAdded: () async {
            Navigator.pop(context);
            if (!widget.storage.isPremium && widget.storage.profiles.length >= 2) {
              await _showPremiumLimitDialog(
                '무료 버전에서는 최대 2개의 프로필까지만 생성할 수 있습니다.\n\n프리미엄 멤버십으로 업그레이드하여 한계 없는 무제한 프로필 추가를 경험해 보세요!',
              );
            } else {
              _openAddProfileDialog();
            }
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
      await _syncPrices();
    }
  }

  Future<void> _syncPrices() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);

    bool hasUpdates = false;
    final yahooService = YahooFinanceService();
    
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
  }

  void _saveAll() {
    widget.storage.saveHoldings(_holdings);
    widget.storage.saveSettings(_settings);
  }

  double get _currentValue =>
      _holdings.fold(0, (previous, holding) => previous + holding.value);

  List<ProjectionPoint> get _projection {
    var total = _currentValue;
    var monthly = _settings.monthlyContribution;
    var cumulativeContrib = 0.0;
    final points = <ProjectionPoint>[
      ProjectionPoint(
          year: 0,
          total: total,
          contribution: 0,
          cumulativeContribution: 0),
    ];

    for (var year = 1; year <= _settings.years; year++) {
      final annualContribution = monthly * 12;
      cumulativeContrib += annualContribution;
      total =
          (total + annualContribution) * (1 + _settings.annualReturn / 100);
      points.add(
        ProjectionPoint(
          year: year,
          total: total,
          contribution: annualContribution,
          cumulativeContribution: cumulativeContrib,
        ),
      );
      monthly *= 1 + _settings.contributionGrowth / 100;
    }

    return points;
  }

  @override
  Widget build(BuildContext context) {
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
              ),
              PensionTaxTab(
                holdings: _holdings,
              ),
              SimulationTab(
                currentValue: _currentValue,
                projectedValue: projectedValue,
                years: _settings.years,
                gain: gain,
                annualReturn: _settings.annualReturn,
                monthlyContribution: _settings.monthlyContribution,
                contributionGrowth: _settings.contributionGrowth,
                projectionPoints: _projection,
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
              ),
              DividendTab(
                storage: widget.storage,
                holdings: _holdings,
                onPremiumChanged: () => setState(() {}),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey : const Color(0xFF8C847A),
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: '내 자산',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.savings_outlined),
            activeIcon: Icon(Icons.savings),
            label: '연금/절세',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: '시뮬레이션',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: '배당',
          ),
        ],
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
    // 프리미엄 회원이 아닌 경우, 자산 등록 개수를 총합 최대 5개로 제한
    if (!widget.storage.isPremium && widget.storage.getTotalHoldingsCount() >= 5) {
      await _showPremiumLimitDialog(
        '무료 버전에서는 모든 프로필을 합쳐 총 5개의 자산까지만 등록할 수 있습니다.\n\n프리미엄 멤버십으로 업그레이드하여 한계 없는 무제한 자산 추가를 경험해 보세요!',
      );
      return;
    }

    final holding = await showModalBottomSheet<Holding>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
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
        );
        setState(() => _holdings[existingIndex] = updated);
        message = "'${holding.name}' 자산이 기존 수량에 합산되었습니다.";
      } else {
        setState(() => _holdings.add(holding));
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
      }
    }
  }

  Future<void> _openEditHoldingSheet(Holding originalHolding) async {
    final index = _holdings.indexOf(originalHolding);
    if (index == -1) return;

    final holding = await showModalBottomSheet<Holding>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) =>
          HoldingFormSheet(initialHolding: originalHolding),
    );

    if (holding != null && mounted) {
      setState(() => _holdings[index] = holding);
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
      }
    }
  }

  void _confirmDelete(Holding holding) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('자산 삭제'),
        content: Text("'${holding.name}' 자산을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _holdings.remove(holding));
              _saveAll();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("'${holding.name}' 자산이 삭제되었습니다."),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}

// ─── 자산 관리 탭 ─────────────────────────────────────────

class AssetManagementTab extends StatelessWidget {
  const AssetManagementTab({
    super.key,
    required this.storage,
    required this.holdings,
    required this.currentValue,
    this.lastSyncedAt,
    required this.lastExchangeRate,
    required this.isSyncing,
    required this.showForeignInKrw,
    required this.onToggleForeignInKrw,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onRefresh,
    required this.onPremiumChanged,
    required this.onProfileTap,
  });

  final StorageService storage;
  final List<Holding> holdings;
  final double currentValue;
  final DateTime? lastSyncedAt;
  final double lastExchangeRate;
  final bool isSyncing;
  final bool showForeignInKrw;
  final ValueChanged<bool> onToggleForeignInKrw;
  final VoidCallback onAdd;
  final ValueChanged<Holding> onEdit;
  final ValueChanged<Holding> onDelete;
  final Future<void> Function() onRefresh;
  final VoidCallback onPremiumChanged;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final grouped = <AccountType, double>{};
    for (final holding in holdings) {
      grouped[holding.account] = (grouped[holding.account] ?? 0) + holding.value;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: onRefresh,
          color: const Color(0xFF176B5B),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: onProfileTap,
                          child: Builder(
                            builder: (context) {
                              final activeProfile = storage.profiles.firstWhere(
                                (p) => p.id == storage.activeProfileId,
                                orElse: () => storage.profiles.first,
                              );
                              final avatarPath = activeProfile.avatarPath;
                              final avatarAbsPath = storage.getAvatarAbsolutePath(avatarPath);
                              final hasAvatar = avatarAbsPath != null && File(avatarAbsPath).existsSync();
                              return Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(8),
                                  image: hasAvatar
                                      ? DecorationImage(
                                          image: FileImage(File(avatarAbsPath)),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: !hasAvatar
                                    ? const Icon(Icons.account_balance_wallet,
                                        color: Colors.white)
                                    : null,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: onProfileTap,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      storage.profiles.firstWhere((p) => p.id == storage.activeProfileId, orElse: () => storage.profiles.first).name,
                                      style: const TextStyle(
                                          fontSize: 20, fontWeight: FontWeight.w800),
                                    ),
                                    const Icon(Icons.arrow_drop_down),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  '내 자산 입력 및 관리',
                                  style: TextStyle(color: Colors.grey, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PremiumSubscriptionScreen(storage: storage),
                              ),
                            ).then((_) {
                              onPremiumChanged();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: storage.isPremium
                                    ? [const Color(0xFF176B5B), const Color(0xFF084C3D)]
                                    : [const Color(0xFFEAA622), const Color(0xFFD48B00)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: storage.isPremium
                                    ? const Color(0xFFEAA622)
                                    : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              storage.isPremium ? '👑 프리미엄 회원' : '👑 프리미엄',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            final current = themeNotifier.value;
                            ThemeMode nextMode;
                            if (current == ThemeMode.system) {
                              nextMode = Theme.of(context).brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
                            } else if (current == ThemeMode.light) {
                              nextMode = ThemeMode.dark;
                            } else {
                              nextMode = ThemeMode.light;
                            }
                            themeNotifier.value = nextMode;
                            storage.themeMode = nextMode.index;
                          },
                          icon: Icon(
                            themeNotifier.value == ThemeMode.dark || (themeNotifier.value == ThemeMode.system && Theme.of(context).brightness == Brightness.dark)
                                ? Icons.light_mode
                                : Icons.dark_mode,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF13584B), Color(0xFF1A7A68)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF176B5B).withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '총 자산',
                              style: TextStyle(color: Color(0xFFD6E8E4)),
                            ),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                holdings.isEmpty
                                    ? '₩0'
                                    : formatCurrencyFull(currentValue),
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            if (lastSyncedAt != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.sync, color: Color(0xFFB0D4CD), size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            '마지막 동기화: ${formatTime(lastSyncedAt!)}',
                                            style: const TextStyle(
                                              color: Color(0xFFB0D4CD),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.currency_exchange, color: Color(0xFFB0D4CD), size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            '적용 환율: 1 USD = ${formatCurrency(lastExchangeRate)}',
                                            style: const TextStyle(
                                              color: Color(0xFFB0D4CD),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    onPressed: isSyncing ? null : () => onRefresh(),
                                    icon: isSyncing
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.refresh, color: Colors.white, size: 20),
                                    tooltip: '지금 새로고침',
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),
                            Container(height: 1, color: const Color(0xFF2A8B79)),
                            const SizedBox(height: 12),
                            const Text(
                              '보유 자산을 수동으로 입력해 보세요. 자산 정보는 실시간으로 시뮬레이션 탭에 반영됩니다.',
                              style: TextStyle(
                                  fontSize: 13, color: Color(0xFFB0D4CD), height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '계좌별 자산 현황',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        TextButton.icon(
                          onPressed: onAdd,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('자산 추가'),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AccountType.values.map((account) {
                        final val = grouped[account] ?? 0;
                        return Chip(
                          label:
                              Text('${account.label} ${formatCurrency(val)}'),
                          backgroundColor: val > 0
                              ? (isDark ? const Color(0xFF1A3D36) : const Color(0xFFE8F0EA))
                              : (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEFECE6)),
                          labelStyle: TextStyle(
                            color: val > 0
                                ? (isDark ? const Color(0xFF26A68A) : const Color(0xFF176B5B))
                                : (isDark ? Colors.grey[400] : const Color(0xFF8C847A)),
                            fontWeight: val > 0 ? FontWeight.w700 : FontWeight.normal,
                          ),
                          side: BorderSide.none,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    PortfolioAllocationCard(
                      holdings: holdings,
                      lastExchangeRate: lastExchangeRate,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '자산 목록',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        Row(
                          children: [
                            Text(
                              '해외자산 원화 환산',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.grey[400] : const Color(0xFF6E675E),
                              ),
                            ),
                            const SizedBox(width: 4),
                            SizedBox(
                              height: 30,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Switch(
                                  value: showForeignInKrw,
                                  onChanged: onToggleForeignInKrw,
                                  activeThumbColor: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            holdings.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add_chart,
                              size: 36,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '아직 등록된 자산이 없습니다',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '아래 버튼을 눌러 첫 자산을 추가해 보세요.\nETF, 주식, 연금, IRP, ISA 등\n다양한 자산을 관리할 수 있습니다.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.grey, fontSize: 14),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: onAdd,
                            icon: const Icon(Icons.add),
                            label: const Text('첫 자산 추가하기'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final holding = holdings[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Card(
                              child: ListTile(
                                onTap: () => onEdit(holding),
                                contentPadding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
                                title: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        holding.name,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                            color: isDark ? Colors.white : Colors.black87),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (holding.symbol != null && holding.symbol!.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        holding.symbol!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? Colors.grey[400] : const Color(0xFF8E867C),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text: holding.type == AssetType.cash
                                                  ? holding.account.label
                                                  : '${holding.account.label} · ',
                                            ),
                                            if (holding.type != AssetType.cash) ...[
                                              TextSpan(
                                                text: '${formatNumber(holding.quantity)}주',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: Theme.of(context).colorScheme.primary,
                                                ),
                                              ),
                                              TextSpan(
                                                text: ' (주당 ${holding.formatOriginalPrice()})',
                                                style: TextStyle(
                                                  color: isDark ? Colors.grey[400] : const Color(0xFF8E867C),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        style: TextStyle(
                                            color: isDark ? Colors.grey[400] : const Color(0xFF6E675E),
                                            fontSize: 13),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        showForeignInKrw
                                            ? holding.formatValueInKrw()
                                            : holding.formatOriginalValue(),
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.primary,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: '수정',
                                      onPressed: () => onEdit(holding),
                                      icon: const Icon(Icons.edit_outlined,
                                          color: Color(0xFF6E675E)),
                                    ),
                                    IconButton(
                                      tooltip: '삭제',
                                      onPressed: () => onDelete(holding),
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.redAccent),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: holdings.length,
                      ),
                    ),
                  ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        ),
        ),
      ),
      floatingActionButton: GestureDetector(
        onTap: onAdd,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF229A85),
                Color(0xFF0F4E42),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F4E42).withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }
}

// ─── 시뮬레이션 탭 ────────────────────────────────────────

class SimulationTab extends StatelessWidget {
  const SimulationTab({
    super.key,
    required this.currentValue,
    required this.projectedValue,
    required this.years,
    required this.gain,
    required this.annualReturn,
    required this.monthlyContribution,
    required this.contributionGrowth,
    required this.projectionPoints,
    required this.onAnnualReturnChanged,
    required this.onMonthlyContributionChanged,
    required this.onContributionGrowthChanged,
    required this.onYearsChanged,
  });

  final double currentValue;
  final double projectedValue;
  final int years;
  final double gain;
  final double annualReturn;
  final double monthlyContribution;
  final double contributionGrowth;
  final List<ProjectionPoint> projectionPoints;
  final ValueChanged<double> onAnnualReturnChanged;
  final ValueChanged<double> onMonthlyContributionChanged;
  final ValueChanged<double> onContributionGrowthChanged;
  final ValueChanged<int> onYearsChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.stacked_line_chart,
                              color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Wealth Flow',
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.w800),
                              ),
                              Text(
                                '미래 자산 시뮬레이션',
                                style: TextStyle(color: isDark ? Colors.grey[400] : const Color(0xFF6E675E)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _Header(
                      currentValue: currentValue,
                      projectedValue: projectedValue,
                      years: years,
                      gain: gain,
                    ),
                    const SizedBox(height: 16),
                    _ScenarioPanel(
                      annualReturn: annualReturn,
                      monthlyContribution: monthlyContribution,
                      contributionGrowth: contributionGrowth,
                      years: years,
                      onAnnualReturnChanged: onAnnualReturnChanged,
                      onMonthlyContributionChanged:
                          onMonthlyContributionChanged,
                      onContributionGrowthChanged: onContributionGrowthChanged,
                      onYearsChanged: onYearsChanged,
                    ),
                    const SizedBox(height: 16),
                    _ProjectionChart(points: projectionPoints),
                    const SizedBox(height: 16),
                    _ProjectionTable(points: projectionPoints),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 시뮬레이션 하위 위젯들 ───────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.currentValue,
    required this.projectedValue,
    required this.years,
    required this.gain,
  });

  final double currentValue;
  final double projectedValue;
  final int years;
  final double gain;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF13584B), Color(0xFF1A7A68)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF176B5B).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '예상 미래 자산',
              style: TextStyle(color: Color(0xFFD6E8E4)),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatCurrencyFull(projectedValue),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _PremiumMetricTile(
                    label: '현재 자산',
                    value: formatCurrencyFull(currentValue),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PremiumMetricTile(
                    label: '$years년 증가분',
                    value: formatCurrencyFull(gain),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumMetricTile extends StatelessWidget {
  const _PremiumMetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFFD6E8E4), fontSize: 12)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScenarioPanel extends StatelessWidget {
  const _ScenarioPanel({
    required this.annualReturn,
    required this.monthlyContribution,
    required this.contributionGrowth,
    required this.years,
    required this.onAnnualReturnChanged,
    required this.onMonthlyContributionChanged,
    required this.onContributionGrowthChanged,
    required this.onYearsChanged,
  });

  final double annualReturn;
  final double monthlyContribution;
  final double contributionGrowth;
  final int years;
  final ValueChanged<double> onAnnualReturnChanged;
  final ValueChanged<double> onMonthlyContributionChanged;
  final ValueChanged<double> onContributionGrowthChanged;
  final ValueChanged<int> onYearsChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '시나리오',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _SliderField(
              label: '연평균 수익률',
              valueLabel: '${annualReturn.toStringAsFixed(1)}%',
              value: annualReturn,
              min: -10,
              max: 20,
              divisions: 60,
              onChanged: onAnnualReturnChanged,
              helpText: '자산이 매년 굴러가며 창출하는 평균 수익률입니다.\n\n물가상승률(인플레이션)을 감안한 실질 수익률을 입력하시면 더욱 정교한 시뮬레이션 결과를 볼 수 있습니다.',
            ),
            _SliderField(
              label: '월 추가 투자금',
              valueLabel: formatCurrencyFull(monthlyContribution),
              value: monthlyContribution,
              min: 0,
              max: 5000000,
              divisions: 50,
              onChanged: onMonthlyContributionChanged,
              helpText: '매월 새롭게 저축하거나 주식/계좌 등에 직접 추가하여 납입할 신규 원금 액수입니다.',
            ),
            _SliderField(
              label: '투자금 연 증가율',
              valueLabel: '${contributionGrowth.toStringAsFixed(1)}%',
              value: contributionGrowth,
              min: 0,
              max: 10,
              divisions: 20,
              onChanged: onContributionGrowthChanged,
              helpText: '연봉 상승이나 소득 증가에 맞추어, 매년 월 투자 저축액을 늘려가는 비율입니다.\n\n예를 들어 월 적립금이 100만 원이고 연 증가율이 5%라면, 2년 차에는 월 105만 원, 3년 차에는 월 110.2만 원으로 증액 납입되어 장기 복리 효과를 더욱 사실적으로 예측해 줍니다.',
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [10, 15, 20, 25].map((option) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                final isSelected = years == option;
                return ChoiceChip(
                  label: Text('$option년'),
                  selected: isSelected,
                  selectedColor: isDark ? const Color(0xFF1A3D36) : const Color(0xFFE8F0EA),
                  backgroundColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEFECE6),
                  labelStyle: TextStyle(
                    color: isSelected 
                       ? (isDark ? const Color(0xFF26A68A) : const Color(0xFF176B5B))
                       : (isDark ? Colors.grey[400] : const Color(0xFF8C847A)),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                  ),
                  side: BorderSide.none,
                  onSelected: (_) => onYearsChanged(option),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliderField extends StatelessWidget {
  const _SliderField({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    this.helpText,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final String? helpText;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(child: Text(label)),
            if (helpText != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: Row(
                        children: [
                          Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            label,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                          ),
                        ],
                      ),
                      content: Text(
                        helpText!,
                        style: TextStyle(
                          height: 1.5,
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('확인', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
                child: Icon(
                  Icons.help_outline_rounded,
                  size: 16,
                  color: isDark ? Colors.grey[400] : const Color(0xFF8E867C),
                ),
              ),
            ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              valueLabel,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// ─── 차트 ─────────────────────────────────────────────────

class _ProjectionChart extends StatefulWidget {
  const _ProjectionChart({required this.points});

  final List<ProjectionPoint> points;

  @override
  State<_ProjectionChart> createState() => _ProjectionChartState();
}

class _ProjectionChartState extends State<_ProjectionChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '복리 성장 흐름',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                if (_selectedIndex != null && _selectedIndex! < widget.points.length)
                  Text(
                    '${widget.points[_selectedIndex!].year}년차 상세',
                    style: TextStyle(
                      fontSize: 12,
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return GestureDetector(
                  onPanStart: (details) => _updateSelectedIndex(details.localPosition, width),
                  onPanUpdate: (details) => _updateSelectedIndex(details.localPosition, width),
                  onPanEnd: (_) => setState(() => _selectedIndex = null),
                  onTapDown: (details) => _updateSelectedIndex(details.localPosition, width),
                  onTapUp: (_) => setState(() => _selectedIndex = null),
                  onTapCancel: () => setState(() => _selectedIndex = null),
                  child: Stack(
                    children: [
                      SizedBox(
                        height: 240,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _ProjectionChartPainter(
                            widget.points,
                            primaryColor,
                            isDark,
                            _selectedIndex,
                          ),
                        ),
                      ),
                      if (_selectedIndex != null && _selectedIndex! < widget.points.length)
                        _buildTooltip(widget.points[_selectedIndex!]),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _updateSelectedIndex(Offset localPosition, double width) {
    if (widget.points.isEmpty) return;
    final chartWidth = width;
    final chartX = localPosition.dx;
    
    if (chartX < 0 || chartX > chartWidth) return;
    
    final double step = chartWidth / (widget.points.length - 1);
    final int index = (chartX / step).round().clamp(0, widget.points.length - 1);
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Widget _buildTooltip(ProjectionPoint point) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initialAsset = widget.points.first.total;
    final totalInvested = initialAsset + point.cumulativeContribution;
    final profit = point.total - totalInvested;
    final returnRate = totalInvested > 0 ? (profit / totalInvested) * 100 : 0.0;

    return Positioned(
      top: 10,
      left: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${point.year}년차 시뮬레이션',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              '누적 투자: ${formatCurrency(totalInvested)}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            Text(
              '총 자산: ${formatCurrency(point.total)}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text(
              '수익: ${formatCurrency(profit)} (${returnRate >= 0 ? '+' : ''}${returnRate.toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: profit >= 0 ? const Color(0xFF176B5B) : Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectionChartPainter extends CustomPainter {
  _ProjectionChartPainter(this.points, this.primaryColor, this.isDark, this.selectedIndex);

  final List<ProjectionPoint> points;
  final Color primaryColor;
  final bool isDark;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final chartWidth = size.width;
    final chartHeight = size.height - 25.0;
    const topMargin = 10.0;
    final actualGraphHeight = chartHeight - topMargin;

    final axisColor = isDark ? const Color(0xFF333333) : const Color(0xFFE5E0D7);
    final gridPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1;

    final maxValue = points.map((point) => point.total).reduce(math.max);
    final minValue = points.map((point) => point.total).reduce(math.min);
    final range = math.max(maxValue - minValue, 1.0);

    Offset mapPoint(ProjectionPoint point, int index) {
      final x = chartWidth * index / (points.length - 1);
      final y = chartHeight - ((point.total - minValue) / range * actualGraphHeight);
      return Offset(x, y);
    }

    // 1. Horizontal grid lines and Y-axis labels
    for (var i = 0; i <= 4; i++) {
      final y = topMargin + actualGraphHeight * i / 4;
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);

      final val = maxValue - (maxValue - minValue) * i / 4;
      final textPainter = TextPainter(
        text: TextSpan(
          text: _formatCompactValue(val),
          style: TextStyle(
            color: isDark ? Colors.grey[500] : const Color(0xFF8E867C),
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      // Y축 텍스트를 차트 내부 왼쪽(0), 그리드 선 위로 배치
      textPainter.paint(
        canvas,
        Offset(0, y - textPainter.height - 2),
      );
    }

    // 2. X-axis labels (bottom)
    final interval = math.max(1, points.length ~/ 4);
    for (var i = 0; i < points.length; i++) {
      bool shouldDraw = false;
      if (i == 0 || i == points.length - 1) {
        shouldDraw = true;
      } else if (i % interval == 0) {
        // 마지막 연도 텍스트와의 겹침 방지 (거리가 interval의 절반 이하로 가까우면 생략)
        if ((points.length - 1 - i) > (interval / 2.0)) {
          shouldDraw = true;
        }
      }

      if (shouldDraw) {
        final offset = mapPoint(points[i], i);
        final yearText = '${points[i].year}년';
        final textPainter = TextPainter(
          text: TextSpan(
            text: yearText,
            style: TextStyle(
              color: isDark ? Colors.grey[500] : const Color(0xFF8E867C),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        // 0년 라벨이 왼쪽으로 짤리지 않게 방어, 마지막 연도 라벨이 오른쪽으로 짤리지 않게 방어
        double labelX = offset.dx - textPainter.width / 2;
        if (i == 0) labelX = 0;
        if (i == points.length - 1) labelX = chartWidth - textPainter.width;

        textPainter.paint(
          canvas,
          Offset(labelX, chartHeight + 6),
        );
      }
    }

    // 3. Gradient fill path
    final linePath = Path();
    final fillPath = Path();
    for (var i = 0; i < points.length; i++) {
      final offset = mapPoint(points[i], i);
      if (i == 0) {
        linePath.moveTo(offset.dx, offset.dy);
        fillPath.moveTo(offset.dx, chartHeight);
        fillPath.lineTo(offset.dx, offset.dy);
      } else {
        linePath.lineTo(offset.dx, offset.dy);
        fillPath.lineTo(offset.dx, offset.dy);
      }
    }
    fillPath.lineTo(chartWidth, chartHeight);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(chartWidth / 2, topMargin),
        Offset(chartWidth / 2, chartHeight),
        [
          primaryColor.withValues(alpha: 0.35),
          primaryColor.withValues(alpha: 0.0),
        ],
      );
    canvas.drawPath(fillPath, fillPaint);

    // 4. Line path
    canvas.drawPath(
      linePath,
      Paint()
        ..color = primaryColor
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // 5. Selection indicator OR static dots
    if (selectedIndex != null && selectedIndex! < points.length) {
      final selectedPoint = points[selectedIndex!];
      final offset = mapPoint(selectedPoint, selectedIndex!);

      // Vertical line
      final trackerPaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.4)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      
      canvas.drawLine(
        Offset(offset.dx, topMargin),
        Offset(offset.dx, chartHeight),
        trackerPaint,
      );

      // Glow dot
      final outerGlowPaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(offset, 9, outerGlowPaint);

      final innerDotPaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(offset, 4.5, innerDotPaint);
    } else {
      final dotPaint = Paint()..color = isDark ? primaryColor : const Color(0xFF0F3D35);
      final step = math.max(1, points.length ~/ 5);
      for (var i = 0; i < points.length; i += step) {
        canvas.drawCircle(mapPoint(points[i], i), 4, dotPaint);
      }
      canvas.drawCircle(mapPoint(points.last, points.length - 1), 4, dotPaint);
    }
  }

  String _formatCompactValue(double value) {
    final abs = value.abs();
    if (abs >= 100000000) {
      return '${(value / 100000000).toStringAsFixed(1)}억';
    }
    if (abs >= 10000) {
      return '${(value / 10000).toStringAsFixed(0)}만';
    }
    return value.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant _ProjectionChartPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.selectedIndex != selectedIndex;
  }
}

// ─── 연도별 상세표 ────────────────────────────────────────

class _ProjectionTable extends StatefulWidget {
  const _ProjectionTable({required this.points});

  final List<ProjectionPoint> points;

  @override
  State<_ProjectionTable> createState() => _ProjectionTableState();
}

class _ProjectionTableState extends State<_ProjectionTable> {
  final ScrollController _scrollController = ScrollController();
  bool _showSwipeHint = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _scrollController.position.maxScrollExtent <= 0) {
        if (mounted) setState(() => _showSwipeHint = false);
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    
    // Hide hint if scrolled to the end (or very close to it)
    if (maxScroll > 0 && currentScroll >= maxScroll - 20) {
      if (_showSwipeHint) setState(() => _showSwipeHint = false);
    } else {
      if (!_showSwipeHint) setState(() => _showSwipeHint = true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (widget.points.length < 2) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '연도별 자산 상세',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                AnimatedOpacity(
                  opacity: _showSwipeHint ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.swipe_left_rounded, 
                        size: 14, 
                        color: isDark ? Colors.grey[500] : const Color(0xFF8E867C),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '밀어서 더 보기',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[500] : const Color(0xFF8E867C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(isDark ? const Color(0xFF1A3D36) : const Color(0xFFF3F6F1)),
                columnSpacing: 16,
                horizontalMargin: 12,
                columns: const [
                  DataColumn(label: Text('연차', style: TextStyle(fontWeight: FontWeight.w700))),
                  DataColumn(label: Text('누적 투자금', style: TextStyle(fontWeight: FontWeight.w700))),
                  DataColumn(label: Text('총 자산', style: TextStyle(fontWeight: FontWeight.w700))),
                  DataColumn(label: Text('수익 (수익률)', style: TextStyle(fontWeight: FontWeight.w700))),
                ],
                rows: widget.points.where((p) => p.year > 0).map((p) {
                  final initialAsset = widget.points.first.total;
                  final totalInvested =
                      initialAsset + p.cumulativeContribution;
                  final profit = p.total - totalInvested;
                  final returnRate = totalInvested > 0 ? (profit / totalInvested) * 100 : 0.0;
                  return DataRow(
                    cells: [
                      DataCell(Text('${p.year}년')),
                      DataCell(Text(formatCurrency(totalInvested))),
                      DataCell(Text(
                        formatCurrency(p.total),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      )),
                      DataCell(Text(
                        '${formatCurrency(profit)} (${returnRate >= 0 ? '+' : ''}${returnRate.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          color: profit >= 0
                              ? (isDark ? const Color(0xFF26A68A) : const Color(0xFF176B5B))
                              : Colors.redAccent,
                          fontWeight: FontWeight.w700,
                        ),
                      )),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 자산 입력 폼 ─────────────────────────────────────────

class HoldingFormSheet extends StatefulWidget {
  const HoldingFormSheet({super.key, this.initialHolding});

  final Holding? initialHolding;

  @override
  State<HoldingFormSheet> createState() => _HoldingFormSheetState();
}

class _HoldingFormSheetState extends State<HoldingFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _yahooService = YahooFinanceService();
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;
  late final FocusNode _searchFocusNode;
  AssetType? _type;
  AccountType? _account;
  String? _currency;
  double? _originalPrice;

  final ValueNotifier<bool> _isLoadingPrice = ValueNotifier(false);
  final ValueNotifier<List<YahooFinanceSearchResult>> _searchResults =
      ValueNotifier([]);
  String _lastSearchQuery = '';
  String? _selectedSymbol;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.initialHolding?.name ?? '');
    _quantityController = TextEditingController(
      text: widget.initialHolding != null
          ? formatNumber(widget.initialHolding!.quantity)
          : '',
    );
    _priceController = TextEditingController(
      text: widget.initialHolding != null
          ? formatNumber(widget.initialHolding!.price)
          : '1',
    );
    _type = widget.initialHolding?.type ?? AssetType.cash;
    _selectedSymbol = widget.initialHolding?.symbol;
    _account = widget.initialHolding?.account ?? AccountType.general;
    _currency = widget.initialHolding?.currency;
    _originalPrice = widget.initialHolding?.originalPrice;

    _searchFocusNode = FocusNode();
    _searchFocusNode.addListener(_onSearchFocusChanged);
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchFocusNode.dispose();
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _searchResults.dispose();
    _isLoadingPrice.dispose();
    super.dispose();
  }

  void _onSearchFocusChanged() {
    if (!_searchFocusNode.hasFocus) {
      // 포커스를 잃었을 때 (다른 입력창 클릭 등) 검색 결과를 닫음 (터치 이벤트 처리를 위해 150ms 지연)
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && !_searchFocusNode.hasFocus) {
          _searchResults.value = [];
        }
      });
    } else {
      // 다시 포커스를 얻었을 때 검색어가 입력되어 있다면 결과창 다시 켬
      if (_nameController.text.trim().isNotEmpty && _selectedSymbol == null) {
        _onSearchQueryChanged(_nameController.text);
      }
    }
  }

  void _onSearchQueryChanged(String query) async {
    if (query.trim().isEmpty) {
      _searchResults.value = [];
      _lastSearchQuery = query;
      setState(() {
        _selectedSymbol = null;
        _type = AssetType.cash;
        _priceController.text = '1';
        _currency = null;
        _originalPrice = null;
      });
      return;
    }
    if (query == _lastSearchQuery) return;
    _lastSearchQuery = query;

    if (_selectedSymbol != null) {
      setState(() {
        _selectedSymbol = null;
        _type = AssetType.cash;
        _priceController.text = '1';
        _currency = null;
        _originalPrice = null;
      });
    }

    final results = await _yahooService.searchStocks(query);
    if (_lastSearchQuery == query && mounted) {
      _searchResults.value = results;
    }
  }

  Future<void> _onSelectSearchResult(YahooFinanceSearchResult result) async {
    if (!mounted) return;
    FocusScope.of(context).unfocus(); // 종목 선택 완료 시 키보드를 선제적으로 닫음
    setState(() {
      _nameController.text = result.shortname;
      _selectedSymbol = result.symbol;
      _searchResults.value = [];
    });
    _isLoadingPrice.value = true;

    try {
      final detailsFuture = _yahooService.fetchStockDetails(result.symbol);
      final details = await detailsFuture;
      if (details != null && details['price'] != null) {
        double price = (details['price'] as num).toDouble();
        final currency = (details['currency'] as String?)?.toUpperCase() ?? 'USD';

        if (currency != 'KRW') {
          // KRW가 아닌 외화인 경우 (USD, CAD, JPY 등), 각 통화에 맞는 환율을 동적으로 가져와 원화로 변환
          double? exchangeRate = await _yahooService.fetchExchangeRate(currency);
          exchangeRate ??= _yahooService.getFallbackExchangeRate(currency);
          price = price * exchangeRate;
        }

        if (mounted) {
          setState(() {
            _priceController.text = formatNumber(price);
            _currency = currency;
            _originalPrice = (details['price'] as num).toDouble();

            if (currency == 'KRW') {
              _type =
                  result.quoteType == 'ETF' ? AssetType.etf : AssetType.koreanStock;
            } else {
              // 미국, 캐나다, 유럽, 일본 등 모든 해외 자산은 해외주식 또는 ETF로 분류
              _type =
                  result.quoteType == 'ETF' ? AssetType.etf : AssetType.usStock;
            }
          });
        }
      }
    } finally {
      if (mounted) {
        _isLoadingPrice.value = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.initialHolding != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 20,
        ),
        child: Form(
          key: _formKey,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        isEditMode ? '자산 수정' : '자산 추가',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      if (_selectedSymbol != null && _selectedSymbol!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          _selectedSymbol!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey[400] : const Color(0xFF8E867C),
                          ),
                        ),
                      ],
                    ],
                  ),
            const SizedBox(height: 16),
            TextFormField(
              focusNode: _searchFocusNode,
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '종목명 (검색하여 자동 입력 가능)',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: _onSearchQueryChanged,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '종목명을 입력하세요';
                }
                if (widget.initialHolding == null || _nameController.text.trim() != widget.initialHolding!.name) {
                  if (_selectedSymbol == null) {
                    return '검색 결과 목록에서 종목을 선택해주세요';
                  }
                }
                return null;
              },
            ),
              // 검색 결과창은 Stack의 두 번째 자식(Positioned)으로 띄워줍니다. (아래쪽 코드 참고)
            ValueListenableBuilder<bool>(
              valueListenable: _isLoadingPrice,
              builder: (context, isLoading, _) {
                if (!isLoading) return const SizedBox.shrink();
                return const Padding(
                  padding: EdgeInsets.only(top: 4, bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 8),
                      Text('실시간 시세 및 환율 적용 중...',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              '계좌 구분',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<AccountType>(
                showSelectedIcon: false,
                segments: AccountType.values
                    .map(
                      (account) => ButtonSegment<AccountType>(
                        value: account,
                        label: Text(
                          account.label,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                selected: {_account ?? AccountType.general},
                onSelectionChanged: (Set<AccountType> newSelection) {
                  FocusScope.of(context).unfocus();
                  setState(() {
                    _account = newSelection.first;
                  });
                },
                style: SegmentedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 0),
                  selectedBackgroundColor: Theme.of(context).colorScheme.primary,
                  selectedForegroundColor: Colors.white,
                  side: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF2C2C2C)
                        : const Color(0xFFE5E0D7),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _quantityController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [NumberInputFormatter()],
              decoration: const InputDecoration(
                labelText: '수량',
                border: OutlineInputBorder(),
              ),
              validator: _numberValidator,
            ),
            if (_selectedSymbol != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF9F8F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEBE6DD),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '자동 연동 정보',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey[400] : const Color(0xFF8C847A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('분류', style: TextStyle(fontSize: 14)),
                        Text(
                          _type?.label ?? '-',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20, thickness: 1),
                    if (_currency != null && _currency != 'KRW' && _originalPrice != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('주당 현재가 ($_currency)', style: const TextStyle(fontSize: 14)),
                          Text(
                            '${_currency == 'USD' ? '\$' : _currency == 'CAD' ? 'C\$' : _currency == 'JPY' ? '¥' : _currency == 'EUR' ? '€' : _currency == 'GBP' ? '£' : '$_currency '}${formatNumber(_originalPrice!)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20, thickness: 1),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_currency != null && _currency != 'KRW' ? '원화 환산가 (주당)' : '실시간 현재가 (주당)', style: const TextStyle(fontSize: 14)),
                        Text(
                          '₩${_priceController.text}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '이미 동일 계좌에 존재하는 자산은 추가 시 기존 수량과 합산됩니다.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.grey[400] 
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  widget.initialHolding == null ? '자산 추가하기' : '저장하기',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        // 공중에 띄워질 검색 결과 목록 창 (Positioned)
        Positioned(
              top: 104, // 타이틀(약 32) + 간격(16) + 입력창(약 56) = 104 주변
              left: 0,
              right: 0,
              child: ValueListenableBuilder<List<YahooFinanceSearchResult>>(
                valueListenable: _searchResults,
                builder: (context, results, _) {
                  if (results.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    height: 180,
                    margin: const EdgeInsets.only(top: 4, bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF262C2A) : const Color(0xFFF8FAF9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                          blurRadius: 24,
                          spreadRadius: 4,
                          offset: const Offset(0, 12),
                        ),
                      ],
                      border: Border.all(
                          color: isDark ? const Color(0xFF38403D) : const Color(0xFFDDE3E0), 
                          width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ListView.separated(
                        shrinkWrap: false,
                        itemCount: results.length,
                        separatorBuilder: (context, index) =>
                            Divider(height: 1, color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF0EBE1)),
                        itemBuilder: (context, index) {
                          final item = results[index];
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _onSelectSearchResult(item),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(Icons.show_chart,
                                          color: Theme.of(context).colorScheme.primary, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.shortname,
                                            style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15,
                                                color: isDark ? Colors.white : const Color(0xFF2C2A28)),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${item.symbol}  •  ${item.exchange}',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: isDark ? Colors.grey[400] : const Color(0xFF8C847A)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  String? _numberValidator(String? value) {
    final parsed = double.tryParse((value ?? '').replaceAll(',', ''));
    if (parsed == null || parsed < 0) {
      return '숫자를 입력하세요';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_type == null || _account == null) return;

    final quantity = double.parse(_quantityController.text.replaceAll(',', ''));
    final price = double.parse(_priceController.text.replaceAll(',', ''));

    Navigator.of(context).pop(
      Holding(
        name: _nameController.text.trim(),
        symbol: _selectedSymbol,
        type: _type!,
        account: _account!,
        quantity: quantity,
        price: price,
        originalPrice: _originalPrice,
        currency: _currency,
      ),
    );
  }
}

// ─── 연금 & 절세 매니저 탭 ───────────────────────────────────

class PensionTaxTab extends StatefulWidget {
  const PensionTaxTab({
    super.key,
    required this.holdings,
  });

  final List<Holding> holdings;

  @override
  State<PensionTaxTab> createState() => _PensionTaxTabState();
}

class _PensionTaxTabState extends State<PensionTaxTab> {
  // 세액공제 계산기 상태
  bool _incomeUnder55 = true; // true: 연봉 5500만원 이하 (16.5%), false: 5500만원 초과 (13.2%)
  double _annualContributionPension = 6000000;
  double _annualContributionIRP = 3000000;

  // ISA 전환 상태
  double _isaMaturityAmount = 30000000;

  // 연금 수령 전략 상태
  double _targetPensionTotal = 300000000;
  int _payoutYears = 20;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 1. 절세 자산 현황 계산
    final pensionHoldings = widget.holdings.where((h) => h.account == AccountType.pension);
    final irpHoldings = widget.holdings.where((h) => h.account == AccountType.irp);
    final isaHoldings = widget.holdings.where((h) => h.account == AccountType.isa);

    final pensionSum = pensionHoldings.fold(0.0, (sum, h) => sum + h.value);
    final irpSum = irpHoldings.fold(0.0, (sum, h) => sum + h.value);
    final isaSum = isaHoldings.fold(0.0, (sum, h) => sum + h.value);
    final totalTaxSavingAssets = pensionSum + irpSum + isaSum;

    final totalAssets = widget.holdings.fold(0.0, (sum, h) => sum + h.value);
    final taxSavingRatio = totalAssets > 0 ? (totalTaxSavingAssets / totalAssets) * 100 : 0.0;

    // 2. 세액공제 예상 환급금 계산
    final taxRate = _incomeUnder55 ? 0.165 : 0.132;
    // 연금저축 인정 한도: 최대 600만원
    final pensionCreditBase = _annualContributionPension.clamp(0.0, 6000000.0);
    // irp 인정 한도: 합산 최대 900만원 -> irp 단독 한도는 (900만원 - 연금저축 인정액)
    final irpLimit = 9000000.0 - pensionCreditBase;
    final irpCreditBase = _annualContributionIRP.clamp(0.0, irpLimit);
    final totalCreditBase = pensionCreditBase + irpCreditBase;
    final calculatedRefund = totalCreditBase * taxRate;

    // 추가 납입 가이드 계산
    final double remainingToMaximize = 9000000.0 - totalCreditBase;
    final double additionalRefundPossible = remainingToMaximize * taxRate;

    // 3. ISA 만기 전환 혜택 계산
    // 전환 금액의 10% (최대 300만원) 추가 세액공제
    final isaRolloverCredit = (_isaMaturityAmount * 0.1).clamp(0.0, 3000000.0);
    final isaRolloverRefund = isaRolloverCredit * taxRate;

    // 4. 은퇴 연금 수령 계산
    final annualPayout = _payoutYears > 0 ? _targetPensionTotal / _payoutYears : 0.0;
    final monthlyPayout = annualPayout / 12;
    final isPayoutSafe = annualPayout <= 15000000; // 연 1500만원 기준

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 헤더
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFF176B5B),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.savings_outlined, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '연금 & 절세 매니저',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              '절세 계좌 분석 및 환급 시뮬레이터',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 섹션 1: 절세 자산 현황
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF13584B), Color(0xFF1A7A68)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF176B5B).withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '총 절세 자산 (연금저축/IRP/ISA)',
                              style: TextStyle(color: Color(0xFFD6E8E4)),
                            ),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                formatCurrencyFull(totalTaxSavingAssets),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            if (totalAssets > 0) ...[
                              const SizedBox(height: 6),
                              Text(
                                '전체 자산 중 ${taxSavingRatio.toStringAsFixed(1)}%가 절세 계좌에서 운용 중입니다.',
                                style: const TextStyle(color: Color(0xFFB0D4CD), fontSize: 13),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Container(height: 1, color: const Color(0xFF2A8B79)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _MiniMetricTile(
                                    label: '연금저축',
                                    value: formatCurrencyFull(pensionSum),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _MiniMetricTile(
                                    label: 'IRP',
                                    value: formatCurrencyFull(irpSum),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _MiniMetricTile(
                                    label: 'ISA',
                                    value: formatCurrencyFull(isaSum),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 섹션 2: 세액공제 계산기
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '올해 세액공제 계산기',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 12),
                            // 소득 선택 토글
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('연봉(소득) 구간', style: TextStyle(fontWeight: FontWeight.w700)),
                                ToggleButtons(
                                  isSelected: [_incomeUnder55, !_incomeUnder55],
                                  onPressed: (index) {
                                    setState(() {
                                      _incomeUnder55 = index == 0;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  selectedColor: Colors.white,
                                  fillColor: Theme.of(context).colorScheme.primary,
                                  constraints: const BoxConstraints(minHeight: 36, minWidth: 100),
                                  children: const [
                                    Text('5.5천 이하\n(16.5% 공제)', style: TextStyle(fontSize: 11), textAlign: TextAlign.center),
                                    Text('5.5천 초과\n(13.2% 공제)', style: TextStyle(fontSize: 11), textAlign: TextAlign.center),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            _SliderField(
                              label: '올해 연금저축 납입 예정액',
                              helpText: '💡 연금저축계좌 꿀팁\n\n• 세액공제 한도: 연간 최대 600만 원 (급여 5,500만 원 초과 13.2%, 이하 16.5% 환급)\n• 최고 납입 한도: 연 최대 1,800만 원 (IRP와 합산)\n• 세금 이연 효과: 일반 계좌에서 배당/수익 시 15.4%를 떼지만, 연금계좌는 세금 없이 온전하게 재투자되며 나중에 5.5%로 정산합니다!',
                              valueLabel: formatCurrencyFull(_annualContributionPension),
                              value: _annualContributionPension,
                              min: 0,
                              max: 18000000,
                              divisions: 180,
                              onChanged: (v) => setState(() => _annualContributionPension = v),
                            ),
                            _SliderField(
                              label: '올해 IRP 납입 예정액',
                              helpText: '💡 IRP (개인형 퇴직연금) 꿀팁\n\n• 세액공제 한도: 연금저축(600) 외에 추가로 300만 원 납입 시 혜택! (연금저축 합산 총 900만 원 세액공제)\n• 투자 제한: 위험자산(주식형) 70%, 안전자산(채권/예금 등) 30% 투자 룰이 있습니다.\n• 혜택: 역시 수익과 배당에 대한 세금을 떼지 않고 과세가 이연됩니다.',
                              valueLabel: formatCurrencyFull(_annualContributionIRP),
                              value: _annualContributionIRP,
                              min: 0,
                              max: 18000000,
                              divisions: 180,
                              onChanged: (v) => setState(() => _annualContributionIRP = v),
                            ),
                            const SizedBox(height: 16),
                            // 환급금 결과 박스
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F6F1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE5E0D7)),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '예상 세액공제 환급금',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? Colors.grey[400] : const Color(0xFF6E675E),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    formatCurrencyFull(calculatedRefund),
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // 극대화 가이드
                                  if (remainingToMaximize > 0) ...[
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.lightbulb_outline, color: Theme.of(context).colorScheme.primary, size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '올해 IRP 계좌에 ${formatCurrencyFull(remainingToMaximize)}을 추가 납입하시면 세금 ${formatCurrencyFull(additionalRefundPossible)}을 더 돌려받을 수 있어요!',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(context).colorScheme.primary,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else ...[
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F0EA),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.check_circle_outline, color: Color(0xFF176B5B), size: 18),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '올해 세액공제 한도(₩9,000,000)를 가득 채우셨습니다! 최고의 세테크를 실천 중이시네요. 🎉',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF176B5B),
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 섹션 3: ISA 만기 연금 전환 혜택
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ISA 만기 전환 혜택',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '3년 만기된 ISA 자금을 연금계좌로 전환하면, 전환금액의 10% (최대 300만 원 한도)가 추가로 세액공제 대상에 산입됩니다.',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.grey[400] : const Color(0xFF6E675E),
                                height: 1.4,
                              ),
                            ),
                            const Divider(height: 24),
                            _SliderField(
                              label: 'ISA 만기 자금 전환 예정액',
                              helpText: '💡 ISA (개인종합자산관리계좌) 꿀팁\n\n• 비과세 혜택: 손익 통산 후 순이익 기준 200만 원 완전 비과세! 초과 수익은 9.9% 분리과세(정산 요금)로 다른 소득과 합산되지 않습니다.\n• 연금 전환: 3년 의무 가입 후 전액 현금화하여 연금계좌로 이전 가능 (연간 1,800만 원 한도를 다 채웠어도 한도 무관하게 이전됨!)\n• 추가 공제: 전환 금액의 10% (최대 300만 원) 추가 세액공제!\n• 이전 후에는 기존 ISA를 해지하고 같은 계좌로 다시 개설하여 무한 반복 운용이 가능합니다.',
                              valueLabel: formatCurrencyFull(_isaMaturityAmount),
                              value: _isaMaturityAmount,
                              min: 0,
                              max: 100000000,
                              divisions: 100,
                              onChanged: (v) => setState(() => _isaMaturityAmount = v),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _SecondaryMetricTile(
                                    label: '추가 세액공제 인정액',
                                    value: formatCurrencyFull(isaRolloverCredit),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _SecondaryMetricTile(
                                    label: '예상 추가 환급금',
                                    value: formatCurrencyFull(isaRolloverRefund),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 섹션 4: 연금 수령 전략
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '은퇴 후 연금 수령 전략',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '만 55세 이후 연금 수령 시 사적연금(연금저축+IRP) 연간 수령액이 ₩15,000,000 이하이면 낮은 연금소득세율(3.3% ~ 5.5% 분리과세)만 내고 수령할 수 있습니다.',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.grey[400] : const Color(0xFF6E675E),
                                height: 1.4,
                              ),
                            ),
                            const Divider(height: 24),
                            _SliderField(
                              label: '은퇴 시 모인 총 연금 자산',
                              helpText: '💡 55세 이후 연금 인출 꿀팁\n\n나중에 연금 수령 시 세금 로직은 "꼬리표"에 따라 다릅니다.\n1순위: 세액공제 안 받은 원금 (한도 무관 100% 비과세)\n2순위: 퇴직금 (퇴직소득세)\n3순위: 세액공제 받은 원금 + 수익 (이 3순위만 1,500만 원 한도 체크!)\n\n📌 1,500만 원 한도 오버 시:\n• 1,500만 원 이하: 15년 동안 안 내고 모아둔 \'세금 이연분\'에 대한 정산 요금(3.3~5.5%)만 납부\n• 1,500만 원 초과: 초과분은 내 근로/사업 소득과 합치지 않고, 딱 16.5%만 떼고 깔끔하게 끝나는 \'16.5% 분리과세\'를 선택할 수 있습니다!',
                              valueLabel: formatCurrencyFull(_targetPensionTotal),
                              value: _targetPensionTotal,
                              min: 0,
                              max: 1000000000,
                              divisions: 100,
                              onChanged: (v) => setState(() => _targetPensionTotal = v),
                            ),
                            _SliderField(
                              label: '희망 연금 수령 기간',
                              valueLabel: '$_payoutYears년',
                              value: _payoutYears.toDouble(),
                              min: 5,
                              max: 30,
                              divisions: 25,
                              onChanged: (v) => setState(() => _payoutYears = v.round()),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _SecondaryMetricTile(
                                    label: '예상 연간 수령액',
                                    value: formatCurrencyFull(annualPayout),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _SecondaryMetricTile(
                                    label: '예상 월 수령액',
                                    value: formatCurrencyFull(monthlyPayout),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // 연금 수령 안전도 판정 박스
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isPayoutSafe
                                    ? (isDark ? const Color(0xFF1A3D36) : const Color(0xFFE8F0EA))
                                    : (isDark ? const Color(0xFF422222) : const Color(0xFFFDF0F0)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isPayoutSafe ? Icons.check_circle : Icons.warning,
                                    color: isPayoutSafe
                                        ? (isDark ? const Color(0xFF26A68A) : const Color(0xFF176B5B))
                                        : Colors.redAccent,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      isPayoutSafe
                                          ? '연간 ₩15,000,000 이하 수령 조건 만족! 저율 연금소득세(3.3%~5.5%) 혜택 대상입니다.'
                                          : '연간 수령액이 ₩15,000,000을 초과하여 종합과세 또는 16.5% 분리과세 대상이 될 우려가 있습니다. 수령 기간을 늘려 한도를 조절하는 것을 추천합니다.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isPayoutSafe
                                            ? (isDark ? const Color(0xFF26A68A) : const Color(0xFF176B5B))
                                            : Colors.redAccent,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniMetricTile extends StatelessWidget {
  const _MiniMetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFFD6E8E4), fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondaryMetricTile extends StatelessWidget {
  const _SecondaryMetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F6F1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE5E0D7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: isDark ? Colors.grey[400] : const Color(0xFF6E675E), fontSize: 11)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 자산 비중 시각화 카드 & 도넛 차트 페인터 ─────────────────────

class _AllocationItem {
  final String label;
  final double value;
  final double percent;
  final Color color;

  _AllocationItem({
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
  });
}

class PortfolioAllocationCard extends StatefulWidget {
  const PortfolioAllocationCard({
    super.key,
    required this.holdings,
    required this.lastExchangeRate,
  });

  final List<Holding> holdings;
  final double lastExchangeRate;

  @override
  State<PortfolioAllocationCard> createState() => _PortfolioAllocationCardState();
}

class _PortfolioAllocationCardState extends State<PortfolioAllocationCard> {
  bool _showByAssetClass = true;

  @override
  Widget build(BuildContext context) {
    if (widget.holdings.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 데이터 집계
    final assetValues = <AssetType, double>{};
    final accountValues = <AccountType, double>{};

    for (final holding in widget.holdings) {
      double val = holding.quantity * holding.price;
      assetValues[holding.type] = (assetValues[holding.type] ?? 0) + val;
      accountValues[holding.account] = (accountValues[holding.account] ?? 0) + val;
    }

    final categories = <String>[];
    final values = <double>[];
    final colors = <Color>[];

    if (_showByAssetClass) {
      final types = [AssetType.koreanStock, AssetType.usStock, AssetType.etf, AssetType.cash];
      final labels = ['국내주식', '해외주식', 'ETF', '현금/기타'];
      final palette = [
        const Color(0xFF26A68A), // 국내주식
        const Color(0xFFEAA622), // 해외주식
        const Color(0xFF2A8B79), // ETF
        const Color(0xFF8E867C), // 현금/기타
      ];

      for (int i = 0; i < types.length; i++) {
        final val = assetValues[types[i]] ?? 0;
        categories.add(labels[i]);
        values.add(val);
        colors.add(palette[i]);
      }
    } else {
      final accounts = [AccountType.general, AccountType.pension, AccountType.irp, AccountType.isa];
      final labels = ['일반계좌', '연금저축', 'IRP', 'ISA'];
      final palette = [
        const Color(0xFF176B5B), // 일반계좌
        const Color(0xFFEAA622), // 연금저축
        const Color(0xFFD46A00), // IRP
        const Color(0xFF4A90E2), // ISA
      ];

      for (int i = 0; i < accounts.length; i++) {
        final val = accountValues[accounts[i]] ?? 0;
        categories.add(labels[i]);
        values.add(val);
        colors.add(palette[i]);
      }
    }

    final total = values.fold<double>(0, (sum, val) => sum + val);
    final displayData = <_AllocationItem>[];
    for (int i = 0; i < categories.length; i++) {
      if (values[i] > 0) {
        final percent = total > 0 ? (values[i] / total) * 100 : 0.0;
        displayData.add(
          _AllocationItem(
            label: categories[i],
            value: values[i],
            percent: percent,
            color: colors[i],
          ),
        );
      }
    }
    displayData.sort((a, b) => b.value.compareTo(a.value));

    final largestPercentText = displayData.isNotEmpty 
        ? '${displayData.first.percent.toStringAsFixed(0)}%' 
        : '0%';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEBE6DD),
          width: 1,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '자산 비중 분석',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                height: 32,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEFECE6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildToggleButton(
                      label: '자산군별',
                      isSelected: _showByAssetClass,
                      onTap: () => setState(() => _showByAssetClass = true),
                    ),
                    _buildToggleButton(
                      label: '계좌별',
                      isSelected: !_showByAssetClass,
                      onTap: () => setState(() => _showByAssetClass = false),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(90, 90),
                      painter: DonutChartPainter(
                        values: values,
                        colors: colors,
                        strokeWidth: 10,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _showByAssetClass ? '최대 비중' : '최대 계좌',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          largestPercentText,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: List.generate(displayData.length, (index) {
                    final item = displayData[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: item.color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.label,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '${item.percent.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.grey[300] : const Color(0xFF2C2C2C),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            formatCurrency(item.value),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF176B5B) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected && !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? (isDark ? Colors.white : const Color(0xFF176B5B))
                : (isDark ? Colors.grey[400] : const Color(0xFF6E675E)),
          ),
        ),
      ),
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final double strokeWidth;

  DonutChartPainter({
    required this.values,
    required this.colors,
    this.strokeWidth = 10.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    double total = values.fold(0, (sum, val) => sum + val);
    if (total == 0) {
      final paint = Paint()
        ..color = Colors.grey.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(center, radius, paint);
      return;
    }

    double startAngle = -1.57079632679; // Top start (-90 degrees)
    final rect = Rect.fromCircle(center: center, radius: radius);

    for (int i = 0; i < values.length; i++) {
      if (values[i] == 0) continue;
      final sweepAngle = (values[i] / total) * 6.28318530718;
      
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.colors != colors;
  }
}


class ProfileSelectionSheet extends StatefulWidget {
  final StorageService storage;
  final ValueChanged<String> onProfileSelected;
  final VoidCallback onProfileAdded;
  final VoidCallback onProfileEdited;

  const ProfileSelectionSheet({
    super.key,
    required this.storage,
    required this.onProfileSelected,
    required this.onProfileAdded,
    required this.onProfileEdited,
  });

  @override
  State<ProfileSelectionSheet> createState() => _ProfileSelectionSheetState();
}

class _ProfileSelectionSheetState extends State<ProfileSelectionSheet> {
  @override
  Widget build(BuildContext context) {
    final profiles = widget.storage.profiles;
    final activeId = widget.storage.activeProfileId;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '프로필 선택',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: profiles.length + 1,
              separatorBuilder: (context, index) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                if (index == profiles.length) {
                  return GestureDetector(
                    onTap: widget.onProfileAdded,
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, size: 30),
                        ),
                        const SizedBox(height: 8),
                        const Text('추가', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  );
                }

                final profile = profiles[index];
                final isActive = profile.id == activeId;
                final avatarAbsPath = widget.storage.getAvatarAbsolutePath(profile.avatarPath);
                final hasAvatar = avatarAbsPath != null && File(avatarAbsPath).existsSync();

                return GestureDetector(
                  onTap: () => widget.onProfileSelected(profile.id),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: isActive ? Theme.of(context).colorScheme.primary : (isDark ? Colors.grey[800] : Colors.grey[300]),
                              shape: BoxShape.circle,
                              border: isActive ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null,
                              image: hasAvatar
                                  ? DecorationImage(
                                      image: FileImage(File(avatarAbsPath)),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: !hasAvatar
                                ? Icon(
                                    Icons.person,
                                    color: isActive ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                                    size: 30,
                                  )
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: () async {
                                final edited = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => EditProfileDialog(
                                    profile: profile,
                                    storage: widget.storage,
                                  ),
                                );
                                if (edited == true && mounted) {
                                  setState(() {});
                                  widget.onProfileEdited();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.secondary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit, size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        profile.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          color: isActive ? Theme.of(context).colorScheme.primary : null,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class EditProfileDialog extends StatefulWidget {
  final Profile profile;
  final StorageService storage;

  const EditProfileDialog({super.key, required this.profile, required this.storage});

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late TextEditingController _nameController;
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _avatarPath = widget.profile.avatarPath;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
      final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
      
      setState(() {
        _avatarPath = fileName;
      });
    }
  }

  void _saveProfile() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      final profiles = widget.storage.profiles;
      final index = profiles.indexWhere((p) => p.id == widget.profile.id);
      if (index != -1) {
        profiles[index].name = name;
        profiles[index].avatarPath = _avatarPath;
        widget.storage.saveProfiles(profiles);
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarAbsPath = widget.storage.getAvatarAbsolutePath(_avatarPath);
    final hasAvatar = avatarAbsPath != null && File(avatarAbsPath).existsSync();

    return AlertDialog(
      title: const Text('프로필 편집'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
                image: hasAvatar
                    ? DecorationImage(
                        image: FileImage(File(avatarAbsPath)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: !hasAvatar
                  ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '프로필 이름',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _saveProfile,
          child: const Text('저장'),
        ),
      ],
    );
  }
}

class AddProfileDialog extends StatefulWidget {
  final StorageService storage;

  const AddProfileDialog({super.key, required this.storage});

  @override
  State<AddProfileDialog> createState() => _AddProfileDialogState();
}

class _AddProfileDialogState extends State<AddProfileDialog> {
  late TextEditingController _nameController;
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
      final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
      
      setState(() {
        _avatarPath = fileName;
      });
    }
  }

  void _addProfile() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      final profiles = widget.storage.profiles;
      final newId = DateTime.now().millisecondsSinceEpoch.toString();
      final newProfile = Profile(id: newId, name: name, avatarPath: _avatarPath);
      profiles.add(newProfile);
      widget.storage.saveProfiles(profiles);
      Navigator.pop(context, newId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarAbsPath = widget.storage.getAvatarAbsolutePath(_avatarPath);
    final hasAvatar = avatarAbsPath != null && File(avatarAbsPath).existsSync();
    
    return AlertDialog(
      title: const Text('새 프로필 추가'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
                image: hasAvatar
                    ? DecorationImage(
                        image: FileImage(File(avatarAbsPath)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: !hasAvatar
                  ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '프로필 이름',
              hintText: '예: 가족, 비상금',
            ),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _addProfile,
          child: const Text('추가'),
        ),
      ],
    );
  }
}
