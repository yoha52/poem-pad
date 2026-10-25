import 'package:flutter/material.dart';
import '../constants/strings.dart';
import '../models/poem.dart';
import '../repositories/poem_repository.dart';
import '../theme/design_tokens.dart';

class TrashPage extends StatefulWidget {
  final PoemRepository repository;
  final AppStrings strings;

  const TrashPage({
    super.key,
    required this.repository,
    this.strings = const AppStrings(),
  });

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {
  List<Poem> _trashPoems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrash();
  }

  Future<void> _loadTrash() async {
    final poems = await widget.repository.getTrashPoems();
    setState(() {
      _trashPoems = poems;
      _isLoading = false;
    });
  }

  Future<void> _restore(Poem poem) async {
    final strings = widget.strings;
    await widget.repository.restorePoem(poem.id);
    await _loadTrash();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${poem.title.isEmpty ? strings.untitled : poem.title}" ${strings.restore}')),
      );
    }
  }

  Future<void> _purge(Poem poem) async {
    final colors = context.colors;
    final strings = widget.strings;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.purge),
        content: Text('"${poem.title.isEmpty ? strings.untitled : poem.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('አይ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: colors.destructive),
            child: Text(strings.delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.repository.purgePoem(poem.id);
      await _loadTrash();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = widget.strings;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(strings.trashTitle, style: DesignTokens.headline(context)),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colors.accent))
          : _trashPoems.isEmpty
              ? Center(
                  child: Text(
                    strings.trashEmpty,
                    style: DesignTokens.subhead(context),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _trashPoems.length,
                  itemBuilder: (context, index) {
                    final poem = _trashPoems[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: colors.surface,
                      child: ListTile(
                        title: Text(
                          poem.title.isEmpty ? strings.untitled : poem.title,
                          style: DesignTokens.headline(context),
                        ),
                        subtitle: Text(
                          poem.content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DesignTokens.subhead(context),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.restore_rounded, color: colors.label),
                              tooltip: strings.restore,
                              onPressed: () => _restore(poem),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_forever_rounded, color: colors.destructive),
                              tooltip: strings.purge,
                              onPressed: () => _purge(poem),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
