// 📱 Sistema de Responsividade - iPoupei Mobile
//
// Sistema centralizado para gerenciar tamanhos responsivos
// Fornece consistência entre diferentes tamanhos de tela
//
// Baseado em: Material Design Guidelines + Padrões de Apps Profissionais

import 'package:flutter/material.dart';

class ResponsiveSizes {
  // === BREAKPOINTS ===
  /// Telas mobile pequenas (iPhone SE, Android compactos)
  static const double mobileSmall = 360.0;

  /// Telas mobile médias (padrão de design)
  static const double mobileMedium = 375.0;

  /// Telas mobile grandes (iPhone Plus, Android grandes)
  static const double mobileLarge = 414.0;

  /// Tablets e dispositivos maiores
  static const double tablet = 768.0;

  // === SISTEMA DE FONTES RESPONSIVAS ===

  /// Calcula tamanho de fonte responsivo baseado na largura da tela
  ///
  /// [base] - Tamanho padrão para mobile médio (375px)
  /// [small] - Tamanho para telas pequenas (opcional, default: base - 2)
  /// [large] - Tamanho para tablets (opcional, default: base + 2)
  /// [extraLarge] - Tamanho para telas muito grandes (opcional, default: base + 4)
  static double fontSize({
    required BuildContext context,
    required double base,
    double? small,
    double? large,
    double? extraLarge,
    bool respectSystemScale = true,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    double fontSize;

    // Determina tamanho base por breakpoint
    if (screenWidth < mobileSmall) {
      fontSize = small ?? (base - 2);
    } else if (screenWidth < mobileLarge) {
      fontSize = base;
    } else if (screenWidth < tablet) {
      fontSize = large ?? (base + 2);
    } else {
      fontSize = extraLarge ?? large ?? (base + 4);
    }

    // Aplica scale factor do sistema se habilitado (com limite para evitar distorção)
    if (respectSystemScale) {
      final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);
      // Limita o scale factor para evitar distorção excessiva nos cards
      final limitedScaleFactor = textScaleFactor.clamp(0.8, 1.3);
      fontSize *= limitedScaleFactor;
    }

    return fontSize;
  }

  /// Calcula tamanho de fonte para cards com escala mais controlada
  /// Ideal para manter layout de cards estável mesmo com fontes grandes do sistema
  static double fontSizeForCards({
    required BuildContext context,
    required double base,
    double? small,
    double? large,
    double? extraLarge,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    double fontSize;

    // Determina tamanho base por breakpoint
    if (screenWidth < mobileSmall) {
      fontSize = small ?? (base - 2);
    } else if (screenWidth < mobileLarge) {
      fontSize = base;
    } else if (screenWidth < tablet) {
      fontSize = large ?? (base + 2);
    } else {
      fontSize = extraLarge ?? large ?? (base + 4);
    }

    // Aplica scale factor muito limitado para cards (máximo 8% de aumento)
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);
    final veryLimitedScaleFactor = textScaleFactor.clamp(0.95, 1.08);
    fontSize *= veryLimitedScaleFactor;

    return fontSize;
  }

  // === SISTEMA DE ESPAÇAMENTOS ===

  /// Calcula padding responsivo
  static EdgeInsets padding({
    required BuildContext context,
    required EdgeInsets base,
    EdgeInsets? compact,
    EdgeInsets? expanded,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < mobileSmall) {
      return compact ?? EdgeInsets.fromLTRB(
        base.left * 0.75,
        base.top * 0.75,
        base.right * 0.75,
        base.bottom * 0.75,
      );
    } else if (screenWidth >= tablet) {
      return expanded ?? EdgeInsets.fromLTRB(
        base.left * 1.5,
        base.top * 1.5,
        base.right * 1.5,
        base.bottom * 1.5,
      );
    }

    return base;
  }

  /// Calcula espaçamento entre elementos
  static double spacing({
    required BuildContext context,
    required double base,
    double? compact,
    double? expanded,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < mobileSmall) {
      return compact ?? (base * 0.75);
    } else if (screenWidth >= tablet) {
      return expanded ?? (base * 1.5);
    }

    return base;
  }

  // === DIMENSÕES ESPECÍFICAS PARA APPBAR ===

  /// Altura do AppBar responsiva
  static double appBarHeight(BuildContext context, {double base = 56}) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < mobileSmall) {
      return base * 0.9; // ~50px se base for 56
    } else if (screenWidth >= tablet) {
      return base * 1.1; // ~62px se base for 56
    }

    return base;
  }

  /// Tamanho de ícones do AppBar responsivo
  static double appBarIconSize(BuildContext context, {double base = 24}) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < mobileSmall) {
      return base * 0.85; // ~20px se base for 24
    } else if (screenWidth >= tablet) {
      return base * 1.2; // ~29px se base for 24
    }

    return base;
  }

  /// Padding do AppBar responsivo
  static EdgeInsets appBarPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < mobileSmall) {
      return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
    } else if (screenWidth >= tablet) {
      return const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
    }

    return const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
  }

  // === DIMENSÕES ESPECÍFICAS PARA BOTÕES DE AÇÃO ===

  /// Altura de botões de ação responsiva
  static double actionButtonHeight(BuildContext context, {double base = 48}) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < mobileSmall) {
      return base * 0.85; // ~41px se base for 48
    } else if (screenWidth >= tablet) {
      return base * 1.1; // ~53px se base for 48
    }

    return base;
  }

  /// Tamanho de ícones em botões de ação - mesmo padrão do AppBar
  static double actionButtonIconSize(BuildContext context, {double base = 21}) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < mobileSmall) {
      return base * 0.85; // ~18px se base for 21
    } else if (screenWidth >= tablet) {
      return base * 1.2; // ~25px se base for 21
    }

    return base;
  }

  /// Padding de botões de ação responsivo
  static EdgeInsets actionButtonPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < mobileSmall) {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
    } else if (screenWidth >= tablet) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 14);
    }

    return const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
  }

  // === DIMENSÕES ESPECÍFICAS DE COMPONENTES ===

  /// Altura de cards responsiva
  static double cardHeight(BuildContext context, {double base = 80}) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < mobileSmall) {
      return base * 0.875; // ~70px se base for 80
    } else if (screenWidth >= tablet) {
      return base * 1.175; // ~94px se base for 80
    }

    return base;
  }

  /// Largura de faixa lateral em cards
  static double cardSidebarWidth(BuildContext context, {double base = 44}) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < mobileSmall) {
      return base * 0.91; // ~40px se base for 44
    } else if (screenWidth >= tablet) {
      return base * 1.14; // ~50px se base for 44
    }

    return base;
  }

  /// Tamanho de ícones responsivo
  static double iconSize({
    required BuildContext context,
    required double base,
    double? small,
    double? large,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < mobileSmall) {
      return small ?? (base * 0.85);
    } else if (screenWidth >= tablet) {
      return large ?? (base * 1.25);
    }

    return base;
  }

  /// Container circular responsivo (para contadores, avatars, etc)
  static double circularContainer({
    required BuildContext context,
    required double base,
    double? small,
    double? large,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < mobileSmall) {
      return small ?? (base * 0.89); // ~32px se base for 36
    } else if (screenWidth >= tablet) {
      return large ?? (base * 1.11); // ~40px se base for 36
    }

    return base;
  }

  // === HELPERS ÚTEIS ===

  /// Verifica se a tela é considerada pequena
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileSmall;
  }

  /// Verifica se a tela é um tablet ou maior
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= tablet;
  }

  /// Retorna o breakpoint atual como string
  static String getCurrentBreakpoint(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < mobileSmall) return 'small';
    if (width < mobileLarge) return 'medium';
    if (width < tablet) return 'large';
    return 'tablet';
  }

  /// Calcula valor responsivo personalizado
  static T responsive<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
  }) {
    if (isTablet(context) && tablet != null) {
      return tablet;
    }
    return mobile;
  }
}