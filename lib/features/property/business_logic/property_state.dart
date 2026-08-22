import '../data/models/property_model.dart';

sealed class PropertyState { const PropertyState(); }

final class PropertyInitial extends PropertyState { const PropertyInitial(); }
final class PropertyLoading extends PropertyState { const PropertyLoading(); }
final class PropertyLoaded  extends PropertyState {
  const PropertyLoaded(this.items);
  final List<PropertyModel> items;
}
final class PropertyError extends PropertyState {
  const PropertyError(this.message);
  final String message;
}
