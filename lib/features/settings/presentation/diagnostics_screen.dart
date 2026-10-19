import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/widgets/common.dart';
import '../../../data/firebase/firestore_streams.dart';

/// Developer-only view of quota-relevant state. Shows counts only — never
/// document contents or other members' data.
class DiagnosticsScreen extends ConsumerWidget {
  const DiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final config = ref.watch(appConfigProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.diagnosticsTitle)),
      body: ContentWidth(
        child: ListView(
          children: [
            ValueListenableBuilder<int>(
              valueListenable: activeListenerCount,
              builder: (context, count, _) => ListTile(
                title: Text(l10n.diagListeners),
                trailing: Text('$count'),
              ),
            ),
            ValueListenableBuilder<int>(
              valueListenable: pendingWriteCount,
              builder: (context, count, _) => ListTile(
                title: Text(l10n.diagPendingWrites),
                trailing: Text('$count'),
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: lastSnapshotFromCache,
              builder: (context, cached, _) => ListTile(
                title: Text(l10n.diagFromCache),
                trailing: Text(cached ? l10n.diagYes : l10n.diagNo),
              ),
            ),
            ListTile(
              title: Text(l10n.diagEnvironment),
              trailing: Text(config.environment),
            ),
            ListTile(
              title: Text(l10n.diagEmulator),
              trailing: Text(
                config.useFirebaseEmulator ? l10n.diagYes : l10n.diagNo,
              ),
            ),
            ListTile(
              title: Text(l10n.diagPlaceSearch),
              trailing: Text(config.placeSearchProvider),
            ),
          ],
        ),
      ),
    );
  }
}
