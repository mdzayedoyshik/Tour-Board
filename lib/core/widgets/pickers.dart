import 'package:flutter/material.dart';

import '../localization/l10n.dart';
import '../money/currency.dart';
import '../theme/app_theme.dart';
import '../utils/dates.dart';

/// Searchable list in a bottom sheet; returns the chosen value.
Future<T?> pickFromList<T>(
  BuildContext context, {
  required String title,
  required List<T> items,
  required String Function(T) label,
  T? selected,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _SearchList<T>(
      title: title,
      items: items,
      label: label,
      selected: selected,
    ),
  );
}

class _SearchList<T> extends StatefulWidget {
  const _SearchList({
    required this.title,
    required this.items,
    required this.label,
    this.selected,
  });

  final String title;
  final List<T> items;
  final String Function(T) label;
  final T? selected;

  @override
  State<_SearchList<T>> createState() => _SearchListState<T>();
}

class _SearchListState<T> extends State<_SearchList<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final filtered = q.isEmpty
        ? widget.items
        : widget.items
              .where((i) => widget.label(i).toLowerCase().contains(q))
              .toList();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  autofocus: false,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: context.l10n.commonSearch,
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final item = filtered[index];
                final isSelected = item == widget.selected;
                return ListTile(
                  title: Text(widget.label(item)),
                  trailing: isSelected ? const Icon(Icons.check) : null,
                  selected: isSelected,
                  onTap: () => Navigator.pop(context, item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Future<String?> pickCurrency(BuildContext context, String? selected) async {
  final c = await pickFromList<Currency>(
    context,
    title: context.l10n.currencyLabel,
    items: supportedCurrencies,
    label: (c) => c.code,
    selected: currencyForCode(selected),
  );
  return c?.code;
}

Future<String?> pickTimeZone(BuildContext context, String? selected) =>
    pickFromList<String>(
      context,
      title: context.l10n.timeZoneLabel,
      items: TimeZones.all(),
      label: (z) => z.replaceAll('_', ' '),
      selected: selected,
    );

/// A read-only field that opens a picker on tap; keeps form styling.
class PickerField extends StatelessWidget {
  const PickerField({
    required this.label,
    required this.value,
    required this.onTap,
    this.icon,
    this.errorText,
    super.key,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;
  final IconData? icon;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label: ${value ?? ''}',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            errorText: errorText,
            suffixIcon: Icon(icon ?? Icons.expand_more),
          ),
          isEmpty: value == null,
          child: value == null ? null : Text(value!),
        ),
      ),
    );
  }
}
