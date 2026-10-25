import 'package:flutter/services.dart';

/// Paste cleaning and per-line syllable counting for Amharic / English poems.
class SyllableCounterService {
  // ─────────────────────────── Paste cleaning ───────────────────────────

  static final RegExp _dirty =
      RegExp(r'[\r\u00A0\u00AD\u200B\u200C\u200D\u2028\u2029\u2060\uFEFF]');

  static String clean(String s) {
    if (!_dirty.hasMatch(s)) return s;

    final out = StringBuffer();
    final n = s.length;
    for (int i = 0; i < n; i++) {
      final c = s.codeUnitAt(i);
      switch (c) {
        case 0x0D:
          out.writeCharCode(0x0A);
          if (i + 1 < n && s.codeUnitAt(i + 1) == 0x0A) i++;
          break;
        case 0x2028:
        case 0x2029:
          out.writeCharCode(0x0A);
          break;
        case 0x00A0:
          out.writeCharCode(0x20);
          break;
        case 0x00AD:
        case 0x200B:
        case 0x200C:
        case 0x200D:
        case 0x2060:
        case 0xFEFF:
          break;
        default:
          out.writeCharCode(c);
      }
    }
    return out.toString();
  }

  static TextEditingValue cleanPaste(TextEditingValue oldV, TextEditingValue newV) {
    final text = newV.text;
    if (!_dirty.hasMatch(text)) return newV;

    final cleaned = clean(text);
    final end = newV.selection.extentOffset.clamp(0, text.length);
    final caret = clean(text.substring(0, end)).length;
    return TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(offset: caret),
    );
  }

  // ─────────────────────────── Syllable counting ───────────────────────────

  static int countLexicalVowels(String text) {
    final n = text.length;
    if (n == 0) return 0;

    for (int i = 0; i < n; i++) {
      final c = text.codeUnitAt(i);
      if (c >= 0x1200 && c <= 0x137F) return _countAmharic(text);
    }
    return _countEnglish(text);
  }

  static bool _isSades(int c) => ((c - 0x1200) & 7) == 5;

  static int _countAmharic(String text) {
    final n = text.length;
    int total = 0;
    bool atWordStart = true;
    bool prevSades = false;
    bool wordStartedWithSades = false;
    int prevChar = -1;

    int segStart = -1;
    bool segHasLatin = false;

    for (int i = 0; i < n; i++) {
      final c = text.codeUnitAt(i);

      if (c >= 0x1200 && c <= 0x137F) {
        if (segHasLatin) total += _countEnglish(text.substring(segStart, i));
        segStart = -1;
        segHasLatin = false;

        if (c <= 0x135A) {
          // Ethiopic syllable letter: skip repeated identical consecutive character
          if (c == prevChar) {
            continue;
          }

          if (_isSades(c)) {
            if (atWordStart) {
              total++;
              wordStartedWithSades = true;
            } else if (prevSades) {
              if (wordStartedWithSades) {
                // Second Sades right after initial Sades merges into the first syllable
                wordStartedWithSades = false;
              } else {
                total++;
              }
            }
            prevSades = true;
          } else {
            total++;
            prevSades = false;
            wordStartedWithSades = false;
          }
          atWordStart = false;
          prevChar = c;
        } else if (c >= 0x135B && c <= 0x135F) {
          // combining marks (gemination etc.): belong to previous letter
        } else {
          // Ethiopic punctuation and numerals: end of word
          atWordStart = true;
          prevSades = false;
          wordStartedWithSades = false;
          prevChar = -1;
        }
      } else {
        // Whitespace, ASCII punctuation, digits, Latin letters...
        atWordStart = true;
        prevSades = false;
        wordStartedWithSades = false;
        prevChar = -1;
        if (segStart < 0) segStart = i;
        if (!segHasLatin && _isLatinLetter(c)) segHasLatin = true;
      }
    }

    if (segHasLatin) total += _countEnglish(text.substring(segStart));
    return total;
  }

  // ─────────────────────────── English fallback ───────────────────────────

  static final RegExp _nonLetters = RegExp(r'[^a-z\s]');
  static final RegExp _whitespace = RegExp(r'\s+');
  static final RegExp _extraSyllable =
      RegExp(r'(?:[aeiou]ing|diet|poet|tri[au]|scien|dual|ide|flu|[^g]et)$');

  static bool _isLatinLetter(int c) =>
      (c >= 0x41 && c <= 0x5A) || (c >= 0x61 && c <= 0x7A);

  static bool _isVowel(int c) =>
      c == 0x61 || c == 0x65 || c == 0x69 || c == 0x6F || c == 0x75 || c == 0x79;

  static int _countEnglish(String text) {
    int sum = 0;
    for (final w in text.toLowerCase().replaceAll(_nonLetters, '').split(_whitespace)) {
      if (w.isEmpty) continue;

      int c = 0;
      bool inVowel = false;
      for (int i = 0; i < w.length; i++) {
        final v = _isVowel(w.codeUnitAt(i));
        if (v && !inVowel) c++;
        inVowel = v;
      }

      if (w.endsWith('e') &&
          !(w.endsWith('le') &&
              w.length > 2 &&
              !_isVowel(w.codeUnitAt(w.length - 3)))) {
        c--;
      }
      if (_extraSyllable.hasMatch(w)) c++;

      sum += c <= 0 ? 1 : c;
    }
    return sum;
  }
}
