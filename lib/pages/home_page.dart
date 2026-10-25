import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/poem.dart';
import '../repositories/poem_repository.dart';
import '../services/export_service.dart';
import '../services/settings_service.dart';
import '../theme/design_tokens.dart';
import '../widgets/poem_card.dart';
import 'settings_page.dart';
import 'text_editor_page.dart';
import 'trash_page.dart';

class HomePage extends StatefulWidget {
  final PoemRepository repository;
  final SettingsService settingsService;

  const HomePage({
    super.key,
    required this.repository,
    required this.settingsService,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Poem> _poems = [];
  List<String> _allTags = [];
  String? _selectedTag;
  bool _isLoading = true;
  String _searchQuery = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _initData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    await widget.repository.migrateFromSharedPreferencesIfNeeded();
    await _loadPoems();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.trim();
        });
        _loadPoems();
      }
    });
  }

  Future<void> _loadPoems() async {
    final poems = await widget.repository.getActivePoems(
      query: _searchQuery,
      selectedTag: _selectedTag,
      sortOption: widget.settingsService.defaultSort,
    );
    final tags = await widget.repository.getAllTags();

    if (mounted) {
      setState(() {
        _poems = poems;
        _allTags = tags;
        _isLoading = false;
      });
    }
  }

  Future<void> _openEditor({Poem? poem}) async {
    final result = await Navigator.push<Poem?>(
      context,
      TextEditorPage.route(
        poem: poem,
        repository: widget.repository,
        settingsService: widget.settingsService,
      ),
    );

    if (result != null) {
      await _loadPoems();
    }
  }

  Future<void> _deletePoem(Poem poem) async {
    final colors = context.colors;
    final strings = widget.settingsService.strings;
    await widget.repository.softDeletePoem(poem.id);
    await _loadPoems();

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${poem.title.isEmpty ? strings.untitled : poem.title}" ${strings.deleteSuccess}'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: strings.undo,
            textColor: colors.accent,
            onPressed: () async {
              await widget.repository.restorePoem(poem.id);
              await _loadPoems();
            },
          ),
        ),
      );
    }
  }

  Future<void> _duplicatePoem(Poem poem) async {
    final strings = widget.settingsService.strings;
    final now = DateTime.now();
    final baseTitle = poem.title.isEmpty ? strings.untitled : poem.title;
    final duplicate = Poem(
      id: now.millisecondsSinceEpoch.toString(),
      title: '$baseTitle (${strings.copySuffix})',
      content: poem.content,
      createdAt: now,
      updatedAt: now,
      isPinned: false,
      tags: poem.tags,
    );
    await widget.repository.savePoem(duplicate);
    await _loadPoems();
  }

  Future<void> _togglePin(Poem poem) async {
    final updated = poem.copyWith(isPinned: !poem.isPinned, updatedAt: DateTime.now());
    await widget.repository.savePoem(updated);
    await _loadPoems();
  }

  Future<void> _sharePoem(Poem poem) async {
    final strings = widget.settingsService.strings;
    await ExportService.copyToClipboard(poem);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.copySuccess)),
      );
    }
  }

  Map<String, List<Poem>> _groupPoems(List<Poem> poems) {
    final strings = widget.settingsService.strings;
    final Map<String, List<Poem>> sections = {};
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final sevenDaysAgo = todayStart.subtract(const Duration(days: 7));

    final pinned = poems.where((p) => p.isPinned).toList();
    final unpinned = poems.where((p) => !p.isPinned).toList();

    if (pinned.isNotEmpty) {
      sections[strings.pinnedSection] = pinned;
    }

    final todayList = unpinned.where((p) => p.updatedAt.isAfter(todayStart)).toList();
    final weekList = unpinned
        .where((p) =>
            p.updatedAt.isBefore(todayStart) && p.updatedAt.isAfter(sevenDaysAgo))
        .toList();
    final earlierList =
        unpinned.where((p) => p.updatedAt.isBefore(sevenDaysAgo)).toList();

    if (todayList.isNotEmpty) sections[strings.todaySection] = todayList;
    if (weekList.isNotEmpty) sections[strings.weekSection] = weekList;
    if (earlierList.isNotEmpty) sections[strings.earlierSection] = earlierList;

    return sections;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = widget.settingsService.strings;
    final sections = _groupPoems(_poems);

    return AnimatedBuilder(
      animation: widget.settingsService,
      builder: (context, child) {
        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.keyN, control: true): () => _openEditor(),
            const SingleActivator(LogicalKeyboardKey.keyF, control: true): () => _searchFocusNode.requestFocus(),
          },
          child: Focus(
            autofocus: true,
            child: Scaffold(
              backgroundColor: colors.background,
              body: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: colors.accent),
                    )
                  : Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: CustomScrollView(
                          slivers: [
                            // Header Bar
                            SliverAppBar.large(
                              backgroundColor: colors.background,
                              surfaceTintColor: Colors.transparent,
                              title: Text(
                                strings.appTitle,
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                  color: colors.label,
                                  letterSpacing: DesignTokens.ethioLetterSpacing,
                                ),
                              ),
                              actions: [
                                IconButton(
                                  icon: Icon(Icons.delete_outline_rounded, color: colors.label),
                                  tooltip: strings.trashTitle,
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      CupertinoPageRoute(
                                        builder: (_) => TrashPage(repository: widget.repository),
                                      ),
                                    );
                                    _loadPoems();
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.settings_outlined, color: colors.label),
                                  tooltip: strings.settingsTitle,
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      CupertinoPageRoute(
                                        builder: (_) => SettingsPage(
                                          settingsService: widget.settingsService,
                                          repository: widget.repository,
                                        ),
                                      ),
                                    );
                                    _loadPoems();
                                  },
                                ),
                              ],
                              pinned: true,
                            ),

                            // Subtitle & Search Bar
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_poems.length} ${strings.poemsCount}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: colors.meta,
                                        letterSpacing: DesignTokens.ethioLetterSpacing,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      height: 36,
                                      child: CupertinoSearchTextField(
                                        controller: _searchController,
                                        focusNode: _searchFocusNode,
                                        placeholder: strings.searchPlaceholder,
                                        backgroundColor: colors.searchFill,
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: colors.label,
                                          letterSpacing: DesignTokens.ethioLetterSpacing,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(DesignTokens.searchRadius),
                                      ),
                                    ),
                                    if (_allTags.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: [
                                            ChoiceChip(
                                              label: Text(strings.allTags),
                                              selected: _selectedTag == null,
                                              onSelected: (_) {
                                                setState(() => _selectedTag = null);
                                                _loadPoems();
                                              },
                                            ),
                                            const SizedBox(width: 8),
                                            ..._allTags.map(
                                              (t) => Padding(
                                                padding: const EdgeInsets.only(right: 6.0),
                                                child: ChoiceChip(
                                                  label: Text('#$t'),
                                                  selected: _selectedTag == t,
                                                  onSelected: (sel) {
                                                    setState(() => _selectedTag = sel ? t : null);
                                                    _loadPoems();
                                                  },
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),

                            // Empty State or Masonry Grid
                            if (_poems.isEmpty)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _searchQuery.isNotEmpty
                                            ? CupertinoIcons.search_circle_fill
                                            : CupertinoIcons.doc_text_fill,
                                        size: 64,
                                        color: colors.meta,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        _searchQuery.isNotEmpty
                                            ? strings.noPoemsFound
                                            : strings.emptyNotesPrompt,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: colors.meta,
                                          letterSpacing: DesignTokens.ethioLetterSpacing,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ...sections.entries.expand((entry) {
                                final sectionTitle = entry.key;
                                final sectionPoems = entry.value;

                                return [
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                                      child: Text(
                                        sectionTitle,
                                        style: TextStyle(
                                          fontSize: 20,
                                          height: 1.3,
                                          fontWeight: FontWeight.bold,
                                          color: colors.label,
                                          letterSpacing: DesignTokens.ethioLetterSpacing,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SliverPadding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                    sliver: SliverLayoutBuilder(
                                      builder: (context, constraints) {
                                        const double minCardWidth = 180.0;
                                        const double gap = 12.0;
                                        final int cols = ((constraints.crossAxisExtent + gap) / (minCardWidth + gap)).floor();
                                        final int crossAxisCount = cols < 1 ? 1 : cols;

                                        return SliverMasonryGrid.count(
                                          crossAxisCount: crossAxisCount,
                                          mainAxisSpacing: gap,
                                          crossAxisSpacing: gap,
                                          childCount: sectionPoems.length,
                                          itemBuilder: (context, index) {
                                            final poem = sectionPoems[index];
                                            return PoemCard(
                                              poem: poem,
                                              strings: strings,
                                              onTap: () => _openEditor(poem: poem),
                                              onDelete: () => _deletePoem(poem),
                                              onDuplicate: () => _duplicatePoem(poem),
                                              onTogglePin: () => _togglePin(poem),
                                              onShare: () => _sharePoem(poem),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ];
                              }),

                            const SliverToBoxAdapter(
                              child: SizedBox(height: 100),
                            ),
                          ],
                        ),
                      ),
                    ),
              floatingActionButton: FloatingActionButton.extended(
                elevation: 4,
                backgroundColor: colors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                onPressed: () => _openEditor(),
                icon: const Icon(CupertinoIcons.add, size: 20),
                label: Text(
                  strings.newPoem,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: DesignTokens.ethioLetterSpacing,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
