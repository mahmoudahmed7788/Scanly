import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();

  // ============================================================
  // TEST AD UNIT IDS
  // ============================================================
  //
  // IMPORTANT:
  // These are Google test IDs.
  // Replace them with your real AdMob IDs before release.
  //

  static const String _androidInterstitialTestId =
      'ca-app-pub-3940256099942544/1033173712';

  static const String _iosInterstitialTestId =
      'ca-app-pub-3940256099942544/4411468910';

  static const String _androidRewardedTestId =
      'ca-app-pub-3940256099942544/5224354917';

  static const String _iosRewardedTestId =
      'ca-app-pub-3940256099942544/1712485313';

  // ============================================================
  // ADS
  // ============================================================

  static InterstitialAd? _interstitialAd;

  static RewardedAd? _rewardedAd;

  // ============================================================
  // STATE
  // ============================================================

  static bool _isLoadingInterstitial = false;

  static bool _isLoadingRewarded = false;

  static bool _isShowingAd = false;

  // ============================================================
  // INTERSTITIAL COUNTER
  // ============================================================
  //
  // We don't show an interstitial after every action.
  //
  // Example:
  // Every 3 eligible actions.
  //

  static int _interstitialActionCount = 0;

  static const int _interstitialEvery =
      3;

  // ============================================================
  // INITIALIZE
  // ============================================================

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

  // ============================================================
  // INTERSTITIAL AD UNIT
  // ============================================================

  static String get _interstitialAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _iosInterstitialTestId;
    }

    return _androidInterstitialTestId;
  }

  // ============================================================
  // REWARDED AD UNIT
  // ============================================================

  static String get _rewardedAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _iosRewardedTestId;
    }

    return _androidRewardedTestId;
  }

  // ============================================================
  // LOAD INTERSTITIAL
  // ============================================================

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
      adLoadCallback:
          InterstitialAdLoadCallback(
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

  // ============================================================
  // SHOW INTERSTITIAL
  // ============================================================

  static Future<bool> showInterstitial({
    bool force = false,
  }) async {
    if (_isShowingAd) {
      return false;
    }

    /*
     * If force is false:
     *
     * We count eligible actions.
     * The ad only appears every few actions.
     */

    if (!force) {
      _interstitialActionCount++;

      if (
          _interstitialActionCount <
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

    bool dismissed = false;

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

        _isShowingAd = false;

        _loadInterstitial();

        dismissed = true;
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

        _isShowingAd = false;

        _loadInterstitial();
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

      /*
       * Give the ad lifecycle callbacks a chance
       * to run before returning.
       */

      await Future<void>.delayed(
        const Duration(
          milliseconds: 300,
        ),
      );

      return true;
    } catch (e) {
      debugPrint(
        'Interstitial show error: $e',
      );

      ad.dispose();

      _isShowingAd = false;

      _loadInterstitial();

      return false;
    }
  }

  // ============================================================
  // LOAD REWARDED
  // ============================================================

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

  // ============================================================
  // REWARDED AD
  // ============================================================
  //
  // Returns:
  //
  // true  = user earned the reward
  // false = user did not earn it / ad unavailable
  //

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

  // ============================================================
  // PRELOAD
  // ============================================================

  static void preload() {
    _loadInterstitial();
    _loadRewarded();
  }

  // ============================================================
  // RESET
  // ============================================================

  static void resetCounter() {
    _interstitialActionCount = 0;
  }

  // ============================================================
  // STATUS
  // ============================================================

  static bool get isInterstitialReady =>
      _interstitialAd != null;

  static bool get isRewardedReady =>
      _rewardedAd != null;

  static bool get isShowingAd =>
      _isShowingAd;
}