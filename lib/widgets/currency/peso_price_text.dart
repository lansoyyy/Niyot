import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Displays Philippine peso amounts reliably (Poppins lacks ₱ glyph on some devices).
class PesoPriceText extends StatelessWidget {
  const PesoPriceText(
    this.amount, {
    super.key,
    this.style,
    this.freeLabel = 'Free',
    this.symbolStyle,
  });

  final int amount;
  final TextStyle? style;
  final String freeLabel;
  /// Optional override for the peso sign only (Roboto carries ₱ reliably).
  final TextStyle? symbolStyle;

  static String formatDigits(int price) {
    if (price == 0) return '0';
    final s = price.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  static TextSpan pesoSpan(TextStyle base, {TextStyle? symbolExtra}) {
    final sym = GoogleFonts.roboto(
      textStyle: base.merge(symbolExtra ?? const TextStyle()),
      fontWeight: base.fontWeight,
    );
    return TextSpan(
      text: '\u20B1',
      style: sym,
    );
  }

  @override
  Widget build(BuildContext context) {
    final base =
        style ??
        GoogleFonts.poppins(
          fontSize: 14,
          color: const Color(0xFF1A1A1A),
        );

    if (amount == 0) {
      return Text(
        freeLabel,
        style: base,
      );
    }

    final digits = formatDigits(amount);
    return Text.rich(
      TextSpan(
        children: [
          pesoSpan(base, symbolExtra: symbolStyle),
          TextSpan(text: digits, style: base),
        ],
      ),
    );
  }
}
