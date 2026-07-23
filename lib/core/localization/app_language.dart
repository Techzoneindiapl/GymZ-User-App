enum AppLanguage {
  english('en', 'English'),
  hindi('hi', 'हिन्दी'),
  marathi('mr', 'मराठी'),
  gujarati('gu', 'ગુજરાતી'),
  tamil('ta', 'தமிழ்'),
  telugu('te', 'తెలుగు'),
  malayalam('ml', 'മലയാളം'),
  kannada('kn', 'ಕನ್ನಡ'),
  bengali('bn', 'বাংলা'),
  punjabi('pa', 'ਪੰਜਾਬੀ');

  final String languageCode;
  final String nativeName;

  const AppLanguage(this.languageCode, this.nativeName);
}
