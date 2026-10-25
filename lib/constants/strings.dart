enum AppLanguage { amharic, english }

class AppStrings {
  final AppLanguage language;

  const AppStrings([this.language = AppLanguage.amharic]);

  bool get isAmharic => language == AppLanguage.amharic;

  String get appTitle => isAmharic ? 'የግጥም መደብ' : 'Poem Pad';
  String get untitled => isAmharic ? 'ያለ ርዕስ' : 'Untitled';
  String get emptyPoem => isAmharic ? '(ባዶ ግጥም)' : '(Empty Poem)';
  String get newPoem => isAmharic ? 'አዲስ ግጥም' : 'New Poem';
  String get editPoem => isAmharic ? 'ግጥም አዘጋጅ' : 'Edit Poem';
  String get save => isAmharic ? 'አስቀምጥ' : 'Save';
  String get undo => isAmharic ? 'መልስ' : 'Undo';
  String get delete => isAmharic ? 'ሰርዝ' : 'Delete';
  String get duplicate => isAmharic ? 'ቅጂ ፍጠር' : 'Duplicate';
  String get share => isAmharic ? 'አጋራ' : 'Share';
  String get pin => isAmharic ? 'ሰካ' : 'Pin';
  String get unpin => isAmharic ? 'ንቀል' : 'Unpin';
  String get restore => isAmharic ? 'መልስ' : 'Restore';
  String get purge => isAmharic ? 'ለዘላለም ሰርዝ' : 'Delete Permanently';
  String get searchPlaceholder => isAmharic ? 'ግጥሞችን ፈልግ...' : 'Search poems...';
  String get noPoemsFound => isAmharic ? 'ምንም የተገኘ ግጥም የለም' : 'No poems found';
  String get emptyNotesPrompt => isAmharic
      ? 'ገና አልጻፉም ማለት ነው\n(አዲስ ግጥም ለመጻፍ ＋ ይጫኑ)'
      : 'No poems written yet\n(Tap ＋ to write a new poem)';
  String get trashTitle => isAmharic ? 'የተሰረዙ ግጥሞች' : 'Trash';
  String get trashEmpty => isAmharic ? 'ምንም የተሰረዘ ግጥም የለም' : 'Trash is empty';
  String get settingsTitle => isAmharic ? 'ማስተካከያ' : 'Settings';

  // Section Headers
  String get pinnedSection => isAmharic ? 'የተሰኩ' : 'Pinned';
  String get todaySection => isAmharic ? 'ዛሬ' : 'Today';
  String get weekSection => isAmharic ? 'ያለፉት 7 ቀናት' : 'Previous 7 Days';
  String get earlierSection => isAmharic ? 'ቀደም ሲል' : 'Earlier';

  // Units / Counts
  String get poemsCount => isAmharic ? 'ግጥሞች' : 'poems';
  String get lineSuffix => isAmharic ? 'መስመር' : 'lines';
  String get wordSuffix => isAmharic ? 'ቃላት' : 'words';
  String get syllableSuffix => isAmharic ? 'ስላብል' : 'syllables';

  // Export / Backup
  String get exportTxt => isAmharic ? 'እንደ TXT ላክ' : 'Export as TXT';
  String get exportPdf => isAmharic ? 'እንደ PDF ላክ' : 'Export as PDF';
  String get exportAllJson => isAmharic ? 'ሁሉንም ባክአፕ አድርግ (JSON)' : 'Backup All (JSON)';
  String get backupRestore => isAmharic ? 'ባክአፕ እና መመለሻ' : 'Backup & Restore';
  String get copySuccess => isAmharic ? 'ወደ ክሊፕቦርድ ተገልብጧል' : 'Copied to clipboard';
  String get deleteSuccess => isAmharic ? 'ወደ ቆሻሻ መጣያ ተዛውሯል' : 'moved to trash';
  String get copySuffix => isAmharic ? 'ቅጂ' : 'copy';
  String get titleHint => isAmharic ? 'ርዕስ' : 'Title';
  String get bodyHint => isAmharic ? 'ግጥምዎን እዚህ ይጻፉ...' : 'Write your poem here...';
  String get allTags => isAmharic ? 'ሁሉንም' : 'All';
  String get addTag => isAmharic ? '+ ታግ አክል...' : '+ Add tag...';
  String get languageLabel => isAmharic ? 'ቋንቋ (Language)' : 'Language';
  String get amharicName => 'አማርኛ (Amharic)';
  String get englishName => 'English';

  String formatDate(DateTime date) {
    final now = DateTime.now();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return isAmharic ? 'ዛሬ $hour:$minute' : 'Today $hour:$minute';
    }

    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return isAmharic ? 'ትናንት $hour:$minute' : 'Yesterday $hour:$minute';
    }

    return '${date.day}/${date.month}/${date.year}';
  }
}
