import '../models/property_model.dart';
import '../models/report_type_model.dart';

class ReportFakeData {
  static const List<PropertyModel> properties = [
    PropertyModel(id: 'all', name: 'Toutes mes résidences'),
    PropertyModel(id: '1', name: 'Résidence Les Cocotiers'),
    PropertyModel(id: '2', name: 'Villa Bingerville'),
    PropertyModel(id: '3', name: 'Appart Plateau'),
  ];

  static const List<ReportType> reportTypes = ReportType.values;
}
