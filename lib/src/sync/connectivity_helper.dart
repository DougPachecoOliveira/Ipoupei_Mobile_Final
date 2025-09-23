// 🌐 Connectivity Helper - iPoupei Mobile
// 
// Helper para lidar com mudanças na API de conectividade
// Compatível com diferentes versões do connectivity_plus
// 
// Baseado em: Adapter pattern

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Helper para gerenciar conectividade de forma compatível
class ConnectivityHelper {
  static ConnectivityHelper? _instance;
  static ConnectivityHelper get instance {
    _instance ??= ConnectivityHelper._internal();
    return _instance!;
  }
  
  ConnectivityHelper._internal();
  
  /// 🌐 VERIFICA CONECTIVIDADE ATUAL
  Future<bool> isOnline() async {
    try {
      final results = await Connectivity().checkConnectivity();

      // Na versão 6.1.5+, sempre retorna List<ConnectivityResult>
      return results.any((result) => result != ConnectivityResult.none);

    } catch (e) {
      debugPrint('❌ Erro ao verificar conectividade: $e');
      return false; // Assume offline em caso de erro
    }
  }

  /// 🌐 ALIAS PARA COMPATIBILIDADE
  Future<bool> isConnected() async {
    return await isOnline();
  }
  
  /// 👂 ESCUTA MUDANÇAS DE CONECTIVIDADE
  Stream<bool> onConnectivityChanged() {
    return Connectivity().onConnectivityChanged.map((results) {
      try {
        // Na versão 6.1.5+, sempre retorna List<ConnectivityResult>
        return results.any((result) => result != ConnectivityResult.none);
        
      } catch (e) {
        debugPrint('❌ Erro ao processar mudança de conectividade: $e');
        return false; // Assume offline em caso de erro
      }
    });
  }
}