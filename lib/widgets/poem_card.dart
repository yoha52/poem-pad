import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/strings.dart';
import '../models/poem.dart';
import '../theme/design_tokens.dart';

class PoemCard extends StatefulWidget {
  final Poem poem;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onTogglePin;
  final VoidCallback onShare;
  final AppStrings strings;

  const PoemCard({
    super.key,
    required this.poem,
    required this.onTap,
    required this.onDelete,
    required this.onDuplicate,
    required this.onTogglePin,
    required this.onShare,
    this.strings = const AppStrings(),
  });

  @override
  State<PoemCard> createState() => _PoemCardState();
}

class _PoemCardState extends State<PoemCard> {
  final ValueNotifier<bool> _isHovered = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isPressed = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _isHovered.dispose();
    _isPressed.dispose();
    super.dispose();
  }

  bool get _isDesktop {
    if (kIsWeb) return true;
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  void _showActionMenu(BuildContext context, {Offset? position}) async {
    final colors = context.colors;
    final strings = widget.strings;

    if (_isDesktop && position != null) {
      final RenderBox overlay =
          Overlay.of(context).context.findRenderObject() as RenderBox;

      final selected = await showMenu<String>(
        context: context,
        position: RelativeRect.fromRect(
          position & const Size(40, 40),
          Offset.zero & overlay.size,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.menuRadius),
        ),
        color: colors.surfaceElevated,
        items: [
          PopupMenuItem<String>(
            value: 'pin',
            child: Row(
              children: [
                Icon(
                  widget.poem.isPinned
                      ? CupertinoIcons.pin_slash
                      : CupertinoIcons.pin,
                  size: 18,
                  color: colors.accent,
                ),
                const SizedBox(width: 10),
                Text(
                  widget.poem.isPinned ? strings.unpin : strings.pin,
                  style: TextStyle(color: colors.label),
                ),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'duplicate',
            child: Row(
              children: [
                Icon(CupertinoIcons.doc_on_doc, size: 18, color: colors.label),
                const SizedBox(width: 10),
                Text(strings.duplicate, style: TextStyle(color: colors.label)),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'share',
            child: Row(
              children: [
                Icon(CupertinoIcons.share, size: 18, color: colors.label),
                const SizedBox(width: 10),
                Text(strings.share, style: TextStyle(color: colors.label)),
              ],
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(CupertinoIcons.trash, size: 18, color: colors.destructive),
                const SizedBox(width: 10),
                Text(strings.delete, style: TextStyle(color: colors.destructive)),
              ],
            ),
          ),
        ],
      );

      if (selected == 'delete') {
        widget.onDelete();
      } else if (selected == 'duplicate') {
        widget.onDuplicate();
      } else if (selected == 'pin') {
        widget.onTogglePin();
      } else if (selected == 'share') {
        widget.onShare();
      }
    } else {
      // Touch/Mobile Bottom Sheet
      HapticFeedback.lightImpact();
      showModalBottomSheet(
        context: context,
        backgroundColor: colors.surfaceElevated,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.meta.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    widget.poem.isPinned
                        ? CupertinoIcons.pin_slash
                        : CupertinoIcons.pin,
                    color: colors.accent,
                  ),
                  title: Text(
                    widget.poem.isPinned ? strings.unpin : strings.pin,
                    style: TextStyle(color: colors.label),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onTogglePin();
                  },
                ),
                ListTile(
                  leading: Icon(CupertinoIcons.doc_on_doc, color: colors.label),
                  title: Text(strings.duplicate, style: TextStyle(color: colors.label)),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onDuplicate();
                  },
                ),
                ListTile(
                  leading: Icon(CupertinoIcons.share, color: colors.label),
                  title: Text(strings.share, style: TextStyle(color: colors.label)),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onShare();
                  },
                ),
                ListTile(
                  leading: Icon(CupertinoIcons.trash, color: colors.destructive),
                  title: Text(strings.delete, style: TextStyle(color: colors.destructive)),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onDelete();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      );
    }
  }

  List<Widget> _buildExcerptWidgets(BuildContext context) {
    final colors = context.colors;
    final strings = widget.strings;
    final rawLines = widget.poem.content.split('\n');
    final List<Widget> widgets = [];

    int lineCount = 0;
    bool lastWasBlank = true;

    for (var raw in rawLines) {
      final line = raw.trim();
      if (line.isEmpty) {
        if (!lastWasBlank && lineCount > 0 && lineCount < 5) {
          widgets.add(const SizedBox(height: 8));
          lastWasBlank = true;
        }
      } else {
        if (lineCount >= 5) break;

        widgets.add(
          Text(
            line,
            style: TextStyle(
              fontSize: 14,
              height: 1.43,
              color: colors.body,
              letterSpacing: DesignTokens.ethioLetterSpacing,
              fontFamily: DesignTokens.primaryFont,
              fontFamilyFallback: DesignTokens.fontFallback,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        );

        lineCount++;
        lastWasBlank = false;
      }
    }

    if (widgets.isEmpty) {
      widgets.add(
        Text(
          strings.emptyPoem,
          style: TextStyle(
            fontSize: 14,
            height: 1.43,
            fontStyle: FontStyle.italic,
            color: colors.meta,
            letterSpacing: DesignTokens.ethioLetterSpacing,
          ),
        ),
      );
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = widget.strings;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final totalLines = widget.poem.content
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .length;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (_isDesktop) _isHovered.value = true;
      },
      onExit: (_) {
        if (_isDesktop) _isHovered.value = false;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _isPressed.value = true,
        onTapUp: (_) => _isPressed.value = false,
        onTapCancel: () => _isPressed.value = false,
        onTap: widget.onTap,
        onSecondaryTapDown: (details) {
          _showActionMenu(context, position: details.globalPosition);
        },
        onLongPress: () {
          _showActionMenu(context);
        },
        child: ValueListenableBuilder<bool>(
          valueListenable: _isPressed,
          builder: (context, isPressed, child) {
            return ValueListenableBuilder<bool>(
              valueListenable: _isHovered,
              builder: (context, isHovered, child) {
                final double translateY = (isHovered && _isDesktop) ? -2.0 : 0.0;
                final double scale = isPressed ? 0.97 : 1.0;

                return Transform.translate(
                  offset: Offset(0, translateY),
                  child: AnimatedScale(
                    scale: scale,
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOut,
                    child: Stack(
                      children: [
                        // Container Box
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          constraints: const BoxConstraints(minHeight: 48),
                          padding: EdgeInsets.fromLTRB(
                            16,
                            16,
                            (_isDesktop ? 36 : 16),
                            14,
                          ),
                          decoration: BoxDecoration(
                            color: isPressed ? colors.surfaceElevated : colors.surface,
                            borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
                            border: Border.all(
                              color: colors.separator,
                              width: 0.5,
                            ),
                            boxShadow: isDark
                                ? const []
                                : [
                                    BoxShadow(
                                      color: const Color.fromRGBO(0, 0, 0, 0.04),
                                      blurRadius: isHovered ? 6 : 3,
                                      offset: const Offset(0, 1),
                                    ),
                                    BoxShadow(
                                      color: const Color.fromRGBO(0, 0, 0, 0.08),
                                      blurRadius: isHovered ? 28 : 24,
                                      offset: Offset(0, isHovered ? 12 : 10),
                                      spreadRadius: -8,
                                    ),
                                  ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Title Row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Hero(
                                      tag: 'poem_title_${widget.poem.id}',
                                      child: Material(
                                        color: Colors.transparent,
                                        child: Text(
                                          widget.poem.title.isEmpty ? strings.untitled : widget.poem.title,
                                          style: TextStyle(
                                            fontSize: 17,
                                            height: 1.3,
                                            fontWeight: widget.poem.title.isEmpty
                                                ? FontWeight.w500
                                                : FontWeight.w600,
                                            color: widget.poem.title.isEmpty
                                                ? colors.meta
                                                : colors.label,
                                            letterSpacing: DesignTokens.ethioLetterSpacing,
                                            fontFamily: DesignTokens.primaryFont,
                                            fontFamilyFallback: DesignTokens.fontFallback,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (widget.poem.isPinned) ...[
                                    const SizedBox(width: 6),
                                    Icon(
                                      CupertinoIcons.pin,
                                      size: 14,
                                      color: colors.accent,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Excerpt
                              ..._buildExcerptWidgets(context),

                              const SizedBox(height: 10),

                              // Adaptive Footer Row
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final dateText = Text(
                                    strings.formatDate(widget.poem.updatedAt),
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.33,
                                      fontWeight: FontWeight.w500,
                                      color: colors.meta,
                                      letterSpacing: DesignTokens.ethioLetterSpacing,
                                    ),
                                  );

                                  final countText = totalLines > 0
                                      ? Text(
                                          '$totalLines ${strings.lineSuffix}',
                                          maxLines: 1,
                                          softWrap: false,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            height: 1.33,
                                            fontWeight: FontWeight.w500,
                                            color: colors.meta,
                                            letterSpacing: DesignTokens.ethioLetterSpacing,
                                          ),
                                        )
                                      : null;

                                  if (constraints.maxWidth < 140) {
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        dateText,
                                        if (countText != null) ...[
                                          const SizedBox(height: 2),
                                          countText,
                                        ],
                                      ],
                                    );
                                  }

                                  return Row(
                                    children: [
                                      Expanded(child: dateText),
                                      if (countText != null) ...[
                                        const SizedBox(width: 8),
                                        countText,
                                      ],
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        // Desktop Hover Overlay Button
                        if (_isDesktop)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: IgnorePointer(
                              ignoring: !isHovered,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 120),
                                opacity: isHovered ? 1.0 : 0.0,
                                child: GestureDetector(
                                  onTapDown: (details) {
                                    _showActionMenu(context, position: details.globalPosition);
                                  },
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: colors.surfaceElevated,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: colors.separator, width: 0.5),
                                    ),
                                    child: Icon(
                                      CupertinoIcons.ellipsis,
                                      size: 16,
                                      color: colors.meta,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
