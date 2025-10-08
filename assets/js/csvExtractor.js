// src/modules/importacao/utils/parsers/extractors/csvExtractor.js
// Extractor para arquivos CSV e TXT - VERSÃO COM SUPORTE AO FORMATO BRADESCO
// COPIADO EXATAMENTE DO REACT QUE FUNCIONA

/**
 * Extractor para arquivos CSV e TXT
 * VERSÃO ATUALIZADA: Suporta contexto de importação + formato Bradesco
 */
class CSVExtractor {
  /**
   * Verifica se pode processar o arquivo
   * @param {string} fileName
   * @returns {boolean}
   */
  static canHandle(fileName) {
    const fileNameLower = fileName.toLowerCase();

    // Por extensão
    if (fileNameLower.endsWith('.csv') || fileNameLower.endsWith('.txt')) {
      return true;
    }

    return false;
  }

  /**
   * Extrai dados brutos do arquivo CSV/TXT
   * @param {string} fileName
   * @param {string} content
   * @returns {CSVRawData}
   */
  extract(fileName, content) {
    try {
      console.log('📄 CSVExtractor: Iniciando extração de', fileName);

      const cleanText = this._cleanText(content);

      if (!cleanText.trim()) {
        throw new Error('Arquivo está vazio ou contém apenas espaços em branco');
      }

      // Analisar estrutura do CSV
      const analysis = this._analyzeCSVStructure(cleanText);

      // Dividir em linhas
      const lines = cleanText.split('\n').filter(line => line.trim());

      if (lines.length === 0) {
        throw new Error('Nenhuma linha válida encontrada no arquivo');
      }

      const result = {
        rawText: cleanText,
        lines: lines,
        analysis: analysis,
        metadata: this._getMetadata(fileName, cleanText)
      };

      console.log('✅ CSVExtractor: Extração concluída', {
        totalLines: lines.length,
        separator: analysis.separator,
        hasHeader: analysis.hasHeader,
        columnCount: analysis.columnCount,
        formatType: analysis.formatType
      });

      return result;

    } catch (error) {
      console.error('❌ CSVExtractor: Erro na extração:', error);
      throw new Error(`Erro ao extrair dados do CSV: ${error.message}`);
    }
  }

  /**
   * ✅ NOVA ASSINATURA: Converte dados brutos em transações COM CONTEXTO
   * @param {CSVRawData} rawData
   * @param {ImportContext} context - Contexto de importação
   * @returns {Array<Transaction>}
   */
  parseTransactions(rawData, context = {}) {
    const { lines, analysis } = rawData;
    const {
      tipoImportacao = 'conta',
      contaId = '',
      cartaoId = '',
      faturaVencimento = ''
    } = context;

    console.log('🔄 CSVExtractor: Processando transações COM CONTEXTO', {
      totalLines: lines.length,
      formatType: analysis.formatType,
      separator: analysis.separator,
      tipoImportacao,
      contaId,
      cartaoId,
      faturaVencimento
    });

    // ✅ NOVA LÓGICA: Escolher parser baseado no formato detectado
    switch (analysis.formatType) {
      case 'itau_fatura':
        return this._parseItauFaturaFormat(rawData, context);
      case 'bradesco':
        return this._parseBradescoFormat(rawData, context);
      case 'generic':
      default:
        return this._parseGenericFormat(rawData, context);
    }
  }

  /**
   * ✅ NOVO MÉTODO: Parser específico para formato Bradesco
   * @param {CSVRawData} rawData
   * @param {ImportContext} context
   * @returns {Array<Transaction>}
   */
  _parseBradescoFormat(rawData, context) {
    const { lines, analysis } = rawData;
    const {
      tipoImportacao = 'conta',
      contaId = '',
      cartaoId = '',
      faturaVencimento = ''
    } = context;

    const transacoes = [];
    const startIndex = analysis.hasHeader ? 1 : 0;
    const separator = analysis.separator;

    console.log('🏦 CSVExtractor: Processando formato BRADESCO', {
      startIndex,
      separator,
      colunas: analysis.columns,
      primeirasLinhas: lines.slice(0, 3)
    });

    // ✅ MAPEAR COLUNAS DINAMICAMENTE
    const columnMap = this._mapBradescoColumns(analysis.columns);
    console.log('🗂️ Mapeamento de colunas Bradesco:', columnMap);

    lines.slice(startIndex).forEach((line, index) => {
      try {
        const parts = line.split(separator).map(p => p.trim());

        console.log(`🔍 Linha ${index + 1}:`, parts);

        if (parts.length >= 5) {
          // ✅ USAR MAPEAMENTO DINÂMICO DE COLUNAS
          const dataStr = parts[columnMap.data] || '';
          const historico = parts[columnMap.historico] || '';
          const docto = parts[columnMap.docto] || '';
          const creditoStr = parts[columnMap.credito] || '0';
          const debitoStr = parts[columnMap.debito] || '0';
          const saldoStr = parts[columnMap.saldo] || '';

          console.log(`📊 Valores mapeados:`, {
            data: dataStr,
            historico: historico,
            docto: docto,
            credito: creditoStr,
            debito: debitoStr,
            saldo: saldoStr
          });

          if (dataStr && historico) {
            const data = this._parseDate(dataStr);
            const credito = this._parseValue(creditoStr) || 0;
            const debito = this._parseValue(debitoStr) || 0;

            console.log(`💰 Valores processados: credito=${credito}, debito=${debito}`);

            // ✅ LÓGICA BRADESCO: Se tem crédito, é receita; se tem débito, é despesa
            if (data && (credito > 0 || debito > 0)) {
              const isCredito = credito > 0;
              const valor = isCredito ? credito : debito;

              // ✅ APLICAR LÓGICA BASEADA NO CONTEXTO
              let tipoTransacao;
              if (tipoImportacao === 'cartao') {
                tipoTransacao = 'despesa'; // Para cartão, sempre despesa
              } else {
                tipoTransacao = isCredito ? 'receita' : 'despesa';
              }

              // ✅ APLICAR STATUS BASEADO NO CONTEXTO
              let efetivado;
              if (tipoImportacao === 'cartao') {
                efetivado = false; // Cartão sempre false
              } else {
                efetivado = new Date(data) <= new Date(); // Conta: efetivado se data <= hoje
              }

              // ✅ DESCRIÇÃO MELHORADA: Combinar histórico + docto se disponível
              let descricao = historico.trim();
              if (docto && docto.trim() && docto.trim() !== '0' && !descricao.includes(docto.trim())) {
                descricao += ` - Doc:${docto.trim()}`;
              }

              transacoes.push({
                id: `csv_bradesco_${Date.now()}_${startIndex + index + 1}`,
                data,
                descricao: descricao,
                valor: valor,
                tipo: tipoTransacao,
                origem: 'CSV-Bradesco',
                conta_id: tipoImportacao === 'conta' ? contaId : '',
                cartao_id: tipoImportacao === 'cartao' ? cartaoId : '',
                fatura_vencimento: tipoImportacao === 'cartao' ? faturaVencimento : '',
                efetivado: efetivado,
                observacoes: `Importado de extrato Bradesco - ${isCredito ? 'Crédito' : 'Débito'}`,
                linhaBruta: line,
                indiceOriginal: startIndex + index + 1,
                metadados: {
                  banco: 'Bradesco',
                  formatType: 'bradesco',
                  docto: docto,
                  credito: creditoStr,
                  debito: debitoStr,
                  saldo: saldoStr
                }
              });

              console.log(`✅ Transação Bradesco criada: ${data} | ${descricao} | ${tipoTransacao} | R$ ${valor.toFixed(2)}`);
            } else {
              console.log(`⚠️ Linha ignorada - sem valores válidos: credito=${credito}, debito=${debito}`);
            }
          } else {
            console.log(`⚠️ Linha ignorada - campos obrigatórios vazios: data="${dataStr}", historico="${historico}"`);
          }
        } else {
          console.log(`⚠️ Linha ignorada - colunas insuficientes: ${parts.length} < 5`);
        }
      } catch (error) {
        console.warn(`⚠️ Erro ao processar linha Bradesco ${startIndex + index + 1}:`, error.message);
      }
    });

    console.log('✅ CSVExtractor: Transações Bradesco processadas:', {
      totalProcessadas: transacoes.length,
      receitas: transacoes.filter(t => t.tipo === 'receita').length,
      despesas: transacoes.filter(t => t.tipo === 'despesa').length
    });

    return transacoes;
  }

  /**
   * ✅ Parser para Itaú Fatura - CÓPIA do genérico com tipo invertido
   * ÚNICA DIFERENÇA: valor positivo = despesa (não receita)
   */
  _parseItauFaturaFormat(rawData, context) {
    const { lines, analysis } = rawData;
    const {
      tipoImportacao = 'cartao',
      contaId = '',
      cartaoId = '',
      faturaVencimento = ''
    } = context;

    const transacoes = [];
    const startIndex = analysis.hasHeader ? 1 : 0;
    const separator = analysis.separator;

    console.log('💳 CSVExtractor: Processando formato ITAÚ FATURA (genérico com tipo invertido)');

    lines.slice(startIndex).forEach((line, index) => {
      try {
        const parts = line.split(separator).map(p => p.trim());

        if (parts.length >= 3) {
          let data, descricao, valor;

          for (let i = 0; i < parts.length; i++) {
            const part = parts[i];

            if (!data && this._isDateLike(part)) {
              data = this._parseDate(part);
            }

            if (!valor && this._isValueLike(part)) {
              valor = this._parseValue(part);
            }

            if (!descricao && !this._isDateLike(part) && !this._isValueLike(part) && part.length > 2) {
              descricao = part;
            }
          }

          if (data && descricao && valor && valor !== 0) {
            // 🎯 ÚNICA MUDANÇA: positivo = despesa (inverso do genérico)
            const tipoTransacao = valor > 0 ? 'despesa' : 'receita';
            const valorAbs = Math.abs(valor);

            // Ignorar valores negativos em fatura Itaú (ajustes)
            if (valor < 0) {
              console.log(`⏭️ Ignorado valor negativo: ${descricao} | R$ ${valor.toFixed(2)}`);
              return;
            }

            // 🎯 DETECTAR PARCELAS NO PADRÃO "XX/XX" NO FIM DA DESCRIÇÃO
            // Exemplo: "Expedia Do Brasil 09/12" → parcela 9 de 12
            // Exemplo: "180Seguros10/12" → parcela 10 de 12 (sem espaço)
            // IMPORTANTE: Itaú mostra data da PRIMEIRA parcela, não da atual!
            let dataReal = data;
            let parcelaInfo = null;
            const parcelaMatch = descricao.match(/\s*(\d{1,2})\/(\d{1,2})$/);

            if (parcelaMatch) {
              const parcelaAtual = parseInt(parcelaMatch[1], 10);
              const totalParcelas = parseInt(parcelaMatch[2], 10);

              if (parcelaAtual > 0 && parcelaAtual <= totalParcelas) {
                // Calcular data real atual da parcela
                // Se a data é da 1ª parcela e estamos na 9ª, precisa AVANÇAR 8 meses
                const mesesParaAvancar = parcelaAtual - 1;

                const dataPrimeiraParcela = new Date(data);
                dataPrimeiraParcela.setMonth(dataPrimeiraParcela.getMonth() + mesesParaAvancar);
                dataReal = dataPrimeiraParcela.toISOString().split('T')[0];

                parcelaInfo = {
                  atual: parcelaAtual,
                  total: totalParcelas,
                  dataPrimeiraParcela: data,
                  dataParcelaAtual: dataReal
                };

                console.log(`📅 Parcela ${parcelaAtual}/${totalParcelas} | 1ª parcela: ${data} → Parcela atual: ${dataReal}`);
              }
            }

            transacoes.push({
              id: `csv_itau_fatura_${Date.now()}_${startIndex + index + 1}`,
              data: dataReal, // ⭐ USA DATA REAL DA COMPRA
              descricao: descricao,
              valor: valorAbs,
              tipo: tipoTransacao,
              origem: 'CSV-Itau-Fatura',
              conta_id: contaId || '',
              cartao_id: cartaoId || '',
              fatura_vencimento: faturaVencimento || '',
              efetivado: false,
              observacoes: parcelaInfo
                ? `Importado de fatura Itaú CSV - Parcela ${parcelaInfo.atual}/${parcelaInfo.total} (1ª parcela: ${parcelaInfo.dataPrimeiraParcela})`
                : 'Importado de fatura Itaú CSV',
              linhaBruta: line,
              indiceOriginal: startIndex + index + 1,
              metadados: {
                banco: 'Itaú',
                formatType: 'itau_fatura',
                parcela: parcelaInfo
              }
            });

            console.log(`✅ Transação Itaú: ${dataReal} | ${descricao} | ${tipoTransacao} | R$ ${valorAbs.toFixed(2)}`);
          }
        }
      } catch (error) {
        console.warn(`⚠️ Erro linha ${startIndex + index + 1}:`, error.message);
      }
    });

    console.log('✅ Itaú Fatura processado:', transacoes.length);
    return transacoes;
  }

  /**
   * ✅ MÉTODO ORIGINAL: Parser genérico (mantém compatibilidade)
   * @param {CSVRawData} rawData
   * @param {ImportContext} context
   * @returns {Array<Transaction>}
   */
  _parseGenericFormat(rawData, context) {
    const { lines, analysis } = rawData;
    const {
      tipoImportacao = 'conta',
      contaId = '',
      cartaoId = '',
      faturaVencimento = ''
    } = context;

    const transacoes = [];
    const startIndex = analysis.hasHeader ? 1 : 0;
    const separator = analysis.separator;

    console.log('📄 CSVExtractor: Processando formato GENÉRICO', {
      startIndex,
      separator
    });

    lines.slice(startIndex).forEach((line, index) => {
      try {
        const parts = line.split(separator).map(p => p.trim());

        if (parts.length >= 3) {
          // Mapear automaticamente colunas comuns
          let data, descricao, valor;

          for (let i = 0; i < parts.length; i++) {
            const part = parts[i];

            if (!data && this._isDateLike(part)) {
              data = this._parseDate(part);
            }

            if (!valor && this._isValueLike(part)) {
              valor = this._parseValue(part);
            }

            if (!descricao && !this._isDateLike(part) && !this._isValueLike(part) && part.length > 2) {
              descricao = part;
            }
          }

          if (data && descricao && valor && valor !== 0) {
            const tipoTransacao = valor > 0 ? 'receita' : 'despesa';
            const valorAbs = Math.abs(valor);

            transacoes.push({
              id: `csv_generic_${Date.now()}_${startIndex + index + 1}`,
              data: data,
              descricao: descricao,
              valor: valorAbs,
              tipo: tipoTransacao,
              origem: 'CSV-Generic',
              conta_id: tipoImportacao === 'conta' ? contaId : '',
              cartao_id: tipoImportacao === 'cartao' ? cartaoId : '',
              fatura_vencimento: tipoImportacao === 'cartao' ? faturaVencimento : '',
              efetivado: tipoImportacao === 'cartao' ? false : true,
              observacoes: 'Importado de CSV genérico',
              linhaBruta: line,
              indiceOriginal: startIndex + index + 1,
              metadados: {
                banco: 'CSV Genérico',
                formatType: 'generic'
              }
            });

            console.log(`✅ Transação genérica criada: ${data} | ${descricao} | ${tipoTransacao} | R$ ${valorAbs.toFixed(2)}`);
          }
        }
      } catch (error) {
        console.warn(`⚠️ Erro ao processar linha genérica ${startIndex + index + 1}:`, error.message);
      }
    });

    console.log('✅ CSVExtractor: Transações genéricas processadas:', transacoes.length);
    return transacoes;
  }

  /**
   * ✅ VERSÃO MELHORADA: Analisa estrutura e detecta formato
   * @param {string} content
   * @returns {CSVAnalysis}
   */
  _analyzeCSVStructure(content) {
    const lines = content.split('\n').filter(line => line.trim());

    if (lines.length === 0) {
      return {
        separator: ';',
        hasHeader: false,
        columnCount: 0,
        encoding: 'UTF-8',
        formatType: 'generic'
      };
    }

    // Detectar separador
    const separadores = ['\t', ';', ',', '|'];
    let separador = ';';
    let maxColunas = 0;

    for (const sep of separadores) {
      const cols = lines[0]?.split(sep) || [];
      if (cols.length > maxColunas) {
        maxColunas = cols.length;
        separador = sep;
      }
    }

    // Analisar primeira linha para detectar cabeçalho e formato
    const firstLine = lines[0].toLowerCase();
    const columns = lines[0].split(separador).map(col => col.trim());

    // ✅ DETECÇÃO DE FORMATOS ESPECÍFICOS
    const isBradescoFormat = this._detectBradescoFormat(firstLine, columns);
    const isItauFaturaFormat = this._detectItauFaturaFormat(content, firstLine, columns);

    // Detectar se tem cabeçalho
    const hasHeader = firstLine.includes('data') ||
                     firstLine.includes('date') ||
                     firstLine.includes('valor') ||
                     firstLine.includes('value') ||
                     firstLine.includes('descricao') ||
                     firstLine.includes('description') ||
                     firstLine.includes('histórico') ||
                     firstLine.includes('historico') ||
                     firstLine.includes('crédito') ||
                     firstLine.includes('credito') ||
                     firstLine.includes('débito') ||
                     firstLine.includes('debito');

    // Determinar tipo de formato
    let formatType = 'generic';
    if (isItauFaturaFormat) {
      formatType = 'itau_fatura';
    } else if (isBradescoFormat) {
      formatType = 'bradesco';
    }

    return {
      separator: separador,
      hasHeader: hasHeader,
      columnCount: maxColunas,
      encoding: 'UTF-8',
      formatType: formatType,
      columns: columns,
      sampleRows: lines.slice(0, 5)
    };
  }

  /**
   * ✅ NOVA FUNÇÃO: Mapeia colunas do formato Bradesco dinamicamente
   * @param {Array<string>} columns
   * @returns {Object} Mapeamento de colunas
   */
  _mapBradescoColumns(columns) {
    const map = {
      data: 0,      // Padrão: primeira coluna
      historico: 1, // Padrão: segunda coluna
      docto: 2,     // Padrão: terceira coluna
      credito: 3,   // Padrão: quarta coluna
      debito: 4,    // Padrão: quinta coluna
      saldo: 5      // Padrão: sexta coluna
    };

    // ✅ FUNÇÃO PARA NORMALIZAR TEXTO
    const normalizeText = (text) => {
      return text.toLowerCase()
        .normalize('NFD')
        .replace(/[\u0300-\u036f]/g, '') // Remove acentos
        .replace(/[^\w\s]/g, '') // Remove caracteres especiais
        .trim();
    };

    console.log('🗂️ Mapeando colunas Bradesco:', {
      originalColumns: columns,
      normalizedColumns: columns.map(normalizeText)
    });

    // ✅ MAPEAMENTO INTELIGENTE baseado no nome das colunas (normalizado)
    columns.forEach((col, index) => {
      const colNormalized = normalizeText(col);

      if (colNormalized.includes('data')) {
        map.data = index;
        console.log(`   📅 Data mapeada para coluna ${index}: "${col}"`);
      } else if (colNormalized.includes('historico') || colNormalized.includes('hist')) {
        map.historico = index;
        console.log(`   📝 Histórico mapeado para coluna ${index}: "${col}"`);
      } else if (colNormalized.includes('docto') || colNormalized.includes('documento')) {
        map.docto = index;
        console.log(`   📄 Docto mapeado para coluna ${index}: "${col}"`);
      } else if (colNormalized.includes('credito') || colNormalized.includes('credit')) {
        map.credito = index;
        console.log(`   💰 Crédito mapeado para coluna ${index}: "${col}"`);
      } else if (colNormalized.includes('debito') || colNormalized.includes('debit')) {
        map.debito = index;
        console.log(`   💸 Débito mapeado para coluna ${index}: "${col}"`);
      } else if (colNormalized.includes('saldo')) {
        map.saldo = index;
        console.log(`   💳 Saldo mapeado para coluna ${index}: "${col}"`);
      }
    });

    console.log('🗂️ Mapeamento final:', map);
    return map;
  }

  /**
   * ✅ NOVA FUNÇÃO: Detecta formato Bradesco
   * @param {string} firstLine
   * @param {Array<string>} columns
   * @returns {boolean}
   */
  _detectBradescoFormat(firstLine, columns) {
    console.log('🔍 Analisando detecção Bradesco:', {
      firstLine: firstLine,
      columns: columns,
      columnCount: columns.length
    });

    // ✅ NORMALIZAR TEXTO para remover acentos e caracteres especiais
    const normalizeText = (text) => {
      return text.toLowerCase()
        .normalize('NFD')
        .replace(/[\u0300-\u036f]/g, '') // Remove acentos
        .replace(/[^\w\s]/g, '') // Remove caracteres especiais
        .trim();
    };

    const normalizedLine = normalizeText(firstLine);
    const normalizedColumns = columns.map(col => normalizeText(col));

    console.log('🔍 Texto normalizado:', {
      normalizedLine,
      normalizedColumns
    });

    // ✅ VERIFICAÇÕES MAIS FLEXÍVEIS
    const hasData = normalizedLine.includes('data');
    const hasHistorico = normalizedLine.includes('historico') || normalizedLine.includes('hist');
    const hasCredito = normalizedLine.includes('credito') || normalizedLine.includes('credit');
    const hasDebito = normalizedLine.includes('debito') || normalizedLine.includes('debit');
    const hasDocto = normalizedLine.includes('docto') || normalizedLine.includes('documento');
    const hasSaldo = normalizedLine.includes('saldo');

    // ✅ CONTAGEM DE INDICADORES
    const indicators = [hasData, hasHistorico, hasCredito, hasDebito, hasDocto, hasSaldo];
    const indicatorCount = indicators.filter(Boolean).length;

    // ✅ VERIFICAÇÃO POR ESTRUTURA DE COLUNAS (fallback)
    const hasMinimumColumns = columns.length >= 5;
    const hasTypicalColumnCount = columns.length === 6; // Data,Hist,Docto,Cred,Deb,Saldo

    // ✅ LÓGICA DE DETECÇÃO: deve ter pelo menos 3 indicadores OU estrutura típica
    const detectedByIndicators = indicatorCount >= 3;
    const detectedByStructure = hasMinimumColumns && hasTypicalColumnCount;
    const detected = detectedByIndicators || detectedByStructure;

    console.log('🔍 Detecção formato Bradesco:', {
      hasData,
      hasHistorico,
      hasCredito,
      hasDebito,
      hasDocto,
      hasSaldo,
      indicatorCount,
      hasMinimumColumns,
      hasTypicalColumnCount,
      detectedByIndicators,
      detectedByStructure,
      columnCount: columns.length,
      detected: detected
    });

    return detected;
  }

  /**
   * ✅ NOVA FUNÇÃO: Detecta formato Itaú Fatura
   * @param {string} content - Conteúdo completo do arquivo
   * @param {string} firstLine - Primeira linha
   * @param {Array<string>} columns - Colunas
   * @returns {boolean}
   */
  _detectItauFaturaFormat(content, firstLine, columns) {
    const normalizeText = (text) => {
      return text.toLowerCase()
        .normalize('NFD')
        .replace(/[\u0300-\u036f]/g, '')
        .trim();
    };

    const normalizedContent = normalizeText(content);

    // Verificar palavras-chave do Itaú fatura
    const hasItauLogo = normalizedContent.includes('logotipo itau');
    const hasFaturaFechada = normalizedContent.includes('fatura fechada') || normalizedContent.includes('fatura de');
    const hasLancamentosNacionais = normalizedContent.includes('lancamentos nacionais');
    const hasTotalFatura = normalizedContent.includes('total da fatura');
    const hasCartaoFinal = normalizedContent.includes('final') && normalizedContent.includes('titular');

    const detected = hasItauLogo || (hasFaturaFechada && hasLancamentosNacionais) || (hasTotalFatura && hasCartaoFinal);

    console.log('🔍 Detecção formato Itaú Fatura:', {
      hasItauLogo,
      hasFaturaFechada,
      hasLancamentosNacionais,
      hasTotalFatura,
      hasCartaoFinal,
      detected
    });

    return detected;
  }

  /**
   * Parse de data flexível
   * @param {string} dateStr
   * @returns {string} Data no formato YYYY-MM-DD ou null
   */
  _parseDate(dateStr) {
    if (!dateStr) return null;

    try {
      // DD/MM/YYYY
      if (/\d{1,2}\/\d{1,2}\/\d{4}/.test(dateStr)) {
        const parts = dateStr.split('/');
        const day = parts[0].padStart(2, '0');
        const month = parts[1].padStart(2, '0');
        const year = parts[2];
        return `${year}-${month}-${day}`;
      }

      // YYYY-MM-DD (já no formato correto)
      if (/\d{4}-\d{1,2}-\d{1,2}/.test(dateStr)) {
        return dateStr;
      }

      // DD-MM-YYYY
      if (/\d{1,2}-\d{1,2}-\d{4}/.test(dateStr)) {
        const parts = dateStr.split('-');
        const day = parts[0].padStart(2, '0');
        const month = parts[1].padStart(2, '0');
        const year = parts[2];
        return `${year}-${month}-${day}`;
      }

      return null;
    } catch (error) {
      console.warn('Erro ao parsear data:', dateStr, error);
      return null;
    }
  }

  /**
   * Parse de valor monetário flexível
   * @param {string} valueStr
   * @returns {number}
   */
  _parseValue(valueStr) {
    if (!valueStr || valueStr.trim() === '') return 0;

    try {
      let cleaned = valueStr.toString().trim();

      // Detectar sinal negativo
      const isNegative = cleaned.includes('(') || cleaned.includes(')') || cleaned.startsWith('-');

      // Remover símbolos
      cleaned = cleaned.replace(/[R$\s()]/g, '');

      if (!cleaned || cleaned === '0' || cleaned === '-') return 0;

      // Se tem vírgula e ponto, assumir formato brasileiro
      if (cleaned.includes(',') && cleaned.includes('.')) {
        const lastComma = cleaned.lastIndexOf(',');
        const lastDot = cleaned.lastIndexOf('.');

        if (lastComma > lastDot) {
          // 1.000,50 (brasileiro)
          cleaned = cleaned.replace(/\./g, '').replace(',', '.');
        } else {
          // 1,000.50 (americano)
          cleaned = cleaned.replace(/,/g, '');
        }
      } else if (cleaned.includes(',')) {
        // Apenas vírgula - assumir decimal se 2 dígitos depois
        const parts = cleaned.split(',');
        if (parts.length === 2 && parts[1].length <= 2) {
          cleaned = cleaned.replace(',', '.');
        } else {
          cleaned = cleaned.replace(/,/g, '');
        }
      }

      const value = parseFloat(cleaned) || 0;
      return isNegative ? -value : value;
    } catch (error) {
      console.warn('Erro ao parsear valor:', valueStr, error);
      return 0;
    }
  }

  /**
   * Verifica se o texto parece uma data
   * @param {string} text
   * @returns {boolean}
   */
  _isDateLike(text) {
    const datePatterns = [
      /\d{1,2}[\/\-]\d{1,2}[\/\-]\d{4}/,
      /\d{4}[\/\-]\d{1,2}[\/\-]\d{1,2}/,
      /\d{1,2}\.\d{1,2}\.\d{4}/
    ];
    return datePatterns.some(pattern => pattern.test(text));
  }

  /**
   * Verifica se o texto parece um valor monetário
   * @param {string} text
   * @returns {boolean}
   */
  _isValueLike(text) {
    const cleanText = text.replace(/[R$\s]/g, '');
    return /^-?\d+[,.]?\d*$/.test(cleanText);
  }

  /**
   * Limpa texto do arquivo
   * @param {string} text
   * @returns {string}
   */
  _cleanText(text) {
    return text
      .replace(/\r\n/g, '\n')
      .replace(/\r/g, '\n')
      .replace(/\0/g, '')
      .trim();
  }

  /**
   * Gera metadados do arquivo
   * @param {string} fileName
   * @param {string} content
   * @returns {Object}
   */
  _getMetadata(fileName, content) {
    return {
      fileName: fileName,
      fileType: 'CSV',
      contentLength: content.length,
      extractedAt: new Date().toISOString(),
      version: '1.0'
    };
  }
}

// Exportar para uso global
if (typeof window !== 'undefined') {
  window.CSVExtractor = CSVExtractor;
}