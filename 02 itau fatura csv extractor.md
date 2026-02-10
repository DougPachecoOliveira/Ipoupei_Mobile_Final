# 💳 Implementação: Importador de Fatura CSV Itaú

**Versão:** 1.0  
**Data:** 03/11/2025  
**Propósito:** Instruções para criar extractor de faturas de cartão de crédito Itaú em formato CSV

---

## 📋 Índice

1. [Análise do Arquivo](#análise-do-arquivo)
2. [Características Específicas](#características-específicas)
3. [Estrutura de Parcelamento](#estrutura-de-parcelamento)
4. [Implementação do Extractor](#implementação-do-extractor)
5. [Lógica de Parcelamento OFX](#lógica-de-parcelamento-ofx)
6. [Integração](#integração)

---

## 1. Análise do Arquivo

### 📄 Estrutura do CSV Itaú

```csv
Logotipo Itaú;;;
Atualização:;07/08/2025 às 08:09:42;;
Nome:;JANAINA CRISTINE COSTA;;
Agência:;5330 ;;
Conta:;08283-4;;
;;;
fatura de agosto;;;
;;;
fatura;você pagou 5.878,88 de;venc. da fatura;
fechada;5.878,88;01/08/2025;
;;;
lançamentos nacionais;;;
;;;
JANAINA CRISTINE COSTA - final 1055 (titular);;;
;;;
data;lançamento;;valor
04/03/2025;Pagamento*natilar 05/06;;R$ 796,85
;;;
total nacional do cartão - final 1055 (titular);;;R$ 796,85
```

### 🔍 Características Importantes

1. **Separador**: Ponto e vírgula (`;`)
2. **Header**: Múltiplas seções com metadados
3. **Cartões múltiplos**: Titular + adicionais com finais diferentes
4. **Parcelamento**: Formato `XX/YY` no final da descrição
5. **Moeda**: Valores em formato brasileiro `R$ 1.234,56`

---

## 2. Características Específicas

### 💳 Múltiplos Cartões

O arquivo contém transações de vários cartões (titular + adicionais):

```
JANAINA CRISTINE COSTA - final 1055 (titular)
JANAINA CRISTINE COSTA - final 5883 (adicional)
JANAINA CRISTINE COSTA - final 6838 (adicional)
JANAINA CRISTINE COSTA - final 2473 (adicional)
JANAINA CRISTINE COSTA - final 9069 (adicional)
```

**Pergunta para o usuário:**
- Agrupar tudo em um único cartão?
- Ou criar cartões separados por final?

### 📅 Datas

- **Data da transação**: Coluna "data" (ex: `04/03/2025`)
- **Vencimento da fatura**: Linha "fatura fechada" (ex: `01/08/2025`)

**Pergunta para o usuário:**
- Usar data da transação ou vencimento da fatura?
- Como lidar com transações de meses anteriores?

---

## 3. Estrutura de Parcelamento

### 🔢 Formato de Parcelas

Transações parceladas aparecem como:
```
Pagamento*natilar 05/06
```

Onde:
- `05` = Parcela atual
- `06` = Total de parcelas

### 📊 Lógica OFX de Parcelamento

O sistema OFX já tem lógica implementada para:

1. **Detectar parcelas** via regex: `(\d{2})/(\d{2})$`
2. **Extrair números**: parcela atual e total
3. **Calcular datas**: somar meses à data base
4. **Projetar faturas futuras**

**Código de referência** (do OFX JavaScript):
```javascript
// Detectar parcelas no formato XX/YY
const installmentMatch = description.match(/(\d{2})\/(\d{2})$/);

if (installmentMatch) {
  const currentInstallment = parseInt(installmentMatch[1]);
  const totalInstallments = parseInt(installmentMatch[2]);
  
  // Calcular data correta da parcela
  const baseDate = new Date(faturaVencimento);
  const monthsToAdd = currentInstallment - 1;
  
  // Adicionar meses mantendo dia do vencimento
  const adjustedDate = new Date(
    baseDate.getFullYear(),
    baseDate.getMonth() + monthsToAdd,
    baseDate.getDate()
  );
  
  return {
    parcelaAtual: currentInstallment,
    totalParcelas: totalInstallments,
    dataCorreta: adjustedDate,
    grupoParcelamento: generateUUID(),
  };
}
```

---

## 4. Implementação do Extractor

### 📝 Template: ItauFaturaExtractor

```dart
/// Extractor para faturas de cartão Itaú em formato CSV
class ItauFaturaExtractor implements BankExtractor {
  @override
  String get bankName => 'Itaú Fatura';
  
  // Padrões de detecção
  static final _installmentPattern = RegExp(r'(\d{2})/(\d{2})$');
  static final _cardSectionPattern = RegExp(r'final (\d{4})');
  
  @override
  bool canHandle(String fileName, String content) {
    final lowerFileName = fileName.toLowerCase();
    final lowerContent = content.toLowerCase();
    
    // Verificar nome do arquivo
    if (lowerFileName.contains('fatura') && 
        lowerFileName.contains('itau')) {
      return true;
    }
    
    // Verificar padrões específicos do Itaú
    if (lowerContent.contains('logotipo itaú') &&
        lowerContent.contains('fatura de') &&
        lowerContent.contains('lançamentos nacionais')) {
      return true;
    }
    
    return false;
  }
  
  @override
  bool validateFormat(String content) {
    final lines = content.split('\n');
    
    if (lines.length < 10) return false;
    
    // Deve ter header do Itaú
    if (!lines[0].toLowerCase().contains('itaú')) {
      return false;
    }
    
    // Deve ter informações de fatura
    if (!content.toLowerCase().contains('fatura')) {
      return false;
    }
    
    return true;
  }
  
  @override
  Map<String, dynamic>? extractMetadata(String content) {
    final lines = content.split('\n');
    final metadata = <String, dynamic>{
      'banco': 'Itaú',
      'tipo': 'fatura_cartao',
    };
    
    // Extrair nome
    for (final line in lines) {
      if (line.toLowerCase().startsWith('nome:')) {
        final parts = line.split(';');
        if (parts.length > 1) {
          metadata['titular'] = parts[1].trim();
        }
      }
    }
    
    // Extrair agência e conta
    for (final line in lines) {
      if (line.toLowerCase().startsWith('agência:')) {
        final parts = line.split(';');
        if (parts.length > 1) {
          metadata['agencia'] = parts[1].trim();
        }
      }
      if (line.toLowerCase().startsWith('conta:')) {
        final parts = line.split(';');
        if (parts.length > 1) {
          metadata['conta'] = parts[1].trim();
        }
      }
    }
    
    // Extrair vencimento da fatura
    for (final line in lines) {
      if (line.toLowerCase().contains('fatura') && 
          line.toLowerCase().contains('fechada')) {
        final parts = line.split(';');
        for (final part in parts) {
          if (_isDate(part.trim())) {
            metadata['vencimento_fatura'] = part.trim();
            break;
          }
        }
      }
    }
    
    return metadata;
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
      throw Exception('Formato inválido para Itaú Fatura');
    }
    
    final transacoes = <TransacaoImportada>[];
    final lines = content.split('\n');
    final userId = AuthIntegration.instance.authService.currentUser?.id ?? '';
    final metadata = extractMetadata(content);
    
    // Extrair vencimento da fatura dos metadados ou parâmetro
    DateTime? vencimentoFatura = faturaVencimento;
    if (vencimentoFatura == null && metadata?['vencimento_fatura'] != null) {
      vencimentoFatura = _parseDate(metadata!['vencimento_fatura']);
    }
    
    String? currentCardFinal;
    bool inTransactionSection = false;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      if (line.isEmpty) continue;
      
      // Detectar seção de cartão
      final cardMatch = _cardSectionPattern.firstMatch(line);
      if (cardMatch != null) {
        currentCardFinal = cardMatch.group(1);
        log('💳 Processando cartão final $currentCardFinal');
        continue;
      }
      
      // Detectar início de transações
      if (line.toLowerCase().contains('data;lançamento')) {
        inTransactionSection = true;
        continue;
      }
      
      // Detectar fim de seção de transações
      if (line.toLowerCase().contains('total nacional do cartão')) {
        inTransactionSection = false;
        continue;
      }
      
      // Processar transação
      if (inTransactionSection) {
        final transacao = _extractTransaction(
          line,
          i,
          userId,
          contaId,
          cartaoId,
          vencimentoFatura,
          currentCardFinal,
          metadata,
        );
        
        if (transacao != null) {
          transacoes.add(transacao);
        }
      }
    }
    
    log('✅ Itaú Fatura: ${transacoes.length} transações extraídas');
    return transacoes;
  }
  
  /// Extrai uma transação de uma linha
  TransacaoImportada? _extractTransaction(
    String line,
    int index,
    String userId,
    String? contaId,
    String? cartaoId,
    DateTime? faturaVencimento,
    String? cardFinal,
    Map<String, dynamic>? metadata,
  ) {
    try {
      // Split por ponto-e-vírgula
      final parts = line.split(';');
      
      if (parts.length < 4) {
        return null; // Linha não é uma transação
      }
      
      // Estrutura: data;lançamento;;valor
      final dataStr = parts[0].trim();
      final descricao = parts[1].trim();
      final valorStr = parts[3].trim();
      
      // Validar campos essenciais
      if (dataStr.isEmpty || descricao.isEmpty || valorStr.isEmpty) {
        return null;
      }
      
      // Parse de data
      final dataTransacao = _parseDate(dataStr);
      if (dataTransacao == null) {
        log('⚠️ Linha $index: data inválida "$dataStr"');
        return null;
      }
      
      // Parse de valor
      final valor = _parseValue(valorStr);
      if (valor == 0.0) {
        log('⚠️ Linha $index: valor zerado ou inválido "$valorStr"');
        return null;
      }
      
      // Detectar parcelamento
      final installmentInfo = _parseInstallment(descricao, faturaVencimento);
      
      // Usar data calculada se for parcela
      final dataFinal = installmentInfo?['dataCorreta'] ?? dataTransacao;
      
      return TransacaoImportada(
        id: 'itau_fatura_${DateTime.now().millisecondsSinceEpoch}_$index',
        data: dataFinal,
        descricao: descricao,
        valor: valor,
        tipo: 'despesa', // Faturas são sempre despesas
        origem: 'Itaú Fatura',
        usuarioId: userId,
        contaId: contaId,
        cartaoId: cartaoId,
        faturaVencimento: faturaVencimento,
        efetivado: false,
        observacoes: cardFinal != null ? 'Cartão final $cardFinal' : '',
        linhaBruta: line,
        indiceOriginal: index,
        metadados: {
          ...?metadata,
          'cartao_final': cardFinal,
          'data_transacao_original': dataStr,
          'linha': index,
          if (installmentInfo != null) ...{
            'parcela_atual': installmentInfo['parcelaAtual'],
            'total_parcelas': installmentInfo['totalParcelas'],
            'grupo_parcelamento': installmentInfo['grupoParcelamento'],
          },
        },
      );
      
    } catch (e) {
      log('❌ Erro ao processar linha $index: $e');
      return null;
    }
  }
  
  /// Detecta e processa informações de parcelamento
  Map<String, dynamic>? _parseInstallment(
    String description,
    DateTime? faturaVencimento,
  ) {
    if (faturaVencimento == null) return null;
    
    // Buscar padrão XX/YY no final da descrição
    final match = _installmentPattern.firstMatch(description);
    if (match == null) return null;
    
    try {
      final parcelaAtual = int.parse(match.group(1)!);
      final totalParcelas = int.parse(match.group(2)!);
      
      // Validar números
      if (parcelaAtual < 1 || parcelaAtual > totalParcelas) {
        return null;
      }
      if (totalParcelas < 2 || totalParcelas > 99) {
        return null;
      }
      
      // Calcular data correta da parcela
      // Parcela 1 = mês da fatura
      // Parcela 2 = próximo mês
      // etc.
      final monthsToAdd = parcelaAtual - 1;
      final dataCorreta = DateTime(
        faturaVencimento.year,
        faturaVencimento.month + monthsToAdd,
        faturaVencimento.day,
      );
      
      // Gerar ID único para o grupo de parcelamento
      final grupoParcelamento = _generateInstallmentGroupId(
        description,
        totalParcelas,
      );
      
      log('📊 Parcelamento detectado: $parcelaAtual/$totalParcelas - Data: ${dataCorreta.toString().split(' ')[0]}');
      
      return {
        'parcelaAtual': parcelaAtual,
        'totalParcelas': totalParcelas,
        'dataCorreta': dataCorreta,
        'grupoParcelamento': grupoParcelamento,
      };
      
    } catch (e) {
      log('❌ Erro ao processar parcelamento: $e');
      return null;
    }
  }
  
  /// Gera ID único para grupo de parcelamento
  String _generateInstallmentGroupId(String description, int totalParcelas) {
    // Remover o sufixo XX/YY da descrição para ter a base
    final baseDescription = description.replaceAll(_installmentPattern, '').trim();
    
    // Gerar hash simples baseado na descrição base + total de parcelas
    final hash = '${baseDescription}_${totalParcelas}'.hashCode.abs();
    
    return 'installment_$hash';
  }
  
  /// Verifica se string parece uma data
  bool _isDate(String text) {
    return RegExp(r'\d{2}/\d{2}/\d{4}').hasMatch(text);
  }
  
  /// Parse de data no formato brasileiro DD/MM/YYYY
  DateTime? _parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    
    try {
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
  
  /// Parse de valor monetário brasileiro (R$ 1.234,56)
  double _parseValue(String valueStr) {
    if (valueStr.isEmpty) return 0.0;
    
    try {
      // Remove "R$", espaços e outros caracteres
      String cleaned = valueStr
          .replaceAll('R\$', '')
          .replaceAll(' ', '')
          .trim();
      
      // Detectar se é negativo (pode estar entre parênteses ou com sinal -)
      bool isNegative = cleaned.startsWith('-') || 
                        (cleaned.startsWith('(') && cleaned.endsWith(')'));
      
      cleaned = cleaned
          .replaceAll('-', '')
          .replaceAll('(', '')
          .replaceAll(')', '');
      
      // Remove pontos (separador de milhar) e substitui vírgula por ponto
      cleaned = cleaned
          .replaceAll('.', '')
          .replaceAll(',', '.');
      
      double value = double.parse(cleaned);
      return isNegative ? -value.abs() : value.abs();
      
    } catch (e) {
      log('❌ Erro ao fazer parse de valor "$valueStr": $e');
      return 0.0;
    }
  }
}
```

---

## 5. Lógica de Parcelamento OFX

### 🔄 Como o OFX Calcula Datas de Parcelas

O sistema OFX usa a seguinte lógica (que replicamos no Itaú):

1. **Base**: Data de vencimento da fatura
2. **Cálculo**: Adicionar `(parcelaAtual - 1)` meses
3. **Ajuste**: Manter o dia do vencimento

**Exemplo:**
```
Vencimento fatura: 01/08/2025
Transação: "Compra parcelada 05/12"

Parcela 1: 01/08/2025 (0 meses)
Parcela 2: 01/09/2025 (1 mês)
Parcela 3: 01/10/2025 (2 meses)
Parcela 4: 01/11/2025 (3 meses)
Parcela 5: 01/12/2025 (4 meses) ✅ Esta é a parcela atual
```

### ⚙️ Código Dart para Cálculo

```dart
// Calcular data correta da parcela
final monthsToAdd = parcelaAtual - 1;
final dataCorreta = DateTime(
  faturaVencimento.year,
  faturaVencimento.month + monthsToAdd,
  faturaVencimento.day,
);
```

### 🔗 Grupo de Parcelamento

Todas as parcelas da mesma compra devem ter o mesmo `grupoParcelamento`:

```dart
// Gerar ID único baseado na descrição sem o sufixo XX/YY
final baseDescription = description.replaceAll(_installmentPattern, '').trim();
final hash = '${baseDescription}_${totalParcelas}'.hashCode.abs();
final grupoParcelamento = 'installment_$hash';
```

---

## 6. Integração

### 🔧 Adicionar ao ExtractorFactory

```dart
class ExtractorFactory {
  static BankExtractor createExtractor(String fileName, String content) {
    // ... outros extractors ...
    
    // 🆕 Adicionar Itaú Fatura
    if (ItauFaturaExtractor().canHandle(fileName, content)) {
      return ItauFaturaExtractor();
    }
    
    // ... continua ...
    
    return GenericExtractor(); // Fallback
  }
}
```

### 🧪 Testar com Arquivo Real

```dart
void main() {
  test('Itaú Fatura - deve extrair transações com parcelamento', () async {
    final extractor = ItauFaturaExtractor();
    final content = await loadFixture('fatura_itau_exemplo.csv');
    
    final transacoes = await extractor.extract(
      content,
      tipoImportacao: 'fatura_cartao',
      cartaoId: 'cartao_123',
      faturaVencimento: DateTime(2025, 8, 1),
    );
    
    expect(transacoes.length, greaterThan(0));
    
    // Verificar se parcelas foram detectadas
    final transacoesParceladas = transacoes.where(
      (t) => t.metadados['parcela_atual'] != null
    );
    
    expect(transacoesParceladas.length, greaterThan(0));
    
    // Verificar se datas foram ajustadas corretamente
    for (final t in transacoesParceladas) {
      final parcelaAtual = t.metadados['parcela_atual'] as int;
      final expectedMonth = 8 + (parcelaAtual - 1); // Agosto + offset
      
      expect(t.data.month, expectedMonth % 12);
    }
  });
}
```

---

## 📚 Considerações Finais

### ✅ Funcionalidades Implementadas

- ✅ Detecção automática de arquivo Itaú
- ✅ Extração de metadados (titular, agência, conta)
- ✅ Suporte a múltiplos cartões (titular + adicionais)
- ✅ Detecção de parcelamento (formato XX/YY)
- ✅ Cálculo correto de datas de parcelas
- ✅ Agrupamento de parcelas

### ⚠️ Questões para o Usuário

**Antes de finalizar a implementação, confirme:**

1. **Múltiplos cartões**: Agrupar tudo ou separar por final?
2. **Tipo de importação**: É sempre "fatura_cartao" ou pode ser diferente?
3. **Cartões adicionais**: Importar separado ou junto com titular?

### 🚀 Próximos Passos

1. Confirmar respostas das questões acima
2. Ajustar código conforme necessário
3. Testar com arquivo real completo
4. Adicionar ao ExtractorFactory
5. Documentar formato do Itaú

---

**FIM DO DOCUMENTO**

Use este documento como referência para implementar o extractor de faturas Itaú CSV.