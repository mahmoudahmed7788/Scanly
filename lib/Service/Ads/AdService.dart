import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();

  static const String _androidInterstitialTestId =
      'ca-app-pub-3940256099942544/1033173712';

  static const String _iosInterstitialTestId =
      'ca-app-pub-3940256099942544/4411468910';

  static const String _androidRewardedTestId =
      'ca-app-pub-3940256099942544/5224354917';

  static const String _iosRewardedTestId =
      'ca-app-pub-3940256099942544/1712485313';

  static InterstitialAd? _interstitialAd;

  static RewardedAd? _rewardedAd;

  static bool _isLoadingInterstitial = false;

  static bool _isLoadingRewarded = false;

  static bool _isShowingAd = false;

  static int _interstitialActionCount = 0;

  static const int _interstitialEvery = 3;

  static Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();

      _loadInterstitial();
      _loadRewarded();
    } catch (e) {
      debugPrint(
        'AdService initialization error: $e',
      );
    }
  }

  static String get _interstitialAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _iosInterstitialTestId;
    }

    return _androidInterstitialTestId;
  }

  static String get _rewardedAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _iosRewardedTestId;
    }

    return _androidRewardedTestId;
  }

  static void _loadInterstitial() {
    if (_isLoadingInterstitial) {
      return;
    }

    if (_interstitialAd != null) {
      return;
    }

    _isLoadingInterstitial = true;

    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (
          InterstitialAd ad,
        ) {
          _isLoadingInterstitial = false;

          _interstitialAd = ad;

          debugPrint(
            'Interstitial ad loaded.',
          );
        },
        onAdFailedToLoad: (
          LoadAdError error,
        ) {
          _isLoadingInterstitial = false;

          _interstitialAd = null;

          debugPrint(
            'Interstitial ad failed to load: '
            '${error.message}',
          );
        },
      ),
    );
  }

  static Future<bool> showInterstitial({
    bool force = false,
  }) async {
    if (_isShowingAd) {
      return false;
    }

    if (!force) {
      _interstitialActionCount++;

      if (_interstitialActionCount <
          _interstitialEvery) {
        _loadInterstitial();
        return false;
      }

      _interstitialActionCount = 0;
    }

    final ad = _interstitialAd;

    if (ad == null) {
      _loadInterstitial();
      return false;
    }

    _interstitialAd = null;

    _isShowingAd = true;

    bool completed = false;

    final completion = Future<void>.delayed(
      const Duration(days: 1),
    );

    void finishAd() {
      if (completed) {
        return;
      }

      completed = true;
      _isShowingAd = false;
      _loadInterstitial();
    }

    ad.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdShowedFullScreenContent: (
        InterstitialAd ad,
      ) {
        debugPrint(
          'Interstitial ad showed.',
        );
      },
      onAdDismissedFullScreenContent: (
        InterstitialAd ad,
      ) {
        debugPrint(
          'Interstitial ad dismissed.',
        );

        ad.dispose();

        finishAd();
      },
      onAdFailedToShowFullScreenContent: (
        InterstitialAd ad,
        AdError error,
      ) {
        debugPrint(
          'Interstitial ad failed to show: '
          '${error.message}',
        );

        ad.dispose();

        finishAd();
      },
      onAdClicked: (
        InterstitialAd ad,
      ) {
        debugPrint(
          'Interstitial ad clicked.',
        );
      },
      onAdImpression: (
        InterstitialAd ad,
      ) {
        debugPrint(
          'Interstitial ad impression.',
        );
      },
    );

    try {
      ad.show();

      await Future<void>.delayed(
        const Duration(
          milliseconds: 100,
        ),
      );

      return true;
    } catch (e) {
      debugPrint(
        'Interstitial show error: $e',
      );

      ad.dispose();

      finishAd();

      return false;
    }
  }

  static Future<void> _waitForInterstitialToFinish() async {
    while (_isShowingAd) {
      await Future<void>.delayed(
        const Duration(
          milliseconds: 100,
        ),
      );
    }
  }

  static Future<bool> showInterstitialBeforeAction() async {
    final shouldShow =
        _interstitialActionCount + 1 >=
            _interstitialEvery;

    final shown = await showInterstitial();

    if (shown && shouldShow) {
      await _waitForInterstitialToFinish();
    }

    return shown;
  }

  static void _loadRewarded() {
    if (_isLoadingRewarded) {
      return;
    }

    if (_rewardedAd != null) {
      return;
    }

    _isLoadingRewarded = true;

    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback:
          RewardedAdLoadCallback(
        onAdLoaded: (
          RewardedAd ad,
        ) {
          _isLoadingRewarded = false;

          _rewardedAd = ad;

          debugPrint(
            'Rewarded ad loaded.',
          );
        },
        onAdFailedToLoad: (
          LoadAdError error,
        ) {
          _isLoadingRewarded = false;

          _rewardedAd = null;

          debugPrint(
            'Rewarded ad failed to load: '
            '${error.message}',
          );
        },
      ),
    );
  }

  static Future<bool> showRewarded() async {
    if (_isShowingAd) {
      return false;
    }

    final ad = _rewardedAd;

    if (ad == null) {
      _loadRewarded();
      return false;
    }

    _rewardedAd = null;

    _isShowingAd = true;

    bool earnedReward = false;

    ad.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdShowedFullScreenContent: (
        RewardedAd ad,
      ) {
        debugPrint(
          'Rewarded ad showed.',
        );
      },
      onAdDismissedFullScreenContent: (
        RewardedAd ad,
      ) {
        debugPrint(
          'Rewarded ad dismissed.',
        );

        ad.dispose();

        _isShowingAd = false;

        _loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (
        RewardedAd ad,
        AdError error,
      ) {
        debugPrint(
          'Rewarded ad failed to show: '
          '${error.message}',
        );

        ad.dispose();

        _isShowingAd = false;

        _loadRewarded();
      },
      onAdClicked: (
        RewardedAd ad,
      ) {
        debugPrint(
          'Rewarded ad clicked.',
        );
      },
      onAdImpression: (
        RewardedAd ad,
      ) {
        debugPrint(
          'Rewarded ad impression.',
        );
      },
    );

    try {
      ad.show(
        onUserEarnedReward: (
          AdWithoutView ad,
          RewardItem reward,
        ) {
          earnedReward = true;

          debugPrint(
            'Reward earned: '
            '${reward.amount} ${reward.type}',
          );
        },
      );

      await Future<void>.delayed(
        const Duration(
          milliseconds: 500,
        ),
      );

      return earnedReward;
    } catch (e) {
      debugPrint(
        'Rewarded show error: $e',
      );

      ad.dispose();

      _isShowingAd = false;

      _loadRewarded();

      return false;
    }
  }

  static void preload() {
    _loadInterstitial();
    _loadRewarded();
  }

  static void resetCounter() {
    _interstitialActionCount = 0;
  }

  static bool get isInterstitialReady =>
      _interstitialAd != null;

  static bool get isRewardedReady =>
      _rewardedAd != null;

  static bool get isShowingAd =>
      _isShowingAd;
}
