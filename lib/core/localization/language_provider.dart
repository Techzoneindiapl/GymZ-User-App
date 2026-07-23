import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/storage_service.dart';
import 'app_language.dart';

class LanguageNotifier extends Notifier<AppLanguage> {
  late final StorageService _storageService;

  @override
  AppLanguage build() {
    _storageService = ref.watch(storageServiceProvider);
    _init();
    return AppLanguage.english;
  }

  Future<void> _init() async {
    final langCode = await _storageService.getLanguage();
    if (langCode != null) {
      final matched = AppLanguage.values.firstWhere(
        (e) => e.languageCode == langCode,
        orElse: () => AppLanguage.english,
      );
      state = matched;
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = language;
    await _storageService.saveLanguage(language.languageCode);
  }
}

final languageProvider = NotifierProvider<LanguageNotifier, AppLanguage>(LanguageNotifier.new);
