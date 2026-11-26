// Data models for the Zmongol Account service responses.
//
// Field names follow the Stage 1 service exactly: the user view is
// camelCase (`displayName`, `contributionsBySource`, `createdAt`), while
// entitlements come from the database columns (`expires_at`,
// `updated_at`). Both shapes are parsed tolerantly — unknown or missing
// fields never throw.

/// The shared Zmongol account user, as returned by the login endpoints
/// and by `GET /users/me`.
class ZmongolUser {
  final int id;

  /// "apple" or "google" — how this account was created.
  final String provider;
  final String? displayName;
  final String? email;
  final int stars;

  /// Helper / Corrector / Script Guardian, or null below 10 stars.
  final String? badge;

  /// Contribution counts and stars grouped by source app
  /// (e.g. "zmedee", "zocr").
  final Map<String, ZmongolContributionSummary> contributionsBySource;
  final String? createdAt;

  const ZmongolUser({
    required this.id,
    required this.provider,
    this.displayName,
    this.email,
    this.stars = 0,
    this.badge,
    this.contributionsBySource = const {},
    this.createdAt,
  });

  factory ZmongolUser.fromJson(Map<String, dynamic> json) {
    final bySource = <String, ZmongolContributionSummary>{};
    final raw = json['contributionsBySource'];
    if (raw is Map) {
      raw.forEach((key, value) {
        if (value is Map) {
          bySource[key.toString()] = ZmongolContributionSummary.fromJson(
              Map<String, dynamic>.from(value));
        }
      });
    }
    return ZmongolUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      provider: json['provider']?.toString() ?? '',
      displayName: json['displayName']?.toString(),
      email: json['email']?.toString(),
      stars: (json['stars'] as num?)?.toInt() ?? 0,
      badge: json['badge']?.toString(),
      contributionsBySource: bySource,
      createdAt: json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'provider': provider,
        'displayName': displayName,
        'email': email,
        'stars': stars,
        'badge': badge,
        'contributionsBySource':
            contributionsBySource.map((k, v) => MapEntry(k, v.toJson())),
        'createdAt': createdAt,
      };

  @override
  String toString() =>
      'ZmongolUser(id: $id, provider: $provider, name: $displayName, stars: $stars)';
}

/// One row of the per-source contribution summary in [ZmongolUser].
class ZmongolContributionSummary {
  final int contributions;
  final int stars;

  const ZmongolContributionSummary(
      {this.contributions = 0, this.stars = 0});

  factory ZmongolContributionSummary.fromJson(Map<String, dynamic> json) =>
      ZmongolContributionSummary(
        contributions: (json['contributions'] as num?)?.toInt() ?? 0,
        stars: (json['stars'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() =>
      {'contributions': contributions, 'stars': stars};
}

/// The token pair returned by the login and refresh endpoints.
class ZmongolSession {
  final String accessToken;
  final String? refreshToken;
  final ZmongolUser? user;

  const ZmongolSession(
      {required this.accessToken, this.refreshToken, this.user});

  factory ZmongolSession.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    return ZmongolSession(
      // The service returns both `token` and `accessToken`; accept either.
      accessToken:
          (json['accessToken'] ?? json['token'])?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString(),
      user: userJson is Map
          ? ZmongolUser.fromJson(Map<String, dynamic>.from(userJson))
          : null,
    );
  }
}

/// One Pro entitlement row from `GET /entitlements`.
class ZmongolEntitlement {
  /// Catalogue app id the entitlement belongs to (e.g. "zmongol2").
  final String app;

  /// Tier name, e.g. "pro".
  final String tier;

  /// Where the grant came from, e.g. "apple", "stripe", "manual".
  final String? source;

  /// ISO-8601 expiry, or null for a lifetime grant.
  final String? expiresAt;
  final String? updatedAt;

  const ZmongolEntitlement({
    required this.app,
    required this.tier,
    this.source,
    this.expiresAt,
    this.updatedAt,
  });

  factory ZmongolEntitlement.fromJson(Map<String, dynamic> json) =>
      ZmongolEntitlement(
        app: json['app']?.toString() ?? '',
        tier: json['tier']?.toString() ?? '',
        source: json['source']?.toString(),
        // The service exposes the raw column names; accept camelCase too.
        expiresAt:
            (json['expires_at'] ?? json['expiresAt'])?.toString(),
        updatedAt:
            (json['updated_at'] ?? json['updatedAt'])?.toString(),
      );

  /// True when the entitlement has no expiry or expires in the future.
  bool get isActive {
    final exp = expiresAt;
    if (exp == null) return true;
    final parsed = DateTime.tryParse(exp);
    return parsed == null || parsed.isAfter(DateTime.now());
  }
}
