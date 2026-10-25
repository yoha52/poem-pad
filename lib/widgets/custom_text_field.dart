import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../constants/strings.dart';
import '../services/syllable_counter_service.dart';
import '../theme/design_tokens.dart';
import '../utils/units.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController titleController;
  final TextEditingController bodyController;
  final bool showPills;
  final double fontSize;
  final AppStrings strings;

  const CustomTextField({
    super.key,
    required this.titleController,
    required this.bodyController,
    this.showPills = true,
    this.fontSize = Units.fontSize,
    this.strings = const AppStrings(),
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  static const double _letterSpacing = 1.0;
  static const double _lineHeight = 1.5;
  static const double _paddingVertical = 8.0;
  static const double _paddingHorizontal = 8.0;
  static const double _pillInset = 4.0;

  final ScrollController _bodyScrollController = ScrollController();
  final GlobalKey _bodyFieldKey = GlobalKey();
  final GlobalKey _gutterKey = GlobalKey();
  final _PillLayoutCache _pillCache = _PillLayoutCache();

  late Listenable _repaint;

  @visibleForTesting
  List<double> get debugPillTops => _pillCache.tops;

  @visibleForTesting
  List<int> get debugPillCounts => _pillCache.counts;

  @override
  void initState() {
    super.initState();
    _repaint = Listenable.merge(<Listenable>[
      widget.bodyController,
      _bodyScrollController,
    ]);
  }

  @override
  void didUpdateWidget(CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bodyController != widget.bodyController) {
      _repaint = Listenable.merge(<Listenable>[
        widget.bodyController,
        _bodyScrollController,
      ]);
    }
  }

  @override
  void dispose() {
    _pillCache.dispose();
    _bodyScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final double counterAreaWidth = widget.showPills ? Units.counterArea : 0.0;
    final TextScaler textScaler = MediaQuery.textScalerOf(context);

    return Column(
      children: [
        // Title Input Area
        Container(
          alignment: Alignment.center,
          constraints: const BoxConstraints(minHeight: 52),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(20),
              topLeft: Radius.circular(20),
            ),
          ),
          child: TextField(
            controller: widget.titleController,
            maxLines: 1,
            style: TextStyle(
              fontSize: widget.fontSize + 8,
              fontFamily: Units.fontFamily,
              color: colors.label,
              fontWeight: FontWeight.bold,
            ),
            strutStyle: StrutStyle(
              fontSize: widget.fontSize + 8,
              fontFamily: Units.fontFamily,
              forceStrutHeight: true,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintText: widget.strings.titleHint,
              hintStyle: TextStyle(
                fontSize: widget.fontSize + 8,
                fontFamily: Units.fontFamily,
                color: colors.meta,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Divider(height: 1, thickness: 1, color: colors.separator),

        // Body Editor & Syllable Counter Area
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              color: colors.surface,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double fieldWidth =
                    (constraints.maxWidth - counterAreaWidth).clamp(0.0, double.infinity).toDouble();

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gutter with animated collapse
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: counterAreaWidth,
                      height: constraints.maxHeight,
                      child: widget.showPills && counterAreaWidth > 0
                          ? CustomPaint(
                              key: _gutterKey,
                              size: Size(counterAreaWidth, constraints.maxHeight),
                              painter: _PillPainter(
                                cache: _pillCache,
                                repaint: _repaint,
                                bodyController: widget.bodyController,
                                bodyFieldKey: _bodyFieldKey,
                                gutterKey: _gutterKey,
                                textScaler: textScaler,
                                fieldWidth: fieldWidth,
                                fontSize: widget.fontSize,
                                lineHeight: _lineHeight,
                                pillInset: _pillInset,
                                colors: colors,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),

                    // Body TextField
                    Expanded(
                      child: TextField(
                        key: _bodyFieldKey,
                        inputFormatters: [
                          TextInputFormatter.withFunction(
                            SyllableCounterService.cleanPaste,
                          ),
                        ],
                        controller: widget.bodyController,
                        scrollController: _bodyScrollController,
                        keyboardType: TextInputType.multiline,
                        scrollPhysics: const ClampingScrollPhysics(),
                        maxLines: null,
                        expands: true,
                        style: TextStyle(
                          fontSize: widget.fontSize,
                          fontFamily: Units.fontFamily,
                          color: colors.label,
                          letterSpacing: _letterSpacing,
                        ),
                        strutStyle: StrutStyle(
                          fontSize: widget.fontSize,
                          fontFamily: Units.fontFamily,
                          height: _lineHeight,
                          forceStrutHeight: true,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: widget.strings.bodyHint,
                          hintStyle: TextStyle(
                            fontSize: widget.fontSize,
                            fontFamily: Units.fontFamily,
                            color: colors.meta,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: _paddingHorizontal,
                            vertical: _paddingVertical,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _PillLayoutCache {
  final Map<String, int> _syllables = <String, int>{};
  final Map<int, TextPainter> _labels = <int, TextPainter>{};
  TextScaler? _labelScaler;
  RenderEditable? _editable;

  String? _text;
  double _width = -1;
  double _lineBox = -1;
  double _endRelTop = double.nan;

  List<double> tops = const <double>[];
  List<int> counts = const <int>[];

  RenderEditable? resolveEditable(RenderObject root) {
    final RenderEditable? known = _editable;
    if (known != null && known.attached) return known;

    RenderEditable? found;
    void visit(RenderObject node) {
      if (found != null) return;
      if (node is RenderEditable) {
        found = node;
        return;
      }
      node.visitChildren(visit);
    }

    visit(root);
    if (!identical(found, _editable)) {
      _editable = found;
      _text = null;
    }
    return found;
  }

  static double _caretTop(RenderEditable editable, int offset) {
    return editable.getLocalRectForCaret(TextPosition(offset: offset)).top;
  }

  void refresh(RenderEditable editable, String text, double lineBox) {
    final double width = editable.size.width;
    final double endRelTop =
        _caretTop(editable, text.length) - _caretTop(editable, 0);

    if (_text == text &&
        _width == width &&
        _lineBox == lineBox &&
        _endRelTop == endRelTop) {
      return;
    }
    _text = text;
    _width = width;
    _lineBox = lineBox;
    _endRelTop = endRelTop;

    final List<String> lines = text.split('\n');
    final List<double> newTops = List<double>.filled(lines.length, 0.0);
    final List<int> newCounts = List<int>.filled(lines.length, 0);
    if (_syllables.length > 5000) _syllables.clear();

    final double firstTop = _caretTop(editable, 0);
    int start = 0;
    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i];
      if (i > 0) {
        final double rel = _caretTop(editable, start) - firstTop;
        final int visualLines = (rel / lineBox).round();
        newTops[i] = (visualLines < 0 ? 0 : visualLines) * lineBox;
      }
      newCounts[i] =
          _syllables[line] ??= SyllableCounterService.countLexicalVowels(line);
      start += line.length + 1;
    }
    tops = newTops;
    counts = newCounts;
  }

  TextPainter labelPainter(int count, TextScaler scaler, double fontSize, Color textColor) {
    if (_labelScaler != scaler) {
      for (final TextPainter p in _labels.values) {
        p.dispose();
      }
      _labels.clear();
      _labelScaler = scaler;
    }
    return _labels.putIfAbsent(count, () {
      return TextPainter(
        text: TextSpan(
          text: '$count',
          style: TextStyle(
            fontSize: fontSize - 3,
            fontWeight: FontWeight.bold,
            color: textColor,
            fontFamily: Units.fontFamily,
          ),
        ),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
    });
  }

  void dispose() {
    for (final TextPainter p in _labels.values) {
      p.dispose();
    }
    _labels.clear();
    _editable = null;
  }
}

class _PillPainter extends CustomPainter {
  _PillPainter({
    required this.cache,
    required Listenable repaint,
    required this.bodyController,
    required this.bodyFieldKey,
    required this.gutterKey,
    required this.textScaler,
    required this.fieldWidth,
    required this.fontSize,
    required this.lineHeight,
    required this.pillInset,
    required this.colors,
  }) : super(repaint: repaint);

  final _PillLayoutCache cache;
  final TextEditingController bodyController;
  final GlobalKey bodyFieldKey;
  final GlobalKey gutterKey;
  final TextScaler textScaler;
  final double fieldWidth;
  final double fontSize;
  final double lineHeight;
  final double pillInset;
  final AppColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0) return;

    final RenderObject? gutterObject = gutterKey.currentContext?.findRenderObject();
    final RenderObject? fieldObject = bodyFieldKey.currentContext?.findRenderObject();
    if (gutterObject is! RenderBox || !gutterObject.attached) return;
    if (fieldObject == null || !fieldObject.attached) return;

    final RenderEditable? editable = cache.resolveEditable(fieldObject);
    if (editable == null || !editable.hasSize) return;

    final double lineBox = textScaler.scale(fontSize) * lineHeight;
    if (lineBox <= 0) return;

    cache.refresh(editable, bodyController.text, lineBox);

    final double originDelta = editable.localToGlobal(Offset.zero).dy -
        gutterObject.localToGlobal(Offset.zero).dy;
    final double scroll = editable.offset.hasPixels ? editable.offset.pixels : 0.0;
    final double base = originDelta - scroll;

    final double pillHeight = lineBox - 2;
    final double pillWidth = size.width - pillInset * 2;
    if (pillWidth <= 0 || pillHeight <= 0) return;

    final Paint filled = Paint()..color = colors.pillFilled;
    final Paint empty = Paint()..color = colors.pillEmpty;
    final Paint border = Paint()
      ..color = colors.separator
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.save();
    canvas.clipRect(Offset.zero & size);

    final List<double> tops = cache.tops;
    final List<int> counts = cache.counts;
    for (int i = 0; i < tops.length; i++) {
      final double y = base + tops[i];
      if (y > size.height) break;
      if (y + lineBox < 0) continue;

      final int count = counts[i];
      final RRect pill = RRect.fromRectAndRadius(
        Rect.fromLTWH(pillInset, y + 1, pillWidth, pillHeight),
        const Radius.circular(12),
      );
      canvas.drawRRect(pill, count > 0 ? filled : empty);
      canvas.drawRRect(pill.deflate(0.5), border);

      if (count > 0) {
        final TextPainter label = cache.labelPainter(count, textScaler, fontSize, colors.pillText);
        label.paint(
          canvas,
          Offset(
            pillInset + (pillWidth - label.width) / 2,
            y + 1 + (pillHeight - label.height) / 2,
          ),
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PillPainter old) {
    return old.fieldWidth != fieldWidth ||
        old.textScaler != textScaler ||
        old.fontSize != fontSize ||
        old.lineHeight != lineHeight ||
        old.pillInset != pillInset ||
        !identical(old.cache, cache) ||
        old.colors != colors ||
        old.bodyController != bodyController;
  }
}
