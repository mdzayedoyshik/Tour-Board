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
  String get homeTitle => 'Tour Board';

  @override
  String get inboxTitle => 'Inbox';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get homeEmptyTitle => 'No tours yet';

  @override
  String get homeEmptyBody =>
      'Create a tour for your group, or join one with a code from a friend.';

  @override
  String get createTour => 'Create tour';

  @override
  String get createTourShort => 'Create';

  @override
  String get joinTour => 'Join with a code';

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
      'Enter the join code you received from the host. They\'ll approve your request.';

  @override
  String get joinCodeLabel => 'Join code';

  @override
  String get joinPaste => 'Paste';

  @override
  String get joinFind => 'Find tour';

  @override
  String get joinInvalidCode =>
      'That doesn\'t look like a join code. It has 12 letters and numbers, like K7QM-4XPT-9C2B.';

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

  @override
  String get planStatusPlanned => 'Planned';

  @override
  String get planStatusDone => 'Done';

  @override
  String get planStatusSkipped => 'Skipped';

  @override
  String get planAdd => 'Add stop';

  @override
  String get planAddToDay => 'Add a stop';

  @override
  String planTimesInZone(String zone, String offset) {
    return 'Times are in the tour\'s time zone: $zone ($offset)';
  }

  @override
  String get planEmptyTitle => 'Nothing planned yet';

  @override
  String get planEmptyBody =>
      'Add places and activities for each day. Coordinates are optional.';

  @override
  String planDayLabel(int number, String date) {
    return 'Day $number · $date';
  }

  @override
  String planEstimated(String amount) {
    return '≈ $amount';
  }

  @override
  String get planFavorite => 'Pinned stop';

  @override
  String get planUnfavorite => 'Unpin';

  @override
  String get planOpenMapsFailed => 'Couldn\'t open a maps app.';

  @override
  String planMarkAs(String status) {
    return 'Mark as $status';
  }

  @override
  String get planMoveUp => 'Move up';

  @override
  String get planMoveDown => 'Move down';

  @override
  String get planDeleteTitle => 'Delete this plan?';

  @override
  String get planAddTitle => 'New plan';

  @override
  String get planEditTitle => 'Edit plan';

  @override
  String get planTitleLabel => 'Title';

  @override
  String get planTitleHint => 'e.g. Sunset at Inani Beach';

  @override
  String get planTitleRequired => 'Add a title';

  @override
  String get planDay => 'Day';

  @override
  String get planStart => 'Start (optional)';

  @override
  String get planEnd => 'End (optional)';

  @override
  String get planEndBeforeStart => 'Ends before it starts';

  @override
  String get planClearTimes => 'Clear times';

  @override
  String planTimeZoneNote(String zone) {
    return 'Times are local to the tour ($zone).';
  }

  @override
  String get planPlace => 'Place';

  @override
  String get placeSearchHint => 'Search places';

  @override
  String get placeNoResults =>
      'No places found. Try another name, or tap the map to drop a pin.';

  @override
  String get placeOffline =>
      'You\'re offline. Tap the map to drop a pin instead.';

  @override
  String get placeUnavailable =>
      'Search isn\'t available right now. Tap the map to drop a pin.';

  @override
  String get planPlaceName => 'Place name (optional)';

  @override
  String get planEstimatedCost => 'Estimated cost (optional)';

  @override
  String get planSaved => 'Plan saved';

  @override
  String get mapNoPlaces =>
      'Stops with a place appear here. Add a place to a plan to see it on the map.';

  @override
  String get inviteOff => 'Joining is turned off';

  @override
  String inviteShareText(String tour, String code) {
    return 'Join \"$tour\" on Tour Board.\nOpen the app, tap Join and enter code: $code';
  }

  @override
  String inviteShareSubject(String tour) {
    return 'Join $tour on Tour Board';
  }

  @override
  String get inviteMembers => 'Invite people';

  @override
  String get inviteMembersHint =>
      'Share the join code — you\'ll approve each request';

  @override
  String get membersTitle => 'Members';

  @override
  String membersPendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pending requests',
      one: '1 pending request',
    );
    return '$_temp0';
  }

  @override
  String get membersFormer => 'Former members';

  @override
  String membersCapReached(int count) {
    return 'Tours are limited to $count members in this version.';
  }

  @override
  String get memberLeft => 'Left the tour';

  @override
  String get memberRemoved => 'Removed';

  @override
  String get notesTitle => 'Notes';

  @override
  String get packingTitle => 'Packing list';

  @override
  String get activityTitle => 'Activity';

  @override
  String get tourSettingsTitle => 'Tour settings';

  @override
  String get tourSettingsHint => 'Details, invites, permissions and status';

  @override
  String get roleHost => 'Host';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleMember => 'Member';

  @override
  String requestedOn(String date) {
    return 'Requested $date';
  }

  @override
  String get requestApprove => 'Approve';

  @override
  String get requestReject => 'Decline';

  @override
  String get requestApproved => 'Request approved';

  @override
  String get requestRejected => 'Request declined';

  @override
  String get memberActions => 'Member actions';

  @override
  String get memberMakeAdmin => 'Make admin';

  @override
  String get memberMakeMember => 'Make regular member';

  @override
  String get memberTransferHost => 'Make host';

  @override
  String get memberRemove => 'Remove from tour';

  @override
  String get memberRoleChanged => 'Role updated';

  @override
  String memberTransferTitle(String name) {
    return 'Make $name the host?';
  }

  @override
  String get memberTransferBody =>
      'They\'ll manage the tour and members. You\'ll become an admin.';

  @override
  String get memberHostTransferred => 'Host changed';

  @override
  String memberRemoveTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get memberRemoveBody =>
      'They lose access right away. Their past expenses and balance stay so the group can settle up.';

  @override
  String get memberRemovedDone => 'Member removed';

  @override
  String get tourDetails => 'Details';

  @override
  String tourBudgetValue(String amount) {
    return 'Budget $amount';
  }

  @override
  String get inviteSection => 'Join code';

  @override
  String get inviteCreate => 'Create code';

  @override
  String get inviteCreated => 'New join code ready';

  @override
  String get inviteRotate => 'Get a new code';

  @override
  String get inviteRotateHint => 'The old code stops working immediately.';

  @override
  String get inviteTurnOff => 'Turn off joining';

  @override
  String get inviteExplainer =>
      'Anyone with the code can ask to join. Nobody gets access until a host or admin approves. Codes expire after 14 days.';

  @override
  String get permissionsSection => 'Permissions';

  @override
  String get permAdminsManage => 'Admins can edit details and close the tour';

  @override
  String get permMembersPacking => 'Members can edit the packing list';

  @override
  String get permMembersForOthers =>
      'Members can record expenses paid by others';

  @override
  String get permMembersForOthersHint =>
      'Off by default: members record what they paid themselves.';

  @override
  String get settingsSaved => 'Saved';

  @override
  String get lifecycleSection => 'Tour status';

  @override
  String get tourClose => 'Close tour';

  @override
  String get tourCloseHint =>
      'Freeze expenses and plans; settling up stays open.';

  @override
  String get tourCloseTitle => 'Close this tour?';

  @override
  String get tourCloseBody =>
      'Expenses, plans and notes become read-only for everyone. Members can still record and confirm payments. You can reopen it later.';

  @override
  String get tourReopen => 'Reopen tour';

  @override
  String get tourReopenTitle => 'Reopen this tour?';

  @override
  String get tourReopenBody =>
      'Members will be able to add and edit expenses and plans again. This is recorded in the activity feed.';

  @override
  String get tourArchive => 'Archive tour';

  @override
  String get tourArchiveHint =>
      'Hide it from your main list. Records stay available.';

  @override
  String get tourArchiveTitle => 'Archive this tour?';

  @override
  String get tourArchiveBody =>
      'It moves to the archived section on Home. Nothing is deleted.';

  @override
  String get tourStatusChanged => 'Tour status updated';

  @override
  String get tourDelete => 'Delete tour permanently';

  @override
  String get tourDeleteTitle => 'Delete this tour for everyone?';

  @override
  String get tourDeleteBody =>
      'All expenses, payments, plans and notes are removed for all members. This can\'t be undone.';

  @override
  String get tourDeleted => 'Tour deleted';

  @override
  String get tourLeave => 'Leave tour';

  @override
  String get tourLeaveTitle => 'Leave this tour?';

  @override
  String get tourLeaveBody =>
      'You\'ll lose access. Your past expenses and balance stay with the group so it can still be settled.';

  @override
  String get tourHostCannotLeave =>
      'As host, make someone else the host before leaving.';

  @override
  String get noteAdd => 'New note';

  @override
  String get noteEdit => 'Edit note';

  @override
  String get noteTitle => 'Note';

  @override
  String get noteTitleLabel => 'Title (optional)';

  @override
  String get noteBodyLabel => 'Note';

  @override
  String get noteDeleteTitle => 'Delete this note?';

  @override
  String get noteConflict =>
      'Someone else edited this note at the same time. Reopen it to see their version, then edit again.';

  @override
  String get notesEmptyTitle => 'No notes yet';

  @override
  String get notesEmptyBody =>
      'Keep booking codes, addresses and reminders here for the whole group.';

  @override
  String get packingAddHint => 'Add an item, e.g. sunscreen';

  @override
  String get packingEmpty => 'Packing list is empty';

  @override
  String get packingEmptyBody =>
      'Add things the group should bring. Anyone can tick them off.';

  @override
  String packingProgress(int done, int total) {
    return '$done of $total packed';
  }

  @override
  String packingAssignedTo(String name) {
    return 'For $name';
  }

  @override
  String get packingAssign => 'Assign to';

  @override
  String get activityEmpty => 'No activity yet';

  @override
  String feedMemberJoined(String actor, String name) {
    return '$actor approved $name';
  }

  @override
  String feedMemberRemoved(String actor, String name) {
    return '$actor removed $name';
  }

  @override
  String feedMemberLeft(String actor) {
    return '$actor left the tour';
  }

  @override
  String feedRoleChanged(String actor, String name) {
    return '$actor changed $name\'s role';
  }

  @override
  String feedHostTransferred(String actor, String name) {
    return '$actor made $name the host';
  }

  @override
  String feedExpenseAdded(String actor, String title) {
    return '$actor added “$title”';
  }

  @override
  String feedExpenseEdited(String actor, String title) {
    return '$actor edited “$title”';
  }

  @override
  String feedExpenseDeleted(String actor, String title) {
    return '$actor deleted “$title”';
  }

  @override
  String feedPlanAdded(String actor, String title) {
    return '$actor planned “$title”';
  }

  @override
  String feedPlanEdited(String actor, String title) {
    return '$actor updated “$title”';
  }

  @override
  String feedSettlementSubmitted(String actor) {
    return '$actor recorded a payment';
  }

  @override
  String feedSettlementConfirmed(String actor) {
    return '$actor confirmed a payment';
  }

  @override
  String feedSettlementDisputed(String actor) {
    return '$actor disputed a payment';
  }

  @override
  String feedSettlementCancelled(String actor) {
    return '$actor cancelled a payment record';
  }

  @override
  String feedTourClosed(String actor) {
    return '$actor closed the tour';
  }

  @override
  String feedTourReopened(String actor) {
    return '$actor reopened the tour';
  }

  @override
  String feedTourArchived(String actor) {
    return '$actor archived the tour';
  }

  @override
  String feedTourUpdated(String actor) {
    return '$actor updated tour details';
  }

  @override
  String get feedUnknown => 'Update from a newer app version';

  @override
  String get reminderLocalNote => 'Reminder on this device';

  @override
  String activityNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new updates',
      one: '1 new update',
    );
    return '$_temp0';
  }

  @override
  String inboxJoinRequest(String name) {
    return '$name asked to join';
  }

  @override
  String get inboxJoinApproved => 'Your request to join was approved';

  @override
  String get inboxJoinRejected => 'Your request to join was declined';

  @override
  String inboxSettlementSubmitted(String name) {
    return '$name recorded a payment for you to confirm';
  }

  @override
  String inboxSettlementConfirmed(String name) {
    return '$name confirmed your payment';
  }

  @override
  String inboxSettlementDisputed(String name) {
    return '$name disputed a payment';
  }

  @override
  String inboxTourClosed(String name) {
    return '$name closed the tour';
  }

  @override
  String inboxTourReopened(String name) {
    return '$name reopened the tour';
  }

  @override
  String inboxRoleChanged(String name) {
    return '$name changed your role';
  }

  @override
  String get inboxMarkAllRead => 'Mark all read';

  @override
  String get inboxExplainer =>
      'Join requests, payments, expenses and plan changes from your tours.';

  @override
  String get inboxEmpty => 'You\'re all caught up';

  @override
  String get profileEdit => 'Edit name';

  @override
  String get profileName => 'Display name';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get profileEmailReadOnly =>
      'Your email comes from your Google account and can\'t be changed here.';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystem => 'Device language';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get prefImportant => 'Important updates';

  @override
  String get prefImportantHint =>
      'Join requests, payments, role changes and tour status';

  @override
  String get prefExpenses => 'Expense updates';

  @override
  String get prefPlans => 'Plan updates';

  @override
  String get prefReminders => 'Plan reminders on this device';

  @override
  String get prefRemindersHint =>
      'Local reminders before planned activities. Other members aren\'t notified.';

  @override
  String get prefRemindersDenied =>
      'Notifications are blocked for Tour Board in system settings.';

  @override
  String get prefReminderLead => 'Remind me';

  @override
  String minutesBefore(int minutes) {
    return '$minutes min before';
  }

  @override
  String get pushLimitation =>
      'Push notifications can take up to a minute to arrive after quiet periods. Reminders are scheduled on this device only.';

  @override
  String get settingsPrivacy => 'Privacy & data';

  @override
  String get privacyTitle => 'Privacy and data retention';

  @override
  String get privacyBody =>
      'Only approved members of a tour can see its expenses, plans and notes. Your profile (name, email, photo link) is private to you; members see only your name and photo.\n\nTour Board doesn\'t access your location.\n\nClosed tours are kept so members can look back at what they spent. Nothing is deleted automatically. Temporary records such as expired join codes and old notifications are cleaned up when someone opens the app.\n\nIf you delete your account, your profile and notifications are removed and you leave every tour. Expenses you were part of stay in those tours under your name so the group\'s balances remain correct.';

  @override
  String get diagnosticsTitle => 'Diagnostics';

  @override
  String get diagListeners => 'Active listeners';

  @override
  String get diagPendingWrites => 'Writes waiting for server';

  @override
  String get diagFromCache => 'Last data from cache';

  @override
  String get diagEnvironment => 'Environment';

  @override
  String get diagEmulator => 'Using emulator';

  @override
  String get diagYes => 'Yes';

  @override
  String get diagNo => 'No';

  @override
  String get settingsAccount => 'Account';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutConfirm => 'Sign out of Tour Board?';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteBlockedTitle => 'Transfer hosting first';

  @override
  String deleteBlockedBody(String tours) {
    return 'You host: $tours. Make someone else the host (or delete those tours) before deleting your account.';
  }

  @override
  String get deleteAccountTitle => 'Delete your account?';

  @override
  String get deleteAccountBody =>
      'You\'ll leave all tours and your profile will be deleted. Expenses and payments you were part of stay in those tours so balances remain correct. You\'ll be asked to confirm with Google.';

  @override
  String get inviteCodeHint => 'Friends enter this in Tour Board → Join';

  @override
  String get mapPlaces => 'Places';

  @override
  String get placeQuota =>
      'Search is busy right now. Tap the map to drop a pin instead.';

  @override
  String get placeDroppedPin => 'Dropped pin';

  @override
  String get placeRename => 'Rename place';

  @override
  String get placeTapHint => 'Search, or tap the map to drop a pin';

  @override
  String get placeUseThis => 'Use this place';

  @override
  String get mapLayers => 'Map type';

  @override
  String get diagBackend => 'Backend';

  @override
  String inboxExpenseAdded(String name) {
    return '$name added an expense';
  }

  @override
  String inboxExpenseEdited(String name) {
    return '$name edited an expense';
  }

  @override
  String inboxExpenseDeleted(String name) {
    return '$name deleted an expense';
  }

  @override
  String inboxPlanAdded(String name) {
    return '$name added to the plan';
  }

  @override
  String inboxPlanEdited(String name) {
    return '$name updated the plan';
  }

  @override
  String get inboxTourDeletionSoon =>
      'This tour will be deleted soon. Settle up and save anything you need.';

  @override
  String get mapAllDays => 'All days';

  @override
  String get mapShowAll => 'Show all stops';

  @override
  String planDayShort(int number) {
    return 'Day $number';
  }

  @override
  String planStops(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stops',
      one: '1 stop',
      zero: 'No stops',
    );
    return '$_temp0';
  }

  @override
  String get planDayEmptyTitle => 'A free day so far';

  @override
  String get planDayEmptyBody =>
      'Add places to visit, meals or activities for this day.';

  @override
  String get planAnyTime => 'Any time';

  @override
  String get planDirections => 'Directions';

  @override
  String get planChoosePlace => 'Choose a place';

  @override
  String get planChoosePlaceHint => 'Search or pick on the map (optional)';

  @override
  String get planChangePlace => 'Tap to change';

  @override
  String get planRemovePlace => 'Remove place';

  @override
  String homeGreeting(String name) {
    return 'Hi, $name';
  }

  @override
  String get homeGreetingNoName => 'Hi there';

  @override
  String get homeSubtitle => 'Where are you heading next?';

  @override
  String tourStartsIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Starts in $days days',
      one: 'Starts tomorrow',
      zero: 'Starts today',
    );
    return '$_temp0';
  }

  @override
  String tourDayOf(int day, int total) {
    return 'Day $day of $total';
  }

  @override
  String tourDeletionNotice(String date) {
    return 'This trip has ended. It will be deleted for everyone on $date. Settle up and save anything you need before then.';
  }

  @override
  String tourDeletionShort(String date) {
    return 'Will be deleted on $date';
  }
}
