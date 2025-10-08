// Stub temporário para evitar erros de compilação
import 'package:flutter/material.dart';

enum AppTextGroups { cardTitles, cardValues, cardSecondary, miniCards }

class AppText {
  static Widget appBarTitle(String text, {TextStyle? style, AppTextGroups? group}) => Text(text, style: style);
  static Widget cardTitle(String text, {TextStyle? style, AppTextGroups? group}) => Text(text, style: style);
  static Widget cardValue(String text, {TextStyle? style, Color? color, AppTextGroups? group}) => Text(text, style: style?.copyWith(color: color) ?? TextStyle(color: color));
  static Widget cardSecondary(String text, {TextStyle? style, AppTextGroups? group}) => Text(text, style: style);
}