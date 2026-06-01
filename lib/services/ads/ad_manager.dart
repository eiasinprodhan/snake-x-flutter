import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/constants/app_constants.dart';
import 'package:flutter/material.dart';

class AdManager {
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  // Load Banner Ad
  BannerAd? loadBannerAd() {
    if (kIsWeb) return null; // Ads not supported on web
    if (_bannerAd != null) return _bannerAd;
    
    _bannerAd = BannerAd(
      adUnitId: AppConstants.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAd = null;
          debugPrint('BannerAd failed to load: $error');
        },
      ),
    )..load();
    return _bannerAd;
  }

  // Preload Interstitial Ad
  void preloadInterstitial() {
    if (kIsWeb) return; // Ads not supported on web
    InterstitialAd.load(
      adUnitId: AppConstants.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (error) => debugPrint('InterstitialAd failed to load: $error'),
      ),
    );
  }

  void showInterstitial(Function onComplete) {
    if (kIsWeb) {
      onComplete();
      return;
    }
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          preloadInterstitial();
          onComplete();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          preloadInterstitial();
          onComplete();
        },
      );
      _interstitialAd!.show();
    } else {
      preloadInterstitial();
      onComplete();
    }
  }

  // Preload Rewarded Ad
  void preloadRewarded() {
    if (kIsWeb) return; // Ads not supported on web
    RewardedAd.load(
      adUnitId: AppConstants.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (error) => debugPrint('RewardedAd failed to load: $error'),
      ),
    );
  }

  void showRewardedAd(Function onRewardEarned, Function onAdClosed) {
    if (kIsWeb) {
      onAdClosed();
      return;
    }
    if (_rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          preloadRewarded();
          onAdClosed();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          preloadRewarded();
          onAdClosed();
        },
      );
      _rewardedAd!.show(onUserEarnedReward: (_, reward) {
        onRewardEarned();
      });
    } else {
      preloadRewarded();
      onAdClosed();
    }
  }

  void disposeBanner() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }
}
