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

  @override
  String get tabExpenses => 'Expenses';

  @override
  String get tabPlan => 'Plan';

  @override
  String get tabMap => 'Map';

  @override
  String get tabMore => 'More';

  @override
  String get tourClosedBanner =>
      'This tour is closed. Records are read-only; settling up still works.';

  @override
  String get categoryFood => 'Food';

  @override
  String get categoryTransport => 'Transport';

  @override
  String get categoryStay => 'Stay';

  @override
  String get categoryActivities => 'Tickets & activities';

  @override
  String get categoryShopping => 'Shopping';

  @override
  String get categoryOther => 'Other';

  @override
  String balanceYouReceive(String amount) {
    return 'You should receive $amount';
  }

  @override
  String balanceYouOwe(String amount) {
    return 'You owe $amount';
  }

  @override
  String get balanceYouSettled => 'You\'re settled up';

  @override
  String balanceTheyReceive(String name, String amount) {
    return '$name should receive $amount';
  }

  @override
  String balanceTheyOwe(String name, String amount) {
    return '$name owes $amount';
  }

  @override
  String balanceTheySettled(String name) {
    return '$name is settled up';
  }

  @override
  String get expenseAdd => 'Add expense';

  @override
  String get expenseFilters => 'Filters';

  @override
  String get expenseCategory => 'Category';

  @override
  String get expenseFilterMember => 'Involving';

  @override
  String get expenseShowDeleted => 'Show deleted expenses';

  @override
  String get expenseSearchHint => 'Search expenses';

  @override
  String expenseLimitReached(int count) {
    return 'Showing the latest $count expenses. Balances use these records only.';
  }

  @override
  String get expenseEmptyTitle => 'No expenses yet';

  @override
  String get expenseEmptyBody =>
      'Record what the group spends and Tour Board works out who owes whom.';

  @override
  String get expenseNoMatches => 'No expenses match your filters.';

  @override
  String get expenseTotalSpent => 'Total spent';

  @override
  String expenseBudgetProgress(String spent, String budget) {
    return '$spent of $budget budget';
  }

  @override
  String get expenseYourBalance => 'Your balance';

  @override
  String get balancesOpen => 'Balances & settle up';

  @override
  String expensePaidBy(String name) {
    return 'Paid by $name';
  }

  @override
  String get expenseAddTitle => 'New expense';

  @override
  String get expenseEditTitle => 'Edit expense';

  @override
  String expenseOtherCurrencyNote(String currency) {
    return 'Balances in this currency are kept separate from $currency. No conversion is applied.';
  }

  @override
  String get expenseTitleLabel => 'Description';

  @override
  String get expenseTitleHint => 'e.g. Dinner at the beach';

  @override
  String get expenseTitleRequired => 'Add a short description';

  @override
  String get expensePayer => 'Paid by';

  @override
  String get expensePayerLocked =>
      'Only hosts and admins can record expenses paid by someone else.';

  @override
  String get expenseDate => 'Date';

  @override
  String get expenseSplit => 'Split';

  @override
  String get splitEqual => 'Equally';

  @override
  String get splitCustom => 'Amounts';

  @override
  String get splitShares => 'Shares';

  @override
  String get splitPayerHintYou =>
      'Tick who shares this cost. You can leave yourself out if you paid for others.';

  @override
  String splitPayerHint(String name) {
    return 'Tick who shares this cost. $name can be left out if they paid for others.';
  }

  @override
  String get splitNoParticipants => 'Choose at least one person';

  @override
  String splitSumMismatch(String remaining) {
    return 'Shares must add up to the total ($remaining left)';
  }

  @override
  String get splitInvalidWeight => 'Shares must be between 1 and 1000';

  @override
  String splitTooMany(int count) {
    return 'At most $count people per expense';
  }

  @override
  String splitPreview(String total, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$total split between $_temp0';
  }

  @override
  String get splitFewerShares => 'Fewer shares';

  @override
  String get splitMoreShares => 'More shares';

  @override
  String get splitShareLabel => 'Share';

  @override
  String get expenseNote => 'Note (optional)';

  @override
  String get expenseSaved => 'Expense saved';

  @override
  String get expenseUpdated => 'Expense updated';

  @override
  String get expenseConfirmEditTitle => 'Update balances?';

  @override
  String expenseConfirmEditBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count other members owe or receive',
      one: '1 other member owes or receives',
    );
    return 'This change affects what $_temp0.';
  }

  @override
  String get conflictTitle => 'Changed by someone else';

  @override
  String get conflictExpenseBody =>
      'Another member edited this expense while you were editing. Your changes weren\'t saved — reopen it to see the latest version.';

  @override
  String get expenseDetailTitle => 'Expense';

  @override
  String expenseDeletedBanner(String name, String time) {
    return 'Deleted by $name on $time. It no longer counts toward balances.';
  }

  @override
  String get viewEdits => 'View edits';

  @override
  String get viewEditsTitle => 'Edit history';

  @override
  String expensePayerNotParticipant(String name) {
    return '$name paid on behalf of the people above.';
  }

  @override
  String expenseCreatedBy(String name, String time) {
    return 'Added by $name · $time';
  }

  @override
  String get expenseDeleteTitle => 'Delete expense?';

  @override
  String get expenseDeleteBody =>
      'It will be removed from balances. A record of the deletion stays in the edit history.';

  @override
  String get expenseDeleted => 'Expense deleted';

  @override
  String get revisionSplitChanged => 'split changed';

  @override
  String revisionBy(String name, String time) {
    return '$name · $time';
  }

  @override
  String get fieldTitle => 'Title';

  @override
  String get fieldSplitMethod => 'Split method';

  @override
  String get fieldBody => 'Text';

  @override
  String get fieldStatus => 'Status';

  @override
  String get balancesTitle => 'Balances';

  @override
  String get balancesExplainer =>
      'Balances are worked out from recorded expenses and confirmed payments. Tour Board never moves money — pay each other however you like, then record it here.';

  @override
  String get balancesEmpty => 'Nothing to settle yet.';

  @override
  String balancesInCurrency(String currency) {
    return 'In $currency';
  }

  @override
  String get balancesSuggested => 'Suggested payments';

  @override
  String get memberFormer => 'Former member';

  @override
  String transferLine(String from, String to) {
    return '$from → $to';
  }

  @override
  String get settlementRecord => 'Record a payment';

  @override
  String get settlementMarkPaid => 'Mark as paid';

  @override
  String get settlementMarkReceived => 'Record received';

  @override
  String get settlementsTitle => 'Payments';

  @override
  String get settlementPending => 'Awaiting confirmation';

  @override
  String get settlementConfirmed => 'Confirmed';

  @override
  String get settlementDisputed => 'Disputed';

  @override
  String get settlementCancelled => 'Cancelled';

  @override
  String settlementRefShort(String ref) {
    return 'Ref $ref';
  }

  @override
  String settlementDisputeReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String settlementConfirmedBy(String name) {
    return 'Confirmed by $name';
  }

  @override
  String get settlementConfirmTitle => 'Confirm this payment?';

  @override
  String settlementConfirmBody(String amount, String name) {
    return 'Confirm that $amount from $name was settled. This updates balances and can\'t be undone.';
  }

  @override
  String get settlementConfirmAction => 'Confirm';

  @override
  String get settlementDisputeTitle => 'Dispute payment';

  @override
  String get settlementDisputeLabel => 'What\'s wrong?';

  @override
  String get settlementDisputeAction => 'Dispute';

  @override
  String get settlementCancelTitle => 'Cancel this payment record?';

  @override
  String get settlementCancelAction => 'Cancel record';

  @override
  String get settlementAlreadyChanged =>
      'This payment was already updated by someone else.';

  @override
  String get settlementIPaid => 'I paid';

  @override
  String get settlementIReceived => 'I received';

  @override
  String get settlementPaidTo => 'Paid to';

  @override
  String get settlementReceivedFrom => 'Received from';

  @override
  String get settlementPartialHint =>
      'Partial payments are fine — record each one separately.';

  @override
  String get settlementMethod => 'Payment method (optional)';

  @override
  String get settlementMethodHint => 'e.g. cash, bKash, bank transfer';

  @override
  String get settlementRef => 'Transaction reference (optional)';

  @override
  String get settlementOfflineNote =>
      'The other person confirms the payment in the app. Only confirmed payments change balances.';

  @override
  String get settlementSubmit => 'Submit for confirmation';

  @override
  String get settlementSubmitted => 'Sent for confirmation';
}
