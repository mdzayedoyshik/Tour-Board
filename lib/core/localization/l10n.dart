import 'package:flutter/widgets.dart';

import '../../l10n/gen/app_localizations.dart';

export '../../l10n/gen/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// Current locale tag (e.g. "en_US") for intl formatting.
  String get localeTag => Localizations.localeOf(this).toString();
}
