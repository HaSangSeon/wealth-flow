import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wealth_flow/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late StorageService storage;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('wealth_flow_backup_test_');
    Hive.init(tempDir.path);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return tempDir.path;
      },
    );
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() async {
    storage = StorageService();
    await storage.init();
  });

  test('백업 파일 내보내기 및 복원(Restore) 무결성 테스트', () {
    // 1. 테스트용 자산 생성
    final testHoldings = [
      Holding(
        name: '삼성전자',
        symbol: '005930.KS',
        type: AssetType.koreanStock,
        account: AccountType.general,
        quantity: 50,
        price: 75000,
        originalPrice: 70000,
        currency: 'KRW',
      ),
      Holding(
        name: 'Apple',
        symbol: 'AAPL',
        type: AssetType.usStock,
        account: AccountType.pension,
        quantity: 10,
        price: 280000,
        originalPrice: 210,
        currency: 'USD',
      ),
    ];

    // 자산 및 연금 설정 저장
    storage.saveHoldings(testHoldings);
    storage.savePensionSettings(PensionTaxSettings(
      incomeUnder55: false,
      annualContributionPension: 5000000,
      annualContributionIRP: 4000000,
      isaMaturityAmount: 20000000,
      targetPensionTotal: 500000000,
      payoutYears: 25,
    ));

    // 2. JSON 백업 파일 생성
    final backupJson = storage.exportBackupJson();
    expect(backupJson.isNotEmpty, isTrue);
    expect(backupJson.contains('WealthFlow'), isTrue);
    expect(backupJson.contains('삼성전자'), isTrue);
    expect(backupJson.contains('AAPL'), isTrue);
    expect(backupJson.contains('500000000'), isTrue);

    // 3. 기존 데이터 초기화 (삭제)
    storage.saveHoldings([]);
    expect(storage.loadHoldings().isEmpty, isTrue);

    // 4. 백업 JSON 복원 실행
    final restoreSuccess = storage.importBackupJson(backupJson);
    expect(restoreSuccess, isTrue);

    // 5. 복원된 데이터 검증
    final restoredHoldings = storage.loadHoldings();
    expect(restoredHoldings.length, equals(2));
    expect(restoredHoldings[0].name, equals('삼성전자'));
    expect(restoredHoldings[0].quantity, equals(50));
    expect(restoredHoldings[1].symbol, equals('AAPL'));
    expect(restoredHoldings[1].account, equals(AccountType.pension));

    final restoredPension = storage.loadPensionSettings();
    expect(restoredPension.incomeUnder55, isFalse);
    expect(restoredPension.targetPensionTotal, equals(500000000));
    expect(restoredPension.payoutYears, equals(25));
  });

  test('잘못된 형식의 백업 파일 복원 실패 방어 테스트', () {
    expect(storage.importBackupJson(''), isFalse);
    expect(storage.importBackupJson('{ "invalid": 123 }'), isFalse);
    expect(storage.importBackupJson('not a json'), isFalse);
  });
}
