import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/features/property/business_logic/create_property_cubit.dart';
import 'package:resi_africa/features/property/business_logic/create_property_state.dart';
import 'package:resi_africa/features/property/business_logic/edit_property_cubit.dart';
import 'package:resi_africa/features/property/business_logic/edit_property_state.dart';
import 'package:resi_africa/features/property/data/models/property_model.dart';
import 'package:resi_africa/features/property/presentation/screens/add_property_screen.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';

/// Cubit piloté par le test : ni service locator, ni réseau.
class _FakeEditCubit extends Cubit<EditPropertyState>
    implements EditPropertyCubit {
  _FakeEditCubit() : super(const EditPropertyIdle());

  int submitCount = 0;

  @override
  Future<void> submit({
    required PropertyModel original,
    required String title,
    required String description,
    required PropertyType propertyType,
    required PropertyAddress address,
    required PropertyDetails details,
    required Set<Amenity> amenities,
    required List<String> images,
    required PropertyPricing pricing,
  }) async {
    submitCount++;
  }

  /// Rejoue l'issue du serveur, que le vrai cubit émettrait après l'appel.
  void succeed(PropertyModel property, {bool unchanged = false}) {
    emit(EditPropertySuccess(property, unchanged: unchanged));
  }
}

/// Routeur de test réduit à `maybePop`.
///
/// L'écran appelle `context.router` pour se fermer, ce qui exigerait un
/// [AutoRouter] et, avec lui, tout le graphe de routes de l'application. Seul
/// le nombre de fermetures demandées nous intéresse ici : `noSuchMethod`
/// absorbe le reste du contrat de [StackRouter], qui n'est jamais sollicité.
class _FakeStackRouter implements StackRouter {
  _FakeStackRouter(this.navigatorKey);

  @override
  final GlobalKey<NavigatorState> navigatorKey;

  /// Délègue à `Navigator.maybePop`, comme le vrai routeur.
  ///
  /// C'est ce qui donne sa valeur au test : la demande traverse le [PopScope]
  /// de l'écran, seul endroit où une fermeture peut être refusée. Un faux qui
  /// se contenterait de compter les appels validerait un écran dont le garde
  /// bloque encore la sortie — et compter les fermetures obtenues ne suffirait
  /// pas non plus, un `maybePop` pouvant n'emporter que le dialog. Ce que les
  /// tests vérifient est donc la page réellement affichée à l'arrivée.
  @override
  Future<bool> maybePop<T extends Object?>([T? result]) =>
      navigatorKey.currentState!.maybePop<T>(result);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Pendant de [_FakeEditCubit] pour le parcours de dépôt.
class _FakeCreateCubit extends Cubit<CreatePropertyState>
    implements CreatePropertyCubit {
  _FakeCreateCubit() : super(const CreatePropertyIdle());

  @override
  Future<void> submit({
    required String title,
    required String description,
    required PropertyType propertyType,
    required PropertyAddress address,
    required PropertyDetails details,
    required Set<Amenity> amenities,
    required List<String> imagePaths,
    required PropertyPricing pricing,
    required DateTime availableFrom,
    bool chargesIncluded = false,
    double? additionalCharges,
  }) async {}
}

PropertyModel _property({
  String title = 'Villa Belvédère',
  double dailyPrice = 15000,
  List<PriceTier> priceTiers = const [],
  List<String> images = const ['https://cdn.test/a.jpg'],
}) {
  return PropertyModel(
    id: 'prop_1',
    ownerId: 'own_1',
    title: title,
    description: 'Une belle villa avec vue sur la lagune.',
    propertyType: PropertyType.villa,
    status: PropertyStatus.published,
    address: const PropertyAddress(street: 'Rue des Jardins', city: 'Abidjan'),
    details: const PropertyDetails(
      surfaceArea: 180,
      bedrooms: 4,
      bathrooms: 2,
      livingRooms: 1,
      kitchens: 1,
      parkingSpaces: 2,
    ),
    amenities: const {Amenity.wifi, Amenity.pool},
    images: images,
    pricing: PropertyPricing(dailyPrice: dailyPrice, priceTiers: priceTiers),
    availableFrom: DateTime.utc(2026, 9, 1),
  );
}

/// Monte l'écran en mode modification, cubit injecté.
Future<void> _pumpEditor(
  WidgetTester tester, {
  required PropertyModel property,
  required _FakeEditCubit cubit,
  GlobalKey<NavigatorState>? navigatorKey,
  StackRouter? router,
}) async {
  Widget screen = BlocProvider<EditPropertyCubit>.value(
    value: cubit,
    child: AddPropertyView(property: property),
  );

  if (router != null) {
    screen = StackRouterScope(controller: router, stateHash: 0, child: screen);
  }

  if (navigatorKey == null) {
    await tester.pumpWidget(MaterialApp(home: screen));
    await tester.pumpAndSettle();
    return;
  }

  // L'écran est empilé sur une page d'accueil, et non posé en `home` : une
  // route unique ne se dépile pas, et la fermeture réussirait sans que le
  // `PopScope` ait eu son mot à dire.
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigatorKey,
      home: const Scaffold(body: Text('fiche du bien')),
    ),
  );
  navigatorKey.currentState!.push(
    MaterialPageRoute<PropertyModel>(builder: (_) => screen),
  );
  await tester.pumpAndSettle();
}

/// Ouvre une section depuis le sommaire.
///
/// La grille des sept sections dépasse la hauteur de l'écran de test : sans
/// défilement préalable, le geste tomberait à côté de la tuile.
Future<void> _openSection(WidgetTester tester, String title) async {
  // La grille interne ne défile pas ; c'est la page qui porte le défilement,
  // d'où le `scrollable` explicite — sans lui, deux zones correspondent.
  await tester.scrollUntilVisible(
    find.text(title),
    120,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.text(title));
  await tester.pumpAndSettle();
}

void main() {
  late _FakeEditCubit cubit;

  setUp(() => cubit = _FakeEditCubit());
  tearDown(() => cubit.close());

  group('Modification — sommaire', () {
    testWidgets('la modification s’ouvre sur le sommaire, pas sur une étape', (
      tester,
    ) async {
      await _pumpEditor(tester, property: _property(), cubit: cubit);

      expect(find.text('Modifier le bien'), findsOneWidget);
      // Les sept sections sont offertes d'emblée, sans parcours imposé.
      expect(find.text('Tarification'), findsOneWidget);
      expect(find.text('Type de bien'), findsOneWidget);
      expect(find.text('Photos'), findsOneWidget);
    });

    testWidgets('aucun compteur d’étapes ne s’affiche sur le sommaire', (
      tester,
    ) async {
      await _pumpEditor(tester, property: _property(), cubit: cubit);

      // « 1/7 » supposerait un ordre : il n'y en a pas ici.
      expect(find.text('1/7'), findsNothing);
    });

    testWidgets('chaque tuile résume l’état de sa section', (tester) async {
      await _pumpEditor(
        tester,
        property: _property(
          dailyPrice: 15000,
          priceTiers: const [PriceTier(minDays: 7, discountPercent: 10)],
        ),
        cubit: cubit,
      );

      // Le montant est composé par le formateur, non écrit à la main : il
      // sépare les milliers par une espace fine insécable, qu'une espace
      // ordinaire dans le test ne retrouverait pas.
      expect(
        find.textContaining('${CurrencyFormatter.fcfa(15000)} / jour'),
        findsOneWidget,
      );
      expect(find.textContaining('1 palier'), findsOneWidget);
      expect(find.text('2 commodités'), findsOneWidget);
      expect(find.text('1 photo'), findsOneWidget);
      expect(find.text('Villa'), findsOneWidget);
    });

    testWidgets('toucher une tuile ouvre la section correspondante', (
      tester,
    ) async {
      await _pumpEditor(tester, property: _property(), cubit: cubit);

      await _openSection(tester, 'Tarification');

      // L'en-tête porte le titre de la section ouverte, et son contenu est là.
      expect(find.text('Définissez votre tarif'), findsOneWidget);
      expect(find.text('Valider cette section'), findsOneWidget);
    });

    testWidgets('valider une section ramène au sommaire', (tester) async {
      await _pumpEditor(tester, property: _property(), cubit: cubit);

      await _openSection(tester, 'Tarification');
      await tester.tap(find.text('Valider cette section'));
      await tester.pumpAndSettle();

      expect(find.text('Modifier le bien'), findsOneWidget);
      // La validation d'une section n'envoie rien : l'enregistrement est
      // groupé, et se déclenche depuis le sommaire.
      expect(cubit.submitCount, 0);
    });

    testWidgets('une section validée est signalée dans la grille', (
      tester,
    ) async {
      await _pumpEditor(tester, property: _property(), cubit: cubit);

      expect(
        find.text('Touchez une section pour la corriger.'),
        findsOneWidget,
      );

      await _openSection(tester, 'Tarification');
      await tester.tap(find.text('Valider cette section'));
      await tester.pumpAndSettle();

      expect(
        find.text('Enregistrez pour appliquer vos modifications.'),
        findsOneWidget,
      );
    });

    testWidgets('enregistrer depuis le sommaire soumet une seule fois', (
      tester,
    ) async {
      await _pumpEditor(tester, property: _property(), cubit: cubit);

      await tester.tap(find.text('Enregistrer les modifications'));
      await tester.pumpAndSettle();

      expect(cubit.submitCount, 1);
    });
  });

  group('Modification — garde-fous', () {
    testWidgets('une section invalide bloque l’enregistrement et s’ouvre', (
      tester,
    ) async {
      // Tarif nul : le serveur refuserait en 422 sans dire où corriger.
      await _pumpEditor(
        tester,
        property: _property(dailyPrice: 0),
        cubit: cubit,
      );

      await tester.tap(find.text('Enregistrer les modifications'));
      await tester.pump();

      expect(cubit.submitCount, 0);
      // La section fautive s'ouvre d'elle-même.
      expect(find.text('Définissez votre tarif'), findsOneWidget);

      // Le toast d'erreur s'efface au bout de quelques secondes : sans cette
      // attente, son minuteur resterait en suspens à la fin du test.
      await tester.pump(const Duration(seconds: 4));
    });

    // Le cas « sortie sans modification » n'est pas couvert ici : il aboutit à
    // `context.router`, que ce montage n'a pas, et l'erreur qui en découle est
    // asynchrone donc inrattrapable proprement. Le test suivant couvre la
    // bascule qui compte — la confirmation n'apparaît qu'après une retouche.

    testWidgets('quitter avec des modifications demande confirmation', (
      tester,
    ) async {
      await _pumpEditor(tester, property: _property(), cubit: cubit);

      await _openSection(tester, 'Tarification');
      await tester.tap(find.text('Valider cette section'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      // Le travail d'édition tient dans l'écran tant qu'il n'est pas envoyé :
      // le perdre sans un mot serait le piège de l'enregistrement groupé.
      expect(find.text('Abandonner les modifications ?'), findsOneWidget);
      expect(find.textContaining('Une section a été modifiée'), findsOneWidget);
    });

    testWidgets('abandonner ferme l’écran au lieu de redemander', (
      tester,
    ) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      final router = _FakeStackRouter(navigatorKey);
      await _pumpEditor(
        tester,
        property: _property(),
        cubit: cubit,
        navigatorKey: navigatorKey,
        router: router,
      );

      await _openSection(tester, 'Tarification');
      await tester.tap(find.text('Valider cette section'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abandonner'));
      await tester.pumpAndSettle();

      // L'abandon doit sortir de l'écran, pas seulement refermer le dialog.
      expect(find.text('Abandonner les modifications ?'), findsNothing);
      expect(find.text('fiche du bien'), findsOneWidget);
      expect(find.text('Modifier le bien'), findsNothing);
    });

    testWidgets('un enregistrement réussi ferme bien l’écran', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      final router = _FakeStackRouter(navigatorKey);
      await _pumpEditor(
        tester,
        property: _property(),
        cubit: cubit,
        navigatorKey: navigatorKey,
        router: router,
      );

      await _openSection(tester, 'Tarification');
      await tester.tap(find.text('Valider cette section'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enregistrer les modifications'));
      await tester.pumpAndSettle();
      cubit.succeed(_property());
      await tester.pumpAndSettle();

      // Le cœur du défaut : le garde refusait la fermeture demandée par le
      // succès. L'écran restait ouvert, son loader éteint, sans rien à toucher
      // — et aucun dialog pour l'expliquer, les sections étant déjà vidées.
      expect(find.text('fiche du bien'), findsOneWidget);
      expect(find.text('Modifier le bien'), findsNothing);
      expect(find.text('Abandonner les modifications ?'), findsNothing);

      // Le toast de succès se referme sur une temporisation de 3,2 s : la
      // laisser courir évite l'échec sur un timer encore pendant.
      await tester.pump(const Duration(seconds: 4));
    });
  });

  group('Dépôt — le parcours linéaire est préservé', () {
    testWidgets('la création démarre sur la première étape', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<CreatePropertyCubit>.value(
            value: _FakeCreateCubit(),
            child: const AddPropertyView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Pas de sommaire : il n'y a rien à survoler d'un dossier vide, et le
      // dépôt garde son enchaînement guidé.
      expect(find.text('Modifier le bien'), findsNothing);
      expect(find.text('1/7'), findsOneWidget);
      expect(find.text('Suivant'), findsOneWidget);
    });
  });
}
