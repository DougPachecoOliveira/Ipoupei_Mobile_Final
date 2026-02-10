# 🏗️ Arquitetura do Sistema de Extractors Bancários - iPoupei

**Versão:** 2.0  
**Data:** 03/11/2025  
**Propósito:** Documentação completa para implementação de extractors específicos por banco

---

## 📋 Índice

1. [Visão Geral](#visão-geral)
2. [Problema Atual](#problema-atual)
3. [Solução Proposta](#solução-proposta)
4. [Arquitetura de Código](#arquitetura-de-código)
5. [Padrões de Design](#padrões-de-design)
6. [Estrutura de Pastas](#estrutura-de-pastas)
7. [Interfaces e Contratos](#interfaces-e-contratos)
8. [Implementação dos Extractors](#implementação-dos-extractors)
9. [Integração com Sistema Existente](#integração-com-sistema-existente)
10. [Roadmap de Implementação](#roadmap-de-implementação)

---

## 1. Visão Geral

### 🎯 Objetivo

Criar um sistema extensível e robusto para importação de extratos bancários de diferentes bancos brasileiros, onde cada banco tem seu próprio extractor especializado.

### 🏆 Benefícios

- ✅ **Precisão**: Cada banco tem parsing específico para seu formato
- ✅ **Manutenibilidade**: Código isolado por banco
- ✅ **Extensibilidade**: Fácil adicionar novos bancos
- ✅ **Testabilidade**: Testes específicos por banco
- ✅ **Robustez**: Tratamento de erros específico

---

## 2. Problema Atual

### ❌ Código Genérico Atual

O sistema atual tenta processar todos os bancos com um único código genérico em `ImportacaoService`:

```dart
// Código atual tenta adivinhar a estrutura
Future<List<TransacaoImportada>> processarArquivoCSV(File file) async {
  final lines = await file.readAsLines();
  
  // ❌ Tenta detectar colunas automaticamente
  int dataCol = -1;
  int descricaoCol = -1;
  int valorCol = -1;
  
  // ❌ Não funciona para formatos complexos
  // ❌ Falha com múltiplas colunas de valor
  // ❌ Não trata casos especiais por banco
}
```

### 🔴 Problemas Identificados

1. **Detecção Automática Falha**
   - Bradesco tem 2 colunas de valor (Crédito/Débito)
   - Sistema detecta apenas 1 coluna
   - Pega coluna errada (saldo ao invés de valor)

2. **Sem Regras Específicas**
   - Não ignora "SALDO ANTERIOR" do Bradesco
   - Não detecta início/fim de dados
   - Não extrai metadados do header (agência/conta)

3. **Parse Frágil**
   - Falha com valores vazios
   - Não remove BOM (Byte Order Mark)
   - Confunde formatos de data/valor

4. **Implementação Incompleta**
   - Referencia métodos que não existem (`_parseBradescoValues`)
   - Fallbacks quebrados
   - Tratamento de erro inadequado

---

## 3. Solução Proposta

### ✅ Sistema de Extractors Específicos

Implementar padrão **Strategy + Factory** onde:

1. **Interface comum**: `BankExtractor`
2. **Factory**: `ExtractorFactory` detecta banco e retorna extractor correto
3. **Extractors específicos**: Um por banco (Bradesco, Nubank, Itaú, etc)
4. **Fallback genérico**: `GenericExtractor` para formatos simples

### 📐 Diagrama de Fluxo

```
Arquivo CSV
    ↓
ImportacaoService.processarArquivoCSV()
    ↓
ExtractorFactory.detectBankAndCreate(fileName, content)
    ↓
    ├─> BradescoExtractor (se detectar Bradesco)
    ├─> NubankExtractor (se detectar Nubank)
    ├─> ItauExtractor (se detectar Itaú)
    └─> GenericExtractor (fallback)
    ↓
extractor.extract(content)
    ↓
List<TransacaoImportada>
    ↓
Preview e Importação
```

---

## 4. Arquitetura de Código

### 🗂️ Estrutura de Pastas

```
lib/src/modules/importacao/
├── services/
│   ├── importacao_service.dart          # Service principal (JÁ EXISTE)
│   └── extractors/                       # 🆕 NOVA PASTA
│       ├── bank_extractor.dart          # Interface base
│       ├── extractor_factory.dart       # Factory pattern
│       ├── generic_extractor.dart       # Fallback genérico
│       └── banks/                        # Extractors por banco
│           ├── bradesco_extractor.dart
│           ├── nubank_extractor.dart
│           ├── itau_extractor.dart
│           ├── santander_extractor.dart
│           └── bb_extractor.dart
├── models/
│   └── transacao_importada_model.dart   # JÁ EXISTE
└── data/
    └── categoria_keywords_mapping.dart   # JÁ EXISTE
```

---

## 5. Padrões de Design

### 🎨 Strategy Pattern

Cada banco é uma estratégia diferente de parsing:

```dart
// Interface comum
abstract class BankExtractor {
  Future<List<TransacaoImportada>> extract(String content);
  bool canHandle(String fileName, String content);
  String get bankName;
}

// Implementações específicas
class BradescoExtractor implements BankExtractor { ... }
class NubankExtractor implements BankExtractor { ... }
```

### 🏭 Factory Pattern

Factory decide qual extractor usar:

```dart
class ExtractorFactory {
  static BankExtractor createExtractor(String fileName, String content) {
    if (BradescoExtractor().canHandle(fileName, content)) {
      return BradescoExtractor();
    }
    if (NubankExtractor().canHandle(fileName, content)) {
      return NubankExtractor();
    }
    // ... outros bancos
    
    return GenericExtractor(); // Fallback
  }
}
```

---

## 6. Interfaces e Contratos

### 📜 Interface: BankExtractor

```dart
/// Interface base para todos os extractors bancários
abstract class BankExtractor {
  /// Nome do banco (ex: "Bradesco", "Nubank")
  String get bankName;
  
  /// Verifica se este extractor pode processar o arquivo
  bool canHandle(String fileName, String content);
  
  /// Extrai transações do conteúdo do arquivo
  Future<List<TransacaoImportada>> extract(
    String content, {
    required String tipoImportacao,
    String? contaId,
    String? cartaoId,
    DateTime? faturaVencimento,
  });
  
  /// Valida se o arquivo está no formato esperado
  bool validateFormat(String content);
  
  /// Extrai metadados específicos do banco (opcional)
  Map<String, dynamic>? extractMetadata(String content) => null;
}
```

### 🔍 Contrato de Detecção

Cada extractor deve implementar `canHandle()` que verifica:

1. **Nome do arquivo** contém identificador do banco
2. **Conteúdo** tem padrões específicos do banco
3. **Estrutura** corresponde ao formato esperado

Exemplo:
```dart
@override
bool canHandle(String fileName, String content) {
  final lowerFileName = fileName.toLowerCase();
  final lowerContent = content.toLowerCase();
  
  // Verificar nome do arquivo
  if (lowerFileName.contains('bradesco') || 
      lowerFileName.contains('extrato_cc')) {
    return true;
  }
  
  // Verificar padrões no conteúdo
  if (lowerContent.contains('ag:') && 
      lowerContent.contains('conta:') &&
      lowerContent.contains('data;histórico;documento')) {
    return true;
  }
  
  return false;
}
```

---

## 7. Implementação dos Extractors

### 🏦 Bradesco Extractor (Completo)

```dart
/// Extractor específico para extratos CSV do Bradesco
class BradescoExtractor implements BankExtractor {
  @override
  String get bankName => 'Bradesco';
  
  // Índices das colunas no CSV Bradesco
  static const int _colData = 0;        // Data
  static const int _colHistorico = 1;   // Histórico (descrição)
  static const int _colDocumento = 2;   // Número do documento
  static const int _colCredito = 3;     // Valor de crédito
  static const int _colDebito = 4;      // Valor de débito
  static const int _colSaldo = 5;       // Saldo após transação
  
  @override
  bool canHandle(String fileName, String content) {
    final lowerFileName = fileName.toLowerCase();
    final lowerContent = content.toLowerCase();
    
    // Verificar nome do arquivo
    if (lowerFileName.contains('bradesco') || 
        lowerFileName.contains('extrato_cc')) {
      return true;
    }
    
    // Verificar padrões específicos do Bradesco
    if (lowerContent.contains('ag:') && 
        lowerContent.contains('conta:') &&
        lowerContent.contains('data;histórico;documento')) {
      return true;
    }
    
    return false;
  }
  
  @override
  bool validateFormat(String content) {
    final lines = content.split('\n');
    
    if (lines.length < 3) return false;
    
    // Linha 1 deve ter agência e conta
    if (!lines[0].contains('Ag:') || !lines[0].contains('Conta:')) {
      return false;
    }
    
    // Linha 2 deve ser o header
    final header = lines[1].toLowerCase();
    if (!header.contains('data') || !header.contains('histórico')) {
      return false;
    }
    
    return true;
  }
  
  @override
  Map<String, dynamic>? extractMetadata(String content) {
    final lines = content.split('\n');
    if (lines.isEmpty) return null;
    
    final firstLine = lines[0];
    
    // Extrair agência e conta da primeira linha
    // Formato: "Ag: XXXX  Conta: XXXXXX-X"
    final agenciaMatch = RegExp(r'Ag:\s*(\d+)').firstMatch(firstLine);
    final contaMatch = RegExp(r'Conta:\s*([\d-]+)').firstMatch(firstLine);
    
    return {
      'banco': 'Bradesco',
      'agencia': agenciaMatch?.group(1),
      'conta': contaMatch?.group(1),
    };
  }
  
  @override
  Future<List<TransacaoImportada>> extract(
    String content, {
    required String tipoImportacao,
    String? contaId,
    String? cartaoId,
    DateTime? faturaVencimento,
  }) async {
    if (!validateFormat(content)) {
      throw Exception('Formato inválido para Bradesco');
    }
    
    final transacoes = <TransacaoImportada>[];
    final lines = content.split('\n');
    final userId = AuthIntegration.instance.authService.currentUser?.id ?? '';
    final metadata = extractMetadata(content);
    
    // Começar da linha 2 (pular header)
    // Terminar quando encontrar o rodapé
    for (int i = 2; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // Parar no rodapé
      if (_isFooterLine(line)) {
        log('🛑 Rodapé detectado na linha $i');
        break;
      }
      
      // Pular linhas vazias
      if (line.isEmpty) continue;
      
      final transacao = _extractTransaction(
        line, 
        i,
        userId,
        contaId,
        cartaoId,
        faturaVencimento,
        metadata,
      );
      
      if (transacao != null) {
        transacoes.add(transacao);
      }
    }
    
    log('✅ Bradesco: ${transacoes.length} transações extraídas');
    return transacoes;
  }
  
  /// Verifica se a linha é parte do rodapé
  bool _isFooterLine(String line) {
    final lowerLine = line.toLowerCase();
    return lowerLine.contains('total do período') ||
           lowerLine.contains('s a l d o s') ||
           lowerLine.contains('período') ||
           line.startsWith('___') ||
           line.startsWith('===');
  }
  
  /// Extrai uma transação de uma linha
  TransacaoImportada? _extractTransaction(
    String line,
    int index,
    String userId,
    String? contaId,
    String? cartaoId,
    DateTime? faturaVencimento,
    Map<String, dynamic>? metadata,
  ) {
    try {
      // Remove BOM se presente
      String cleanLine = line;
      if (cleanLine.codeUnitAt(0) == 0xFEFF) {
        cleanLine = cleanLine.substring(1);
      }
      
      // Split por ponto-e-vírgula
      final parts = cleanLine.split(';');
      
      if (parts.length < 6) {
        log('⚠️ Linha $index tem menos de 6 colunas: ${parts.length}');
        return null;
      }
      
      // Extrair dados das colunas fixas
      final dataStr = parts[_colData].trim();
      final historico = parts[_colHistorico].trim();
      final documento = parts[_colDocumento].trim();
      final creditoStr = parts[_colCredito].trim();
      final debitoStr = parts[_colDebito].trim();
      final saldoStr = parts[_colSaldo].trim();
      
      // Ignorar "SALDO ANTERIOR"
      if (historico.toUpperCase().contains('SALDO ANTERIOR')) {
        log('⏭️ Ignorando SALDO ANTERIOR');
        return null;
      }
      
      // Parse de data
      final data = _parseDate(dataStr);
      if (data == null) {
        log('⚠️ Linha $index: data inválida "$dataStr"');
        return null;
      }
      
      // Determinar valor e tipo baseado em crédito/débito
      double valor = 0.0;
      String tipo = 'despesa';
      
      if (creditoStr.isNotEmpty && creditoStr != '0,00') {
        valor = _parseValue(creditoStr);
        tipo = 'receita';
      } else if (debitoStr.isNotEmpty && debitoStr != '0,00') {
        valor = _parseValue(debitoStr);
        tipo = 'despesa';
      } else {
        log('⚠️ Linha $index: sem valor de crédito ou débito');
        return null;
      }
      
      return TransacaoImportada(
        id: 'bradesco_${DateTime.now().millisecondsSinceEpoch}_$index',
        data: data,
        descricao: historico,
        valor: valor,
        tipo: tipo,
        origem: 'Bradesco',
        usuarioId: userId,
        contaId: contaId,
        cartaoId: cartaoId,
        faturaVencimento: faturaVencimento,
        efetivado: false,
        observacoes: documento.isNotEmpty ? 'Doc: $documento' : '',
        linhaBruta: line,
        indiceOriginal: index,
        metadados: {
          ...?metadata,
          'documento': documento,
          'saldo_apos': saldoStr,
          'linha': index,
        },
      );
      
    } catch (e) {
      log('❌ Erro ao processar linha $index: $e');
      return null;
    }
  }
  
  /// Parse de data no formato brasileiro DD/MM/YYYY
  DateTime? _parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    
    try {
      // Formato esperado: DD/MM/YYYY
      final parts = dateStr.split('/');
      if (parts.length != 3) return null;
      
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      
      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }
  
  /// Parse de valor monetário brasileiro (1.234,56)
  double _parseValue(String valueStr) {
    if (valueStr.isEmpty) return 0.0;
    
    try {
      // Remove espaços e BOM
      String cleaned = valueStr.trim();
      if (cleaned.isNotEmpty && cleaned.codeUnitAt(0) == 0xFEFF) {
        cleaned = cleaned.substring(1);
      }
      
      // Remove pontos (separador de milhar) e substitui vírgula por ponto
      cleaned = cleaned
          .replaceAll('.', '')
          .replaceAll(',', '.');
      
      return double.parse(cleaned);
    } catch (e) {
      return 0.0;
    }
  }
}
```

---

## 8. Integração com Sistema Existente

### 🔧 Modificações no ImportacaoService

**Mudanças mínimas** no código existente:

```dart
// lib/src/modules/importacao/services/importacao_service.dart

import 'extractors/extractor_factory.dart';
import 'extractors/bank_extractor.dart';

class ImportacaoService {
  // ... código existente ...
  
  /// Processa arquivo CSV/TXT e retorna lista de transações
  Future<List<TransacaoImportada>> processarArquivoCSV(
    File file, {
    required String tipoImportacao,
    String? contaId,
    String? cartaoId,
    DateTime? faturaVencimento,
  }) async {
    try {
      log('🚀 INICIANDO PROCESSAMENTO CSV: ${file.path}');
      
      final content = await file.readAsString();
      final fileName = file.path.split('/').last;
      
      // 🆕 USAR FACTORY PARA DETECTAR E CRIAR EXTRACTOR
      final extractor = ExtractorFactory.createExtractor(fileName, content);
      
      log('📊 Usando extractor: ${extractor.bankName}');
      
      // 🆕 USAR EXTRACTOR ESPECÍFICO
      final transacoes = await extractor.extract(
        content,
        tipoImportacao: tipoImportacao,
        contaId: contaId,
        cartaoId: cartaoId,
        faturaVencimento: faturaVencimento,
      );
      
      log('✅ Processamento concluído: ${transacoes.length} transações');
      return transacoes;
      
    } catch (e) {
      log('❌ Erro no processamento CSV: $e');
      rethrow;
    }
  }
  
  // ... resto do código existente permanece igual ...
}
```

### ✅ Sem Quebrar Código Existente

- ✅ Mantém assinatura dos métodos
- ✅ Mantém modelos existentes
- ✅ Mantém integração com TransacaoService
- ✅ Mantém fluxo de preview/importação
- ✅ Apenas adiciona nova camada de extractors

---

## 9. Roadmap de Implementação

### 📅 Fase 1: Fundação (Prioridade ALTA)

**Objetivo:** Criar estrutura base e Bradesco funcionando

1. ✅ Criar pasta `lib/src/modules/importacao/services/extractors/`
2. ✅ Criar interface `BankExtractor`
3. ✅ Criar `ExtractorFactory`
4. ✅ Implementar `BradescoExtractor` completo
5. ✅ Criar `GenericExtractor` (fallback)
6. ✅ Integrar com `ImportacaoService`
7. ✅ Testar com arquivo real do Bradesco

### 📅 Fase 2: Outros Bancos (Prioridade MÉDIA)

**Objetivo:** Adicionar suporte aos bancos mais comuns

8. ⏳ Implementar `NubankExtractor`
9. ⏳ Implementar `ItauExtractor`
10. ⏳ Implementar `SantanderExtractor`
11. ⏳ Implementar `BBExtractor`
12. ⏳ Testar cada extractor com arquivos reais

### 📅 Fase 3: Melhorias (Prioridade BAIXA)

**Objetivo:** Polir e otimizar

13. ⏳ Adicionar testes unitários
14. ⏳ Melhorar detecção automática
15. ⏳ Adicionar métricas e logs
16. ⏳ Documentar formatos de cada banco

---

## 10. Guia: Como Adicionar um Novo Banco

### 📝 Template para Novo Extractor

```dart
/// Extractor para [NOME DO BANCO]
class [Banco]Extractor implements BankExtractor {
  @override
  String get bankName => '[Nome do Banco]';
  
  @override
  bool canHandle(String fileName, String content) {
    // TODO: Implementar detecção específica
    final lowerFileName = fileName.toLowerCase();
    final lowerContent = content.toLowerCase();
    
    // Verificar nome do arquivo
    if (lowerFileName.contains('[banco]')) {
      return true;
    }
    
    // Verificar padrões no conteúdo
    if (lowerContent.contains('[padrão específico]')) {
      return true;
    }
    
    return false;
  }
  
  @override
  bool validateFormat(String content) {
    // TODO: Validar estrutura do arquivo
    return true;
  }
  
  @override
  Map<String, dynamic>? extractMetadata(String content) {
    // TODO: Extrair metadados específicos do banco
    return {
      'banco': '[Nome do Banco]',
      // ... outros metadados
    };
  }
  
  @override
  Future<List<TransacaoImportada>> extract(
    String content, {
    required String tipoImportacao,
    String? contaId,
    String? cartaoId,
    DateTime? faturaVencimento,
  }) async {
    // TODO: Implementar extração específica
    final transacoes = <TransacaoImportada>[];
    
    // Seu código de parsing aqui...
    
    return transacoes;
  }
}
```

### 🔧 Passos para Adicionar

1. **Criar arquivo** em `extractors/banks/[banco]_extractor.dart`
2. **Implementar interface** `BankExtractor`
3. **Adicionar detecção** no `ExtractorFactory`
4. **Testar com arquivo real**
5. **Documentar formato** do banco

---

## 📚 Recursos Adicionais

### 📖 Documentos Relacionados

- `02_FLUXO_IMPORTACAO_BRADESCO.md` - Análise detalhada do fluxo Bradesco
- `03_COMPARACAO_GENERICO_VS_BRADESCO.md` - Por que extractors específicos
- `04_TEMPLATE_ITAU_FATURA.md` - Como implementar extractor para Itaú

### 🧪 Testes

Criar testes unitários para cada extractor:

```dart
// test/extractors/bradesco_extractor_test.dart

void main() {
  group('BradescoExtractor', () {
    late BradescoExtractor extractor;
    
    setUp(() {
      extractor = BradescoExtractor();
    });
    
    test('deve detectar arquivo Bradesco pelo nome', () {
      expect(
        extractor.canHandle('extrato_Bradesco.csv', ''),
        isTrue,
      );
    });
    
    test('deve extrair 39 transações do arquivo de exemplo', () async {
      final content = await loadFixture('bradesco_exemplo.csv');
      final transacoes = await extractor.extract(
        content,
        tipoImportacao: 'conta_corrente',
      );
      
      expect(transacoes.length, 39);
      expect(transacoes.where((t) => t.tipo == 'receita').length, 7);
      expect(transacoes.where((t) => t.tipo == 'despesa').length, 32);
    });
    
    // ... mais testes
  });
}
```

---

**FIM DO DOCUMENTO**

Esta é a arquitetura completa do sistema de extractors. Use este documento como referência principal para implementação.