# Implementation Plan

Fixing the broken Google Places city autocomplete feature in the Flutter mobile app.

## Root Causes Identified

1. **Silent error swallowing** — Both `searchCities()` and `getPlaceDetails()` have bare `catch (e) {}` blocks that silently discard every exception.
2. **API key configuration** — Uses hardcoded default key that may be restricted to specific bundle IDs or have other access restrictions.
3. **No error logging** — The `logger` package is available but never used, making debugging impossible.
4. **UI shows no error feedback** — Users see empty list with no indication of what went wrong.
5. **Types parameter is correct** — `&types=(cities)` is the correct format for the Google Places Autocomplete API.
6. **Missing French language support** — No `language=fr` parameter despite the app supporting French.

## Implementation Steps

- [ ] 1. Add proper error logging to GooglePlacesService using the logger package already in pubspec.yaml.
      Import logger, create instance, log all HTTP requests, responses, and errors with appropriate levels (info for requests, error for failures, debug for successful responses).
      Files: c:\Divers\perso\Projets\resi\mobile\lib\features\property\data\services\google_places_service.dart
      Verify: `flutter test test/core/l10n/translations_test.dart --plain-name "aucun libellé affiché n'est écrit en dur"` should still fail (known issue), but run `flutter test` to ensure no new test failures.

- [ ] 2. Replace silent error handling with proper error logging and user feedback mechanism.
      Remove empty catch blocks, log specific error details (status codes, API error messages), and return meaningful error states that the UI can display.
      Files: c:\Divers\perso\Projets\resi\mobile\lib\features\property\data\services\google_places_service.dart
      Verify: `flutter analyze` passes without new warnings.

- [ ] 3. Add French language support to Google Places API requests.
      Add `&language=fr` parameter to both autocomplete and place details API calls to match the app's French language support.
      Files: c:\Divers\perso\Projets\resi\mobile\lib\features\property\data\services\google_places_service.dart
      Verify: Check that API URLs are correctly formatted with language parameter via logging output.

- [ ] 4. Enhance CityPickerWidget to display error states and provide better user feedback.
      Remove hardcoded French text "Utiliser" and "Google Places API non configuré" that fails the translation test. Add proper error state handling when API calls fail. Show meaningful error messages to users using proper translation keys.
      Files: c:\Divers\perso\Projets\resi\mobile\lib\features\property\presentation\widgets\add_property\city_picker_widget.dart
      Verify: `flutter test test/core/l10n/translations_test.dart --plain-name "aucun libellé affiché n'est écrit en dur"` should pass, and `flutter test` should run without timing out on this widget.

- [ ] 5. Add comprehensive error handling with specific error types for different failure scenarios.
      Create enum for different error types (network error, API key invalid, quota exceeded, etc.), modify service to return Result-like objects with success/error states, and update UI to handle each error type appropriately.
      Files: c:\Divers\perso\Projets\resi\mobile\lib\features\property\data\services\google_places_service.dart, c:\Divers\perso\Projets\resi\mobile\lib\features\property\presentation\widgets\add_property\city_picker_widget.dart
      Verify: `flutter test` completes successfully and `flutter analyze` shows no issues.

## Key Technical Details

- **API Key Configuration**: The hardcoded API key `AIzaSyBGvCTV3gWWFALypi3IoVgYuYIT8iOpPNQ` can be overridden via `--dart-define=GOOGLE_PLACES_API_KEY=<key>` at build time.
- **Types Parameter**: `&types=(cities)` is correct for the Google Places Autocomplete API legacy version.
- **Build Commands**: Use `flutter run -t lib/main_dev.dart --dart-define=GOOGLE_PLACES_API_KEY=<key>` for testing with a valid API key.
- **Error Response Format**: Google Places API returns errors in the `status` field of the JSON response (e.g., "REQUEST_DENIED", "INVALID_REQUEST").
- **Language Support**: Adding `&language=fr` will return French place names when available.

## Verification Notes

- The translation test failure for hardcoded French text is expected and will be fixed in step 4.
- The API key restrictions may need to be configured in Google Cloud Console for the bundle ID `africa.resi.app`.
- Test with both valid and invalid API keys to ensure proper error handling.
- Verify that the manual fallback (typing city name without API) continues to work.