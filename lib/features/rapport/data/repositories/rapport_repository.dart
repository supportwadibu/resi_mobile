import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/error/exception_mapper.dart';
import '../../../../core/error/failures.dart';
import '../models/period_preset_model.dart';
import '../models/report_export_model.dart';
import '../models/report_type_model.dart';

class RapportRepository {
  const RapportRepository(this._dio);
  final Dio _dio;

  /// Demande la génération d'un rapport et l'écrit sur le disque.
  ///
  /// L'API renvoie désormais le PDF lui-même dans le corps de la réponse
  /// (`Content-Type: application/pdf`) plutôt qu'un lien Cloudinary : rien
  /// n'est plus stocké côté serveur. `ResponseType.bytes` est donc requis pour
  /// que Dio ne tente pas de décoder le corps en JSON.
  ///
  /// [customStart] et [customEnd] ne sont lus que si [preset] vaut
  /// [PeriodPreset.custom] : l'API exige `from`/`to` dans ce cas précis et les
  /// refuse sinon.
  Future<ReportExportModel> generate({
    required ReportType type,
    required PeriodPreset preset,
    DateTime? customStart,
    DateTime? customEnd,
    String? residenceId,
  }) async {
    try {
      final response = await _dio.post<List<int>>(
        ApiEndpoints.reports,
        data: {
          'type': type.apiValue,
          'period': preset.apiValue,
          if (preset == PeriodPreset.custom && customStart != null)
            'from': _formatDate(customStart),
          if (preset == PeriodPreset.custom && customEnd != null)
            'to': _formatDate(customEnd),
          // `'all'` est la sentinelle du sélecteur local, pas un identifiant :
          // l'envoyer telle quelle ferait chercher une résidence 'all' côté
          // serveur. Omettre la clé revient à demander toutes les résidences.
          if (residenceId != null && residenceId != 'all')
            'residence_id': residenceId,
        },
        options: Options(responseType: ResponseType.bytes),
      );

      final filename = _filenameFrom(response.headers, type);
      final filePath = await _writeToDisk(response.data!, type);
      return ReportExportModel(filePath: filePath, filename: filename);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(_withDecodedErrorBody(e));
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }

  /// Reparse en JSON le corps d'une réponse d'erreur reçue en octets.
  ///
  /// La route renvoie soit le PDF, soit une erreur JSON, mais `ResponseType
  /// .bytes` s'applique aux deux : sans ce décodage, `mapDioExceptionToFailure`
  /// recevrait une `List<int>` au lieu d'une `Map` et retomberait sur un
  /// message générique — le propriétaire perdrait le code d'erreur métier
  /// (résidence introuvable, période trop large...).
  DioException _withDecodedErrorBody(DioException e) {
    final data = e.response?.data;
    if (data is! List<int>) return e;

    try {
      final decoded = jsonDecode(utf8.decode(data));
      final response = e.response!;
      return e.copyWith(
        response: Response(
          requestOptions: response.requestOptions,
          data: decoded,
          statusCode: response.statusCode,
          statusMessage: response.statusMessage,
          headers: response.headers,
        ),
      );
    } catch (_) {
      // Corps illisible (ni JSON, ni UTF-8 valide) : on rend l'exception
      // telle quelle, le mapper retombera sur son message générique.
      return e;
    }
  }

  /// Extrait le nom de fichier de l'en-tête `Content-Disposition`.
  ///
  /// Repli sur un nom dérivé du type de rapport et de la date du jour si
  /// l'en-tête est absent ou mal formé : rare, mais un nom de repli lisible
  /// vaut mieux qu'une exception qui ferait échouer tout le téléchargement.
  String _filenameFrom(Headers headers, ReportType type) {
    final disposition = headers.value('content-disposition');
    final match = disposition == null
        ? null
        : RegExp('filename="?([^"]+)"?').firstMatch(disposition);
    if (match != null) return match.group(1)!;

    final today = DateTime.now();
    final date =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return 'rapport-${type.apiValue}-$date.pdf';
  }

  /// Écrit le rapport sous un nom **fixe** par type, dans le répertoire
  /// temporaire.
  ///
  /// L'API suffixe son propre nom d'un horodatage (un fichier de plus à
  /// chaque génération) ; le garder tel quel côté mobile accumulerait les
  /// PDF sur le téléphone. Un nom stable fait qu'une réédition écrase la
  /// précédente, et le répertoire temporaire est nettoyé par le système —
  /// inutile de gérer sa purge ici.
  Future<String> _writeToDisk(List<int> bytes, ReportType type) async {
    final dir = await getTemporaryDirectory();
    final path = p.join(dir.path, 'rapport-${type.apiValue}.pdf');
    await File(path).writeAsBytes(Uint8List.fromList(bytes), flush: true);
    return path;
  }

  // L'API raisonne en journées entières (`from`/`to` inclusifs, sans heure) :
  // envoyer un horodatage complet exposerait à un décalage de fuseau qui
  // rogne un jour de période.
  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
