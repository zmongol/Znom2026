# Verification — zmongol_kit 0.1.0

Run on the Mac Mini, Flutter 3.50.1, 26 Nov 2026.

## flutter pub get

```
Changed 88 dependencies!
```

Resolved versions follow the fleet pins: http ^1.2.2,
flutter_secure_storage ^11.2.0, google_sign_in ^7.2.0,
sign_in_with_apple ^8.2.0, url_launcher ^6.3.1,
shared_preferences ^2.3.2, flutter_lints ^6.0.0.

## flutter analyze

```
Analyzing zmongol_kit...

   info • 'package:flutter/material.dart' is deprecated and shouldn't be
   used. Use package:material_ui/material_ui.dart instead. •
   lib/src/promo.dart:3:1 • deprecated_member_use
   info • 'package:flutter/material.dart' is deprecated and shouldn't be
   used. Use package:material_ui/material_ui.dart instead. •
   lib/src/sign_in_buttons.dart:1:1 • deprecated_member_use

2 issues found. (ran in 0.9s)
```

Zero errors, zero warnings. The two remaining infos are emitted by this
SDK fork for **every** `package:flutter/material.dart` import — all
fleet apps (Zmedee, Zocr, …) import material.dart the same way and
carry the same infos, so the kit deliberately matches the fleet rather
than adding a material_ui dependency the fleet's code does not use.

## flutter test

```
00:00 +29: All tests passed!
```

29 tests: config parsing against the live `/config/apps` fixture
(11 apps, links, recommendations, Z52 passthrough), the version gate
(forced / recommended / none, numeric version comparison), the config
cache (fresh-cache no-refetch, stale-cache offline fallback), promo
selection (never self, dismissed excluded, null-link targets excluded
from the card but present in the section), dismissal persistence,
promo event sink, and the account flows (Google/Apple sign-in, session
restore, refresh-on-401 with exactly one refresh and a retry carrying
the new token, failed refresh → signed out, entitlements parsing,
account deletion, sign-out, state stream).
