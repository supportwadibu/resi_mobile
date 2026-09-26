import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/widgets/app_sheet.dart';

/// Ouvre une liste d'options avec recherche incrémentale.
///
/// Renvoie l'option choisie, ou `null` si la feuille est fermée sans
/// sélection.
Future<String?> showAppOptionPicker({
  required BuildContext context,
  required List<String> options,
  String searchHint = 'Rechercher',
  String emptyLabel = 'Aucun résultat',
}) {
  return showAppSheet<String>(
    context: context,
    builder: (_) => _OptionPickerSheet(
      options: options,
      searchHint: searchHint,
      emptyLabel: emptyLabel,
    ),
  );
}

class _OptionPickerSheet extends StatefulWidget {
  const _OptionPickerSheet({
    required this.options,
    required this.searchHint,
    required this.emptyLabel,
  });

  final List<String> options;
  final String searchHint;
  final String emptyLabel;

  @override
  State<_OptionPickerSheet> createState() => _OptionPickerSheetState();
}

class _OptionPickerSheetState extends State<_OptionPickerSheet> {
  late List<String> _filtered = widget.options;

  void _filter(String query) {
    final normalized = query.trim().toLowerCase();
    setState(() {
      _filtered = normalized.isEmpty
          ? widget.options
          : widget.options
                .where((o) => o.toLowerCase().contains(normalized))
                .toList(growable: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                autofocus: false,
                onChanged: _filter,
                style: context.text.bodyMedium,
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  prefixIcon: const Icon(LucideIcons.search, size: 16),
                ),
              ),
            ),
            Divider(height: 1, color: t.border),
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Text(
                        widget.emptyLabel,
                        style: context.text.bodyMedium!.copyWith(
                          color: t.muted,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _filtered.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, i) => ListTile(
                        title: Text(
                          _filtered[i],
                          style: context.text.bodyMedium,
                        ),
                        onTap: () => Navigator.of(context).pop(_filtered[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
