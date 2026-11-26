# zmongol_kit

The shared ecosystem kit for the Zmongol app family — Stage 2, part 1 of
the ecosystem unification (one account, one backend, all platforms).
Pure local path package for now: no pub.dev, no GitHub until the user
creates the repo.

```yaml
dependencies:
  zmongol_kit:
    path: ../zmongol_kit   # adjust to the checkout location
```

See **INTEGRATION.md** for the integration snippet.

## What's inside

| Piece | Class | Talks to |
|---|---|---|
| Account client | `ZmongolAccount` | `POST /auth/apple`, `POST /auth/google`, `POST /auth/refresh`, `GET/DELETE /users/me`, `GET /entitlements` |
| Config client | `ZmongolConfig` | `GET /config/apps` (24 h on-device cache, stale cache offline) |
| Cross-promo | `ZmongolPromo`, `MoreAppsSection`, `ZmongolPromoCard` | `POST /promo/event` |
| Sign-in UI | `ZmongolSignInButtons` | — (wired to `ZmongolAccount`) |
| Strings | `ZmongolLabels` (EN defaults, `ZmongolLabels.zh()`) | — |

## Design decisions

- **The backend is the Stage 1 account service.** Default base URL is
  the Mac Mini Funnel address (`ZmongolKit.defaultBaseUrl`); every
  client takes a `baseUrl` override, so repointing the whole family to
  a domain or the Hong Kong host is a one-line change per app — no kit
  release needed.
- **Tokens**: the service's access/refresh pair lives in
  `flutter_secure_storage`. Authenticated calls attach the access token
  and, on a 401, refresh **once** and retry **once**; a failed refresh
  signs the user out locally and surfaces `ZmongolAuthException`.
- **Providers**: Apple/Google SDK calls follow the exact pattern the
  fleet apps already ship (google_sign_in 7.x `instance` API,
  sign_in_with_apple credential flow). Each host app passes its own
  Google OAuth client ID — every fleet app has its own Google Cloud
  project, and the service accepts all of them as audiences.
- **State**: `ZmongolAccount` is a `ChangeNotifier` (the fleet pattern)
  and also exposes a broadcast `states` stream of `ZmongolAuthState`
  (`signedOut` / `signedIn(user)`).
- **Catalogue models are tolerant**: unknown fields are ignored, the
  user view's camelCase and the entitlements' snake_case are both
  accepted, and Z52 strings are carried raw — the kit never renders
  Z52; host apps own that, exactly as they do today.
- **Promo discipline** (from the Stage 1 design): the occasional card
  appears at most once per 3 days, only promotes targets with a live
  link on the current platform, never the host app itself, and honours
  per-target "Don't show again" dismissals persisted on device. The
  permanent section lists every target, live or "Coming soon".
- **Testability**: HTTP (`http.Client`), token storage, key/value
  storage, the provider-token source and the clock are all injectable.
  The test suite runs against a fake HTTP layer and a fixture captured
  from the live `/config/apps` response.

## Contract notes (Stage 1, as consumed — server unchanged)

- Login/refresh return `{token, accessToken, refreshToken, tokenType,
  expiresIn, user}`; the client accepts `accessToken` or `token`.
- `GET /entitlements` wraps rows as `{"entitlements": [...]}` with
  snake_case `expires_at` / `updated_at`.
- In the live catalogue, the IME's Android link is the relative path
  `downloads/zmongol-ime-android.apk` (relative to the download
  website). `ZmongolPromo.openTarget` only launches absolute URLs, so
  that entry is treated as non-launchable from inside an app until the
  catalogue carries an absolute URL. Reported, not changed.
