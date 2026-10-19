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

  @override
  String get planStatusPlanned => 'Planned';

  @override
  String get planStatusDone => 'Done';

  @override
  String get planStatusSkipped => 'Skipped';

  @override
  String get planAdd => 'Add plan';

  @override
  String get planAddToDay => 'Add to this day';

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
  String get planDayEmpty => 'Free day';

  @override
  String planEstimated(String amount) {
    return '≈ $amount';
  }

  @override
  String get planFavorite => 'Pinned stop';

  @override
  String get planUnfavorite => 'Unpin';

  @override
  String get planHasLocation => 'Has location';

  @override
  String get planOpenInMaps => 'Open in maps';

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
  String get planTitleLabel => 'What';

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
  String get placeSearchHint => 'Search for a place';

  @override
  String get placeSearchAttribution => 'Search by OpenStreetMap Nominatim';

  @override
  String get placeNoResults => 'No places found. You can enter it manually.';

  @override
  String get placeRateLimited =>
      'Search is busy. Wait a moment or enter the place manually.';

  @override
  String get placeOffline =>
      'Search needs a connection. You can enter the place manually.';

  @override
  String get placeUnavailable =>
      'Search isn\'t available right now. Enter the place manually.';

  @override
  String get placeManualOnly =>
      'Place search is turned off. Enter a name and, if you know them, coordinates.';

  @override
  String get placeEnterManually => 'Enter manually';

  @override
  String get placeUseSearch => 'Search instead';

  @override
  String get planPlaceName => 'Place name (optional)';

  @override
  String get planLatitude => 'Latitude';

  @override
  String get planLongitude => 'Longitude';

  @override
  String get planInvalidCoordinates =>
      'Enter both latitude (−90 to 90) and longitude (−180 to 180), or leave both empty.';

  @override
  String get planRemoveCoordinates => 'Remove coordinates';

  @override
  String get planEstimatedCost => 'Estimated cost (optional)';

  @override
  String get planSaved => 'Plan saved';

  @override
  String get mapTilesUnavailable =>
      'Map tiles couldn\'t load. Saved places and member status still work.';

  @override
  String get mapLocationsUnavailable =>
      'Live locations are unavailable right now.';

  @override
  String get mapPeople => 'People';

  @override
  String get mapNoPlaces =>
      'No plans have coordinates yet. Add a place to see it on the map.';

  @override
  String mapDistance(String distance) {
    return 'About $distance from you';
  }

  @override
  String distanceMeters(int meters) {
    return '$meters m';
  }

  @override
  String distanceKm(String km) {
    return '$km km';
  }

  @override
  String get shareLive => 'Live';

  @override
  String get shareStale => 'Stale';

  @override
  String get sharePaused => 'Paused';

  @override
  String get shareNotSharing => 'Not sharing';

  @override
  String get shareStartTitle => 'Share your location';

  @override
  String get shareStartBody =>
      'Only current members of this tour can see it. It updates while the app is open and stops automatically.';

  @override
  String get share30Min => 'For 30 minutes';

  @override
  String get share2Hours => 'For 2 hours (recommended)';

  @override
  String get shareUntilTripEnds => 'Until the trip ends';

  @override
  String get shareActive => 'Sharing your location';

  @override
  String get shareActivePaused =>
      'Sharing paused while the app is in the background';

  @override
  String shareUntil(String time) {
    return 'Until $time';
  }

  @override
  String get shareStop => 'Stop';

  @override
  String shareLeftover(String time) {
    return 'Your last shared location ($time) is still visible to members.';
  }

  @override
  String get shareOff =>
      'Location sharing is off. Members only see you if you turn it on.';

  @override
  String get shareStart => 'Share';

  @override
  String get shareClosedTour =>
      'Location sharing is unavailable for closed tours.';

  @override
  String get shareServiceOff =>
      'Location services are turned off on this device.';

  @override
  String get sharePermissionDenied =>
      'Location permission wasn\'t granted, so sharing stopped.';

  @override
  String get sharePermissionForever =>
      'Location access is blocked for Tour Board. Enable it in system settings to share.';

  @override
  String get shareWriteFailed =>
      'Couldn\'t update your location. It\'ll retry with the next update.';

  @override
  String get shareOpenSettings => 'Open settings';

  @override
  String get inviteOff => 'Invites are turned off';

  @override
  String inviteShareText(String tour, String link, String code) {
    return 'Join \"$tour\" on Tour Board: $link\nOr open the app and enter code $code';
  }

  @override
  String inviteShareSubject(String tour) {
    return 'Join $tour on Tour Board';
  }

  @override
  String get inviteMembers => 'Invite people';

  @override
  String get inviteMembersHint => 'Share a link — you\'ll approve each request';

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
  String get inviteSection => 'Invite link';

  @override
  String get inviteCreate => 'Create link';

  @override
  String get inviteCreated => 'New invite link ready';

  @override
  String get inviteRotate => 'Get a new link';

  @override
  String get inviteRotateHint =>
      'The old link and code stop working immediately.';

  @override
  String get inviteTurnOff => 'Turn off invites';

  @override
  String get inviteExplainer =>
      'Anyone with the link can ask to join. Nobody gets access until a host or admin approves. Links expire after 14 days.';

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
  String get tourDeletePartial =>
      'Part of the tour was deleted. Run delete again to finish.';

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
}
