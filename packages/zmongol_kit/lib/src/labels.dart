/// Every string the kit's widgets show, in one overridable object.
///
/// Defaults are English; [ZmongolLabels.zh] provides Simplified Chinese.
/// Host apps pass their own instance to localise or reword — including
/// pairing these labels with their own Z52 rendering, which the kit
/// deliberately leaves to the host.
class ZmongolLabels {
  /// Language code the labels are in: "en" or "zh". Also selects which
  /// catalogue intro the widgets display.
  final String languageCode;

  /// Heading of the "More apps" section.
  final String moreAppsTitle;

  /// Heading of the occasional recommendation card.
  final String recommendedTitle;

  /// Affordance on a target with a live store link.
  final String getApp;

  /// Shown for a target with no link on this platform yet.
  final String comingSoon;

  /// Card action: dismiss for now (it may return after the interval).
  final String notNow;

  /// Card action: never recommend this app again.
  final String dontShowAgain;

  final String signInWithApple;
  final String signInWithGoogle;

  const ZmongolLabels({
    this.languageCode = 'en',
    this.moreAppsTitle = 'More Zmongol Apps',
    this.recommendedTitle = 'You may also like',
    this.getApp = 'Get',
    this.comingSoon = 'Coming soon',
    this.notNow = 'Not now',
    this.dontShowAgain = "Don't show again",
    this.signInWithApple = 'Sign in with Apple',
    this.signInWithGoogle = 'Sign in with Google',
  });

  /// Simplified Chinese labels.
  const ZmongolLabels.zh()
      : languageCode = 'zh',
        moreAppsTitle = '更多 Zmongol 应用',
        recommendedTitle = '为你推荐',
        getApp = '获取',
        comingSoon = '即将推出',
        notNow = '暂不',
        dontShowAgain = '不再显示',
        signInWithApple = '通过 Apple 登录',
        signInWithGoogle = '通过 Google 登录';

  ZmongolLabels copyWith({
    String? languageCode,
    String? moreAppsTitle,
    String? recommendedTitle,
    String? getApp,
    String? comingSoon,
    String? notNow,
    String? dontShowAgain,
    String? signInWithApple,
    String? signInWithGoogle,
  }) =>
      ZmongolLabels(
        languageCode: languageCode ?? this.languageCode,
        moreAppsTitle: moreAppsTitle ?? this.moreAppsTitle,
        recommendedTitle: recommendedTitle ?? this.recommendedTitle,
        getApp: getApp ?? this.getApp,
        comingSoon: comingSoon ?? this.comingSoon,
        notNow: notNow ?? this.notNow,
        dontShowAgain: dontShowAgain ?? this.dontShowAgain,
        signInWithApple: signInWithApple ?? this.signInWithApple,
        signInWithGoogle: signInWithGoogle ?? this.signInWithGoogle,
      );
}
