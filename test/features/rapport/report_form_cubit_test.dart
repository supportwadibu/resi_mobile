import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/session_role_fixture.dart';
import 'package:resi_africa/features/rapport/business_logic/report_form_cubit.dart';
import 'package:resi_africa/features/rapport/business_logic/report_form_state.dart';
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

void main() {
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
