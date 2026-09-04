import 'dart:convert';
import 'dart:math' as math;
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
  double targetAmount;
  int targetYears;

  SimulationSettings({
    this.annualReturn = 7,
    this.monthlyContribution = 1000000,
    this.contributionGrowth = 3,
    this.years = 15,
    this.targetAmount = 1000000000.0,
    this.targetYears = 15,
  });

  Map<String, dynamic> toJson() => {
        'annualReturn': annualReturn,
        'monthlyContribution': monthlyContribution,
        'contributionGrowth': contributionGrowth,
        'years': years,
        'targetAmount': targetAmount,
        'targetYears': targetYears,
      };

  factory SimulationSettings.fromJson(Map<String, dynamic> json) =>
      SimulationSettings(
        annualReturn: (json['annualReturn'] as num?)?.toDouble() ?? 7.0,
        monthlyContribution: (json['monthlyContribution'] as num?)?.toDouble() ?? 1000000.0,
        contributionGrowth: (json['contributionGrowth'] as num?)?.toDouble() ?? 3.0,
        years: json['years'] as int? ?? 15,
        targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 1000000000.0,
        targetYears: json['targetYears'] as int? ?? 15,
      );
}

/// 연금 및 절세 계산기 설정
class PensionTaxSettings {
  bool incomeUnder55;
  double annualContributionPension;
  double annualContributionIRP;
  double isaMaturityAmount;
  double targetPensionTotal;
  int payoutYears;

  PensionTaxSettings({
    this.incomeUnder55 = true,
    this.annualContributionPension = 6000000.0,
    this.annualContributionIRP = 3000000.0,
    this.isaMaturityAmount = 30000000.0,
    this.targetPensionTotal = 300000000.0,
    this.payoutYears = 20,
  });

  Map<String, dynamic> toJson() => {
    'incomeUnder55': incomeUnder55,
    'annualContributionPension': annualContributionPension,
    'annualContributionIRP': annualContributionIRP,
    'isaMaturityAmount': isaMaturityAmount,
    'targetPensionTotal': targetPensionTotal,
    'payoutYears': payoutYears,
  };

  factory PensionTaxSettings.fromJson(Map<String, dynamic> json) => PensionTaxSettings(
    incomeUnder55: json['incomeUnder55'] as bool? ?? true,
    annualContributionPension: (json['annualContributionPension'] as num?)?.toDouble() ?? 6000000.0,
    annualContributionIRP: (json['annualContributionIRP'] as num?)?.toDouble() ?? 3000000.0,
    isaMaturityAmount: (json['isaMaturityAmount'] as num?)?.toDouble() ?? 30000000.0,
    targetPensionTotal: (json['targetPensionTotal'] as num?)?.toDouble() ?? 300000000.0,
    payoutYears: json['payoutYears'] as int? ?? 20,
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

/// 월 적립식 복리 계산을 수행하여 연도별 자산 추이를 산출하는 표준 금융 함수
List<ProjectionPoint> calculateProjectionPoints({
  required double initialAsset,
  required double monthlyContribution,
  required double annualReturnPercent,
  required double contributionGrowthPercent,
  required int years,
}) {
  var total = initialAsset;
  var monthly = monthlyContribution;
  var cumulativeContrib = 0.0;
  final points = <ProjectionPoint>[
    ProjectionPoint(
      year: 0,
      total: total,
      contribution: 0,
      cumulativeContribution: 0,
    ),
  ];

  final r = annualReturnPercent / 100.0;
  // 월 실효 수익률 rm = (1 + r)^(1/12) - 1
  // 음수 수익률 대비: 1 + r > 0 인 경우 거듭제곱 사용, 아닐 경우 r / 12
  final monthlyRate = (1.0 + r > 0)
      ? (math.pow(1.0 + r, 1.0 / 12.0).toDouble() - 1.0)
      : (r / 12.0);

  for (var year = 1; year <= years; year++) {
    final annualContribution = monthly * 12.0;
    cumulativeContrib += annualContribution;

    if (annualReturnPercent == 0) {
      total += annualContribution;
    } else {
      // 12개월 동안 매월 초 적립 + 월복리 운용
      for (var m = 0; m < 12; m++) {
        total = (total + monthly) * (1.0 + monthlyRate);
      }
    }

    points.add(
      ProjectionPoint(
        year: year,
        total: total,
        contribution: annualContribution,
        cumulativeContribution: cumulativeContrib,
      ),
    );

    monthly *= (1.0 + contributionGrowthPercent / 100.0);
  }

  return points;
}

/// N년 후 최종 미래 자산 단일값 계산 (은퇴·목표 플래너 및 AI 조언 역산용)
double calculateCompoundFutureValue({
  required double initialAsset,
  required double monthlyContribution,
  required double annualReturnPercent,
  required double contributionGrowthPercent,
  required int years,
}) {
  if (years <= 0) return initialAsset;
  final points = calculateProjectionPoints(
    initialAsset: initialAsset,
    monthlyContribution: monthlyContribution,
    annualReturnPercent: annualReturnPercent,
    contributionGrowthPercent: contributionGrowthPercent,
    years: years,
  );
  return points.last.total;
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
  static const _pensionSettingsKey = 'pension_tax_settings';
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
  String get _currentPensionSettingsKey => activeProfileId == 'default' ? _pensionSettingsKey : '${_pensionSettingsKey}_$activeProfileId';

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

  /// 연금 및 절세 설정 저장
  void savePensionSettings(PensionTaxSettings settings) {
    _box.put(_currentPensionSettingsKey, jsonEncode(settings.toJson()));
  }

  /// 연금 및 절세 설정 로드
  PensionTaxSettings loadPensionSettings() {
    final raw = _box.get(_currentPensionSettingsKey);
    if (raw == null) return PensionTaxSettings();
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      return PensionTaxSettings.fromJson(json);
    } catch (_) {
      return PensionTaxSettings();
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

  static const _stockAlertEnabledKey = 'stock_alert_enabled';
  static const _stockAlertThresholdKey = 'stock_alert_threshold';

  /// 보유 종목 급등/급락 알림 활성화 여부
  bool get stockAlertEnabled => _box.get(_stockAlertEnabledKey, defaultValue: true) as bool;

  set stockAlertEnabled(bool value) => _box.put(_stockAlertEnabledKey, value);

  /// 급등/급락 기준 퍼센트 (기본 5%)
  double get stockAlertThreshold => (_box.get(_stockAlertThresholdKey, defaultValue: 5.0) as num).toDouble();

  set stockAlertThreshold(double value) => _box.put(_stockAlertThresholdKey, value);

  /// 특정 종목에 오늘 이미 알림을 보냈는지 확인 (종목당 하루 1회 제한)
  bool isAlertSentToday(String symbol, String dateStr) {
    final key = 'alert_sent_${symbol}_$dateStr';
    return _box.get(key, defaultValue: false) as bool;
  }

  /// 특정 종목에 오늘 알림을 보냈음을 기록
  Future<void> markAlertSent(String symbol, String dateStr) async {
    final key = 'alert_sent_${symbol}_$dateStr';
    await _box.put(key, true);
  }

  /// 전체 자산 및 설정 데이터를 JSON 문자열로 백업 생성
  String exportBackupJson() {
    final Map<String, dynamic> backupData = {
      'app': 'WealthFlow',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'profiles': profiles.map((p) => p.toJson()).toList(),
      'activeProfileId': activeProfileId,
      'profileData': <String, dynamic>{},
    };

    final profileDataMap = <String, dynamic>{};
    for (var profile in profiles) {
      final hKey = profile.id == 'default' ? _holdingsKey : '${_holdingsKey}_${profile.id}';
      final sKey = profile.id == 'default' ? _settingsKey : '${_settingsKey}_${profile.id}';
      final pKey = profile.id == 'default' ? _pensionSettingsKey : '${_pensionSettingsKey}_${profile.id}';

      final holdingsRaw = _box.get(hKey);
      final settingsRaw = _box.get(sKey);
      final pensionRaw = _box.get(pKey);

      profileDataMap[profile.id] = {
        'holdings': holdingsRaw != null ? jsonDecode(holdingsRaw as String) : [],
        'simulationSettings': settingsRaw != null ? jsonDecode(settingsRaw as String) : null,
        'pensionSettings': pensionRaw != null ? jsonDecode(pensionRaw as String) : null,
      };
    }
    backupData['profileData'] = profileDataMap;

    return const JsonEncoder.withIndent('  ').convert(backupData);
  }

  /// 백업 JSON 문자열을 검증하고 복원
  bool importBackupJson(String jsonStr) {
    try {
      final dynamic decoded = jsonDecode(jsonStr);
      if (decoded is! Map<String, dynamic>) return false;
      if (decoded['app'] != 'WealthFlow' && !decoded.containsKey('profileData') && !decoded.containsKey('holdings')) {
        return false;
      }

      // 1. 프로필 목록 복원
      if (decoded.containsKey('profiles') && decoded['profiles'] is List) {
        final profileList = (decoded['profiles'] as List)
            .map((item) => Profile.fromJson(item as Map<String, dynamic>))
            .toList();
        if (profileList.isNotEmpty) {
          saveProfiles(profileList);
        }
      }

      if (decoded.containsKey('activeProfileId') && decoded['activeProfileId'] is String) {
        activeProfileId = decoded['activeProfileId'] as String;
      }

      // 2. 프로필별 데이터 복원
      if (decoded.containsKey('profileData') && decoded['profileData'] is Map) {
        final profileData = decoded['profileData'] as Map<String, dynamic>;
        profileData.forEach((profileId, data) {
          if (data is Map<String, dynamic>) {
            final hKey = profileId == 'default' ? _holdingsKey : '${_holdingsKey}_$profileId';
            final sKey = profileId == 'default' ? _settingsKey : '${_settingsKey}_$profileId';
            final pKey = profileId == 'default' ? _pensionSettingsKey : '${_pensionSettingsKey}_$profileId';

            if (data['holdings'] != null) {
              _box.put(hKey, jsonEncode(data['holdings']));
            }
            if (data['simulationSettings'] != null) {
              _box.put(sKey, jsonEncode(data['simulationSettings']));
            }
            if (data['pensionSettings'] != null) {
              _box.put(pKey, jsonEncode(data['pensionSettings']));
            }
          }
        });
      } else if (decoded.containsKey('holdings')) {
        _box.put(_currentHoldingsKey, jsonEncode(decoded['holdings']));
      }

      return true;
    } catch (_) {
      return false;
    }
  }
}
