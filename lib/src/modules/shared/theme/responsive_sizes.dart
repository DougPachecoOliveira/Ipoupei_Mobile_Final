// Stub temporário para evitar erros de compilação
import 'package:flutter/material.dart';

class ResponsiveSizes {
  static EdgeInsets padding({required BuildContext context, required EdgeInsets base, EdgeInsets? compact, EdgeInsets? expanded}) => base;
  static double iconSize({required BuildContext context, required double base, double? small, double? large}) => base;
  static double spacing({required BuildContext context, required double base, double? compact, double? expanded}) => base;
  static double cardSidebarWidth(BuildContext context, {required double base}) => base;
  static double appBarHeight(BuildContext context, {required double base}) => base;
  static double appBarIconSize(BuildContext context, {required double base}) => base;
  static double fontSizeForCards(BuildContext context, {required double base}) => base;
  static double cardHeight(BuildContext context, {required double base}) => base;
  static double circularContainer({required BuildContext context, required double base, double? small, double? large}) => base;
  static EdgeInsets actionButtonPadding(BuildContext context) => const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  static double actionButtonHeight(BuildContext context, {required double base}) => base;
  static double actionButtonIconSize(BuildContext context, {required double base}) => base;
}