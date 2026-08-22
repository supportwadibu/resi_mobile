import 'package:flutter/material.dart';
import 'package:resi_africa/shared/widgets/app_text_field.dart';

/// Identification du bien : titre et description.
///
/// L'API impose un titre d'au moins 3 caractères et une description d'au moins
/// 10 : les deux remontent séparément, le titre n'étant pas déductible de la
/// description.
class StepIdentificationWidget extends StatefulWidget {
  const StepIdentificationWidget({
    super.key,
    required this.title,
    required this.description,
    required this.onTitleChanged,
    required this.onDescriptionChanged,
  });

  final String title;
  final String description;
  final void Function(String) onTitleChanged;
  final void Function(String) onDescriptionChanged;

  @override
  State<StepIdentificationWidget> createState() =>
      _StepIdentificationWidgetState();
}

class _StepIdentificationWidgetState extends State<StepIdentificationWidget> {
  late final TextEditingController _nameCtrl = TextEditingController(
    text: widget.title,
  );
  late final TextEditingController _descCtrl = TextEditingController(
    text: widget.description,
  );

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          label: 'Nom du bien',
          hint: 'Ex: Villa Belvédère, Appart Cocody...',
          controller: _nameCtrl,
          prefixIcon: const Icon(Icons.home_outlined, size: 18),
          onChanged: widget.onTitleChanged,
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Description',
          hint: 'Décrivez votre bien en quelques mots...',
          controller: _descCtrl,
          maxLines: 4,
          onChanged: widget.onDescriptionChanged,
        ),
      ],
    );
  }
}
