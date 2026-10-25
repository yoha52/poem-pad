import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../constants/strings.dart';
import '../repositories/poem_repository.dart';
import '../services/export_service.dart';
import '../services/settings_service.dart';
import '../theme/design_tokens.dart';
import 'trash_page.dart';

class SettingsPage extends StatefulWidget {
  final SettingsService settingsService;
  final PoemRepository repository;

  const SettingsPage({
    super.key,
    required this.repository,
    required this.settingsService,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _lastBackupDate = 'አልተደረገም';

  Future<void> _handleBackup() async {
    final jsonStr = await widget.repository.exportBackupJson();
    final success = await ExportService.exportBackup(jsonStr);
    if (mounted && success) {
      final now = DateTime.now();
      setState(() {
        _lastBackupDate = '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ባክአፕ በተሳካ ሁኔታ ተቀምጧል')),
      );
    }
  }

  Future<void> _handleRestore() async {
    final colors = context.colors;
    final jsonStr = await ExportService.pickBackupFile();
    if (jsonStr == null || !mounted) return;

    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ባክአፕ መልስ'),
        content: const Text('ያሉትን ግጥሞች ደርበህ መተካት ወይስ አብረህ ቀላቅለህ ማስገባት ትፈልጋለህ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'merge'),
            child: const Text('ቀላቅል'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'replace'),
            style: TextButton.styleFrom(foregroundColor: colors.destructive),
            child: const Text('ተካ'),
          ),
        ],
      ),
    );

    if (action != null) {
      final count = await widget.repository.restoreBackupJson(
        jsonStr,
        replace: action == 'replace',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count ግጥሞች በተሳካ ሁኔታ ተመልሰዋል')),
        );
      }
    }
  }

  Widget _buildGroup({
    required BuildContext context,
    required String title,
    required List<Widget> children,
    String? footer,
  }) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 6, top: 16),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.meta,
              letterSpacing: DesignTokens.ethioLetterSpacing,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.separator, width: 0.5),
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                if (i > 0) Divider(height: 1, thickness: 0.5, color: colors.separator),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: children[i],
                ),
              ],
            ],
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 6, bottom: 8),
            child: Text(
              footer,
              style: TextStyle(fontSize: 12, color: colors.meta),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: widget.settingsService,
      builder: (context, child) {
        final settings = widget.settingsService;
        final strings = settings.strings;

        return Scaffold(
          backgroundColor: colors.background,
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: CustomScrollView(
                slivers: [
                  SliverAppBar.large(
                    backgroundColor: colors.background,
                    surfaceTintColor: Colors.transparent,
                    leading: IconButton(
                      icon: Icon(CupertinoIcons.chevron_left, color: colors.label, size: 24),
                      onPressed: () => Navigator.pop(context),
                    ),
                    title: Text(
                      strings.settingsTitle,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: colors.label,
                        letterSpacing: DesignTokens.ethioLetterSpacing,
                      ),
                    ),
                    pinned: true,
                  ),

                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Column(
                            children: [
                              // 1. Language & Appearance (መልክ)
                              _buildGroup(
                                context: context,
                                title: strings.languageLabel,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      children: [
                                        CupertinoSlidingSegmentedControl<AppLanguage>(
                                          groupValue: settings.language,
                                          thumbColor: colors.surfaceElevated,
                                          backgroundColor: colors.searchFill,
                                          children: {
                                            AppLanguage.amharic: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              child: Text(strings.amharicName, style: TextStyle(color: colors.label, fontSize: 14)),
                                            ),
                                            AppLanguage.english: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              child: Text(strings.englishName, style: TextStyle(color: colors.label, fontSize: 14)),
                                            ),
                                          },
                                          onValueChanged: (lang) {
                                            if (lang != null) settings.setLanguage(lang);
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                        CupertinoSlidingSegmentedControl<ThemeMode>(
                                          groupValue: settings.themeMode,
                                          thumbColor: colors.surfaceElevated,
                                          backgroundColor: colors.searchFill,
                                          children: {
                                            ThemeMode.system: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              child: Text(strings.isAmharic ? 'ስርዓት' : 'System', style: TextStyle(color: colors.label, fontSize: 14)),
                                            ),
                                            ThemeMode.light: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              child: Text(strings.isAmharic ? 'ብርሃን' : 'Light', style: TextStyle(color: colors.label, fontSize: 14)),
                                            ),
                                            ThemeMode.dark: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              child: Text(strings.isAmharic ? 'ጨለማ' : 'Dark', style: TextStyle(color: colors.label, fontSize: 14)),
                                            ),
                                          },
                                          onValueChanged: (mode) {
                                            if (mode != null) settings.setThemeMode(mode);
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                        // Color Theme Swatches Row
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                                          children: List.generate(
                                            DesignTokens.accentColors.length,
                                            (index) {
                                              final opt = DesignTokens.accentColors[index];
                                              final isSelected = settings.accentColorIndex == index;
                                              final swColor = isDark ? opt.darkColor : opt.lightColor;

                                              return GestureDetector(
                                                onTap: () => settings.setAccentColorIndex(index),
                                                child: Container(
                                                  width: 36,
                                                  height: 36,
                                                  decoration: BoxDecoration(
                                                    color: swColor,
                                                    shape: BoxShape.circle,
                                                    border: isSelected
                                                        ? Border.all(color: colors.label, width: 3)
                                                        : null,
                                                  ),
                                                  child: isSelected
                                                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                                                      : null,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            Text('A-', style: TextStyle(fontSize: 12, color: colors.meta, fontWeight: FontWeight.bold)),
                                            Expanded(
                                              child: Slider(
                                                value: settings.fontSize,
                                                min: 12.0,
                                                max: 28.0,
                                                divisions: 8,
                                                activeColor: colors.accent,
                                                onChanged: (val) => settings.setFontSize(val),
                                              ),
                                            ),
                                            Text('A+', style: TextStyle(fontSize: 18, color: colors.label, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          strings.isAmharic ? 'ግጥም አዘጋጅ የጽሁፍ ናሙና' : 'Poem editor text sample',
                                          style: TextStyle(fontSize: settings.fontSize, color: colors.label),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // 2. አርታዒ (Editor)
                              _buildGroup(
                                context: context,
                                title: strings.isAmharic ? 'አርታዒ' : 'Editor',
                                footer: strings.isAmharic ? 'የስላብል ቁጥር ማሳያን በጽሁፉ ግራ በኩል ያሳያል' : 'Displays syllable counter pills on the left side',
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(strings.isAmharic ? 'የስላብል ቁጥር ማሳያ' : 'Syllable Pills', style: TextStyle(fontSize: 16, color: colors.label)),
                                        CupertinoSwitch(
                                          value: settings.showSyllablePills,
                                          activeTrackColor: colors.accent,
                                          onChanged: (val) => settings.setShowSyllablePills(val),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // 3. ዝርዝር (Sorting)
                              _buildGroup(
                                context: context,
                                title: strings.isAmharic ? 'ዝርዝር' : 'List',
                                children: [
                                  InkWell(
                                    onTap: () {
                                      showCupertinoModalPopup(
                                        context: context,
                                        builder: (context) => CupertinoActionSheet(
                                          title: Text(strings.isAmharic ? 'ነባሪ ቅደም ተከተል' : 'Default Sort Order'),
                                          actions: [
                                            CupertinoActionSheetAction(
                                              onPressed: () {
                                                settings.setDefaultSort(PoemSortOption.lastEdited);
                                                Navigator.pop(context);
                                              },
                                              child: Text(strings.isAmharic ? 'የመጨረሻ የታረሙ' : 'Last Edited'),
                                            ),
                                            CupertinoActionSheetAction(
                                              onPressed: () {
                                                settings.setDefaultSort(PoemSortOption.created);
                                                Navigator.pop(context);
                                              },
                                              child: Text(strings.isAmharic ? 'የተፈጠሩበት ቀን' : 'Date Created'),
                                            ),
                                            CupertinoActionSheetAction(
                                              onPressed: () {
                                                settings.setDefaultSort(PoemSortOption.title);
                                                Navigator.pop(context);
                                              },
                                              child: Text(strings.isAmharic ? 'በአልፋቤት (ርዕስ)' : 'Alphabetical (Title)'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(strings.isAmharic ? 'ነባሪ ቅደም ተከተል' : 'Default Sort', style: TextStyle(fontSize: 16, color: colors.label)),
                                          Row(
                                            children: [
                                              Text(
                                                settings.defaultSort == PoemSortOption.lastEdited
                                                    ? (strings.isAmharic ? 'የመጨረሻ የታረሙ' : 'Last Edited')
                                                    : (settings.defaultSort == PoemSortOption.created
                                                        ? (strings.isAmharic ? 'የተፈጠሩበት ቀን' : 'Date Created')
                                                        : (strings.isAmharic ? 'በአልፋቤት' : 'Alphabetical')),
                                                style: TextStyle(fontSize: 15, color: colors.meta),
                                              ),
                                              const SizedBox(width: 6),
                                              Icon(CupertinoIcons.chevron_right, size: 16, color: colors.meta),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // 4. ውሂብ (Data Backup/Restore/Trash)
                              _buildGroup(
                                context: context,
                                title: strings.isAmharic ? 'ውሂብ' : 'Data',
                                footer: '${strings.isAmharic ? "መጨረሻ ባክአፕ የተደረገው" : "Last backup"}: $_lastBackupDate',
                                children: [
                                  InkWell(
                                    onTap: _handleBackup,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(color: colors.searchFill, borderRadius: BorderRadius.circular(6)),
                                            child: Icon(CupertinoIcons.square_arrow_up, size: 16, color: colors.label),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(child: Text(strings.exportAllJson, style: TextStyle(fontSize: 16, color: colors.label))),
                                          Icon(CupertinoIcons.chevron_right, size: 16, color: colors.meta),
                                        ],
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: _handleRestore,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(color: colors.searchFill, borderRadius: BorderRadius.circular(6)),
                                            child: Icon(CupertinoIcons.square_arrow_down, size: 16, color: colors.label),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(child: Text(strings.isAmharic ? 'ባክአፕ መልስ (Restore)' : 'Restore Backup', style: TextStyle(fontSize: 16, color: colors.label))),
                                          Icon(CupertinoIcons.chevron_right, size: 16, color: colors.meta),
                                        ],
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        CupertinoPageRoute(
                                          builder: (_) => TrashPage(repository: widget.repository),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(color: colors.searchFill, borderRadius: BorderRadius.circular(6)),
                                            child: Icon(CupertinoIcons.trash, size: 16, color: colors.label),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(child: Text(strings.trashTitle, style: TextStyle(fontSize: 16, color: colors.label))),
                                          Icon(CupertinoIcons.chevron_right, size: 16, color: colors.meta),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // 5. ስለ (About)
                              _buildGroup(
                                context: context,
                                title: strings.isAmharic ? 'ስለ' : 'About',
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(strings.isAmharic ? 'ስሪት' : 'Version', style: TextStyle(fontSize: 16, color: colors.label)),
                                        Text('1.0.0', style: TextStyle(fontSize: 15, color: colors.meta)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
