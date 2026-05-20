import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Returns a TextStyle with Noto Nastaliq Urdu applied when the string contains
/// Urdu/Arabic-script characters; otherwise returns [base] unchanged.
///
/// Use this when rendering bilingual assistant output so Urdu glyphs render
/// in a proper Nastaliq form instead of falling back to whatever the system
/// happens to ship.
TextStyle urduAwareStyle(String text, TextStyle? base) {
  if (_containsUrdu(text)) {
    return GoogleFonts.notoNastaliqUrdu(textStyle: base);
  }
  return base ?? const TextStyle();
}

/// Heuristic: does the text contain any character in the Arabic Unicode block?
/// Covers Urdu, Arabic, Persian — all use the same script range.
bool _containsUrdu(String text) {
  for (final codeUnit in text.runes) {
    // U+0600–U+06FF: Arabic; U+0750–U+077F: Arabic Supplement;
    // U+FB50–U+FDFF: Arabic Presentation Forms-A; U+FE70–U+FEFF: Forms-B
    if ((codeUnit >= 0x0600 && codeUnit <= 0x06FF) ||
        (codeUnit >= 0x0750 && codeUnit <= 0x077F) ||
        (codeUnit >= 0xFB50 && codeUnit <= 0xFDFF) ||
        (codeUnit >= 0xFE70 && codeUnit <= 0xFEFF)) {
      return true;
    }
  }
  return false;
}
