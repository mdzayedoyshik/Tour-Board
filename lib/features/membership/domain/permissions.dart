import '../../tours/domain/tour.dart';
import 'member.dart';

/// UI-side evaluation of the permission matrix (brief §7).
///
/// This only decides what to *show*. Firestore Security Rules enforce the same
/// matrix server-side; keep both in sync when changing anything here.
class TourPermissions {
  const TourPermissions({required this.tour, required this.viewer});

  final Tour tour;

  /// The signed-in user's member record, or null if they are not a member.
  final Member? viewer;

  bool get isMember => viewer?.isActive ?? false;
  bool get isHost => isMember && viewer!.role == MemberRole.host;
  bool get isAdmin => isMember && viewer!.role == MemberRole.admin;
  bool get isHostOrAdmin => isHost || isAdmin;

  bool get canView => isMember;

  // --- Expenses ---------------------------------------------------------

  bool get canAddExpense => isMember && tour.isOpen;

  /// Whether the viewer may pick a payer other than themselves.
  bool get canRecordForOthers =>
      canAddExpense &&
      (isHostOrAdmin || tour.settings.membersCanRecordForOthers);

  bool canEditExpense(String createdBy) =>
      isMember && tour.isOpen && (createdBy == viewer!.uid || isHostOrAdmin);

  // --- Plans and notes (same ownership model) ---------------------------

  bool get canAddContent => isMember && tour.isOpen;

  bool canEditContent(String createdBy) =>
      isMember && tour.isOpen && (createdBy == viewer!.uid || isHostOrAdmin);

  // --- Packing ------------------------------------------------------------

  bool get canEditPacking =>
      isMember &&
      tour.isOpen &&
      (isHostOrAdmin || tour.settings.membersCanEditPacking);

  bool canDeletePackingItem(String createdBy) =>
      canEditPacking && (createdBy == viewer!.uid || isHostOrAdmin);

  // --- Membership -----------------------------------------------------------

  bool get canReviewJoinRequests => isHostOrAdmin;
  bool get canManageInvites => isHostOrAdmin;

  /// Host can remove anyone but themselves; admins can remove ordinary members.
  bool canRemoveMember(Member target) {
    if (!isMember || !target.isActive || target.uid == viewer!.uid) {
      return false;
    }
    if (target.isHost) return false;
    if (isHost) return true;
    return isAdmin && target.role == MemberRole.member;
  }

  bool get canChangeRoles => isHost;
  bool get canTransferHost => isHost;

  /// The host must transfer hosting before leaving.
  bool get canLeave => isMember && !isHost;

  // --- Tour settings ----------------------------------------------------------

  bool get canEditTourDetails =>
      isHost || (isAdmin && tour.settings.adminsCanManageTour);

  bool get canChangeStatus => canEditTourDetails;
  bool get canChangeSettings => isHost;
  bool get canDeleteTour => isHost && tour.status == TourStatus.archived;

  // --- Location -----------------------------------------------------------------

  bool get canShareLocation => isMember && tour.isOpen;
  bool get canViewLocations => isMember;
}
