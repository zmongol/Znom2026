# Integrating zmongol_kit

The whole integration is three objects created once, plus one widget
per surface. Replace `'zchat'` with your app's catalogue id
(`zmongol2`, `mongolian`, `znom`, `ime`, `zcag`, `zconvert`, `zlingo`,
`zchat`, `zmedee`, `zocr`, `zbook`).

## 1. Create the clients (main, before runApp)

```dart
final account = ZmongolAccount(
  appId: 'zchat',
  googleClientId: '<this app\'s Google OAuth client ID>',
  // baseUrl: 'https://<future domain>/account',  // repoint here only
);
final config = ZmongolConfig();
final promo = ZmongolPromo(config: config, account: account);

await account.restore();    // revive any saved session
await config.catalogue();   // warm the catalogue cache (24 h)
```

## 2. Sign-in buttons (account sheet / settings)

```dart
ZmongolSignInButtons(account: account)   // Apple + Google, EN labels
ZmongolSignInButtons(account: account, labels: const ZmongolLabels.zh())
```

Signed-in state: listen to `account` (ChangeNotifier) or
`account.states`; the user is `account.user`. Sign out with
`account.signOut()`; account deletion with `account.deleteAccount()`.

## 3. "More Zmongol apps" section (Settings / About / home shelf)

```dart
FutureBuilder(
  future: promo.sectionTargets('zchat'),
  builder: (_, snap) => !snap.hasData
      ? const SizedBox.shrink()
      : MoreAppsSection(
          targets: snap.data!,
          platform: zmongolCurrentPlatform(),
          onTargetTap: (e) => promo.openTarget('zchat', e),
        ),
)
```

## 4. The occasional recommendation card

Call once, after the first frame has settled (never during a task):

```dart
promo.maybeShowPromoCard(context, currentAppId: 'zchat');
```

Caps itself to one card per 3 days, live links only, and remembers
"Don't show again" per target.

## 5. Version gate and entitlements

```dart
final gate = await config.updateRequired(
    'zchat', zmongolCurrentPlatform(), '1.0.0');  // this build's version
if (gate == ZmongolUpdateStatus.forced) { /* block + store link */ }

final me = await account.currentUser();           // cached; forceRefresh to re-read
final proApps = await account.entitlements();     // paid anywhere, honoured everywhere
```

## Notes

- **Repointing**: pass `baseUrl:` to any client to move the whole
  family to a new host — nothing else changes.
- **Z52**: catalogue intros expose `intro.z52` raw via
  `ZmongolLocalizedText`; render them with the app's own Z52 widgets
  when needed. Widget labels come from `ZmongolLabels` — override any
  of them per app.
- **Errors**: a dead session surfaces as `ZmongolAuthException` after
  one refresh attempt; other service failures are
  `ZmongolApiException` with the status code attached.
