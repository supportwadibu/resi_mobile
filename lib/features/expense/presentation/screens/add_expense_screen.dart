import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/shared/widgets/app_callout.dart';
import 'package:resi_africa/shared/widgets/app_loader.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';
import 'package:resi_africa/shared/widgets/app_top_bar.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/router/role_guard.dart';
import '../../../../core/session/session_role.dart';
import '../../../property/business_logic/property_cubit.dart';
import '../../../property/business_logic/property_state.dart';
import '../../../residence/business_logic/residence_cubit.dart';
import '../../../residence/business_logic/residence_state.dart';
import '../../business_logic/add_expense_cubit.dart';
import '../../business_logic/add_expense_state.dart';
import '../../data/models/expense_model.dart';
import '../widgets/create/amount_field.dart';
import '../widgets/create/category_grid.dart';
import '../widgets/create/date_picker_field.dart';
import '../widgets/create/residence_dropdown.dart';
import '../widgets/create/save_expense_button.dart';

/// Saisie d'une dépense — création, ou modification si [expense] est fourni.
@RoutePage()
class AddExpenseScreen extends StatelessWidget {
  const AddExpenseScreen({super.key, this.expense});

  final ExpenseModel? expense;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Les biens du propriétaire alimentent le sélecteur : une dépense doit
        // être imputée à un bien existant, que l'API vérifie de son côté.
        BlocProvider(create: (_) => sl<PropertyCubit>()..load()),
        // Les résidences alimentent le second sélecteur : une charge commune —
        // électricité, gardien — se rattache au lieu et non à un logement.
        BlocProvider(create: (_) => sl<ResidenceCubit>()..load()),
        BlocProvider(create: (_) => sl<AddExpenseCubit>()),
      ],
      child: _AddExpenseView(expense: expense),
    );
  }
}

class _AddExpenseView extends StatefulWidget {
  const _AddExpenseView({this.expense});

  final ExpenseModel? expense;

  @override
  State<_AddExpenseView> createState() => _AddExpenseViewState();
}

class _AddExpenseViewState extends State<_AddExpenseView> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  String? _propertyId;
  String? _residenceId;

  /// Charge commune du lieu, plutôt que charge d’un logement.
  ///
  /// Porté par l’écran et non déduit des identifiants : le propriétaire choisit
  /// le type avant la cible, et les deux sélecteurs gardent leur valeur s’il
  /// revient en arrière.
  bool _isCommonCharge = false;
  ExpenseCategory? _category;
  late DateTime _spentAt;

  ExpenseModel? get _original => widget.expense;
  bool get _isEditing => _original != null;

  /// Une charge commune de résidence est-elle offerte à ce rôle ?
  ///
  /// `POST /gerant/expenses` exige un `property_id` et répond 422
  /// `property_required` sans lui : une charge commune n'est rattachée à aucun
  /// logement, porte sur la résidence entière — y compris des logements hors du
  /// périmètre du gérant — et entre dans le net du propriétaire, que le gérant
  /// ne voit pas. Le choix disparaît donc plutôt que d'échouer à l'envoi.
  ///
  /// Le rôle se lit sur la session, comme partout ailleurs dans le projet.
  late final bool _canChargeCommon = isGestureAllowed(
    sl<SessionRole>().value,
    'expense_common_charge',
  );

  @override
  void initState() {
    super.initState();

    final original = _original;
    _amountController = TextEditingController(
      text: original == null ? '' : original.amount.toInt().toString(),
    );
    _noteController = TextEditingController(text: original?.note ?? '');
    _propertyId = original?.propertyId;
    _residenceId = original?.residenceId;
    // Le rôle prime sur la dépense relue : le gérant n'ayant pas le type
    // commun, l'écran ne peut pas s'ouvrir dessus — il présenterait un
    // sélecteur de résidence sans le choix qui l'explique.
    _isCommonCharge = _canChargeCommon && (original?.isCommonCharge ?? false);
    _category = original?.category;
    _spentAt = original?.spentAt ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_amountController.text.trim()) ?? 0;

  /// Message bloquant, ou `null` si la saisie est complète.
  ///
  /// Les règles reprennent celles du validateur serveur : mieux vaut un refus
  /// immédiat et situé qu'une erreur 422 après coup.
  String? _validate() {
    if (_isCommonCharge && _residenceId == null) {
      return 'Choisissez la résidence concernée.';
    }
    if (!_isCommonCharge && _propertyId == null) {
      return 'Choisissez le bien concerné.';
    }
    if (_category == null) return 'Choisissez une catégorie.';
    if (_amount <= 0) return 'Indiquez un montant supérieur à zéro.';
    return null;
  }

  void _submit() {
    final error = _validate();
    if (error != null) {
      _showMessage(error);
      return;
    }

    final cubit = context.read<AddExpenseCubit>();
    final original = _original;

    if (original == null) {
      cubit.submit(
        propertyId: _isCommonCharge ? null : _propertyId,
        residenceId: _isCommonCharge ? _residenceId : null,
        category: _category!,
        amount: _amount,
        spentAt: _spentAt,
        note: _noteController.text,
      );
    } else {
      cubit.update(
        original: original,
        propertyId: _isCommonCharge ? null : _propertyId,
        residenceId: _isCommonCharge ? _residenceId : null,
        category: _category!,
        amount: _amount,
        spentAt: _spentAt,
        note: _noteController.text,
      );
    }
  }

  void _showMessage(String message) {
    AppToast.error(message, context: context);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _spentAt,
      firstDate: DateTime(2000),
      // Une dépense future n'a pas de sens dans un relevé de charges.
      lastDate: DateTime.now(),
    );

    if (picked != null) setState(() => _spentAt = picked);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddExpenseCubit, AddExpenseState>(
      listener: (context, state) {
        switch (state) {
          case AddExpenseSuccess():
            // `true` : l'écran d'historique s'en sert pour se recharger.
            context.router.maybePop(true);
          case AddExpenseFailure(:final message):
            _showMessage(message);
          default:
            break;
        }
      },
      builder: (context, state) {
        final isBusy = state is AddExpenseSubmitting;

        return Scaffold(
          appBar: AppTopBar(
            title: _isEditing ? 'Modifier la dépense' : 'Nouvelle dépense',
          ),
          bottomNavigationBar: SaveExpenseButton(
            onPressed: isBusy ? null : _submit,
            isBusy: isBusy,
            label: _isEditing ? 'Enregistrer les modifications' : null,
          ),
          body: AbsorbPointer(
            absorbing: isBusy,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Le montant ouvre la saisie : c'est la donnée que le
                  // propriétaire a en tête en arrivant sur l'écran, et la
                  // placer au troisième rang l'obligeait à parcourir deux
                  // sélecteurs avant de la poser.
                  AmountField(controller: _amountController),
                  const SizedBox(height: 24),
                  if (_canChargeCommon) ...[
                    const _FieldLabel('Type de dépense'),
                    _chargeKindPicker(),
                    const SizedBox(height: 20),
                  ],
                  _FieldLabel(
                    _isCommonCharge ? 'Résidence concernée' : 'Logement concerné',
                  ),
                  if (_isCommonCharge)
                    _residenceTargetPicker()
                  else
                    _residencePicker(),
                  const SizedBox(height: 20),
                  const _FieldLabel('Catégorie'),
                  CategoryGrid(
                    categories: ExpenseCategory.values,
                    selected: _category,
                    onSelected: (category) =>
                        setState(() => _category = category),
                  ),
                  const SizedBox(height: 20),
                  const _FieldLabel('Date'),
                  DatePickerField(
                    date: DateFormat('d MMMM yyyy', 'fr').format(_spentAt),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 20),
                  const _FieldLabel('Note', isOptional: true),
                  TextField(
                    controller: _noteController,
                    maxLength: 500,
                    maxLines: 2,
                    style: context.text.bodyMedium,
                    inputFormatters: [LengthLimitingTextInputFormatter(500)],
                    decoration: const InputDecoration(
                      hintText: 'Ex : facture de janvier',
                      // Le compteur de caractères double le libellé
                      // « facultatif » et alourdit la section pour une
                      // limite qu'une note courte n'approche jamais.
                      counterText: '',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Choix entre charge d’un logement et charge commune du lieu.
  ///
  /// Le type est demandé avant la cible : une charge commune n’a pas de
  /// logement, et présenter les deux sélecteurs ensemble laisserait croire
  /// qu’on peut renseigner les deux — ce que le serveur refuse.
  Widget _chargeKindPicker() {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<bool>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(
            value: false,
            icon: Icon(LucideIcons.doorOpen, size: 16),
            label: Text('Un logement'),
          ),
          ButtonSegment(
            value: true,
            icon: Icon(LucideIcons.building2, size: 16),
            label: Text('Partie commune'),
          ),
        ],
        selected: {_isCommonCharge},
        onSelectionChanged: (s) => setState(() => _isCommonCharge = s.first),
      ),
    );
  }

  /// Sélecteur de résidence, pour une charge commune.
  ///
  /// Réutilise `ResidenceDropdown`, dont le nom désigne historiquement un
  /// sélecteur d’identifiant quelconque et non la notion de résidence.
  Widget _residenceTargetPicker() {
    return BlocBuilder<ResidenceCubit, ResidenceState>(
      builder: (context, state) => switch (state) {
        ResidenceLoading() || ResidenceInitial() => const _PickerLoading(
          'Chargement de vos résidences...',
        ),
        ResidenceError(:final message) => _PickerNotice(message, isError: true),
        ResidenceLoaded(:final items) when items.isEmpty => const _PickerNotice(
          'Créez d’abord une résidence pour y imputer une charge commune.',
        ),
        ResidenceLoaded(:final items) => ResidenceDropdown(
          hint: 'Choisir une résidence',
          // La résidence d’une dépense en cours d’édition peut avoir été
          // supprimée : sans ce garde-fou, `DropdownButtonFormField` lèverait
          // sur une valeur absente de ses éléments.
          value: items.any((r) => r.id == _residenceId) ? _residenceId : null,
          residences: [
            for (final residence in items)
              ResidenceOption(id: residence.id, label: residence.name),
          ],
          onChanged: (value) => setState(() => _residenceId = value),
        ),
      },
    );
  }

  /// Sélecteur de bien, qui reflète l'état du chargement des annonces.
  Widget _residencePicker() {
    return BlocBuilder<PropertyCubit, PropertyState>(
      builder: (context, state) => switch (state) {
        PropertyLoading() ||
        PropertyInitial() => const _PickerLoading('Chargement de vos biens...'),
        PropertyError(:final message) => _PickerNotice(message, isError: true),
        PropertyLoaded(:final items) when items.isEmpty => const _PickerNotice(
          'Enregistrez d’abord un bien pour pouvoir y imputer une dépense.',
        ),
        PropertyLoaded(:final items) => ResidenceDropdown(
          // Le bien d'une dépense en cours d'édition peut avoir été supprimé :
          // sans ce garde-fou, `DropdownButtonFormField` lèverait sur une
          // valeur absente de ses éléments.
          value: items.any((p) => p.id == _propertyId) ? _propertyId : null,
          residences: [
            for (final property in items)
              ResidenceOption(id: property.id, label: property.title),
          ],
          onChanged: (value) => setState(() => _propertyId = value),
        ),
      },
    );
  }
}

/// Libellé d'un champ de la saisie.
///
/// Porte son propre espacement bas : réparti dans l'écran, il variait d'un
/// champ à l'autre (10 ici, 12 là) sans que rien ne le justifie.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {this.isOptional = false});

  final String text;

  /// Champ facultatif, signalé à côté du libellé plutôt que dans une
  /// parenthèse du texte : la mention est une information de saisie, pas une
  /// partie du nom du champ.
  final bool isOptional;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(text, style: context.text.titleSmall),
          if (isOptional) ...[
            const SizedBox(width: 6),
            Text('facultatif', style: context.text.bodySmall),
          ],
        ],
      ),
    );
  }
}

/// Attente du chargement d'un sélecteur.
class _PickerLoading extends StatelessWidget {
  const _PickerLoading(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const AppLoader(size: 20),
          const SizedBox(width: 10),
          Text(message, style: context.mutedText),
        ],
      ),
    );
  }
}

/// Message tenant la place d'un sélecteur qui n'a rien à proposer.
class _PickerNotice extends StatelessWidget {
  const _PickerNotice(this.message, {this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return AppCallout(
      icon: isError ? LucideIcons.circleAlert : LucideIcons.info,
      tone: isError ? AppAccent.red : AppAccent.neutral,
      message: message,
    );
  }
}
