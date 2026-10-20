import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../localization/l10n.dart';
import '../theme/app_theme.dart';
import 'buttons.dart';

/// Small rounded label for status. Always includes text (and optionally an
/// icon) so meaning never relies on color alone.
class StatusPill extends StatelessWidget {
  const StatusPill({required this.label, this.color, this.icon, super.key});

  final String label;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = color ?? theme.colorScheme.onSurfaceVariant;
    final dark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        // Tonal fill tuned per brightness so the label stays readable.
        color: fg.withValues(alpha: dark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {this.trailing, super.key});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.xl,
        AppSpacing.page,
        AppSpacing.sm,
      ),
      child: Semantics(
        header: true,
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// Constrains content width on tablets so layouts do not stretch.
class ContentWidth extends StatelessWidget {
  const ContentWidth({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
      child: child,
    ),
  );
}

/// Bottom-sheet confirmation for destructive or financially meaningful
/// actions. Resolves to true only on explicit confirmation.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      final theme = Theme.of(context);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            0,
            AppSpacing.page,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleLarge),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              if (destructive)
                DestructiveButton(
                  label: confirmLabel,
                  onPressed: () => Navigator.pop(context, true),
                )
              else
                PrimaryButton(
                  label: confirmLabel,
                  onPressed: () => Navigator.pop(context, true),
                ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(context.l10n.commonCancel),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  return result ?? false;
}

/// Prompts for a short text (e.g. a dispute reason).
Future<String?> promptText(
  BuildContext context, {
  required String title,
  required String label,
  required String confirmLabel,
  int maxLength = 120,
  String? initial,
  bool required = true,
}) {
  final controller = TextEditingController(text: initial);
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.page,
        right: AppSpacing.page,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: StatefulBuilder(
        builder: (context, setState) {
          final text = controller.text.trim();
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: maxLength,
                decoration: InputDecoration(labelText: label),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: confirmLabel,
                onPressed: required && text.isEmpty
                    ? null
                    : () => Navigator.pop(context, text),
              ),
            ],
          );
        },
      ),
    ),
  ).whenComplete(controller.dispose);
}

void showAppSnack(BuildContext context, String message, {bool error = false}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  if (error) {
    HapticFeedback.mediumImpact();
  } else {
    HapticFeedback.lightImpact();
  }
}

/// A card-like tappable row container with consistent padding.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: Elevations.of(context).card,
      ),
      child: Material(
        color: dark ? theme.colorScheme.surfaceContainerLow : Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: BorderSide(
            color: dark
                ? theme.colorScheme.outlineVariant
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// A rounded square with a tinted background holding an icon (category,
/// place, settings rows).
class IconBadge extends StatelessWidget {
  const IconBadge({
    required this.icon,
    required this.color,
    this.size = 44,
    this.semanticLabel,
    super.key,
  });

  final IconData icon;
  final Color color;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? 0.22 : 0.13),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(
        icon,
        size: size * 0.5,
        color: dark ? Color.lerp(color, Colors.white, 0.35) : color,
        semanticLabel: semanticLabel,
      ),
    );
  }
}

/// Small section label inside forms and detail pages.
class FormSectionLabel extends StatelessWidget {
  const FormSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ),
  );
}
