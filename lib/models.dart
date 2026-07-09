import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

/// 계좌 구분
enum AccountType {
  general('일반계좌'),
  pension('연금저축'),
  irp('IRP'),
  isa('ISA');

  const AccountType(this.label);
  final String label;
}

/// 자산 분류
enum AssetType {
  koreanStock('국내주식'),
  usStock('해외주식'),
  etf('ETF'),
  cash('현금/기타');

  const AssetType(this.label);
  final String label;
}

/// 보유 자산
class Holding {
  Holding({
    required this.name,
    this.symbol,
    required this.type,
    required this.account,
    required this.quantity,
    required this.price,
    this.originalPrice,
    this.currency,
    this.dividends,
  });

  String name;
  String? symbol;
  AssetType type;
  AccountType account;
  double quantity;
  double price; // KRW 환산가
  double? originalPrice; // 현지 통화 기준 원가
  String? currency; // 통화 코드 (USD, CAD, JPY 등)
  List<Map<String, dynamic>>? dividends; // 배당 이력 [{amount: 0.25, date: 1707489000}]

  double get value => quantity * price;

  double get effectiveOriginalPrice => originalPrice ?? price;
  String get effectiveCurrency => currency ?? 'KRW';

  String formatOriginalPrice() {
    final cur = effectiveCurrency.toUpperCase();
    final p = effectiveOriginalPrice;
    
    // 이 숫자가 세 자릿수 콤마가 필요할 때 포맷팅을 돕는 로컬 함수
    String formatWithComma(double val, {int decimals = 2}) {
      final parts = val.toStringAsFixed(decimals).split('.');
      final whole = parts[0].replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
      return decimals > 0 ? '$whole.${parts[1]}' : whole;
    }

    if (cur == 'KRW') {
      // 원화는 소수점 제외
      return '₩${formatWithComma(p, decimals: 0)}';
    } else if (cur == 'USD') {
      return '\$${formatWithComma(p, decimals: 2)}';
    } else if (cur == 'CAD') {
      return 'C\$${formatWithComma(p, decimals: 2)}';
    } else if (cur == 'JPY') {
      return '¥${formatWithComma(p, decimals: 0)}';
    } else if (cur == 'EUR') {
      return '€${formatWithComma(p, decimals: 2)}';
    } else if (cur == 'GBP') {
      return '£${formatWithComma(p, decimals: 2)}';
    } else {
      return '$cur ${formatWithComma(p, decimals: 2)}';
    }
  }

  String formatOriginalValue() {
    final cur = effectiveCurrency.toUpperCase();
    final val = quantity * effectiveOriginalPrice;
    
    String formatWithComma(double v, {int decimals = 2}) {
      final parts = v.toStringAsFixed(decimals).split('.');
      final whole = parts[0].replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
      return decimals > 0 ? '$whole.${parts[1]}' : whole;
    }

    if (cur == 'KRW') {
      return '₩${formatWithComma(val, decimals: 0)}';
    } else if (cur == 'USD') {
      return '\$${formatWithComma(val, decimals: 2)}';
    } else if (cur == 'CAD') {
      return 'C\$${formatWithComma(val, decimals: 2)}';
    } else if (cur == 'JPY') {
      return '¥${formatWithComma(val, decimals: 0)}';
    } else if (cur == 'EUR') {
      return '€${formatWithComma(val, decimals: 2)}';
    } else if (cur == 'GBP') {
      return '£${formatWithComma(val, decimals: 2)}';
    } else {
      return '$cur ${formatWithComma(val, decimals: 2)}';
    }
  }

  String formatValueInKrw() {
    String formatWithComma(double v, {int decimals = 0}) {
      final parts = v.toStringAsFixed(decimals).split('.');
      final whole = parts[0].replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
      return decimals > 0 ? '$whole.${parts[1]}' : whole;
    }
    return '₩${formatWithComma(value, decimals: 0)}';
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'symbol': symbol,
        'type': type.index,
        'account': account.index,
        'quantity': quantity,
        'price': price,
        'originalPrice': originalPrice,
        'currency': currency,
        'dividends': dividends,
      };

  factory Holding.fromJson(Map<String, dynamic> json) {
    final int rawTypeIndex = json['type'] as int;
    
    AssetType type;
    AccountType account;

    if (json.containsKey('account')) {
      type = AssetType.values[rawTypeIndex];
      account = AccountType.values[json['account'] as int];
    } else {
      // 구버전 데이터 마이그레이션
      if (rawTypeIndex == 3) { // 구 pension
        type = AssetType.etf;
        account = AccountType.pension;
      } else if (rawTypeIndex == 4) { // 구 irp
        type = AssetType.etf;
        account = AccountType.irp;
      } else if (rawTypeIndex == 5) { // 구 isa
        type = AssetType.koreanStock;
        account = AccountType.isa;
      } else {
        // 구 etf(0), koreanStock(1), usStock(2)
        account = AccountType.general;
        if (rawTypeIndex == 0) {
          type = AssetType.etf;
        } else if (rawTypeIndex == 1) {
          type = AssetType.koreanStock;
        } else {
          type = AssetType.usStock;
        }
      }
    }

    return Holding(
      name: json['name'] as String,
      symbol: json['symbol'] as String?,
      type: type,
      account: account,
      quantity: (json['quantity'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      originalPrice: json.containsKey('originalPrice')
          ? (json['originalPrice'] as num?)?.toDouble()
          : null,
      currency: json['currency'] as String?,
      dividends: json['dividends'] != null 
          ? (json['dividends'] as List<dynamic>)
              .map((d) => Map<String, dynamic>.from(d as Map))
              .toList()
          : null,
    );
  }
}

/// 시뮬레이션 설정
class SimulationSettings {
  double annualReturn;
  double monthlyContribution;
  double contributionGrowth;
  int years;

  SimulationSettings({
    this.annualReturn = 7,
    this.monthlyContribution = 1000000,
    this.contributionGrowth = 3,
    this.years = 15,
  });

  Map<String, dynamic> toJson() => {
        'annualReturn': annualReturn,
        'monthlyContribution': monthlyContribution,
        'contributionGrowth': contributionGrowth,
        'years': years,
      };

  factory SimulationSettings.fromJson(Map<String, dynamic> json) =>
      SimulationSettings(
        annualReturn: (json['annualReturn'] as num).toDouble(),
        monthlyContribution: (json['monthlyContribution'] as num).toDouble(),
        contributionGrowth: (json['contributionGrowth'] as num).toDouble(),
        years: json['years'] as int,
      );
}

/// 시뮬레이션 차트 데이터 포인트
class ProjectionPoint {
  const ProjectionPoint({
    required this.year,
    required this.total,
    required this.contribution,
    required this.cumulativeContribution,
  });

  final int year;
  final double total;
  final double contribution;
  final double cumulativeContribution;
}

/// 프로필 (가족 계좌 분리)
class Profile {
  Profile({required this.id, required this.name, this.avatarPath});
  
  String id;
  String name;
  String? avatarPath;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'avatarPath': avatarPath};
  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'] as String,
    name: json['name'] as String,
    avatarPath: json['avatarPath'] as String?,
  );
}

/// Hive 기반 로컬 저장소
class StorageService {
  static const _holdingsKey = 'holdings';
  static const _settingsKey = 'simulation_settings';
  static const _onboardingKey = 'onboarding_complete';
  static const _lastSyncedKey = 'last_synced_at';
  static const _displayUsdKey = 'display_usd';
  static const _exchangeRateKey = 'last_exchange_rate';
  static const _profilesKey = 'profiles';
  static const _activeProfileIdKey = 'active_profile_id';
  static const _boxName = 'wealth_flow';

  late Box _box;
  late String documentDirPath;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    documentDirPath = (await getApplicationDocumentsDirectory()).path;
  }

  String? getAvatarAbsolutePath(String? path) {
    if (path == null) return null;
    final fileName = path.contains('/') ? path.split('/').last : path;
    return '$documentDirPath/$fileName';
  }

  /// 프로필 로드
  List<Profile> get profiles {
    final raw = _box.get(_profilesKey);
    if (raw == null) {
      return [Profile(id: 'default', name: '내 프로필')];
    }
    try {
      final list = jsonDecode(raw as String) as List<dynamic>;
      return list.map((item) => Profile.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [Profile(id: 'default', name: '내 프로필')];
    }
  }

  void saveProfiles(List<Profile> profilesList) {
    final jsonList = profilesList.map((p) => p.toJson()).toList();
    _box.put(_profilesKey, jsonEncode(jsonList));
  }

  String get activeProfileId => _box.get(_activeProfileIdKey, defaultValue: 'default') as String;
  set activeProfileId(String value) => _box.put(_activeProfileIdKey, value);

  String get _currentHoldingsKey => activeProfileId == 'default' ? _holdingsKey : '${_holdingsKey}_$activeProfileId';
  String get _currentSettingsKey => activeProfileId == 'default' ? _settingsKey : '${_settingsKey}_$activeProfileId';

  /// 모든 프로필의 총 자산 개수 조회 (프리미엄 제한용)
  int getTotalHoldingsCount() {
    int count = 0;
    for (var profile in profiles) {
      final key = profile.id == 'default' ? _holdingsKey : '${_holdingsKey}_${profile.id}';
      final raw = _box.get(key);
      if (raw != null) {
        try {
          final list = jsonDecode(raw as String) as List<dynamic>;
          count += list.length;
        } catch (_) {}
      }
    }
    return count;
  }

  /// 보유 자산 저장
  void saveHoldings(List<Holding> holdings) {
    final jsonList = holdings.map((h) => h.toJson()).toList();
    _box.put(_currentHoldingsKey, jsonEncode(jsonList));
  }

  /// 보유 자산 로드
  List<Holding> loadHoldings() {
    final raw = _box.get(_currentHoldingsKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw as String) as List<dynamic>;
      return list
          .map((item) => Holding.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 시뮬레이션 설정 저장
  void saveSettings(SimulationSettings settings) {
    _box.put(_currentSettingsKey, jsonEncode(settings.toJson()));
  }

  /// 시뮬레이션 설정 로드
  SimulationSettings loadSettings() {
    final raw = _box.get(_currentSettingsKey);
    if (raw == null) return SimulationSettings();
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      return SimulationSettings.fromJson(json);
    } catch (_) {
      return SimulationSettings();
    }
  }

  static const _isPremiumKey = 'is_premium';

  /// 온보딩 완료 여부
  bool get isOnboardingComplete => _box.get(_onboardingKey, defaultValue: false) as bool;

  set isOnboardingComplete(bool value) => _box.put(_onboardingKey, value);

  /// 프리미엄 가입 여부
  bool get isPremium => _box.get(_isPremiumKey, defaultValue: false) as bool;

  set isPremium(bool value) => _box.put(_isPremiumKey, value);

  /// 테마 모드 저장 (0: system, 1: light, 2: dark)
  int get themeMode => _box.get('theme_mode', defaultValue: 0) as int;

  set themeMode(int value) => _box.put('theme_mode', value);

  /// 마지막 동기화 시간
  DateTime? get lastSyncedAt {
    final raw = _box.get(_lastSyncedKey);
    if (raw == null) return null;
    return DateTime.parse(raw as String);
  }

  set lastSyncedAt(DateTime? value) {
    if (value == null) {
      _box.delete(_lastSyncedKey);
    } else {
      _box.put(_lastSyncedKey, value.toIso8601String());
    }
  }

  /// USD 보기 여부
  bool get displayUsd => _box.get(_displayUsdKey, defaultValue: false) as bool;

  set displayUsd(bool value) => _box.put(_displayUsdKey, value);

  /// 마지막 환율
  double get lastExchangeRate => _box.get(_exchangeRateKey, defaultValue: 1350.0) as double;

  set lastExchangeRate(double value) => _box.put(_exchangeRateKey, value);
}
