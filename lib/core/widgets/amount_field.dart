import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../localization/l10n.dart';
import '../money/currency.dart';
import '../money/money.dart';

/// Amount input that parses into integer minor units.
///
/// Accepts digits plus the locale decimal separator (and '.'), limits
/// fraction digits to the currency exponent and reports the parsed value via
/// [onChanged] — null while the input is invalid.
class AmountField extends StatefulWidget {
  const AmountField({
    required this.currency,
    required this.onChanged,
    this.initialMinor,
    this.label,
    this.large = false,
    this.allowZero = false,
    this.optional = false,
    this.autofocus = false,
    this.focusNode,
    this.textInputAction,
    super.key,
  });

  final Currency currency;
  final ValueChanged<int?> onChanged;
  final int? initialMinor;
  final String? label;
  final bool large;
  final bool allowZero;

  /// Empty input is valid (reported as null) for optional amounts.
  final bool optional;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;

  @override
  State<AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<AmountField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialMinor == null
          ? ''
          : minorToPlainString(widget.initialMinor!, widget.currency),
    );
  }

  @override
  void didUpdateWidget(AmountField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currency != widget.currency) {
      // Re-validate against the new exponent.
      WidgetsBinding.instance.addPostFrameCallback((_) => _emit());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  AmountParseResult _parse(String text) {
    final seps = numberSeparators(context.localeTag);
    return parseAmount(
      text,
      widget.currency,
      decimalSeparator: seps.decimal,
      groupSeparator: seps.group,
      allowZero: widget.allowZero,
    );
  }

  void _emit() {
    if (!mounted) return;
    widget.onChanged(_parse(_controller.text).minor);
  }

  String? _validate(String? text) {
    if (widget.optional && (text ?? '').trim().isEmpty) return null;
    final result = _parse(text ?? '');
    final l10n = context.l10n;
    return switch (result.error) {
      null => null,
      AmountParseError.empty => l10n.amountRequired,
      AmountParseError.invalid => l10n.amountInvalid,
      AmountParseError.tooManyDecimals => l10n.amountTooManyDecimals(
        widget.currency.minorDigits,
      ),
      AmountParseError.notPositive => l10n.amountMustBePositive,
      AmountParseError.tooLarge => l10n.amountTooLarge,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final seps = numberSeparators(context.localeTag);
    final allowed = RegExp(
      '[0-9${RegExp.escape(seps.decimal)}${seps.decimal == '.' ? '' : r'\.'}]',
    );
    return TextFormField(
      controller: _controller,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      textInputAction: widget.textInputAction,
      keyboardType: TextInputType.numberWithOptions(
        decimal: widget.currency.minorDigits > 0,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(allowed),
        LengthLimitingTextInputFormatter(16),
      ],
      style: widget.large
          ? theme.textTheme.headlineMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            )
          : null,
      decoration: InputDecoration(
        labelText: widget.label ?? context.l10n.amountLabel,
        suffixText: widget.currency.code,
        hintText: minorToPlainString(0, widget.currency),
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: _validate,
      onChanged: (_) => _emit(),
    );
  }
}
