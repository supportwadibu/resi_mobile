import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/service_locator.dart';
import '../../../property/business_logic/property_cubit.dart';
import '../../../property/business_logic/property_state.dart';
import '../../../residence/business_logic/residence_cubit.dart';
import '../../../residence/business_logic/residence_state.dart';
import '../../business_logic/add_expense_cubit.dart';
import '../../business_logic/add_expense_state.dart';
import '../../data/models/expense_model.dart';
import '../widgets/create/add_expense_header.dart';
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
    _isCommonCharge = original?.isCommonCharge ?? false;
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
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _spentAt,
      firstDate: DateTime(2000),
      // Une dépense future n'a pas de sens dans un relevé de charges.
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Colors.black,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
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
          backgroundColor: Colors.white,

          body: SafeArea(
            child: AbsorbPointer(
              absorbing: isBusy,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AddExpenseHeader(
                      title: _isEditing
                          ? 'Modifier la dépense'
                          : 'Nouvelle dépense',
                    ),

                    const SizedBox(height: 40),

                    const Text("Type de dépense"),
                    const SizedBox(height: 10),
                    _chargeKindPicker(),

                    const SizedBox(height: 24),

                    Text(
                      _isCommonCharge
                          ? "Sélectionner la résidence"
                          : "Sélectionner le logement",
                    ),
                    const SizedBox(height: 10),
                    if (_isCommonCharge) _residenceTargetPicker() else _residencePicker(),

                    const SizedBox(height: 24),

                    const Text("Montant de la dépense (Fcfa)"),
                    const SizedBox(height: 10),
                    AmountField(controller: _amountController),

                    const SizedBox(height: 24),

                    const Text("Catégorie"),
                    const SizedBox(height: 12),
                    CategoryGrid(
                      categories: ExpenseCategory.values,
                      selected: _category,
                      onSelected: (category) =>
                          setState(() => _category = category),
                    ),

                    const SizedBox(height: 24),

                    const Text("Date"),
                    const SizedBox(height: 10),
                    DatePickerField(
                      date: DateFormat('dd MMMM yyyy', 'fr').format(_spentAt),
                      onTap: _pickDate,
                    ),

                    const SizedBox(height: 24),

                    const Text("Note (facultatif)"),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _noteController,
                      maxLength: 500,
                      maxLines: 2,
                      inputFormatters: [LengthLimitingTextInputFormatter(500)],
                      decoration: InputDecoration(
                        hintText: 'Ex : facture de janvier',
                        filled: true,
                        fillColor: const Color(0xffF5F5FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    SaveExpenseButton(
                      onPressed: isBusy ? null : _submit,
                      label: switch ((isBusy, _isEditing)) {
                        (true, _) => 'Enregistrement...',
                        (false, true) => 'Enregistrer les modifications',
                        (false, false) => null,
                      },
                    ),
                  ],
                ),
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
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(
          value: false,
          label: Text('Un logement'),
          icon: Icon(Icons.meeting_room_outlined, size: 18),
        ),
        ButtonSegment(
          value: true,
          label: Text('Partie commune'),
          icon: Icon(Icons.apartment_outlined, size: 18),
        ),
      ],
      selected: {_isCommonCharge},
      showSelectedIcon: false,
      onSelectionChanged: (selection) =>
          setState(() => _isCommonCharge = selection.first),
    );
  }

  /// Sélecteur de résidence, pour une charge commune.
  ///
  /// Réutilise `ResidenceDropdown`, dont le nom désigne historiquement un
  /// sélecteur d’identifiant quelconque et non la notion de résidence.
  Widget _residenceTargetPicker() {
    return BlocBuilder<ResidenceCubit, ResidenceState>(
      builder: (context, state) => switch (state) {
        ResidenceLoading() || ResidenceInitial() => const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text(
                'Chargement de vos résidences...',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        ResidenceError(:final message) => Text(
          message,
          style: const TextStyle(fontSize: 12, color: Colors.red),
        ),
        ResidenceLoaded(:final items) when items.isEmpty => Text(
          'Créez d’abord une résidence pour y imputer une charge commune.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
        PropertyLoading() || PropertyInitial() => const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text(
                'Chargement de vos biens...',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        PropertyError(:final message) => Text(
          message,
          style: const TextStyle(fontSize: 12, color: Colors.red),
        ),
        PropertyLoaded(:final items) when items.isEmpty => Text(
          'Enregistrez d’abord un bien pour pouvoir y imputer une dépense.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
