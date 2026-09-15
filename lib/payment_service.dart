import 'package:flutter/foundation.dart';
import 'models.dart';

class PaymentService {
  static final ValueNotifier<bool> isPremiumNotifier = ValueNotifier<bool>(true);

  static Future<void> initialize(StorageService storage) async {
    // 100% 완전 무료: 모든 프리미엄 기능을 모든 유저에게 상시 무료 개방
    storage.isPremium = true;
    isPremiumNotifier.value = true;
    debugPrint("[PaymentService] 모든 기능 100% 무료 활성화 완료.");
  }

  static Future<void> updatePremiumStatus(StorageService storage) async {
    storage.isPremium = true;
    isPremiumNotifier.value = true;
  }

  /// Initiates premium purchase (100% free app)
  static Future<bool> purchasePremium() async {
    isPremiumNotifier.value = true;
    return true;
  }

  /// Restores previous purchases (100% free app)
  static Future<bool> restorePurchases(StorageService storage) async {
    storage.isPremium = true;
    isPremiumNotifier.value = true;
    return true;
  }
}
