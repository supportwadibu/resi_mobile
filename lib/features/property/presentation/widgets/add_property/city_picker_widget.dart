import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/di/service_locator.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/features/property/data/services/google_places_service.dart';
import 'package:resi_africa/shared/widgets/app_text_field.dart';

class CityPickerWidget extends StatefulWidget {
  const CityPickerWidget({
    super.key,
    required this.onCitySelected,
  });

  final void Function(String cityName, LatLng coordinates) onCitySelected;

  @override
  State<CityPickerWidget> createState() => _CityPickerWidgetState();
}

class _CityPickerWidgetState extends State<CityPickerWidget> {
  final TextEditingController _searchController = TextEditingController();
  final GooglePlacesService _placesService = sl<GooglePlacesService>();

  List<PlaceSuggestion> _suggestions = [];
  bool _isLoading = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      if (_placesService.isAvailable) {
        final suggestions = await _placesService.searchCities(query);
        if (mounted) {
          setState(() {
            _suggestions = suggestions;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    });
  }

  Future<void> _onSuggestionTap(PlaceSuggestion suggestion) async {
    if (_placesService.isAvailable) {
      final details = await _placesService.getPlaceDetails(suggestion.placeId);
      if (details != null) {
        widget.onCitySelected(details.name, details.coordinates);
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  void _onManualSubmit(String value) {
    if (value.trim().isNotEmpty) {
      // En mode dégradé, on utilise des coordonnées par défaut d'Abidjan
      widget.onCitySelected(value.trim(), const LatLng(5.3364, -3.9772));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              Expanded(
                child: Text(
                  'property_form.search_city'.tr(),
                  style: context.text.titleLarge,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(LucideIcons.x),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Champ de recherche
          AppTextField(
            controller: _searchController,
            label: '',
            hint: 'property_form.city_search_placeholder'.tr(),
            prefixIcon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.search, size: 16),
            onChanged: _onSearchChanged,
          ),

          if (!_placesService.isAvailable) ...[
            const SizedBox(height: 8),
            Text(
              'Google Places API non configuré - saisissez le nom et appuyez sur le bouton',
              style: context.text.bodySmall?.copyWith(
                color: context.tokens.muted,
              ),
            ),
            const SizedBox(height: 8),
            if (_searchController.text.trim().isNotEmpty)
              ElevatedButton(
                onPressed: () => _onManualSubmit(_searchController.text),
                child: Text('Utiliser "${_searchController.text}"'),
              ),
          ],

          const SizedBox(height: 16),

          // Liste des suggestions
          Expanded(
            child: _placesService.isAvailable
                ? (_suggestions.isEmpty && !_isLoading
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: _suggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = _suggestions[index];
                          return ListTile(
                            leading: const Icon(LucideIcons.mapPin, size: 20),
                            title: Text(
                              suggestion.description,
                              style: context.text.bodyMedium,
                            ),
                            onTap: () => _onSuggestionTap(suggestion),
                          );
                        },
                      ))
                : Center(
                    child: Text(
                      'Saisissez le nom de la ville ci-dessus',
                      style: context.text.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_searchController.text.trim().isEmpty) {
      return Center(
        child: Text(
          'property_form.city_search_hint'.tr(),
          style: context.text.bodyMedium,
          textAlign: TextAlign.center,
        ),
      );
    }

    return Center(
      child: Text(
        'property_form.no_city_found'.tr(),
        style: context.text.bodyMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}