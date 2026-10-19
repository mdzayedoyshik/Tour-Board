import 'package:flutter_test/flutter_test.dart';
import 'package:tour_board/features/membership/domain/member.dart';
import 'package:tour_board/features/membership/domain/permissions.dart';
import 'package:tour_board/features/settlements/domain/settlement.dart';
import 'package:tour_board/features/tours/domain/tour.dart';

final _t = DateTime.utc(2026, 1, 1);

Tour tour({
  TourStatus status = TourStatus.active,
  TourSettings settings = const TourSettings(),
}) => Tour(
  id: 't',
  name: 'Trip',
  hostUid: 'host',
  status: status,
  startAt: _t,
  endAt: _t,
  timeZone: 'UTC',
  currencyCode: 'BDT',
  createdAt: _t,
  updatedAt: _t,
  settings: settings,
);

Member member(
  String uid,
  MemberRole role, {
  MemberStatus status = MemberStatus.active,
}) => Member(
  uid: uid,
  displayName: uid,
  role: role,
  status: status,
  joinedAt: _t,
);

void main() {
  final host = member('host', MemberRole.host);
  final admin = member('admin', MemberRole.admin);
  final alice = member('alice', MemberRole.member);
  final bob = member('bob', MemberRole.member);

  TourPermissions p(Member? viewer, {Tour? t}) =>
      TourPermissions(tour: t ?? tour(), viewer: viewer);

  test('non-members and removed members cannot view', () {
    expect(p(null).canView, isFalse);
    expect(
      p(member('x', MemberRole.member, status: MemberStatus.removed)).canView,
      isFalse,
    );
    expect(p(alice).canView, isTrue);
  });

  test('members edit only their own expenses; admins edit any', () {
    expect(p(alice).canEditExpense('alice'), isTrue);
    expect(p(alice).canEditExpense('bob'), isFalse);
    expect(p(admin).canEditExpense('bob'), isTrue);
    expect(p(host).canEditExpense('bob'), isTrue);
  });

  test('closed tours freeze ordinary content for everyone', () {
    final closed = tour(status: TourStatus.closed);
    expect(p(alice, t: closed).canAddExpense, isFalse);
    expect(p(host, t: closed).canEditExpense('host'), isFalse);
    expect(p(alice, t: closed).canAddContent, isFalse);
    expect(p(host, t: closed).canChangeStatus, isTrue);
  });

  test('recording for others follows the tour setting', () {
    expect(p(alice).canRecordForOthers, isFalse);
    expect(p(admin).canRecordForOthers, isTrue);
    final open = tour(
      settings: const TourSettings(membersCanRecordForOthers: true),
    );
    expect(p(alice, t: open).canRecordForOthers, isTrue);
  });

  test('member management', () {
    expect(p(host).canRemoveMember(admin), isTrue);
    expect(p(host).canRemoveMember(host), isFalse);
    expect(p(admin).canRemoveMember(alice), isTrue);
    expect(p(admin).canRemoveMember(host), isFalse);
    expect(p(alice).canRemoveMember(bob), isFalse);
    expect(p(alice).canChangeRoles, isFalse);
    expect(p(admin).canChangeRoles, isFalse);
    expect(p(host).canTransferHost, isTrue);
    expect(p(host).canLeave, isFalse);
    expect(p(alice).canLeave, isTrue);
  });

  test('admin tour management depends on setting', () {
    expect(p(admin).canEditTourDetails, isTrue);
    final locked = tour(
      settings: const TourSettings(adminsCanManageTour: false),
    );
    expect(p(admin, t: locked).canEditTourDetails, isFalse);
    expect(p(host, t: locked).canEditTourDetails, isTrue);
    expect(p(admin).canChangeSettings, isFalse);
  });

  test('tour deletion requires archived status and host', () {
    expect(p(host).canDeleteTour, isFalse);
    expect(p(host, t: tour(status: TourStatus.archived)).canDeleteTour, isTrue);
    expect(
      p(admin, t: tour(status: TourStatus.archived)).canDeleteTour,
      isFalse,
    );
  });

  group('settlement actions', () {
    final s = Settlement(
      id: 's',
      fromUid: 'alice',
      toUid: 'admin',
      amountMinor: 100,
      currencyCode: 'BDT',
      status: SettlementStatus.pendingConfirmation,
      createdBy: 'alice',
      createdAt: _t,
      updatedAt: _t,
    );

    SettlementActions a(Member viewer, {bool active = true, Settlement? x}) =>
        SettlementActions(
          settlement: x ?? s,
          permissions: p(viewer),
          counterpartyIsActive: active,
        );

    test('only the counterparty confirms or disputes', () {
      expect(a(admin).canConfirm, isTrue);
      expect(a(admin).canDispute, isTrue);
      expect(a(alice).canConfirm, isFalse);
      expect(a(alice).canCancel, isTrue);
      expect(a(bob).canConfirm, isFalse);
    });

    test('uninvolved admin may confirm only if counterparty is inactive', () {
      expect(a(host).canConfirm, isFalse);
      expect(a(host, active: false).canConfirm, isTrue);
    });

    test('confirmed settlements are final', () {
      final done = Settlement(
        id: 's',
        fromUid: 'alice',
        toUid: 'admin',
        amountMinor: 100,
        currencyCode: 'BDT',
        status: SettlementStatus.confirmed,
        createdBy: 'alice',
        createdAt: _t,
        updatedAt: _t,
      );
      expect(a(admin, x: done).canConfirm, isFalse);
      expect(a(alice, x: done).canCancel, isFalse);
    });
  });
}
