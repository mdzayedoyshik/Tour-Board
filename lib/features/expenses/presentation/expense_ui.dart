import 'package:flutter/material.dart';

import '../../../core/localization/l10n.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/common.dart';
import '../../membership/domain/member.dart';
import '../domain/expense.dart';

IconData categoryIcon(ExpenseCategory c) => switch (c) {
  ExpenseCategory.food => Icons.restaurant_outlined,
  ExpenseCategory.transport => Icons.directions_bus_outlined,
  ExpenseCategory.stay => Icons.hotel_outlined,
  ExpenseCategory.activities => Icons.local_activity_outlined,
  ExpenseCategory.shopping => Icons.shopping_bag_outlined,
  ExpenseCategory.other => Icons.category_outlined,
};

String categoryLabel(AppLocalizations l10n, ExpenseCategory c) => switch (c) {
  ExpenseCategory.food => l10n.categoryFood,
  ExpenseCategory.transport => l10n.categoryTransport,
  ExpenseCategory.stay => l10n.categoryStay,
  ExpenseCategory.activities => l10n.categoryActivities,
  ExpenseCategory.shopping => l10n.categoryShopping,
  ExpenseCategory.other => l10n.categoryOther,
};

/// Display name for a UID, falling back for unknown/historical members and
/// labelling the viewer as "You".
String memberName(
  BuildContext context,
  Map<String, Member> members,
  String uid, {
  String? viewerUid,
}) {
  if (uid == viewerUid) return context.l10n.commonYou;
  return members[uid]?.displayName ?? context.l10n.commonUnknownMember;
}

/// Photo (or initials) for a UID; unknown/historical members get "?".
class MemberUidAvatar extends StatelessWidget {
  const MemberUidAvatar({
    required this.members,
    required this.uid,
    this.size = AppSizes.avatarSm,
    super.key,
  });

  final Map<String, Member> members;
  final String uid;
  final double size;

  @override
  Widget build(BuildContext context) {
    final m = members[uid];
    return MemberAvatar(
      name: m?.displayName ?? '?',
      photoUrl: m?.photoUrl,
      size: size,
    );
  }
}

/// One line of text led by a member's small photo ("Paid by X · …").
class MemberCaption extends StatelessWidget {
  const MemberCaption({
    required this.members,
    required this.uid,
    required this.text,
    this.style,
    super.key,
  });

  final Map<String, Member> members;
  final String uid;
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MemberUidAvatar(members: members, uid: uid, size: AppSizes.avatarXs),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            text,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Distinct, accessible hue per category (tinted backgrounds via IconBadge).
Color categoryColor(ExpenseCategory c) => switch (c) {
  ExpenseCategory.food => const Color(0xFFEA580C),
  ExpenseCategory.transport => const Color(0xFF2563EB),
  ExpenseCategory.stay => const Color(0xFF7C3AED),
  ExpenseCategory.activities => const Color(0xFFDB2777),
  ExpenseCategory.shopping => const Color(0xFF0D9488),
  ExpenseCategory.other => const Color(0xFF64748B),
};

class CategoryIcon extends StatelessWidget {
  const CategoryIcon(this.category, {this.size = 44, super.key});

  final ExpenseCategory category;
  final double size;

  @override
  Widget build(BuildContext context) => IconBadge(
    icon: categoryIcon(category),
    color: categoryColor(category),
    size: size,
    semanticLabel: categoryLabel(context.l10n, category),
  );
}

/// Plain-language balance: "You should receive …", "You owe …".
class BalanceLine extends StatelessWidget {
  const BalanceLine({
    required this.net,
    required this.currencyCode,
    this.subject,
    this.style,
    super.key,
  });

  final int net;
  final String currencyCode;

  /// Name for third-person phrasing; null means "you".
  final String? subject;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = StatusColors.of(context);
    final amount = formatMoney(
      net.abs(),
      currencyCode,
      locale: context.localeTag,
    );
    final (text, color, icon) = net > 0
        ? (
            subject == null
                ? l10n.balanceYouReceive(amount)
                : l10n.balanceTheyReceive(subject!, amount),
            colors.success,
            Icons.south_west,
          )
        : net < 0
        ? (
            subject == null
                ? l10n.balanceYouOwe(amount)
                : l10n.balanceTheyOwe(subject!, amount),
            colors.error,
            Icons.north_east,
          )
        : (
            subject == null
                ? l10n.balanceYouSettled
                : l10n.balanceTheySettled(subject!),
            colors.muted,
            Icons.check,
          );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSizes.iconSm, color: color),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            text,
            style: (style ?? Theme.of(context).textTheme.bodyMedium)?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
