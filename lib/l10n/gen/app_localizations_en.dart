// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Tour Board';

  @override
  String get tagline => 'Plan together. Spend clearly. Travel better.';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonDone => 'Done';

  @override
  String get commonClose => 'Close';

  @override
  String get commonBack => 'Back';

  @override
  String get commonNext => 'Next';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonShare => 'Share';

  @override
  String get commonCopied => 'Copied';

  @override
  String get commonLoadMore => 'Load more';

  @override
  String get commonOptional => 'Optional';

  @override
  String get commonNone => 'None';

  @override
  String get commonYou => 'You';

  @override
  String get commonUnknownMember => 'Former member';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonOk => 'OK';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNetwork =>
      'Can\'t reach the server. Check your connection and try again.';

  @override
  String get errorPermission => 'You don\'t have access to this.';

  @override
  String get errorNotFound => 'This item no longer exists.';

  @override
  String get errorConflict =>
      'Someone else changed this at the same time. Reload and try again.';

  @override
  String get errorCancelled => 'Cancelled.';

  @override
  String get errorQuota => 'The app is busy right now. Please try again later.';

  @override
  String get errorInvalid =>
      'Some details aren\'t valid. Please check and try again.';

  @override
  String get stateOfflineCached => 'Offline — showing saved data';

  @override
  String get statePendingSync => 'Pending sync';

  @override
  String get stateSavedOffline =>
      'Saved on this device. It will sync when you\'re back online.';

  @override
  String get stateAccessRevoked => 'You\'re no longer a member of this tour.';

  @override
  String get stateAccessRevokedBody =>
      'Your access was removed or you left. Past records stay with the group.';

  @override
  String stateStale(String time) {
    return 'Last updated $time';
  }

  @override
  String get stateEdited => 'Edited';

  @override
  String get stateDeleted => 'Deleted';

  @override
  String get amountLabel => 'Amount';

  @override
  String get amountRequired => 'Enter an amount';

  @override
  String get amountInvalid => 'Enter a valid number';

  @override
  String amountTooManyDecimals(int digits) {
    return 'Use at most $digits decimal places';
  }

  @override
  String get amountMustBePositive => 'Amount must be more than zero';

  @override
  String get amountTooLarge => 'Amount is too large';

  @override
  String get signInWithGoogle => 'Continue with Google';

  @override
  String get privacyNote =>
      'Your tours are shared only with people who are members.';

  @override
  String get signInErrorNetwork =>
      'You\'re offline. Connect to the internet to sign in.';

  @override
  String get signInErrorConfig =>
      'Google sign-in isn\'t set up for this build yet. Enable it in Firebase and re-run `flutterfire configure`.';

  @override
  String get signInErrorGeneric => 'Couldn\'t sign in. Please try again.';

  @override
  String get configErrorTitle => 'Setup needed';

  @override
  String get configErrorBody =>
      'Firebase isn\'t configured for this build yet. Run `flutterfire configure` as described in README.md, then rebuild the app.';
}
