import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/poem.dart';
import '../repositories/poem_repository.dart';
import '../services/export_service.dart';
import '../services/settings_service.dart';
import '../services/syllable_counter_service.dart';
import '../theme/design_tokens.dart';
import '../widgets/custom_text_field.dart';

class TextEditorPage extends StatefulWidget {
  final Poem? poem;
  final PoemRepository repository;
  final SettingsService settingsService;

  const TextEditorPage({
    super.key,
    this.poem,
    required this.repository,
    required this.settingsService,
  });

  static Route<Poem?> route({
    Poem? poem,
    required PoemRepository repository,
    required SettingsService settingsService,
  }) {
    return CupertinoPageRoute<Poem?>(
      builder: (context) => TextEditorPage(
        poem: poem,
        repository: repository,
        settingsService: settingsService,
      ),
    );
  }

  @override
  State<TextEditorPage> createState() => _TextEditorPageState();
}

class _TextEditorPageState extends State<TextEditorPage>
    with WidgetsBindingObserver {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late Poem _currentPoem;

  Timer? _autosaveTimer;
  bool _isSaving = false;
  bool _isSaved = true;
  bool _isDisposing = false;

  String _lastSavedTitle = '';
  String _lastSavedContent = '';

  final List<String> _tags = [];
  final TextEditingController _tagInputController = TextEditingController();

  int _totalLines = 0;
  int _totalWords = 0;
  int _totalSyllables = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final now = DateTime.now();
    _currentPoem = widget.poem ??
        Poem(
          id: now.millisecondsSinceEpoch.toString(),
          title: '',
          content: '',
          createdAt: now,
          updatedAt: now,
        );

    _titleController = TextEditingController(text: _currentPoem.title);
    _bodyController = TextEditingController(text: _currentPoem.content);
    _lastSavedTitle = _currentPoem.title.trim();
    _lastSavedContent = _currentPoem.content;

    _tags.addAll(_currentPoem.tags);

    _titleController.addListener(_onContentChanged);
    _bodyController.addListener(_onContentChanged);
    _updateLiveStats();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _performSave();
    }
  }

  @override
  void dispose() {
    _isDisposing = true;
    WidgetsBinding.instance.removeObserver(this);
    _autosaveTimer?.cancel();
    _titleController.removeListener(_onContentChanged);
    _bodyController.removeListener(_onContentChanged);
    _performSave();
    _titleController.dispose();
    _bodyController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  bool get _hasTextContentChanged {
    return _titleController.text.trim() != _lastSavedTitle ||
        _bodyController.text != _lastSavedContent;
  }

  void _onContentChanged() {
    _updateLiveStats();

    // Skip autosave if only caret/cursor position moved without text changes
    if (!_hasTextContentChanged) return;

    if (_isSaved && !_isDisposing) {
      setState(() {
        _isSaved = false;
      });
    }

    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(milliseconds: 800), () {
      _performSave();
    });
  }

  void _updateLiveStats() {
    final text = _bodyController.text;
    final lines = text.split('\n');
    _totalLines = lines.where((l) => l.trim().isNotEmpty).length;

    final words = text.trim().isEmpty ? [] : text.trim().split(RegExp(r'\s+'));
    _totalWords = words.length;

    int syllables = 0;
    for (var l in lines) {
      syllables += SyllableCounterService.countLexicalVowels(l);
    }
    _totalSyllables = syllables;

    if (mounted && !_isDisposing) setState(() {});
  }

  Future<void> _performSave() async {
    final title = _titleController.text.trim();
    final content = _bodyController.text;

    if (!_hasTextContentChanged) return;
    if (title.isEmpty && content.trim().isEmpty) return;

    if (mounted && !_isDisposing) {
      setState(() {
        _isSaving = true;
      });
    }

    final now = DateTime.now();
    _currentPoem = _currentPoem.copyWith(
      title: title,
      content: content,
      updatedAt: now,
      tags: _tags,
    );

    await widget.repository.savePoem(_currentPoem);

    _lastSavedTitle = title;
    _lastSavedContent = content;

    if (mounted && !_isDisposing) {
      setState(() {
        _isSaving = false;
        _isSaved = true;
      });
    }
  }

  void _addTag(String tag) {
    final clean = tag.trim().replaceAll(',', '');
    if (clean.isNotEmpty && !_tags.contains(clean)) {
      setState(() {
        _tags.add(clean);
        _tagInputController.clear();
      });
      _performSave();
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
    _performSave();
  }

  void _showExportMenu() async {
    final strings = widget.settingsService.strings;
    final selected = await showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(100, 80, 16, 0),
      items: [
        PopupMenuItem(value: 'copy', child: Text(strings.isAmharic ? 'ወደ ክሊፕቦርድ ገልብጥ' : 'Copy to Clipboard')),
        PopupMenuItem(value: 'txt', child: Text(strings.exportTxt)),
        PopupMenuItem(value: 'pdf', child: Text(strings.exportPdf)),
      ],
    );

    if (selected == 'copy') {
      await ExportService.copyToClipboard(_currentPoem);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.copySuccess)),
        );
      }
    } else if (selected == 'txt') {
      await ExportService.exportTxt(_currentPoem);
    } else if (selected == 'pdf') {
      await ExportService.exportPdf(_currentPoem);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = widget.settingsService.strings;

    final displayTitle = _titleController.text.trim().isEmpty
        ? strings.newPoem
        : _titleController.text.trim();

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        _performSave();
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
            _performSave();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(strings.save)),
            );
          },
          const SingleActivator(LogicalKeyboardKey.escape): () {
            _performSave();
            Navigator.pop(context, _currentPoem);
          },
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            backgroundColor: colors.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: colors.label,
                  size: 20,
                ),
                onPressed: () {
                  _performSave();
                  Navigator.pop(context, _currentPoem);
                },
              ),
              title: Column(
                children: [
                  Text(
                    displayTitle,
                    style: DesignTokens.headline(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isSaved ? Icons.cloud_done_rounded : Icons.sync_rounded,
                        size: 12,
                        color: colors.meta,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isSaving
                            ? (strings.isAmharic ? 'እያሰቀመጠ ነው...' : 'Saving...')
                            : (_isSaved
                                ? (strings.isAmharic ? 'ተቀምጧል' : 'Saved')
                                : (strings.isAmharic ? 'ያልተቀመጡ ለውጦች' : 'Unsaved changes')),
                        style: TextStyle(fontSize: 10, color: colors.meta),
                      ),
                    ],
                  ),
                ],
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: Icon(Icons.share_rounded, size: 20, color: colors.label),
                  onPressed: _showExportMenu,
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () async {
                      await _performSave();
                      if (!context.mounted) return;
                      Navigator.pop(context, _currentPoem);
                    },
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      strings.save,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
            body: SafeArea(
              child: AnimatedBuilder(
                animation: widget.settingsService,
                builder: (context, child) {
                  return Column(
                    children: [
                      // Tags Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  ..._tags.map(
                                    (tag) => Chip(
                                      label: Text('#$tag', style: TextStyle(fontSize: 12, color: colors.label)),
                                      deleteIcon: Icon(Icons.close, size: 14, color: colors.label),
                                      onDeleted: () => _removeTag(tag),
                                      backgroundColor: colors.searchFill,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 100,
                                    height: 32,
                                    child: TextField(
                                      controller: _tagInputController,
                                      style: TextStyle(fontSize: 12, color: colors.label),
                                      decoration: InputDecoration(
                                        hintText: strings.addTag,
                                        hintStyle: TextStyle(color: colors.meta),
                                        border: InputBorder.none,
                                      ),
                                      onSubmitted: _addTag,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Editor Box
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: CustomTextField(
                                titleController: _titleController,
                                bodyController: _bodyController,
                                showPills: widget.settingsService.showSyllablePills,
                                fontSize: widget.settingsService.fontSize,
                                strings: strings,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Live Stats Footer
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        color: colors.surface,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text('$_totalLines ${strings.lineSuffix}', style: DesignTokens.footnote(context)),
                            Text('$_totalWords ${strings.wordSuffix}', style: DesignTokens.footnote(context)),
                            Text('$_totalSyllables ${strings.syllableSuffix}', style: DesignTokens.footnote(context)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
