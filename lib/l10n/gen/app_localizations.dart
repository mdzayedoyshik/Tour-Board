import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'Tour Board'**
  String get appTitle;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Plan together. Spend clearly. Travel better.'**
  String get tagline;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonRetry;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// No description provided for @commonCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get commonCopy;

  /// No description provided for @commonShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get commonShare;

  /// No description provided for @commonCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get commonCopied;

  /// No description provided for @commonLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get commonLoadMore;

  /// No description provided for @commonOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get commonOptional;

  /// No description provided for @commonNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get commonNone;

  /// No description provided for @commonYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get commonYou;

  /// No description provided for @commonUnknownMember.
  ///
  /// In en, this message translates to:
  /// **'Former member'**
  String get commonUnknownMember;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @commonClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the server. Check your connection and try again.'**
  String get errorNetwork;

  /// No description provided for @errorPermission.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have access to this.'**
  String get errorPermission;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'This item no longer exists.'**
  String get errorNotFound;

  /// No description provided for @errorConflict.
  ///
  /// In en, this message translates to:
  /// **'Someone else changed this at the same time. Reload and try again.'**
  String get errorConflict;

  /// No description provided for @errorCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled.'**
  String get errorCancelled;

  /// No description provided for @errorQuota.
  ///
  /// In en, this message translates to:
  /// **'The app is busy right now. Please try again later.'**
  String get errorQuota;

  /// No description provided for @errorInvalid.
  ///
  /// In en, this message translates to:
  /// **'Some details aren\'t valid. Please check and try again.'**
  String get errorInvalid;

  /// No description provided for @stateOfflineCached.
  ///
  /// In en, this message translates to:
  /// **'Offline — showing saved data'**
  String get stateOfflineCached;

  /// No description provided for @statePendingSync.
  ///
  /// In en, this message translates to:
  /// **'Pending sync'**
  String get statePendingSync;

  /// No description provided for @stateSavedOffline.
  ///
  /// In en, this message translates to:
  /// **'Saved on this device. It will sync when you\'re back online.'**
  String get stateSavedOffline;

  /// No description provided for @stateAccessRevoked.
  ///
  /// In en, this message translates to:
  /// **'You\'re no longer a member of this tour.'**
  String get stateAccessRevoked;

  /// No description provided for @stateAccessRevokedBody.
  ///
  /// In en, this message translates to:
  /// **'Your access was removed or you left. Past records stay with the group.'**
  String get stateAccessRevokedBody;

  /// No description provided for @stateStale.
  ///
  /// In en, this message translates to:
  /// **'Last updated {time}'**
  String stateStale(String time);

  /// No description provided for @stateEdited.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get stateEdited;

  /// No description provided for @stateDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get stateDeleted;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @amountRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount'**
  String get amountRequired;

  /// No description provided for @amountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get amountInvalid;

  /// No description provided for @amountTooManyDecimals.
  ///
  /// In en, this message translates to:
  /// **'Use at most {digits} decimal places'**
  String amountTooManyDecimals(int digits);

  /// No description provided for @amountMustBePositive.
  ///
  /// In en, this message translates to:
  /// **'Amount must be more than zero'**
  String get amountMustBePositive;

  /// No description provided for @amountTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Amount is too large'**
  String get amountTooLarge;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get signInWithGoogle;

  /// No description provided for @privacyNote.
  ///
  /// In en, this message translates to:
  /// **'Your tours are shared only with people who are members.'**
  String get privacyNote;

  /// No description provided for @signInErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Connect to the internet to sign in.'**
  String get signInErrorNetwork;

  /// No description provided for @signInErrorConfig.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in isn\'t set up for this build yet. Enable it in Firebase and re-run `flutterfire configure`.'**
  String get signInErrorConfig;

  /// No description provided for @signInErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sign in. Please try again.'**
  String get signInErrorGeneric;

  /// No description provided for @configErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Setup needed'**
  String get configErrorTitle;

  /// No description provided for @configErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Firebase isn\'t configured for this build yet. Run `flutterfire configure` as described in README.md, then rebuild the app.'**
  String get configErrorBody;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 min ago} other{{count} min ago}}'**
  String timeMinutesAgo(num count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 h ago} other{{count} h ago}}'**
  String timeHoursAgo(num count);

  /// No description provided for @statusUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get statusUpcoming;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get statusClosed;

  /// No description provided for @statusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get statusArchived;

  /// No description provided for @statusEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get statusEnded;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your tours'**
  String get homeTitle;

  /// No description provided for @inboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get inboxTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No tours yet'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Create a tour for your group, or join one with a link or code from a friend.'**
  String get homeEmptyBody;

  /// No description provided for @createTour.
  ///
  /// In en, this message translates to:
  /// **'Create tour'**
  String get createTour;

  /// No description provided for @createTourShort.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createTourShort;

  /// No description provided for @joinTour.
  ///
  /// In en, this message translates to:
  /// **'Join with link or code'**
  String get joinTour;

  /// No description provided for @joinTourShort.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get joinTourShort;

  /// No description provided for @homeSectionCurrent.
  ///
  /// In en, this message translates to:
  /// **'Active & upcoming'**
  String get homeSectionCurrent;

  /// No description provided for @homeSectionClosed.
  ///
  /// In en, this message translates to:
  /// **'Recently closed'**
  String get homeSectionClosed;

  /// No description provided for @homeSectionArchived.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 archived tour} other{{count} archived tours}}'**
  String homeSectionArchived(num count);

  /// No description provided for @memberCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String memberCount(num count);

  /// No description provided for @createTourTitle.
  ///
  /// In en, this message translates to:
  /// **'New tour'**
  String get createTourTitle;

  /// No description provided for @editTourTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit tour'**
  String get editTourTitle;

  /// No description provided for @tourNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Tour name'**
  String get tourNameLabel;

  /// No description provided for @tourNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Cox\'s Bazar weekend'**
  String get tourNameHint;

  /// No description provided for @tourNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Give the tour a name'**
  String get tourNameRequired;

  /// No description provided for @tourDatesLabel.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get tourDatesLabel;

  /// No description provided for @tourDatesEndBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'End date can\'t be before the start date'**
  String get tourDatesEndBeforeStart;

  /// No description provided for @tourDatesTooLong.
  ///
  /// In en, this message translates to:
  /// **'Tours can be at most one year long'**
  String get tourDatesTooLong;

  /// No description provided for @currencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencyLabel;

  /// No description provided for @timeZoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get timeZoneLabel;

  /// No description provided for @tourCurrencyChangeNote.
  ///
  /// In en, this message translates to:
  /// **'Existing expenses keep their own currency. Balances are shown per currency.'**
  String get tourCurrencyChangeNote;

  /// No description provided for @tourBudgetLabel.
  ///
  /// In en, this message translates to:
  /// **'Budget (optional)'**
  String get tourBudgetLabel;

  /// No description provided for @tourDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get tourDescriptionLabel;

  /// No description provided for @tourCreated.
  ///
  /// In en, this message translates to:
  /// **'Tour created'**
  String get tourCreated;

  /// No description provided for @tourUpdated.
  ///
  /// In en, this message translates to:
  /// **'Tour updated'**
  String get tourUpdated;

  /// No description provided for @joinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join a tour'**
  String get joinTitle;

  /// No description provided for @joinIntro.
  ///
  /// In en, this message translates to:
  /// **'Paste the invite link or enter the code you received. The host will approve your request.'**
  String get joinIntro;

  /// No description provided for @joinCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Invite link or code'**
  String get joinCodeLabel;

  /// No description provided for @joinPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get joinPaste;

  /// No description provided for @joinFind.
  ///
  /// In en, this message translates to:
  /// **'Find tour'**
  String get joinFind;

  /// No description provided for @joinInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'That doesn\'t look like an invite code. Check it and try again.'**
  String get joinInvalidCode;

  /// No description provided for @joinCodeNotFound.
  ///
  /// In en, this message translates to:
  /// **'No tour found for this code.'**
  String get joinCodeNotFound;

  /// No description provided for @joinCodeExpired.
  ///
  /// In en, this message translates to:
  /// **'This invite has expired or was turned off. Ask the host for a new one.'**
  String get joinCodeExpired;

  /// No description provided for @joinHostedBy.
  ///
  /// In en, this message translates to:
  /// **'Hosted by {name}'**
  String joinHostedBy(String name);

  /// No description provided for @joinRequest.
  ///
  /// In en, this message translates to:
  /// **'Request to join'**
  String get joinRequest;

  /// No description provided for @joinRequestAgain.
  ///
  /// In en, this message translates to:
  /// **'Request again'**
  String get joinRequestAgain;

  /// No description provided for @joinPending.
  ///
  /// In en, this message translates to:
  /// **'Request sent. You\'ll get access once the host approves.'**
  String get joinPending;

  /// No description provided for @joinCancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get joinCancelRequest;

  /// No description provided for @joinRejected.
  ///
  /// In en, this message translates to:
  /// **'The host declined this request.'**
  String get joinRejected;

  /// No description provided for @joinTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached the limit of join requests for this tour.'**
  String get joinTooManyAttempts;

  /// No description provided for @joinOpenTour.
  ///
  /// In en, this message translates to:
  /// **'Open tour'**
  String get joinOpenTour;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
