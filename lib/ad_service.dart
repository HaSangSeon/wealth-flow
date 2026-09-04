import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static bool _initialized = false;

  static InterstitialAd? _interstitialAd;
  static bool _isAdLoading = false;
  static DateTime? _lastShownTime;
  static const Duration _coolDownDuration = Duration(minutes: 3);

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      debugPrint("Google Mobile Ads initialized successfully.");
      preloadInterstitialAd();
    } catch (e) {
      debugPrint("Failed to initialize Google Mobile Ads: $e");
    }
  }

  /// Returns Banner Ad Unit ID based on platform and build mode
  static String get bannerAdUnitId {
    if (kDebugMode) {
      // Debug / Emulator mode: Google Official Test Banner ID
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/6300978111';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/2934735716';
      }
    } else {
      // Release / Production mode: Real Production Ad Unit ID
      if (Platform.isAndroid) {
        return 'ca-app-pub-3702899361747571/2924840916';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/2934735716';
      }
    }
    return '';
  }

  /// Returns Interstitial Ad Unit ID based on platform and build mode
  static String get interstitialAdUnitId {
    if (kDebugMode) {
      // Debug / Emulator mode: Google Official Test Interstitial ID
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/1033173712';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/4411468910';
      }
    } else {
      // Release / Production mode: Real Production Ad Unit ID
      if (Platform.isAndroid) {
        return 'ca-app-pub-3702899361747571/6130362839';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/4411468910';
      }
    }
    return '';
  }

  /// Preload interstitial ad in the background
  static void preloadInterstitialAd() {
    if (_interstitialAd != null || _isAdLoading) return;
    final adUnitId = interstitialAdUnitId;
    if (adUnitId.isEmpty) return;

    _isAdLoading = true;
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdLoading = false;
          debugPrint("[AdService] 전면광고 사전 로드 완료.");
        },
        onAdFailedToLoad: (err) {
          _interstitialAd = null;
          _isAdLoading = false;
          debugPrint("[AdService] 전면광고 사전 로드 실패: $err");
        },
      ),
    );
  }

  /// Show interstitial ad with a 3-minute cool-down guarantee
  static void showInterstitialAd({VoidCallback? onDismissed}) {
    final now = DateTime.now();

    // 1. 쿨다운 검사 (3분 제한)
    if (_lastShownTime != null && now.difference(_lastShownTime!) < _coolDownDuration) {
      final remaining = _coolDownDuration - now.difference(_lastShownTime!);
      debugPrint("[AdService] 전면광고 쿨다운 중 (${remaining.inSeconds}초 남음). 광고 노출 스킵.");
      onDismissed?.call();
      return;
    }

    // 2. 준비된 전면광고가 없으면 사전 로드 후 스킵
    if (_interstitialAd == null) {
      debugPrint("[AdService] 준비된 전면광고가 없어 광고를 건너뛰고 사전 로드를 시작합니다.");
      preloadInterstitialAd();
      onDismissed?.call();
      return;
    }

    // 3. 광고 표시 및 콜백 등록
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        debugPrint("[AdService] 전면광고가 닫혔습니다.");
        ad.dispose();
        _interstitialAd = null;
        _lastShownTime = DateTime.now();
        preloadInterstitialAd(); // 다음 노출을 위해 백그라운드에서 사전 로드
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        debugPrint("[AdService] 전면광고 노출 실패: $err");
        ad.dispose();
        _interstitialAd = null;
        preloadInterstitialAd();
        onDismissed?.call();
      },
    );

    _interstitialAd!.show();
  }
}

/// A reusable sticky banner ad widget for bottom navigation
class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bannerAd == null) {
      _loadBannerAd();
    }
  }

  Future<void> _loadBannerAd() async {
    final adUnitId = AdService.bannerAdUnitId;
    if (adUnitId.isEmpty) return;

    final width = MediaQuery.of(context).size.width.truncate();
    final AnchoredAdaptiveBannerAdSize? size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: size ?? AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd failed to load: $err');
          ad.dispose();
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
            });
          }
        },
      ),
    );
    await _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      alignment: Alignment.center,
      width: double.infinity,
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
