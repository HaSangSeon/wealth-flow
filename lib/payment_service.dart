import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'models.dart';

class PaymentService {
  // TODO: Replace with the actual API Key generated in the RevenueCat console
  static const String _googleApiKey = "goog_placeholder"; 
  static const String _iosApiKey = "appl_placeholder"; 

  static final ValueNotifier<bool> isPremiumNotifier = ValueNotifier<bool>(false);

  static Future<void> initialize(StorageService storage) async {
    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration? configuration;
    if (Platform.isAndroid) {
      configuration = PurchasesConfiguration(_googleApiKey);
    } else if (Platform.isIOS) {
      configuration = PurchasesConfiguration(_iosApiKey);
    }

    if (configuration != null) {
      await Purchases.configure(configuration);
    }

    // Check current entitlement status and sync
    await updatePremiumStatus(storage);

    // Listen to customer info changes (such as purchase completed, refunded, expired)
    Purchases.addCustomerInfoUpdateListener((customerInfo) {
      _syncPremiumStatus(customerInfo, storage);
    });
  }

  static Future<void> updatePremiumStatus(StorageService storage) async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      _syncPremiumStatus(customerInfo, storage);
    } catch (e) {
      debugPrint("Failed to get CustomerInfo: $e");
    }
  }

  static void _syncPremiumStatus(CustomerInfo customerInfo, StorageService storage) {
    // We check if the user has an active entitlement with the identifier 'premium'
    final isPremium = customerInfo.entitlements.all["premium"]?.isActive ?? false;
    storage.isPremium = isPremium;
    isPremiumNotifier.value = isPremium;
    debugPrint("Premium status synced: $isPremium");
  }

  /// Initiates the lifetime premium purchase
  static Future<bool> purchasePremium() async {
    try {
      Offerings offerings = await Purchases.getOfferings();
      if (offerings.current != null && offerings.current!.lifetime != null) {
        // ignore: deprecated_member_use
        PurchaseResult purchaseResult = await Purchases.purchasePackage(offerings.current!.lifetime!);
        final isPremium = purchaseResult.customerInfo.entitlements.all["premium"]?.isActive ?? false;
        isPremiumNotifier.value = isPremium;
        return isPremium;
      } else {
        debugPrint("No current lifetime package found");
        return false;
      }
    } catch (e) {
      debugPrint("Purchase failed: $e");
      return false;
    }
  }

  /// Restores previous purchases (e.g., if user reinstalls the app)
  static Future<bool> restorePurchases(StorageService storage) async {
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      _syncPremiumStatus(customerInfo, storage);
      return isPremiumNotifier.value;
    } catch (e) {
      debugPrint("Restore failed: $e");
      return false;
    }
  }
}
