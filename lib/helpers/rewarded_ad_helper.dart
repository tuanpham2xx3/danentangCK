import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardedAdHelper {
  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  /// Hàm tải và hiển thị quảng cáo, sau đó gọi `onRewarded` khi người dùng xem xong
  Future<void> loadAd(Function onRewarded) async {
    if (_isLoading) return;
    _isLoading = true;

    await RewardedAd.load(
      adUnitId: _testAdUnitId(),
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _isLoading = false;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _rewardedAd = null;
            },
          );

          ad.show(
            onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
              onRewarded(); // Gọi callback khi xem xong
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isLoading = false;
          print('❌ Không tải được quảng cáo nhận thưởng: $error');
        },
      ),
    );
  }

  /// Dùng ID test của Google
  String _testAdUnitId() {
    return 'ca-app-pub-3940256099942544/5224354917'; // Android
    // return 'ca-app-pub-3940256099942544/1712485313'; // iOS nếu cần
  }
}
