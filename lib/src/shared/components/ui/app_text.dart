// 📝 App Text - iPoupei Mobile
//
// Widget wrapper para AutoSizeText que resolve acessibilidade
// Permite fontes extremas (até 3.12 no iOS) sem quebrar layout
//
// Features:
// - AutoSizeText com ranges inteligentes
// - Factory methods para contextos específicos
// - Grupos para consistência
// - Detecção de modos extremos

import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

/// Widget wrapper que usa AutoSizeText para acessibilidade extrema
class AppText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int maxLines;
  final double? minFontSize;
  final double? maxFontSize;
  final AutoSizeGroup? group;
  final bool useAutoSize;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final bool softWrap;
  final double? textScaleFactor;

  const AppText(
    this.text, {
    super.key,
    this.style,
    this.maxLines = 1,
    this.minFontSize,
    this.maxFontSize,
    this.group,
    this.useAutoSize = true,
    this.textAlign,
    this.overflow,
    this.softWrap = true,
    this.textScaleFactor,
  });

  /// Factory para título de cards - mais restritivo
  factory AppText.cardTitle(
    String text, {
    Key? key,
    TextStyle? style,
    Color? color,
    AutoSizeGroup? group,
  }) {
    return AppText(
      text,
      key: key,
      style: style?.copyWith(color: color) ?? TextStyle(color: color),
      minFontSize: 10,
      maxFontSize: 16,
      maxLines: 1,
      group: group,
    );
  }

  /// Factory para valores monetários - críticos
  factory AppText.cardValue(
    String text, {
    Key? key,
    TextStyle? style,
    Color? color,
    AutoSizeGroup? group,
  }) {
    return AppText(
      text,
      key: key,
      style: style?.copyWith(color: color) ?? TextStyle(color: color),
      minFontSize: 7,  // 10 - 3 = 7
      maxFontSize: 13, // 16 - 3 = 13
      maxLines: 1,
      group: group,
    );
  }

  /// Factory para texto secundário (banco, tipo)
  factory AppText.cardSecondary(
    String text, {
    Key? key,
    TextStyle? style,
    Color? color,
    AutoSizeGroup? group,
  }) {
    return AppText(
      text,
      key: key,
      style: style?.copyWith(color: color) ?? TextStyle(color: color),
      minFontSize: 8,
      maxFontSize: 12,
      maxLines: 1,
      group: group,
    );
  }

  /// Factory para título do AppBar
  factory AppText.appBarTitle(
    String text, {
    Key? key,
    TextStyle? style,
    Color? color,
  }) {
    return AppText(
      text,
      key: key,
      style: style?.copyWith(color: color) ?? TextStyle(color: color),
      minFontSize: 9,  // 12 - 3 = 9
      maxFontSize: 17, // 20 - 3 = 17
      maxLines: 1,
    );
  }

  /// Factory para botões - usa FittedBox internamente
  factory AppText.button(
    String text, {
    Key? key,
    TextStyle? style,
    Color? color,
  }) {
    return AppText(
      text,
      key: key,
      style: style?.copyWith(color: color) ?? TextStyle(color: color),
      minFontSize: 10,
      maxFontSize: 18,
      maxLines: 1,
      useAutoSize: true, // Sempre usa AutoSize em botões
    );
  }

  /// Factory para texto livre (menos restritivo)
  factory AppText.body(
    String text, {
    Key? key,
    TextStyle? style,
    Color? color,
    int maxLines = 999,
    TextAlign? textAlign,
  }) {
    return AppText(
      text,
      key: key,
      style: style?.copyWith(color: color) ?? TextStyle(color: color),
      minFontSize: 12,
      maxFontSize: 24,
      maxLines: maxLines,
      textAlign: textAlign,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Detecta se está em modo de acessibilidade extrema
    final scale = MediaQuery.textScalerOf(context).scale(1.0);
    final isExtremeMode = scale > 2.0;

    // Se não usar AutoSize ou modo extremo, usa Text normal
    if (!useAutoSize && !isExtremeMode) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        textAlign: textAlign,
        overflow: overflow,
        softWrap: softWrap,
        textScaler: textScaleFactor != null
            ? TextScaler.linear(textScaleFactor!)
            : null,
      );
    }

    // Usa AutoSizeText para garantir que cabe no espaço
    return AutoSizeText(
      text,
      style: style,
      maxLines: maxLines,
      minFontSize: minFontSize ?? 8,
      maxFontSize: maxFontSize ?? 20,
      group: group,
      textAlign: textAlign,
      overflow: overflow ?? TextOverflow.ellipsis,
      softWrap: softWrap,
    );
  }
}

/// Grupos pré-definidos para consistência
class AppTextGroups {
  static final AutoSizeGroup cardTitles = AutoSizeGroup();
  static final AutoSizeGroup cardValues = AutoSizeGroup();
  static final AutoSizeGroup cardSecondary = AutoSizeGroup();
  static final AutoSizeGroup miniCards = AutoSizeGroup();
  static final AutoSizeGroup buttons = AutoSizeGroup();
}

/// Extension para detecção de acessibilidade
extension AccessibilityHelper on BuildContext {
  /// Scale factor atual do sistema
  double get textScale => MediaQuery.textScalerOf(this).scale(1.0);

  /// Está usando fonte grande (> 1.3)
  bool get isLargeText => textScale > 1.3;

  /// Está usando fonte extrema (> 2.0)
  bool get isExtremeText => textScale > 2.0;

  /// Nível de acessibilidade
  String get accessibilityLevel {
    if (textScale <= 1.0) return 'normal';
    if (textScale <= 1.3) return 'large';
    if (textScale <= 2.0) return 'very_large';
    return 'extreme';
  }
}