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

  /// No description provided for @tabExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get tabExpenses;

  /// No description provided for @tabPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get tabPlan;

  /// No description provided for @tabMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get tabMap;

  /// No description provided for @tabMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get tabMore;

  /// No description provided for @tourClosedBanner.
  ///
  /// In en, this message translates to:
  /// **'This tour is closed. Records are read-only; settling up still works.'**
  String get tourClosedBanner;

  /// No description provided for @categoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get categoryFood;

  /// No description provided for @categoryTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get categoryTransport;

  /// No description provided for @categoryStay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get categoryStay;

  /// No description provided for @categoryActivities.
  ///
  /// In en, this message translates to:
  /// **'Tickets & activities'**
  String get categoryActivities;

  /// No description provided for @categoryShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get categoryShopping;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @balanceYouReceive.
  ///
  /// In en, this message translates to:
  /// **'You should receive {amount}'**
  String balanceYouReceive(String amount);

  /// No description provided for @balanceYouOwe.
  ///
  /// In en, this message translates to:
  /// **'You owe {amount}'**
  String balanceYouOwe(String amount);

  /// No description provided for @balanceYouSettled.
  ///
  /// In en, this message translates to:
  /// **'You\'re settled up'**
  String get balanceYouSettled;

  /// No description provided for @balanceTheyReceive.
  ///
  /// In en, this message translates to:
  /// **'{name} should receive {amount}'**
  String balanceTheyReceive(String name, String amount);

  /// No description provided for @balanceTheyOwe.
  ///
  /// In en, this message translates to:
  /// **'{name} owes {amount}'**
  String balanceTheyOwe(String name, String amount);

  /// No description provided for @balanceTheySettled.
  ///
  /// In en, this message translates to:
  /// **'{name} is settled up'**
  String balanceTheySettled(String name);

  /// No description provided for @expenseAdd.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get expenseAdd;

  /// No description provided for @expenseFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get expenseFilters;

  /// No description provided for @expenseCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get expenseCategory;

  /// No description provided for @expenseFilterMember.
  ///
  /// In en, this message translates to:
  /// **'Involving'**
  String get expenseFilterMember;

  /// No description provided for @expenseShowDeleted.
  ///
  /// In en, this message translates to:
  /// **'Show deleted expenses'**
  String get expenseShowDeleted;

  /// No description provided for @expenseSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search expenses'**
  String get expenseSearchHint;

  /// No description provided for @expenseLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Showing the latest {count} expenses. Balances use these records only.'**
  String expenseLimitReached(int count);

  /// No description provided for @expenseEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No expenses yet'**
  String get expenseEmptyTitle;

  /// No description provided for @expenseEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Record what the group spends and Tour Board works out who owes whom.'**
  String get expenseEmptyBody;

  /// No description provided for @expenseNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No expenses match your filters.'**
  String get expenseNoMatches;

  /// No description provided for @expenseTotalSpent.
  ///
  /// In en, this message translates to:
  /// **'Total spent'**
  String get expenseTotalSpent;

  /// No description provided for @expenseBudgetProgress.
  ///
  /// In en, this message translates to:
  /// **'{spent} of {budget} budget'**
  String expenseBudgetProgress(String spent, String budget);

  /// No description provided for @expenseYourBalance.
  ///
  /// In en, this message translates to:
  /// **'Your balance'**
  String get expenseYourBalance;

  /// No description provided for @balancesOpen.
  ///
  /// In en, this message translates to:
  /// **'Balances & settle up'**
  String get balancesOpen;

  /// No description provided for @expensePaidBy.
  ///
  /// In en, this message translates to:
  /// **'Paid by {name}'**
  String expensePaidBy(String name);

  /// No description provided for @expenseAddTitle.
  ///
  /// In en, this message translates to:
  /// **'New expense'**
  String get expenseAddTitle;

  /// No description provided for @expenseEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit expense'**
  String get expenseEditTitle;

  /// No description provided for @expenseOtherCurrencyNote.
  ///
  /// In en, this message translates to:
  /// **'Balances in this currency are kept separate from {currency}. No conversion is applied.'**
  String expenseOtherCurrencyNote(String currency);

  /// No description provided for @expenseTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get expenseTitleLabel;

  /// No description provided for @expenseTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Dinner at the beach'**
  String get expenseTitleHint;

  /// No description provided for @expenseTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Add a short description'**
  String get expenseTitleRequired;

  /// No description provided for @expensePayer.
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get expensePayer;

  /// No description provided for @expensePayerLocked.
  ///
  /// In en, this message translates to:
  /// **'Only hosts and admins can record expenses paid by someone else.'**
  String get expensePayerLocked;

  /// No description provided for @expenseDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get expenseDate;

  /// No description provided for @expenseSplit.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get expenseSplit;

  /// No description provided for @splitEqual.
  ///
  /// In en, this message translates to:
  /// **'Equally'**
  String get splitEqual;

  /// No description provided for @splitCustom.
  ///
  /// In en, this message translates to:
  /// **'Amounts'**
  String get splitCustom;

  /// No description provided for @splitShares.
  ///
  /// In en, this message translates to:
  /// **'Shares'**
  String get splitShares;

  /// No description provided for @splitPayerHintYou.
  ///
  /// In en, this message translates to:
  /// **'Tick who shares this cost. You can leave yourself out if you paid for others.'**
  String get splitPayerHintYou;

  /// No description provided for @splitPayerHint.
  ///
  /// In en, this message translates to:
  /// **'Tick who shares this cost. {name} can be left out if they paid for others.'**
  String splitPayerHint(String name);

  /// No description provided for @splitNoParticipants.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one person'**
  String get splitNoParticipants;

  /// No description provided for @splitSumMismatch.
  ///
  /// In en, this message translates to:
  /// **'Shares must add up to the total ({remaining} left)'**
  String splitSumMismatch(String remaining);

  /// No description provided for @splitInvalidWeight.
  ///
  /// In en, this message translates to:
  /// **'Shares must be between 1 and 1000'**
  String get splitInvalidWeight;

  /// No description provided for @splitTooMany.
  ///
  /// In en, this message translates to:
  /// **'At most {count} people per expense'**
  String splitTooMany(int count);

  /// No description provided for @splitPreview.
  ///
  /// In en, this message translates to:
  /// **'{total} split between {count, plural, =1{1 person} other{{count} people}}'**
  String splitPreview(String total, int count);

  /// No description provided for @splitFewerShares.
  ///
  /// In en, this message translates to:
  /// **'Fewer shares'**
  String get splitFewerShares;

  /// No description provided for @splitMoreShares.
  ///
  /// In en, this message translates to:
  /// **'More shares'**
  String get splitMoreShares;

  /// No description provided for @splitShareLabel.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get splitShareLabel;

  /// No description provided for @expenseNote.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get expenseNote;

  /// No description provided for @expenseSaved.
  ///
  /// In en, this message translates to:
  /// **'Expense saved'**
  String get expenseSaved;

  /// No description provided for @expenseUpdated.
  ///
  /// In en, this message translates to:
  /// **'Expense updated'**
  String get expenseUpdated;

  /// No description provided for @expenseConfirmEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Update balances?'**
  String get expenseConfirmEditTitle;

  /// No description provided for @expenseConfirmEditBody.
  ///
  /// In en, this message translates to:
  /// **'This change affects what {count, plural, =1{1 other member owes or receives} other{{count} other members owe or receive}}.'**
  String expenseConfirmEditBody(int count);

  /// No description provided for @conflictTitle.
  ///
  /// In en, this message translates to:
  /// **'Changed by someone else'**
  String get conflictTitle;

  /// No description provided for @conflictExpenseBody.
  ///
  /// In en, this message translates to:
  /// **'Another member edited this expense while you were editing. Your changes weren\'t saved — reopen it to see the latest version.'**
  String get conflictExpenseBody;

  /// No description provided for @expenseDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expenseDetailTitle;

  /// No description provided for @expenseDeletedBanner.
  ///
  /// In en, this message translates to:
  /// **'Deleted by {name} on {time}. It no longer counts toward balances.'**
  String expenseDeletedBanner(String name, String time);

  /// No description provided for @viewEdits.
  ///
  /// In en, this message translates to:
  /// **'View edits'**
  String get viewEdits;

  /// No description provided for @viewEditsTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit history'**
  String get viewEditsTitle;

  /// No description provided for @expensePayerNotParticipant.
  ///
  /// In en, this message translates to:
  /// **'{name} paid on behalf of the people above.'**
  String expensePayerNotParticipant(String name);

  /// No description provided for @expenseCreatedBy.
  ///
  /// In en, this message translates to:
  /// **'Added by {name} · {time}'**
  String expenseCreatedBy(String name, String time);

  /// No description provided for @expenseDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete expense?'**
  String get expenseDeleteTitle;

  /// No description provided for @expenseDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'It will be removed from balances. A record of the deletion stays in the edit history.'**
  String get expenseDeleteBody;

  /// No description provided for @expenseDeleted.
  ///
  /// In en, this message translates to:
  /// **'Expense deleted'**
  String get expenseDeleted;

  /// No description provided for @revisionSplitChanged.
  ///
  /// In en, this message translates to:
  /// **'split changed'**
  String get revisionSplitChanged;

  /// No description provided for @revisionBy.
  ///
  /// In en, this message translates to:
  /// **'{name} · {time}'**
  String revisionBy(String name, String time);

  /// No description provided for @fieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get fieldTitle;

  /// No description provided for @fieldSplitMethod.
  ///
  /// In en, this message translates to:
  /// **'Split method'**
  String get fieldSplitMethod;

  /// No description provided for @fieldBody.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get fieldBody;

  /// No description provided for @fieldStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get fieldStatus;

  /// No description provided for @balancesTitle.
  ///
  /// In en, this message translates to:
  /// **'Balances'**
  String get balancesTitle;

  /// No description provided for @balancesExplainer.
  ///
  /// In en, this message translates to:
  /// **'Balances are worked out from recorded expenses and confirmed payments. Tour Board never moves money — pay each other however you like, then record it here.'**
  String get balancesExplainer;

  /// No description provided for @balancesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to settle yet.'**
  String get balancesEmpty;

  /// No description provided for @balancesInCurrency.
  ///
  /// In en, this message translates to:
  /// **'In {currency}'**
  String balancesInCurrency(String currency);

  /// No description provided for @balancesSuggested.
  ///
  /// In en, this message translates to:
  /// **'Suggested payments'**
  String get balancesSuggested;

  /// No description provided for @memberFormer.
  ///
  /// In en, this message translates to:
  /// **'Former member'**
  String get memberFormer;

  /// No description provided for @transferLine.
  ///
  /// In en, this message translates to:
  /// **'{from} → {to}'**
  String transferLine(String from, String to);

  /// No description provided for @settlementRecord.
  ///
  /// In en, this message translates to:
  /// **'Record a payment'**
  String get settlementRecord;

  /// No description provided for @settlementMarkPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as paid'**
  String get settlementMarkPaid;

  /// No description provided for @settlementMarkReceived.
  ///
  /// In en, this message translates to:
  /// **'Record received'**
  String get settlementMarkReceived;

  /// No description provided for @settlementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get settlementsTitle;

  /// No description provided for @settlementPending.
  ///
  /// In en, this message translates to:
  /// **'Awaiting confirmation'**
  String get settlementPending;

  /// No description provided for @settlementConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get settlementConfirmed;

  /// No description provided for @settlementDisputed.
  ///
  /// In en, this message translates to:
  /// **'Disputed'**
  String get settlementDisputed;

  /// No description provided for @settlementCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get settlementCancelled;

  /// No description provided for @settlementRefShort.
  ///
  /// In en, this message translates to:
  /// **'Ref {ref}'**
  String settlementRefShort(String ref);

  /// No description provided for @settlementDisputeReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String settlementDisputeReason(String reason);

  /// No description provided for @settlementConfirmedBy.
  ///
  /// In en, this message translates to:
  /// **'Confirmed by {name}'**
  String settlementConfirmedBy(String name);

  /// No description provided for @settlementConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm this payment?'**
  String get settlementConfirmTitle;

  /// No description provided for @settlementConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Confirm that {amount} from {name} was settled. This updates balances and can\'t be undone.'**
  String settlementConfirmBody(String amount, String name);

  /// No description provided for @settlementConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get settlementConfirmAction;

  /// No description provided for @settlementDisputeTitle.
  ///
  /// In en, this message translates to:
  /// **'Dispute payment'**
  String get settlementDisputeTitle;

  /// No description provided for @settlementDisputeLabel.
  ///
  /// In en, this message translates to:
  /// **'What\'s wrong?'**
  String get settlementDisputeLabel;

  /// No description provided for @settlementDisputeAction.
  ///
  /// In en, this message translates to:
  /// **'Dispute'**
  String get settlementDisputeAction;

  /// No description provided for @settlementCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this payment record?'**
  String get settlementCancelTitle;

  /// No description provided for @settlementCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel record'**
  String get settlementCancelAction;

  /// No description provided for @settlementAlreadyChanged.
  ///
  /// In en, this message translates to:
  /// **'This payment was already updated by someone else.'**
  String get settlementAlreadyChanged;

  /// No description provided for @settlementIPaid.
  ///
  /// In en, this message translates to:
  /// **'I paid'**
  String get settlementIPaid;

  /// No description provided for @settlementIReceived.
  ///
  /// In en, this message translates to:
  /// **'I received'**
  String get settlementIReceived;

  /// No description provided for @settlementPaidTo.
  ///
  /// In en, this message translates to:
  /// **'Paid to'**
  String get settlementPaidTo;

  /// No description provided for @settlementReceivedFrom.
  ///
  /// In en, this message translates to:
  /// **'Received from'**
  String get settlementReceivedFrom;

  /// No description provided for @settlementPartialHint.
  ///
  /// In en, this message translates to:
  /// **'Partial payments are fine — record each one separately.'**
  String get settlementPartialHint;

  /// No description provided for @settlementMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method (optional)'**
  String get settlementMethod;

  /// No description provided for @settlementMethodHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. cash, bKash, bank transfer'**
  String get settlementMethodHint;

  /// No description provided for @settlementRef.
  ///
  /// In en, this message translates to:
  /// **'Transaction reference (optional)'**
  String get settlementRef;

  /// No description provided for @settlementOfflineNote.
  ///
  /// In en, this message translates to:
  /// **'The other person confirms the payment in the app. Only confirmed payments change balances.'**
  String get settlementOfflineNote;

  /// No description provided for @settlementSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit for confirmation'**
  String get settlementSubmit;

  /// No description provided for @settlementSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Sent for confirmation'**
  String get settlementSubmitted;

  /// No description provided for @planStatusPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get planStatusPlanned;

  /// No description provided for @planStatusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get planStatusDone;

  /// No description provided for @planStatusSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get planStatusSkipped;

  /// No description provided for @planAdd.
  ///
  /// In en, this message translates to:
  /// **'Add plan'**
  String get planAdd;

  /// No description provided for @planAddToDay.
  ///
  /// In en, this message translates to:
  /// **'Add to this day'**
  String get planAddToDay;

  /// No description provided for @planTimesInZone.
  ///
  /// In en, this message translates to:
  /// **'Times are in the tour\'s time zone: {zone} ({offset})'**
  String planTimesInZone(String zone, String offset);

  /// No description provided for @planEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned yet'**
  String get planEmptyTitle;

  /// No description provided for @planEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add places and activities for each day. Coordinates are optional.'**
  String get planEmptyBody;

  /// No description provided for @planDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Day {number} · {date}'**
  String planDayLabel(int number, String date);

  /// No description provided for @planDayEmpty.
  ///
  /// In en, this message translates to:
  /// **'Free day'**
  String get planDayEmpty;

  /// No description provided for @planEstimated.
  ///
  /// In en, this message translates to:
  /// **'≈ {amount}'**
  String planEstimated(String amount);

  /// No description provided for @planFavorite.
  ///
  /// In en, this message translates to:
  /// **'Pinned stop'**
  String get planFavorite;

  /// No description provided for @planUnfavorite.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get planUnfavorite;

  /// No description provided for @planHasLocation.
  ///
  /// In en, this message translates to:
  /// **'Has location'**
  String get planHasLocation;

  /// No description provided for @planOpenInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in maps'**
  String get planOpenInMaps;

  /// No description provided for @planOpenMapsFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open a maps app.'**
  String get planOpenMapsFailed;

  /// No description provided for @planMarkAs.
  ///
  /// In en, this message translates to:
  /// **'Mark as {status}'**
  String planMarkAs(String status);

  /// No description provided for @planMoveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get planMoveUp;

  /// No description provided for @planMoveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get planMoveDown;

  /// No description provided for @planDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this plan?'**
  String get planDeleteTitle;

  /// No description provided for @planAddTitle.
  ///
  /// In en, this message translates to:
  /// **'New plan'**
  String get planAddTitle;

  /// No description provided for @planEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit plan'**
  String get planEditTitle;

  /// No description provided for @planTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'What'**
  String get planTitleLabel;

  /// No description provided for @planTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Sunset at Inani Beach'**
  String get planTitleHint;

  /// No description provided for @planTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Add a title'**
  String get planTitleRequired;

  /// No description provided for @planDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get planDay;

  /// No description provided for @planStart.
  ///
  /// In en, this message translates to:
  /// **'Start (optional)'**
  String get planStart;

  /// No description provided for @planEnd.
  ///
  /// In en, this message translates to:
  /// **'End (optional)'**
  String get planEnd;

  /// No description provided for @planEndBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'Ends before it starts'**
  String get planEndBeforeStart;

  /// No description provided for @planClearTimes.
  ///
  /// In en, this message translates to:
  /// **'Clear times'**
  String get planClearTimes;

  /// No description provided for @planTimeZoneNote.
  ///
  /// In en, this message translates to:
  /// **'Times are local to the tour ({zone}).'**
  String planTimeZoneNote(String zone);

  /// No description provided for @planPlace.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get planPlace;

  /// No description provided for @placeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a place'**
  String get placeSearchHint;

  /// No description provided for @placeSearchAttribution.
  ///
  /// In en, this message translates to:
  /// **'Search by OpenStreetMap Nominatim'**
  String get placeSearchAttribution;

  /// No description provided for @placeNoResults.
  ///
  /// In en, this message translates to:
  /// **'No places found. You can enter it manually.'**
  String get placeNoResults;

  /// No description provided for @placeRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Search is busy. Wait a moment or enter the place manually.'**
  String get placeRateLimited;

  /// No description provided for @placeOffline.
  ///
  /// In en, this message translates to:
  /// **'Search needs a connection. You can enter the place manually.'**
  String get placeOffline;

  /// No description provided for @placeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Search isn\'t available right now. Enter the place manually.'**
  String get placeUnavailable;

  /// No description provided for @placeManualOnly.
  ///
  /// In en, this message translates to:
  /// **'Place search is turned off. Enter a name and, if you know them, coordinates.'**
  String get placeManualOnly;

  /// No description provided for @placeEnterManually.
  ///
  /// In en, this message translates to:
  /// **'Enter manually'**
  String get placeEnterManually;

  /// No description provided for @placeUseSearch.
  ///
  /// In en, this message translates to:
  /// **'Search instead'**
  String get placeUseSearch;

  /// No description provided for @planPlaceName.
  ///
  /// In en, this message translates to:
  /// **'Place name (optional)'**
  String get planPlaceName;

  /// No description provided for @planLatitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get planLatitude;

  /// No description provided for @planLongitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get planLongitude;

  /// No description provided for @planInvalidCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Enter both latitude (−90 to 90) and longitude (−180 to 180), or leave both empty.'**
  String get planInvalidCoordinates;

  /// No description provided for @planRemoveCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Remove coordinates'**
  String get planRemoveCoordinates;

  /// No description provided for @planEstimatedCost.
  ///
  /// In en, this message translates to:
  /// **'Estimated cost (optional)'**
  String get planEstimatedCost;

  /// No description provided for @planSaved.
  ///
  /// In en, this message translates to:
  /// **'Plan saved'**
  String get planSaved;

  /// No description provided for @mapTilesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Map tiles couldn\'t load. Saved places and member status still work.'**
  String get mapTilesUnavailable;

  /// No description provided for @mapLocationsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Live locations are unavailable right now.'**
  String get mapLocationsUnavailable;

  /// No description provided for @mapPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get mapPeople;

  /// No description provided for @mapNoPlaces.
  ///
  /// In en, this message translates to:
  /// **'No plans have coordinates yet. Add a place to see it on the map.'**
  String get mapNoPlaces;

  /// No description provided for @mapDistance.
  ///
  /// In en, this message translates to:
  /// **'About {distance} from you'**
  String mapDistance(String distance);

  /// No description provided for @distanceMeters.
  ///
  /// In en, this message translates to:
  /// **'{meters} m'**
  String distanceMeters(int meters);

  /// No description provided for @distanceKm.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String distanceKm(String km);

  /// No description provided for @shareLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get shareLive;

  /// No description provided for @shareStale.
  ///
  /// In en, this message translates to:
  /// **'Stale'**
  String get shareStale;

  /// No description provided for @sharePaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get sharePaused;

  /// No description provided for @shareNotSharing.
  ///
  /// In en, this message translates to:
  /// **'Not sharing'**
  String get shareNotSharing;

  /// No description provided for @shareStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Share your location'**
  String get shareStartTitle;

  /// No description provided for @shareStartBody.
  ///
  /// In en, this message translates to:
  /// **'Only current members of this tour can see it. It updates while the app is open and stops automatically.'**
  String get shareStartBody;

  /// No description provided for @share30Min.
  ///
  /// In en, this message translates to:
  /// **'For 30 minutes'**
  String get share30Min;

  /// No description provided for @share2Hours.
  ///
  /// In en, this message translates to:
  /// **'For 2 hours (recommended)'**
  String get share2Hours;

  /// No description provided for @shareUntilTripEnds.
  ///
  /// In en, this message translates to:
  /// **'Until the trip ends'**
  String get shareUntilTripEnds;

  /// No description provided for @shareActive.
  ///
  /// In en, this message translates to:
  /// **'Sharing your location'**
  String get shareActive;

  /// No description provided for @shareActivePaused.
  ///
  /// In en, this message translates to:
  /// **'Sharing paused while the app is in the background'**
  String get shareActivePaused;

  /// No description provided for @shareUntil.
  ///
  /// In en, this message translates to:
  /// **'Until {time}'**
  String shareUntil(String time);

  /// No description provided for @shareStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get shareStop;

  /// No description provided for @shareLeftover.
  ///
  /// In en, this message translates to:
  /// **'Your last shared location ({time}) is still visible to members.'**
  String shareLeftover(String time);

  /// No description provided for @shareOff.
  ///
  /// In en, this message translates to:
  /// **'Location sharing is off. Members only see you if you turn it on.'**
  String get shareOff;

  /// No description provided for @shareStart.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareStart;

  /// No description provided for @shareClosedTour.
  ///
  /// In en, this message translates to:
  /// **'Location sharing is unavailable for closed tours.'**
  String get shareClosedTour;

  /// No description provided for @shareServiceOff.
  ///
  /// In en, this message translates to:
  /// **'Location services are turned off on this device.'**
  String get shareServiceOff;

  /// No description provided for @sharePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission wasn\'t granted, so sharing stopped.'**
  String get sharePermissionDenied;

  /// No description provided for @sharePermissionForever.
  ///
  /// In en, this message translates to:
  /// **'Location access is blocked for Tour Board. Enable it in system settings to share.'**
  String get sharePermissionForever;

  /// No description provided for @shareWriteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update your location. It\'ll retry with the next update.'**
  String get shareWriteFailed;

  /// No description provided for @shareOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get shareOpenSettings;

  /// No description provided for @inviteOff.
  ///
  /// In en, this message translates to:
  /// **'Invites are turned off'**
  String get inviteOff;

  /// No description provided for @inviteShareText.
  ///
  /// In en, this message translates to:
  /// **'Join \"{tour}\" on Tour Board: {link}\nOr open the app and enter code {code}'**
  String inviteShareText(String tour, String link, String code);

  /// No description provided for @inviteShareSubject.
  ///
  /// In en, this message translates to:
  /// **'Join {tour} on Tour Board'**
  String inviteShareSubject(String tour);

  /// No description provided for @inviteMembers.
  ///
  /// In en, this message translates to:
  /// **'Invite people'**
  String get inviteMembers;

  /// No description provided for @inviteMembersHint.
  ///
  /// In en, this message translates to:
  /// **'Share a link — you\'ll approve each request'**
  String get inviteMembersHint;

  /// No description provided for @membersTitle.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get membersTitle;

  /// No description provided for @membersPendingCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 pending request} other{{count} pending requests}}'**
  String membersPendingCount(int count);

  /// No description provided for @membersFormer.
  ///
  /// In en, this message translates to:
  /// **'Former members'**
  String get membersFormer;

  /// No description provided for @membersCapReached.
  ///
  /// In en, this message translates to:
  /// **'Tours are limited to {count} members in this version.'**
  String membersCapReached(int count);

  /// No description provided for @memberLeft.
  ///
  /// In en, this message translates to:
  /// **'Left the tour'**
  String get memberLeft;

  /// No description provided for @memberRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get memberRemoved;

  /// No description provided for @notesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesTitle;

  /// No description provided for @packingTitle.
  ///
  /// In en, this message translates to:
  /// **'Packing list'**
  String get packingTitle;

  /// No description provided for @activityTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityTitle;

  /// No description provided for @tourSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tour settings'**
  String get tourSettingsTitle;

  /// No description provided for @tourSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'Details, invites, permissions and status'**
  String get tourSettingsHint;

  /// No description provided for @roleHost.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get roleHost;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @roleMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get roleMember;

  /// No description provided for @requestedOn.
  ///
  /// In en, this message translates to:
  /// **'Requested {date}'**
  String requestedOn(String date);

  /// No description provided for @requestApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get requestApprove;

  /// No description provided for @requestReject.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get requestReject;

  /// No description provided for @requestApproved.
  ///
  /// In en, this message translates to:
  /// **'Request approved'**
  String get requestApproved;

  /// No description provided for @requestRejected.
  ///
  /// In en, this message translates to:
  /// **'Request declined'**
  String get requestRejected;

  /// No description provided for @memberActions.
  ///
  /// In en, this message translates to:
  /// **'Member actions'**
  String get memberActions;

  /// No description provided for @memberMakeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Make admin'**
  String get memberMakeAdmin;

  /// No description provided for @memberMakeMember.
  ///
  /// In en, this message translates to:
  /// **'Make regular member'**
  String get memberMakeMember;

  /// No description provided for @memberTransferHost.
  ///
  /// In en, this message translates to:
  /// **'Make host'**
  String get memberTransferHost;

  /// No description provided for @memberRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from tour'**
  String get memberRemove;

  /// No description provided for @memberRoleChanged.
  ///
  /// In en, this message translates to:
  /// **'Role updated'**
  String get memberRoleChanged;

  /// No description provided for @memberTransferTitle.
  ///
  /// In en, this message translates to:
  /// **'Make {name} the host?'**
  String memberTransferTitle(String name);

  /// No description provided for @memberTransferBody.
  ///
  /// In en, this message translates to:
  /// **'They\'ll manage the tour and members. You\'ll become an admin.'**
  String get memberTransferBody;

  /// No description provided for @memberHostTransferred.
  ///
  /// In en, this message translates to:
  /// **'Host changed'**
  String get memberHostTransferred;

  /// No description provided for @memberRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String memberRemoveTitle(String name);

  /// No description provided for @memberRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'They lose access right away. Their past expenses and balance stay so the group can settle up.'**
  String get memberRemoveBody;

  /// No description provided for @memberRemovedDone.
  ///
  /// In en, this message translates to:
  /// **'Member removed'**
  String get memberRemovedDone;

  /// No description provided for @tourDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get tourDetails;

  /// No description provided for @tourBudgetValue.
  ///
  /// In en, this message translates to:
  /// **'Budget {amount}'**
  String tourBudgetValue(String amount);

  /// No description provided for @inviteSection.
  ///
  /// In en, this message translates to:
  /// **'Invite link'**
  String get inviteSection;

  /// No description provided for @inviteCreate.
  ///
  /// In en, this message translates to:
  /// **'Create link'**
  String get inviteCreate;

  /// No description provided for @inviteCreated.
  ///
  /// In en, this message translates to:
  /// **'New invite link ready'**
  String get inviteCreated;

  /// No description provided for @inviteRotate.
  ///
  /// In en, this message translates to:
  /// **'Get a new link'**
  String get inviteRotate;

  /// No description provided for @inviteRotateHint.
  ///
  /// In en, this message translates to:
  /// **'The old link and code stop working immediately.'**
  String get inviteRotateHint;

  /// No description provided for @inviteTurnOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off invites'**
  String get inviteTurnOff;

  /// No description provided for @inviteExplainer.
  ///
  /// In en, this message translates to:
  /// **'Anyone with the link can ask to join. Nobody gets access until a host or admin approves. Links expire after 14 days.'**
  String get inviteExplainer;

  /// No description provided for @permissionsSection.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissionsSection;

  /// No description provided for @permAdminsManage.
  ///
  /// In en, this message translates to:
  /// **'Admins can edit details and close the tour'**
  String get permAdminsManage;

  /// No description provided for @permMembersPacking.
  ///
  /// In en, this message translates to:
  /// **'Members can edit the packing list'**
  String get permMembersPacking;

  /// No description provided for @permMembersForOthers.
  ///
  /// In en, this message translates to:
  /// **'Members can record expenses paid by others'**
  String get permMembersForOthers;

  /// No description provided for @permMembersForOthersHint.
  ///
  /// In en, this message translates to:
  /// **'Off by default: members record what they paid themselves.'**
  String get permMembersForOthersHint;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get settingsSaved;

  /// No description provided for @lifecycleSection.
  ///
  /// In en, this message translates to:
  /// **'Tour status'**
  String get lifecycleSection;

  /// No description provided for @tourClose.
  ///
  /// In en, this message translates to:
  /// **'Close tour'**
  String get tourClose;

  /// No description provided for @tourCloseHint.
  ///
  /// In en, this message translates to:
  /// **'Freeze expenses and plans; settling up stays open.'**
  String get tourCloseHint;

  /// No description provided for @tourCloseTitle.
  ///
  /// In en, this message translates to:
  /// **'Close this tour?'**
  String get tourCloseTitle;

  /// No description provided for @tourCloseBody.
  ///
  /// In en, this message translates to:
  /// **'Expenses, plans and notes become read-only for everyone. Members can still record and confirm payments. You can reopen it later.'**
  String get tourCloseBody;

  /// No description provided for @tourReopen.
  ///
  /// In en, this message translates to:
  /// **'Reopen tour'**
  String get tourReopen;

  /// No description provided for @tourReopenTitle.
  ///
  /// In en, this message translates to:
  /// **'Reopen this tour?'**
  String get tourReopenTitle;

  /// No description provided for @tourReopenBody.
  ///
  /// In en, this message translates to:
  /// **'Members will be able to add and edit expenses and plans again. This is recorded in the activity feed.'**
  String get tourReopenBody;

  /// No description provided for @tourArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive tour'**
  String get tourArchive;

  /// No description provided for @tourArchiveHint.
  ///
  /// In en, this message translates to:
  /// **'Hide it from your main list. Records stay available.'**
  String get tourArchiveHint;

  /// No description provided for @tourArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive this tour?'**
  String get tourArchiveTitle;

  /// No description provided for @tourArchiveBody.
  ///
  /// In en, this message translates to:
  /// **'It moves to the archived section on Home. Nothing is deleted.'**
  String get tourArchiveBody;

  /// No description provided for @tourStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'Tour status updated'**
  String get tourStatusChanged;

  /// No description provided for @tourDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete tour permanently'**
  String get tourDelete;

  /// No description provided for @tourDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this tour for everyone?'**
  String get tourDeleteTitle;

  /// No description provided for @tourDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'All expenses, payments, plans and notes are removed for all members. This can\'t be undone.'**
  String get tourDeleteBody;

  /// No description provided for @tourDeleted.
  ///
  /// In en, this message translates to:
  /// **'Tour deleted'**
  String get tourDeleted;

  /// No description provided for @tourDeletePartial.
  ///
  /// In en, this message translates to:
  /// **'Part of the tour was deleted. Run delete again to finish.'**
  String get tourDeletePartial;

  /// No description provided for @tourLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave tour'**
  String get tourLeave;

  /// No description provided for @tourLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave this tour?'**
  String get tourLeaveTitle;

  /// No description provided for @tourLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll lose access. Your past expenses and balance stay with the group so it can still be settled.'**
  String get tourLeaveBody;

  /// No description provided for @tourHostCannotLeave.
  ///
  /// In en, this message translates to:
  /// **'As host, make someone else the host before leaving.'**
  String get tourHostCannotLeave;

  /// No description provided for @noteAdd.
  ///
  /// In en, this message translates to:
  /// **'New note'**
  String get noteAdd;

  /// No description provided for @noteEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get noteEdit;

  /// No description provided for @noteTitle.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get noteTitle;

  /// No description provided for @noteTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title (optional)'**
  String get noteTitleLabel;

  /// No description provided for @noteBodyLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get noteBodyLabel;

  /// No description provided for @noteDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this note?'**
  String get noteDeleteTitle;

  /// No description provided for @noteConflict.
  ///
  /// In en, this message translates to:
  /// **'Someone else edited this note at the same time. Reopen it to see their version, then edit again.'**
  String get noteConflict;

  /// No description provided for @notesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get notesEmptyTitle;

  /// No description provided for @notesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Keep booking codes, addresses and reminders here for the whole group.'**
  String get notesEmptyBody;

  /// No description provided for @packingAddHint.
  ///
  /// In en, this message translates to:
  /// **'Add an item, e.g. sunscreen'**
  String get packingAddHint;

  /// No description provided for @packingEmpty.
  ///
  /// In en, this message translates to:
  /// **'Packing list is empty'**
  String get packingEmpty;

  /// No description provided for @packingEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add things the group should bring. Anyone can tick them off.'**
  String get packingEmptyBody;

  /// No description provided for @packingProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} packed'**
  String packingProgress(int done, int total);

  /// No description provided for @packingAssignedTo.
  ///
  /// In en, this message translates to:
  /// **'For {name}'**
  String packingAssignedTo(String name);

  /// No description provided for @packingAssign.
  ///
  /// In en, this message translates to:
  /// **'Assign to'**
  String get packingAssign;

  /// No description provided for @activityEmpty.
  ///
  /// In en, this message translates to:
  /// **'No activity yet'**
  String get activityEmpty;

  /// No description provided for @feedMemberJoined.
  ///
  /// In en, this message translates to:
  /// **'{actor} approved {name}'**
  String feedMemberJoined(String actor, String name);

  /// No description provided for @feedMemberRemoved.
  ///
  /// In en, this message translates to:
  /// **'{actor} removed {name}'**
  String feedMemberRemoved(String actor, String name);

  /// No description provided for @feedMemberLeft.
  ///
  /// In en, this message translates to:
  /// **'{actor} left the tour'**
  String feedMemberLeft(String actor);

  /// No description provided for @feedRoleChanged.
  ///
  /// In en, this message translates to:
  /// **'{actor} changed {name}\'s role'**
  String feedRoleChanged(String actor, String name);

  /// No description provided for @feedHostTransferred.
  ///
  /// In en, this message translates to:
  /// **'{actor} made {name} the host'**
  String feedHostTransferred(String actor, String name);

  /// No description provided for @feedExpenseAdded.
  ///
  /// In en, this message translates to:
  /// **'{actor} added “{title}”'**
  String feedExpenseAdded(String actor, String title);

  /// No description provided for @feedExpenseEdited.
  ///
  /// In en, this message translates to:
  /// **'{actor} edited “{title}”'**
  String feedExpenseEdited(String actor, String title);

  /// No description provided for @feedExpenseDeleted.
  ///
  /// In en, this message translates to:
  /// **'{actor} deleted “{title}”'**
  String feedExpenseDeleted(String actor, String title);

  /// No description provided for @feedPlanAdded.
  ///
  /// In en, this message translates to:
  /// **'{actor} planned “{title}”'**
  String feedPlanAdded(String actor, String title);

  /// No description provided for @feedPlanEdited.
  ///
  /// In en, this message translates to:
  /// **'{actor} updated “{title}”'**
  String feedPlanEdited(String actor, String title);

  /// No description provided for @feedSettlementSubmitted.
  ///
  /// In en, this message translates to:
  /// **'{actor} recorded a payment'**
  String feedSettlementSubmitted(String actor);

  /// No description provided for @feedSettlementConfirmed.
  ///
  /// In en, this message translates to:
  /// **'{actor} confirmed a payment'**
  String feedSettlementConfirmed(String actor);

  /// No description provided for @feedSettlementDisputed.
  ///
  /// In en, this message translates to:
  /// **'{actor} disputed a payment'**
  String feedSettlementDisputed(String actor);

  /// No description provided for @feedSettlementCancelled.
  ///
  /// In en, this message translates to:
  /// **'{actor} cancelled a payment record'**
  String feedSettlementCancelled(String actor);

  /// No description provided for @feedTourClosed.
  ///
  /// In en, this message translates to:
  /// **'{actor} closed the tour'**
  String feedTourClosed(String actor);

  /// No description provided for @feedTourReopened.
  ///
  /// In en, this message translates to:
  /// **'{actor} reopened the tour'**
  String feedTourReopened(String actor);

  /// No description provided for @feedTourArchived.
  ///
  /// In en, this message translates to:
  /// **'{actor} archived the tour'**
  String feedTourArchived(String actor);

  /// No description provided for @feedTourUpdated.
  ///
  /// In en, this message translates to:
  /// **'{actor} updated tour details'**
  String feedTourUpdated(String actor);

  /// No description provided for @feedUnknown.
  ///
  /// In en, this message translates to:
  /// **'Update from a newer app version'**
  String get feedUnknown;

  /// No description provided for @reminderLocalNote.
  ///
  /// In en, this message translates to:
  /// **'Reminder on this device'**
  String get reminderLocalNote;

  /// No description provided for @activityNew.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new update} other{{count} new updates}}'**
  String activityNew(int count);

  /// No description provided for @inboxJoinRequest.
  ///
  /// In en, this message translates to:
  /// **'{name} asked to join'**
  String inboxJoinRequest(String name);

  /// No description provided for @inboxJoinApproved.
  ///
  /// In en, this message translates to:
  /// **'Your request to join was approved'**
  String get inboxJoinApproved;

  /// No description provided for @inboxJoinRejected.
  ///
  /// In en, this message translates to:
  /// **'Your request to join was declined'**
  String get inboxJoinRejected;

  /// No description provided for @inboxSettlementSubmitted.
  ///
  /// In en, this message translates to:
  /// **'{name} recorded a payment for you to confirm'**
  String inboxSettlementSubmitted(String name);

  /// No description provided for @inboxSettlementConfirmed.
  ///
  /// In en, this message translates to:
  /// **'{name} confirmed your payment'**
  String inboxSettlementConfirmed(String name);

  /// No description provided for @inboxSettlementDisputed.
  ///
  /// In en, this message translates to:
  /// **'{name} disputed a payment'**
  String inboxSettlementDisputed(String name);

  /// No description provided for @inboxTourClosed.
  ///
  /// In en, this message translates to:
  /// **'{name} closed the tour'**
  String inboxTourClosed(String name);

  /// No description provided for @inboxTourReopened.
  ///
  /// In en, this message translates to:
  /// **'{name} reopened the tour'**
  String inboxTourReopened(String name);

  /// No description provided for @inboxRoleChanged.
  ///
  /// In en, this message translates to:
  /// **'{name} changed your role'**
  String inboxRoleChanged(String name);

  /// No description provided for @inboxMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get inboxMarkAllRead;

  /// No description provided for @inboxExplainer.
  ///
  /// In en, this message translates to:
  /// **'Updates appear here while you use the app. Tour Board doesn\'t send push notifications.'**
  String get inboxExplainer;

  /// No description provided for @inboxEmpty.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get inboxEmpty;

  /// No description provided for @profileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit name'**
  String get profileEdit;

  /// No description provided for @profileName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get profileName;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @profileEmailReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Your email comes from your Google account and can\'t be changed here.'**
  String get profileEmailReadOnly;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Device language'**
  String get languageSystem;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @prefImportant.
  ///
  /// In en, this message translates to:
  /// **'Important updates'**
  String get prefImportant;

  /// No description provided for @prefImportantHint.
  ///
  /// In en, this message translates to:
  /// **'Join requests, payments and tour status in your inbox'**
  String get prefImportantHint;

  /// No description provided for @prefExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expense updates'**
  String get prefExpenses;

  /// No description provided for @prefPlans.
  ///
  /// In en, this message translates to:
  /// **'Plan updates'**
  String get prefPlans;

  /// No description provided for @prefReminders.
  ///
  /// In en, this message translates to:
  /// **'Plan reminders on this device'**
  String get prefReminders;

  /// No description provided for @prefRemindersHint.
  ///
  /// In en, this message translates to:
  /// **'Local reminders before planned activities. Other members aren\'t notified.'**
  String get prefRemindersHint;

  /// No description provided for @prefRemindersDenied.
  ///
  /// In en, this message translates to:
  /// **'Notifications are blocked for Tour Board in system settings.'**
  String get prefRemindersDenied;

  /// No description provided for @prefReminderLead.
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get prefReminderLead;

  /// No description provided for @minutesBefore.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min before'**
  String minutesBefore(int minutes);

  /// No description provided for @pushLimitation.
  ///
  /// In en, this message translates to:
  /// **'Tour Board works without its own server, so it can\'t send push notifications to other people. You\'ll see updates when you open the app.'**
  String get pushLimitation;

  /// No description provided for @settingsLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get settingsLocation;

  /// No description provided for @locationHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'How location sharing works'**
  String get locationHelpTitle;

  /// No description provided for @locationHelpBody.
  ///
  /// In en, this message translates to:
  /// **'It\'s off unless you start it from a tour\'s map. Only that tour\'s members can see it, it stops automatically, and it pauses when the app is in the background. It can use extra battery.'**
  String get locationHelpBody;

  /// No description provided for @locationOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Location permission settings'**
  String get locationOpenSettings;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy & data'**
  String get settingsPrivacy;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy and data retention'**
  String get privacyTitle;

  /// No description provided for @privacyBody.
  ///
  /// In en, this message translates to:
  /// **'Only approved members of a tour can see its expenses, plans, notes and shared locations. Your profile (name, email, photo link) is private to you; members see only your name and photo.\n\nLocation is shared only when you turn it on, only the latest position is kept, and it\'s hidden as soon as the sharing window ends.\n\nClosed tours are kept so members can look back at what they spent. Nothing is deleted automatically. Temporary records such as expired invites, old notifications and expired locations are cleaned up when someone opens the app.\n\nIf you delete your account, your profile and notifications are removed and you leave every tour. Expenses you were part of stay in those tours under your name so the group\'s balances remain correct.'**
  String get privacyBody;

  /// No description provided for @diagnosticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get diagnosticsTitle;

  /// No description provided for @diagListeners.
  ///
  /// In en, this message translates to:
  /// **'Active listeners'**
  String get diagListeners;

  /// No description provided for @diagPendingWrites.
  ///
  /// In en, this message translates to:
  /// **'Writes waiting for server'**
  String get diagPendingWrites;

  /// No description provided for @diagFromCache.
  ///
  /// In en, this message translates to:
  /// **'Last data from cache'**
  String get diagFromCache;

  /// No description provided for @diagEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Environment'**
  String get diagEnvironment;

  /// No description provided for @diagEmulator.
  ///
  /// In en, this message translates to:
  /// **'Using emulator'**
  String get diagEmulator;

  /// No description provided for @diagPlaceSearch.
  ///
  /// In en, this message translates to:
  /// **'Place search'**
  String get diagPlaceSearch;

  /// No description provided for @diagYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get diagYes;

  /// No description provided for @diagNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get diagNo;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out of Tour Board?'**
  String get signOutConfirm;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer hosting first'**
  String get deleteBlockedTitle;

  /// No description provided for @deleteBlockedBody.
  ///
  /// In en, this message translates to:
  /// **'You host: {tours}. Make someone else the host (or delete those tours) before deleting your account.'**
  String deleteBlockedBody(String tours);

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll leave all tours and your profile will be deleted. Expenses and payments you were part of stay in those tours so balances remain correct. You\'ll be asked to confirm with Google.'**
  String get deleteAccountBody;

  /// No description provided for @placeQueryTooShort.
  ///
  /// In en, this message translates to:
  /// **'Type at least 3 characters, then search.'**
  String get placeQueryTooShort;
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
