// Stub temporário para evitar erros de compilação
import 'package:flutter/material.dart';

class AppTypography {
  static TextStyle onDark(BuildContext context, TextStyle style) => style.copyWith(color: Colors.white);
  static TextStyle onDarkSecondary(BuildContext context, TextStyle style) => style.copyWith(color: Colors.white.withAlpha(208));
  static TextStyle currencyMedium(BuildContext context) => const TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
  static TextStyle label(BuildContext context) => const TextStyle(fontSize: 12);
  static TextStyle bodyMedium(BuildContext context) => const TextStyle(fontSize: 14);
  static TextStyle bodySmall(BuildContext context) => const TextStyle(fontSize: 12);
  static TextStyle bold(TextStyle style) => style.copyWith(fontWeight: FontWeight.bold);
  static TextStyle semiBold(TextStyle style) => style.copyWith(fontWeight: FontWeight.w600);
  static TextStyle caption(BuildContext context) => const TextStyle(fontSize: 12);
  static TextStyle h3(BuildContext context) => const TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
  static TextStyle appBarTitle(BuildContext context) => const TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
  static TextStyle actionButton(BuildContext context) => const TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
  static TextStyle actionButtonSecondary(BuildContext context) => const TextStyle(fontSize: 16, fontWeight: FontWeight.w500);
}