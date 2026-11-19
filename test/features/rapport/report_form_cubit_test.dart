import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/session_role_fixture.dart';
import 'package:resi_africa/features/rapport/business_logic/report_form_cubit.dart';
import 'package:resi_africa/features/rapport/business_logic/report_form_state.dart';
import 'package:resi_africa/features/rapport/data/models/period_preset_model.dart';
import 'package:resi_africa/features/rapport/data/models/report_export_model.dart';
import 'package:resi_africa/features/rapport/data/models/report_type_model.dart';
import 'package:resi_africa/features/rapport/data/repositories/rapport_repository.dart';
import 'package:resi_africa/features/residence/data/repositories/residence_repository.dart';

/// Rejette systématiquement, comme une panne réseau.
class _FailingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    handler.reject(
      DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      ),
    );
  }
}

ReportFormCubit _build() {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
  dio.interceptors.add(_FailingInterceptor());
  return ReportFormCubit(
    RapportRepository(dio),
    ResidenceRepository(dio, sessionRoleFixture()),
  );
}

/// Expose `emit` pour poser un rapport déjà généré, sans appel réseau.
class _SeededCubit extends ReportFormCubit {
  _SeededCubit()
    : super(
        RapportRepository(Dio()),
        ResidenceRepository(Dio(), sessionRoleFixture()),
      );

  void seed(ReportFormState state) => emit(state);
}

const _previous = ReportExportModel(
  filePath: '/tmp/ancien.pdf',
  filename: 'ancien.pdf',
);

void main() {
  // Régression : après une génération, choisir un autre type rouvrait l'ancien
  // PDF, resté dans l'état. Tout changement de choix doit l'effacer.
  group('ReportFormCubit — un nouveau choix efface le rapport précédent', () {
    late _SeededCubit cubit;

    setUp(() {
      cubit = _SeededCubit()..seed(const ReportFormState(result: _previous));
    });
    tearDown(() => cubit.close());

    test('changer de type', () {
      cubit.setReportType(ReportType.police);
      expect(cubit.state.result, isNull);
      expect(cubit.state.selectedType, ReportType.police);
    });

    test('changer de résidence', () {
      cubit.setResidence('r1');
      expect(cubit.state.result, isNull);
    });

    test('changer de période', () {
      cubit.setPreset(PeriodPreset.lastMonth);
      expect(cubit.state.result, isNull);
    });

    test('un appui pendant la génération ne relance rien', () async {
      cubit.seed(const ReportFormState(isGenerating: true, result: _previous));
      await cubit.generate();
      expect(cubit.state.isGenerating, isTrue);
      expect(cubit.state.result, same(_previous));
    });
  });

  group('ReportFormCubit.loadResidences', () {
    test(
      'un échec de chargement laisse le sélecteur utilisable avec « Toutes mes résidences »',
      () async {
        final cubit = _build();

        await cubit.loadResidences();

        expect(cubit.state.isLoadingResidences, isFalse);
        expect(cubit.state.residences, [allResidencesOption]);
        expect(cubit.state.residences.single.id, 'all');
      },
    );
  });
}
