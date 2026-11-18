import 'package:aquawatt/data/prefs_repository.dart';
import 'package:aquawatt/data/regions_seed.dart';
import 'package:aquawatt/domain/models.dart';
import 'package:flutter/material.dart';

enum AppThemeChoice { system, light, dark, highContrast }

extension AppThemeChoiceX on AppThemeChoice {
  String get label => switch (this) {
        AppThemeChoice.system => 'Sistema',
        AppThemeChoice.light => 'Claro',
        AppThemeChoice.dark => 'Escuro',
        AppThemeChoice.highContrast => 'Alto contraste',
      };

  ThemeMode get themeMode => switch (this) {
        AppThemeChoice.system => ThemeMode.system,
        AppThemeChoice.light => ThemeMode.light,
        AppThemeChoice.dark => ThemeMode.dark,
        AppThemeChoice.highContrast => ThemeMode.dark,
      };
}

/// Estado global: consentimento, aparência, bairro selecionado e limiares.
/// Compartilhado entre várias telas e persistido localmente.
class AppState extends ChangeNotifier {
  AppState(PrefsRepository prefs)
      : _prefs = prefs,
        consentGiven = prefs.consent,
        themeChoice = _parseTheme(prefs.theme),
        textScale = prefs.textScale,
        selectedRegionId = prefs.selectedRegion ?? kProfiles.first.region.id,
        thresholds = prefs.loadThresholds();

  final PrefsRepository _prefs;

  bool consentGiven;
  AppThemeChoice themeChoice;
  double textScale;
  String selectedRegionId;
  Thresholds thresholds;

  static AppThemeChoice _parseTheme(String? name) => AppThemeChoice.values.firstWhere(
        (t) => t.name == name,
        orElse: () => AppThemeChoice.system,
      );

  Region get selectedRegion => regionById(selectedRegionId);

  Future<void> giveConsent() async {
    consentGiven = true;
    notifyListeners();
    await _prefs.saveConsent(true);
  }

  /// Revoga o consentimento e apaga todos os dados locais.
  Future<void> revokeConsent() async {
    await _prefs.clearAll();
    consentGiven = false;
    themeChoice = AppThemeChoice.system;
    textScale = 1.0;
    selectedRegionId = kProfiles.first.region.id;
    thresholds = const Thresholds();
    notifyListeners();
  }

  Future<void> setTheme(AppThemeChoice choice) async {
    themeChoice = choice;
    notifyListeners();
    await _prefs.saveTheme(choice.name);
  }

  Future<void> setTextScale(double value) async {
    textScale = value;
    notifyListeners();
    await _prefs.saveTextScale(value);
  }

  Future<void> selectRegion(String id) async {
    if (id == selectedRegionId) return;
    selectedRegionId = id;
    notifyListeners();
    await _prefs.saveSelectedRegion(id);
  }

  Future<void> setThresholds(Thresholds value) async {
    thresholds = value;
    notifyListeners();
    await _prefs.saveThresholds(value);
  }
}
