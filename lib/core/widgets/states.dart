import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/app_error.dart';
import '../localization/l10n.dart';
import '../theme/app_theme.dart';
import 'buttons.dart';

/// Centered column used by empty/error states.
class _StateLayout extends StatelessWidget {
  const _StateLayout({
    required this.icon,
    required this.title,
    this.message,
    this.actions = const [],
  });

  final IconData icon;
  final String title;
  final String? message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.sm),
                  actions[i],
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    this.message,
    this.actions = const [],
    super.key,
  });

  final IconData icon;
  final String title;
  final String? message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => _StateLayout(
    icon: icon,
    title: title,
    message: message,
    actions: actions,
  );
}

class ErrorState extends StatelessWidget {
  const ErrorState({required this.error, this.onRetry, super.key});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final kind = classifyError(error);
    if (kind == AppErrorKind.permissionDenied) {
      return const AccessRevokedView();
    }
    return _StateLayout(
      icon: kind == AppErrorKind.network
          ? Icons.cloud_off_outlined
          : Icons.error_outline,
      title: errorMessage(context, error),
      actions: [
        if (onRetry != null)
          SecondaryButton(
            label: context.l10n.commonRetry,
            onPressed: onRetry,
            expand: false,
          ),
      ],
    );
  }
}

/// Shown when a stream fails with permission-denied: the user was removed
/// from the tour or left it.
class AccessRevokedView extends StatelessWidget {
  const AccessRevokedView({this.onBack, super.key});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => _StateLayout(
    icon: Icons.lock_outline,
    title: context.l10n.stateAccessRevoked,
    message: context.l10n.stateAccessRevokedBody,
    actions: [
      if (onBack != null)
        SecondaryButton(
          label: context.l10n.commonBack,
          onPressed: onBack,
          expand: false,
        ),
    ],
  );
}

/// Lightweight skeleton list shown while the first snapshot loads.
class LoadingList extends StatelessWidget {
  const LoadingList({this.count = 6, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHigh;
    return Semantics(
      label: context.l10n.commonLoading,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.page),
        itemCount: count,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 12, width: 160, color: color),
                    const SizedBox(height: AppSpacing.sm),
                    Container(height: 10, width: 100, color: color),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Semantics(
      label: context.l10n.commonLoading,
      child: const CircularProgressIndicator(),
    ),
  );
}

/// Renders an [AsyncValue] with consistent loading and error states.
/// Keeps showing previous data while refreshing.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    required this.value,
    required this.data,
    this.onRetry,
    this.loading,
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    if (value.hasValue) return data(value.requireValue);
    if (value.hasError) {
      return ErrorState(error: value.error!, onRetry: onRetry);
    }
    return loading ?? const LoadingList();
  }
}

/// Thin informational banner (offline/cached, pending sync, closed tour).
class InlineBanner extends StatelessWidget {
  const InlineBanner({
    required this.icon,
    required this.message,
    this.color,
    this.action,
    super.key,
  });

  final IconData icon;
  final String message;
  final Color? color;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = color ?? theme.colorScheme.onSurfaceVariant;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        color: theme.colorScheme.surfaceContainerLow,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.page,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(icon, size: AppSizes.iconSm, color: fg),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(color: fg),
              ),
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}
