// lib/shared/theme/app_colors.dart
import 'package:flutter/material.dart';

/// Sistema de cores do iPoupei baseado no design system
/// Versão atualizada sem withOpacity() para melhor performance
class AppColors {
  // Cores Principais
  static const Color tealPrimary = Color(0xFF008080);
  static const Color tealEscuro = Color(0xFF006666);
  static const Color tealClaro = Color(0x1A008080); // rgba(0, 128, 128, 0.1)

  // Cores Secundárias
  static const Color azul = Color(0xFF0043C0);
  static const Color verdeSucesso = Color(0xFF006400);
  static const Color roxoPrimario = Color(0xFF673AB7);
  
  // Background
  static const Color backgroundPrimary = Color(0xFFF5F7FA);

  // Cores de Estado
  static const Color vermelhoErro = Color(0xFFDC3545);
  static const Color amareloAlerta = Color(0xFFFFC107);

  // Verde Sucesso
  static const Color verdeSucesso10 = Color(0x1A006400); // 10% transparência
  static const Color verdeSucesso20 = Color(0x33006400); // 20% transparência
  static const Color verdeSucesso30 = Color(0x4D006400); // 30% transparência
  static const Color verdeSucesso50 = Color(0x80006400); // 50% transparência
  static const Color verdeSucesso70 = Color(0xB3006400); // 70% transparência

  // Vermelho Erro
  static const Color vermelhoErro10 = Color(0x1ADC3545); // 10% transparência
  static const Color vermelhoErro20 = Color(0x33DC3545); // 20% transparência
  static const Color vermelhoErro30 = Color(0x4DDC3545); // 30% transparência
  static const Color vermelhoErro50 = Color(0x80DC3545); // 50% transparência
  static const Color vermelhoErro70 = Color(0xB3DC3545); // 70% transparência

  // Amarelo Alerta
  static const Color amareloAlerta10 = Color(0x1AFFC107); // 10% transparência
  static const Color amareloAlerta20 = Color(0x33FFC107); // 20% transparência
  static const Color amareloAlerta30 = Color(0x4DFFC107); // 30% transparência
  static const Color amareloAlerta50 = Color(0x80FFC107); // 50% transparência
  static const Color amareloAlerta70 = Color(0xB3FFC107); // 70% transparência

// ===== CORES CONTEXTUAIS PARA HEADERS =====
  static const Color vermelhoHeader = Color(0xFFDC3545);
  static const Color azulHeader = Color(0xFF1565C0);       // Contas
  static const Color roxoHeader = Color(0xFF673AB7);       // Cartões

  // Cores Neutras
  static const Color branco = Color(0xFFFFFFFF);
  static const Color cinzaClaro = Color(0xFFF5F7FA);
  static const Color cinzaMedio = Color(0xFF6C757D);
  static const Color cinzaEscuro = Color(0xFF333333);
  static const Color cinzaTexto = Color(0xFF666666);
  static const Color cinzaLegenda = Color(0xFF999999);
  static const Color cinzaBorda = Color(0xFFE0E0E0);

  // Cores Neutras - 10% Transparência
  static const Color brancoTransparente10 = Color(0x1AFFFFFF);
  static const Color cinzaClaroTransparente10 = Color(0x1AF5F7FA);
  static const Color cinzaMedioTransparente10 = Color(0x1A6C757D);
  static const Color cinzaEscuroTransparente10 = Color(0x1A333333);
  static const Color cinzaTextoTransparente10 = Color(0x1A666666);
  static const Color cinzaLegendaTransparente10 = Color(0x1A999999);
  static const Color cinzaBordaTransparente10 = Color(0x1AE0E0E0);

  // Cores Neutras - 20% Transparência
  static const Color brancoTransparente20 = Color(0x33FFFFFF);
  static const Color cinzaClaroTransparente20 = Color(0x33F5F7FA);
  static const Color cinzaMedioTransparente20 = Color(0x336C757D);
  static const Color cinzaEscuroTransparente20 = Color(0x33333333);
  static const Color cinzaTextoTransparente20 = Color(0x33666666);
  static const Color cinzaLegendaTransparente20 = Color(0x33999999);
  static const Color cinzaBordaTransparente20 = Color(0x33E0E0E0);

  // Cores Neutras - 30% Transparência
  static const Color brancoTransparente30 = Color(0x4DFFFFFF);
  static const Color cinzaClaroTransparente30 = Color(0x4DF5F7FA);
  static const Color cinzaMedioTransparente30 = Color(0x4D6C757D);
  static const Color cinzaEscuroTransparente30 = Color(0x4D333333);
  static const Color cinzaTextoTransparente30 = Color(0x4D666666);
  static const Color cinzaLegendaTransparente30 = Color(0x4D999999);
  static const Color cinzaBordaTransparente30 = Color(0x4DE0E0E0);

  // Cores Neutras - 50% Transparência
  static const Color brancoTransparente50 = Color(0x80FFFFFF);
  static const Color cinzaClaroTransparente50 = Color(0x80F5F7FA);
  static const Color cinzaMedioTransparente50 = Color(0x806C757D);
  static const Color cinzaEscuroTransparente50 = Color(0x80333333);
  static const Color cinzaTextoTransparente50 = Color(0x80666666);
  static const Color cinzaLegendaTransparente50 = Color(0x80999999);
  static const Color cinzaBordaTransparente50 = Color(0x80E0E0E0);

  

  // ===== TRANSPARÊNCIAS PRÉ-CALCULADAS (performance otimizada) =====
  
  // Teal com transparências (para headers e outros)
  static const Color tealTransparente10 = Color(0x1A008080); // 10% - backgrounds sutis
  static const Color tealTransparente20 = Color(0x33008080); // 20% - hover states
  static const Color tealTransparente50 = Color(0x80008080); // 50% - overlays
  

  // ===== TRANSPARÊNCIAS PRÉ-CALCULADAS PARA HEADERS =====

  // Vermelho com transparências (para despesas)
  static const Color vermelhoTransparente10 = Color(0x1ADC3545); // 10%
  static const Color vermelhoTransparente20 = Color(0x33DC3545); // 20%
  static const Color vermelhoTransparente50 = Color(0x80DC3545); // 50%

  // Azul com transparências (para contas)
  static const Color azulTransparente10 = Color(0x1A1565C0); // 10%
  static const Color azulTransparente20 = Color(0x331565C0); // 20%
  static const Color azulTransparente50 = Color(0x801565C0); // 50%

  // Roxo com transparências (para cartões)
  static const Color roxoTransparente10 = Color(0x1A673AB7); // 10%
  static const Color roxoTransparente20 = Color(0x33673AB7); // 20%
  static const Color roxoTransparente50 = Color(0x80673AB7); // 50%

  // Preto com transparências (para sombras)
  static const Color sombraSutil = Color(0x1A000000);       // 10% - cards normais
  static const Color sombraMedia = Color(0x33000000);       // 20% - cards elevados
  static const Color sombraForte = Color(0x4D000000);       // 30% - modals
  
  // Âmbar para conta principal
  static const Color ambarTransparente10 = Color(0x1AFFC107); // 10% - background badge
  static const Color ambarTransparente30 = Color(0x4DFFC107); // 30% - sombra dourada

  // ===== GRADIENTES PARA CARDS DO DASHBOARD =====
  
  // Gradientes LinearGradient (para uso em containers)
  static const LinearGradient gradientSaldo = LinearGradient(
    colors: [verdeSucesso, Color(0xFF2E7D32)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientReceitas = LinearGradient(
    colors: [azul, Color(0xFF1565C0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientDespesas = LinearGradient(
    colors: [vermelhoErro, Color(0xFFC62828)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientCartao = LinearGradient(
    colors: [Color(0xFF7B1FA2), Color(0xFF4A148C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ===== ALIASES PARA COMPATIBILIDADE COM HOME_PAGE =====
  // Lista de cores para uso em widgets que esperam List<Color>
  static const List<Color> greenGradient = [verdeSucesso, Color(0xFF2E7D32)];
  static const List<Color> blueGradient = [azul, Color(0xFF1565C0)];
  static const List<Color> redGradient = [vermelhoErro, Color(0xFFC62828)];
  static const List<Color> purpleGradient = [Color(0xFF7B1FA2), Color(0xFF4A148C)];

  // Métodos auxiliares
  static Color getValueColor(double value) {
    if (value > 0) return verdeSucesso;
    if (value < 0) return vermelhoErro;
    return cinzaTexto;
  }

  static LinearGradient getCardGradient(String type) {
    switch (type.toLowerCase()) {
      case 'saldo':
        return gradientSaldo;
      case 'receitas':
        return gradientReceitas;
      case 'despesas':
        return gradientDespesas;
      case 'cartao':
        return gradientCartao;
      default:
        return const LinearGradient(
          colors: [cinzaMedio, cinzaEscuro],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  // ===== SOMBRAS PRÉ-DEFINIDAS =====
  static const List<BoxShadow> cardSuave = [
    BoxShadow(
      color: sombraSutil,
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> cardDestaque = [
    BoxShadow(
      color: ambarTransparente30,
      blurRadius: 12,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> cardNormal = [
    BoxShadow(
      color: sombraMedia,
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
}