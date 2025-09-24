// 📝 Sistema de Tipografia - iPoupei Mobile
//
// Sistema centralizado de estilos de texto responsivos
// Integrado com ResponsiveSizes e AppColors para consistência
//
// Baseado em: Material Design Typography + Design System Profissional

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'responsive_sizes.dart';

class AppTypography {
  // === TÍTULOS E CABEÇALHOS ===

  /// Título principal (H1) - Usado em páginas principais e headers importantes
  static TextStyle h1(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveSizes.fontSize(
        context: context,
        base: 32,
        small: 28,
        large: 36,
      ),
      fontWeight: FontWeight.bold,
      color: AppColors.cinzaEscuro,
      height: 1.2,
    );
  }

  /// Título secundário (H2) - Usado em seções e cards importantes
  static TextStyle h2(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveSizes.fontSize(
        context: context,
        base: 24,
        small: 22,
        large: 28,
      ),
      fontWeight: FontWeight.bold,
      color: AppColors.cinzaEscuro,
      height: 1.3,
    );
  }

  /// Título terciário (H3) - Usado em subtítulos e labels importantes
  static TextStyle h3(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveSizes.fontSize(
        context: context,
        base: 18,
        small: 16,
        large: 20,
      ),
      fontWeight: FontWeight.w600,
      color: AppColors.cinzaEscuro,
      height: 1.4,
    );
  }

  // === TEXTOS CORPORAIS ===

  /// Texto corporal principal - Padrão para a maioria dos textos
  static TextStyle body(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveSizes.fontSize(
        context: context,
        base: 16,
        small: 15,
        large: 17,
      ),
      fontWeight: FontWeight.normal,
      color: AppColors.cinzaEscuro,
      height: 1.5,
    );
  }

  /// Texto corporal médio - Para textos secundários
  static TextStyle bodyMedium(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveSizes.fontSize(
        context: context,
        base: 14,
        small: 13,
        large: 15,
      ),
      fontWeight: FontWeight.normal,
      color: AppColors.cinzaEscuro,
      height: 1.4,
    );
  }

  /// Texto corporal pequeno - Para informações complementares
  static TextStyle bodySmall(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveSizes.fontSize(
        context: context,
        base: 12,
        small: 11,
        large: 13,
      ),
      fontWeight: FontWeight.normal,
      color: AppColors.cinzaTexto,
      height: 1.3,
    );
  }

  // === VALORES MONETÁRIOS ===

  /// Valor monetário grande - Para saldos principais
  static TextStyle currencyLarge(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: ResponsiveSizes.fontSize(
        context: context,
        base: 24,
        small: 22,
        large: 28,
      ),
      fontWeight: FontWeight.bold,
      color: color ?? AppColors.cinzaEscuro,
      height: 1.2,
    );
  }

  /// Valor monetário médio - Para valores em cards
  static TextStyle currencyMedium(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: ResponsiveSizes.fontSize(
        context: context,
        base: 18,
        small: 16,
        large: 20,
      ),
      fontWeight: FontWeight.bold,
      color: color ?? AppColors.cinzaEscuro,
      height: 1.3,
    );
  }

  /// Valor monetário pequeno - Para mini cards
  static TextStyle currencySmall(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: ResponsiveSizes.fontSize(
        context: context,
        base: 14,
        small: 12,
        large: 16,
      ),
      fontWeight: FontWeight.bold,
      color: color ?? AppColors.cinzaEscuro,
      height: 1.2,
    );
  }

  // === LABELS E LEGENDAS ===

  /// Label principal - Para rótulos importantes
  static TextStyle label(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveSizes.fontSize(
        context: context,
        base: 12,
        small: 11,
        large: 13,
      ),
      fontWeight: FontWeight.w500,
      color: AppColors.cinzaTexto,
      height: 1.3,
    );
  }

  /// Caption - Para textos muito pequenos e informativos
  static TextStyle caption(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveSizes.fontSize(
        context: context,
        base: 10,
        small: 9,
        large: 11,
      ),
      fontWeight: FontWeight.normal,
      color: AppColors.cinzaTexto,
      height: 1.2,
    );
  }

  // === ESTILOS ESPECÍFICOS PARA BOTÕES DE AÇÃO ===

  /// Texto de botão de ação - mesmo padrão do AppBar
  static TextStyle actionButton(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveSizes.fontSizeForCards(
        context: context,
        base: 14,
        small: 12,
        large: 15,
      ),
      fontWeight: FontWeight.w600,
      color: Colors.white,
      height: 1.2,
    );
  }

  /// Texto de botão secundário/outline - mesmo padrão do AppBar
  static TextStyle actionButtonSecondary(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveSizes.fontSizeForCards(
        context: context,
        base: 14,
        small: 12,
        large: 15,
      ),
      fontWeight: FontWeight.w600,
      color: AppColors.tealPrimary,
      height: 1.2,
    );
  }

  // === BOTÕES ===

  /// Texto de botão principal
  static TextStyle button(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveSizes.fontSize(
        context: context,
        base: 16,
        small: 15,
        large: 17,
      ),
      fontWeight: FontWeight.w600,
      color: Colors.white,
      height: 1.2,
    );
  }

  /// Texto de botão secundário
  static TextStyle buttonSecondary(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveSizes.fontSize(
        context: context,
        base: 14,
        small: 13,
        large: 15,
      ),
      fontWeight: FontWeight.w500,
      color: AppColors.tealPrimary,
      height: 1.2,
    );
  }

  // === VARIAÇÕES DE COR ===

  /// Extensão para cores de sucesso (verde)
  static TextStyle success(BuildContext context, TextStyle baseStyle) {
    return baseStyle.copyWith(color: Colors.green[600]);
  }

  /// Extensão para cores de erro (vermelho)
  static TextStyle error(BuildContext context, TextStyle baseStyle) {
    return baseStyle.copyWith(color: Colors.red[600]);
  }

  /// Extensão para cores de aviso (laranja)
  static TextStyle warning(BuildContext context, TextStyle baseStyle) {
    return baseStyle.copyWith(color: Colors.orange[600]);
  }

  /// Extensão para cor primária
  static TextStyle primary(BuildContext context, TextStyle baseStyle) {
    return baseStyle.copyWith(color: AppColors.tealPrimary);
  }

  /// Extensão para texto em superfície escura
  static TextStyle onDark(BuildContext context, TextStyle baseStyle) {
    return baseStyle.copyWith(color: Colors.white);
  }

  /// Extensão para texto semi-transparente em superfície escura
  static TextStyle onDarkSecondary(BuildContext context, TextStyle baseStyle) {
    return baseStyle.copyWith(color: Colors.white.withValues(alpha: 0.8));
  }

  // === ESTILOS ESPECÍFICOS PARA APPBAR ===

  /// Título do AppBar - com escala controlada
  static TextStyle appBarTitle(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveSizes.fontSizeForCards(
        context: context,
        base: 18,
        small: 16,
        large: 20,
      ),
      fontWeight: FontWeight.w600,
      color: Colors.white,
      height: 1.2,
    );
  }

  /// Subtítulo do AppBar - com escala controlada
  static TextStyle appBarSubtitle(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveSizes.fontSizeForCards(
        context: context,
        base: 12,
        small: 11,
        large: 13,
      ),
      fontWeight: FontWeight.normal,
      color: Colors.white.withValues(alpha: 0.9),
      height: 1.2,
    );
  }

  // === ESTILOS ESPECÍFICOS PARA CARDS ===

  /// Texto de nome em cards - com escala controlada para evitar distorção
  static TextStyle cardTitle(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveSizes.fontSizeForCards(
        context: context,
        base: 13,
        small: 12,
        large: 14,
      ),
      fontWeight: FontWeight.w600,
      color: AppColors.cinzaEscuro,
      height: 1.3,
    );
  }

  /// Valor monetário em cards - com escala controlada (mesmo tamanho do título)
  static TextStyle cardCurrency(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: ResponsiveSizes.fontSizeForCards(
        context: context,
        base: 13,
        small: 12,
        large: 14,
      ),
      fontWeight: FontWeight.bold,
      color: color ?? AppColors.cinzaEscuro,
      height: 1.2,
    );
  }

  /// Texto secundário em cards - com escala controlada
  static TextStyle cardSecondary(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveSizes.fontSizeForCards(
        context: context,
        base: 10,
        small: 9,
        large: 11,
      ),
      fontWeight: FontWeight.normal,
      color: AppColors.cinzaTexto,
      height: 1.2,
    );
  }

  // === HELPERS DE FORMATAÇÃO ===

  /// Aplica negrito ao estilo
  static TextStyle bold(TextStyle style) {
    return style.copyWith(fontWeight: FontWeight.bold);
  }

  /// Aplica semi-negrito ao estilo
  static TextStyle semiBold(TextStyle style) {
    return style.copyWith(fontWeight: FontWeight.w600);
  }

  /// Aplica itálico ao estilo
  static TextStyle italic(TextStyle style) {
    return style.copyWith(fontStyle: FontStyle.italic);
  }

  /// Aplica sublinhado ao estilo
  static TextStyle underline(TextStyle style) {
    return style.copyWith(decoration: TextDecoration.underline);
  }
}