import 'package:flutter/material.dart';
import '../../data/models/client_filter_model.dart';

/// Filtre du carnet, en segments d'égale largeur.
class ClientFilterTabs extends StatelessWidget {
  final ClientFilter selected;
  final ValueChanged<ClientFilter> onChanged;

  const ClientFilterTabs({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<ClientFilter>(
        showSelectedIcon: false,
        segments: [
          for (final f in ClientFilter.values)
            ButtonSegment(value: f, label: Text(f.label)),
        ],
        selected: {selected},
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    );
  }
}
