import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';

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
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
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
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey200,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: TextField(
                autofocus: false,
                onChanged: _filter,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  filled: true,
                  fillColor: AppColors.surface,
                  prefixIcon: const Icon(Icons.search, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Text(
                        widget.emptyLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.grey500,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _filtered.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: AppColors.divider),
                      itemBuilder: (_, i) => ListTile(
                        title: Text(
                          _filtered[i],
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
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
