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

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutesAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min ago',
      one: '1 min ago',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count h ago',
      one: '1 h ago',
    );
    return '$_temp0';
  }

  @override
  String get statusUpcoming => 'Upcoming';

  @override
  String get statusActive => 'Active';

  @override
  String get statusClosed => 'Closed';

  @override
  String get statusArchived => 'Archived';

  @override
  String get statusEnded => 'Ended';

  @override
  String get homeTitle => 'Your tours';

  @override
  String get inboxTitle => 'Inbox';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get homeEmptyTitle => 'No tours yet';

  @override
  String get homeEmptyBody =>
      'Create a tour for your group, or join one with a link or code from a friend.';

  @override
  String get createTour => 'Create tour';

  @override
  String get createTourShort => 'Create';

  @override
  String get joinTour => 'Join with link or code';

  @override
  String get joinTourShort => 'Join';

  @override
  String get homeSectionCurrent => 'Active & upcoming';

  @override
  String get homeSectionClosed => 'Recently closed';

  @override
  String homeSectionArchived(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archived tours',
      one: '1 archived tour',
    );
    return '$_temp0';
  }

  @override
  String memberCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String get createTourTitle => 'New tour';

  @override
  String get editTourTitle => 'Edit tour';

  @override
  String get tourNameLabel => 'Tour name';

  @override
  String get tourNameHint => 'e.g. Cox\'s Bazar weekend';

  @override
  String get tourNameRequired => 'Give the tour a name';

  @override
  String get tourDatesLabel => 'Dates';

  @override
  String get tourDatesEndBeforeStart =>
      'End date can\'t be before the start date';

  @override
  String get tourDatesTooLong => 'Tours can be at most one year long';

  @override
  String get currencyLabel => 'Currency';

  @override
  String get timeZoneLabel => 'Time zone';

  @override
  String get tourCurrencyChangeNote =>
      'Existing expenses keep their own currency. Balances are shown per currency.';

  @override
  String get tourBudgetLabel => 'Budget (optional)';

  @override
  String get tourDescriptionLabel => 'Description (optional)';

  @override
  String get tourCreated => 'Tour created';

  @override
  String get tourUpdated => 'Tour updated';

  @override
  String get joinTitle => 'Join a tour';

  @override
  String get joinIntro =>
      'Paste the invite link or enter the code you received. The host will approve your request.';

  @override
  String get joinCodeLabel => 'Invite link or code';

  @override
  String get joinPaste => 'Paste';

  @override
  String get joinFind => 'Find tour';

  @override
  String get joinInvalidCode =>
      'That doesn\'t look like an invite code. Check it and try again.';

  @override
  String get joinCodeNotFound => 'No tour found for this code.';

  @override
  String get joinCodeExpired =>
      'This invite has expired or was turned off. Ask the host for a new one.';

  @override
  String joinHostedBy(String name) {
    return 'Hosted by $name';
  }

  @override
  String get joinRequest => 'Request to join';

  @override
  String get joinRequestAgain => 'Request again';

  @override
  String get joinPending =>
      'Request sent. You\'ll get access once the host approves.';

  @override
  String get joinCancelRequest => 'Cancel request';

  @override
  String get joinRejected => 'The host declined this request.';

  @override
  String get joinTooManyAttempts =>
      'You\'ve reached the limit of join requests for this tour.';

  @override
  String get joinOpenTour => 'Open tour';
}
