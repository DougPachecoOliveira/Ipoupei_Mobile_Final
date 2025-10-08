// OFX Extractor - iPoupei Mobile
// Extrator para arquivos OFX (Open Financial Exchange)
// Adaptado do projeto web para Flutter

class OFXExtractor {
  static canHandle(fileName) {
    const name = fileName.toLowerCase();
    return name.endsWith('.ofx') || name.endsWith('.qfx');
  }

  extract(fileName, content) {
    try {
      console.log('📄 OFXExtractor: Iniciando extração de OFX', fileName);

      const cleanText = this._cleanOFXText(content);
      if (!cleanText.trim()) {
        throw new Error('Arquivo OFX está vazio');
      }

      const analysis = this._analyzeOFXStructure(cleanText);

      const result = {
        rawText: cleanText,
        lines: cleanText.split('\n').filter(line => line.trim()),
        analysis: analysis,
        metadata: this._getMetadata(fileName, cleanText)
      };

      console.log('✅ OFXExtractor: Extração concluída', {
        totalLines: result.lines.length,
        formatType: result.analysis.formatType,
        accountType: result.analysis.accountType,
        transactionCount: result.analysis.transactionCount
      });

      return result;

    } catch (error) {
      console.error('❌ OFXExtractor: Erro na extração:', error);
      throw new Error(`Erro ao extrair dados do OFX: ${error.message}`);
    }
  }

  parseTransactions(rawData, context = {}) {
    const { rawText, analysis } = rawData;
    const {
      tipoImportacao = 'conta',
      contaId = '',
      cartaoId = '',
      faturaVencimento = ''
    } = context;

    console.log('🔄 OFXExtractor: Processando transações OFX COM CONTEXTO', {
      formatType: analysis.formatType,
      accountType: analysis.accountType,
      transactionCount: analysis.transactionCount,
      tipoImportacao,
      contaId,
      cartaoId,
      faturaVencimento
    });

    // Extrair transações baseado no tipo de conta
    switch (analysis.accountType) {
      case 'CREDITCARD':
        return this._parseCreditCardTransactions(rawData, context);
      case 'CHECKING':
      case 'SAVINGS':
        return this._parseBankTransactions(rawData, context);
      default:
        return this._parseGenericOFXTransactions(rawData, context);
    }
  }

  _cleanOFXText(content) {
    // Remove caracteres de controle e normaliza quebras de linha
    return content
      .replace(/\r\n/g, '\n')
      .replace(/\r/g, '\n')
      .replace(/\0/g, '')
      .trim();
  }

  _analyzeOFXStructure(content) {
    const upperContent = content.toUpperCase();

    console.log('🔍 Analisando estrutura OFX...');
    console.log('📄 Conteúdo contém CCSTMTRS:', upperContent.includes('<CCSTMTRS>'));
    console.log('📄 Conteúdo contém BANKSTMTRS:', upperContent.includes('<BANKSTMTRS>'));

    // Detectar tipo de conta
    let accountType = 'UNKNOWN';
    if (upperContent.includes('<CCSTMTRS>')) {
      accountType = 'CREDITCARD';
    } else if (upperContent.includes('<BANKSTMTRS>')) {
      if (upperContent.includes('<ACCTTYPE>CHECKING')) {
        accountType = 'CHECKING';
      } else if (upperContent.includes('<ACCTTYPE>SAVINGS')) {
        accountType = 'SAVINGS';
      } else {
        accountType = 'CHECKING'; // default
      }
    }

    // Contar transações
    const transactionMatches = content.match(/<STMTTRN>/gi);
    const transactionCount = transactionMatches ? transactionMatches.length : 0;

    console.log('📊 Estrutura detectada:', {
      accountType,
      transactionCount,
      hasSTMTTRN: transactionCount > 0
    });

    return {
      formatType: 'ofx',
      accountType: accountType,
      transactionCount: transactionCount,
      hasHeader: true,
      separator: null
    };
  }

  _parseCreditCardTransactions(rawData, context) {
    console.log('💳 OFXExtractor: Processando transações de cartão de crédito');
    return this._parseGenericOFXTransactions(rawData, context);
  }

  _parseBankTransactions(rawData, context) {
    console.log('🏦 OFXExtractor: Processando transações bancárias');
    return this._parseGenericOFXTransactions(rawData, context);
  }

  _parseGenericOFXTransactions(rawData, context) {
    const { rawText, analysis } = rawData;
    const {
      tipoImportacao = 'conta',
      contaId = '',
      cartaoId = '',
      faturaVencimento = ''
    } = context;

    const transacoes = [];
    let transactionIndex = 0;

    console.log('🔧 OFXExtractor: Processando OFX genérico');
    console.log('📝 Tamanho do rawText:', rawText ? rawText.length : 'undefined');
    console.log('📋 Analysis:', analysis);

    // Extrair blocos de transação
    const transactionBlocks = this._extractTransactionBlocks(rawText);
    console.log('📦 Blocos retornados:', transactionBlocks.length);

    for (const block of transactionBlocks) {
      try {
        const transactionData = this._parseTransactionBlock(block, transactionIndex);

        if (transactionData) {
          const transacao = {
            id: `ofx_${Date.now()}_${transactionIndex++}`,
            data: transactionData.data,
            descricao: transactionData.descricao,
            valor: Math.abs(transactionData.valor),
            tipo: transactionData.valor >= 0 ? 'receita' : 'despesa',
            origem: 'OFX',
            conta_id: contaId,
            cartao_id: cartaoId,
            fatura_vencimento: faturaVencimento,
            efetivado: false,
            observacoes: `Importado de OFX: ${rawData.metadata?.fileName || 'arquivo.ofx'}`,
            linhaBruta: block.substring(0, 100) + '...', // Primeiros 100 chars
            indiceOriginal: transactionIndex,
            metadados: {
              banco: 'OFX Import',
              formatType: 'ofx',
              accountType: analysis.accountType,
              fitid: transactionData.fitid || '',
              memo: transactionData.memo || ''
            }
          };

          transacoes.push(transacao);
          console.log(`✅ Transação OFX extraída: ${transactionData.descricao} - R$ ${transactionData.valor}`);
        }
      } catch (e) {
        console.warn(`⚠️ Erro ao processar bloco de transação ${transactionIndex}:`, e);
        continue;
      }
    }

    console.log(`🎯 OFXExtractor: ${transacoes.length} transações processadas`);
    return transacoes;
  }

  _extractTransactionBlocks(content) {
    console.log('🔍 OFXExtractor: Procurando blocos STMTTRN no conteúdo...');
    console.log('📝 Primeiros 800 chars do conteúdo:', content.substring(0, 800));

    // Vamos testar diferentes padrões
    const stmttrnMatches = content.match(/<STMTTRN>/gi);
    const stmttrnCloseMatches = content.match(/<\/STMTTRN>/gi);
    console.log('🔍 Tags <STMTTRN> encontradas:', stmttrnMatches ? stmttrnMatches.length : 0);
    console.log('🔍 Tags </STMTTRN> encontradas:', stmttrnCloseMatches ? stmttrnCloseMatches.length : 0);

    const blocks = [];
    const regex = /<STMTTRN>(.*?)<\/STMTTRN>/gis;
    let match;
    let matchCount = 0;

    while ((match = regex.exec(content)) !== null) {
      matchCount++;
      const blockContent = match[1].trim();
      console.log(`🎯 Bloco ${matchCount} encontrado (${blockContent.length} chars):`, blockContent.substring(0, 200));
      blocks.push(blockContent);
    }

    console.log(`📊 Total de blocos STMTTRN encontrados: ${blocks.length}`);

    // Se não encontrou blocos, mas tem tags, pode ser problema de formatação
    if (blocks.length === 0 && stmttrnMatches && stmttrnMatches.length > 0) {
      console.log('⚠️ AVISO: Tags STMTTRN encontradas mas nenhum bloco extraído!');
      console.log('📝 Buscando primeira ocorrência para debug...');
      const firstIndex = content.indexOf('<STMTTRN>');
      if (firstIndex !== -1) {
        console.log('📝 Contexto da primeira tag:', content.substring(firstIndex, firstIndex + 300));
      }
    }

    return blocks;
  }

  _parseTransactionBlock(block, index) {
    try {
      console.log(`🔧 Processando bloco ${index}:`, block.substring(0, 150));

      // Extrair campos OFX
      const trntype = this._extractOFXField(block, 'TRNTYPE');
      const dtposted = this._extractOFXField(block, 'DTPOSTED');
      const trnamt = this._extractOFXField(block, 'TRNAMT');
      const fitid = this._extractOFXField(block, 'FITID');
      const name = this._extractOFXField(block, 'NAME');
      const memo = this._extractOFXField(block, 'MEMO');

      console.log(`📋 Campos extraídos:`, {
        trntype, dtposted, trnamt, fitid, name, memo
      });

      // Processar data
      let data;
      try {
        if (dtposted && dtposted.length >= 8) {
          const year = dtposted.substring(0, 4);
          const month = dtposted.substring(4, 6);
          const day = dtposted.substring(6, 8);
          data = `${year}-${month}-${day}`;
        } else {
          data = new Date().toISOString().substring(0, 10);
        }
      } catch (e) {
        data = new Date().toISOString().substring(0, 10);
      }

      // Processar valor
      const valor = parseFloat(trnamt) || 0;

      // Processar descrição
      let descricao = name || memo || 'Transação OFX';
      if (name && memo && name !== memo) {
        descricao = `${name} - ${memo}`;
      }

      // Limpar descrição
      descricao = descricao
        .replace(/\s+/g, ' ')
        .trim()
        .substring(0, 200); // Limitar tamanho

      console.log(`📝 Transação processada:`, {
        data, descricao, valor, fitid
      });

      if (!descricao || valor === 0) {
        console.log(`❌ Transação rejeitada: descrição="${descricao}", valor=${valor}`);
        return null;
      }

      console.log(`✅ Transação válida criada`);
      return {
        data: data,
        descricao: descricao,
        valor: valor,
        fitid: fitid,
        memo: memo,
        trntype: trntype
      };

    } catch (e) {
      console.warn(`⚠️ Erro ao processar campo OFX:`, e);
      return null;
    }
  }

  _extractOFXField(block, fieldName) {
    // Primeiro, vamos tentar o padrão com tag de fechamento
    let regex = new RegExp(`<${fieldName}>(.*?)<\/${fieldName}>`, 'is');
    let match = block.match(regex);
    if (match) {
      console.log(`🔍 Campo ${fieldName} (com fechamento):`, match[1].trim());
      return match[1].trim();
    }

    // Se não encontrou, tenta padrão até próxima tag ou quebra de linha
    regex = new RegExp(`<${fieldName}>([^<\\n\\r]*?)(?=\\s*<|\\s*$)`, 'i');
    match = block.match(regex);
    if (match) {
      console.log(`🔍 Campo ${fieldName} (sem fechamento):`, match[1].trim());
      return match[1].trim();
    }

    console.log(`❌ Campo ${fieldName} não encontrado`);
    return '';
  }

  _getMetadata(fileName, content) {
    const upperContent = content.toUpperCase();

    // Extrair informações do cabeçalho OFX
    const org = this._extractOFXField(content, 'ORG') || 'Banco não identificado';
    const acctid = this._extractOFXField(content, 'ACCTID') || '';
    const dtstart = this._extractOFXField(content, 'DTSTART') || '';
    const dtend = this._extractOFXField(content, 'DTEND') || '';

    return {
      fileName: fileName,
      fileType: 'OFX',
      contentLength: content.length,
      extractedAt: new Date().toISOString(),
      bank: org,
      accountId: acctid,
      dateStart: dtstart,
      dateEnd: dtend,
      version: '1.0'
    };
  }
}

// Exportar para uso global
if (typeof window !== 'undefined') {
  window.OFXExtractor = OFXExtractor;
}