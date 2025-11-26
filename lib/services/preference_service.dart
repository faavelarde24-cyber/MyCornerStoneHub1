// lib/services/preferences_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyWizardLastUsed = 'wizard_last_used';
  static const String _keyWizardPagesCreated = 'wizard_pages_created';
  static const String _keyShowWizardTips = 'show_wizard_tips';

  // Singleton pattern
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Onboarding completed
  Future<bool> hasCompletedOnboarding() async {
    await init();
    return _prefs?.getBool(_keyOnboardingCompleted) ?? false;
  }

  Future<void> markOnboardingComplete() async {
    await init();
    await _prefs?.setBool(_keyOnboardingCompleted, true);
    await _prefs?.setString(_keyWizardLastUsed, DateTime.now().toIso8601String());
  }

  Future<void> resetOnboarding() async {
    await init();
    await _prefs?.setBool(_keyOnboardingCompleted, false);
  }

  // Wizard usage tracking
  Future<void> updateWizardLastUsed() async {
    await init();
    await _prefs?.setString(_keyWizardLastUsed, DateTime.now().toIso8601String());
  }

  Future<DateTime?> getWizardLastUsed() async {
    await init();
    final dateStr = _prefs?.getString(_keyWizardLastUsed);
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr);
  }

  Future<void> incrementPagesCreated() async {
    await init();
    final current = _prefs?.getInt(_keyWizardPagesCreated) ?? 0;
    await _prefs?.setInt(_keyWizardPagesCreated, current + 1);
  }

  Future<int> getPagesCreated() async {
    await init();
    return _prefs?.getInt(_keyWizardPagesCreated) ?? 0;
  }

  // Tips visibility
  Future<bool> shouldShowWizardTips() async {
    await init();
    return _prefs?.getBool(_keyShowWizardTips) ?? true;
  }

  Future<void> setShowWizardTips(bool show) async {
    await init();
    await _prefs?.setBool(_keyShowWizardTips, show);
  }
}