// PDFExtractor para iPoupei Mobile
// Extractor para arquivos PDF com suporte avançado a múltiplos formatos
// Adaptado do projeto React para Flutter/JS sem ES6 imports
// Versão completa com parsing sofisticado do Nubank e outros bancos

/**
 * Extractor para arquivos PDF com suporte a múltiplos formatos
 * Suporta tanto layout tabular quanto linear, incluindo faturas Nubank
 */
class PDFExtractor {
  /**
   * Verifica se pode processar o arquivo
   * @param {string} fileName
   * @returns {boolean}
   */
  static canHandle(fileName) {
    const name = fileName.toLowerCase();
    const fileType = fileName.toLowerCase();

    return name.endsWith('.pdf') || fileType.includes('pdf');
  }

  /**
   * Extrai dados brutos do arquivo PDF via base64
   * @param {string} fileName
   * @param {string} base64Content
   * @returns {Promise<Object>}
   */
  extractFromBase64(fileName, base64Content) {
    try {
      console.log('📄 PDFExtractor: Iniciando extração de', fileName);

      // Mock para desenvolvimento - em produção precisaria de pdf.js
      const mockContent = this._mockPDFExtraction(fileName, base64Content);

      const result = {
        rawText: mockContent,
        lines: mockContent.split('\n').filter(line => line.trim()),
        analysis: {
          formatType: 'pdf',
          separator: null,
          hasHeader: false,
          columnCount: 0,
          pagesProcessed: 1
        },
        metadata: this._getMetadata(fileName, mockContent)
      };

      console.log('✅ PDFExtractor: Extração concluída', {
        totalLines: result.lines.length,
        formatType: result.analysis.formatType,
        pagesProcessed: result.analysis.pagesProcessed
      });

      return result;

    } catch (error) {
      console.error('❌ PDFExtractor: Erro na extração:', error);
      throw new Error(`Erro ao extrair dados do PDF: ${error.message}`);
    }
  }

  /**
   * Valida os dados extraídos do PDF
   * @param {Object} rawData
   * @returns {Object}
   */
  static validate(rawData) {
    const errors = [];
    const warnings = [];

    if (!rawData.rawText || rawData.rawText.trim().length === 0) {
      errors.push('Nenhum texto foi extraído do PDF');
    }

    if (rawData.rawText && rawData.rawText.length < 100) {
      warnings.push('Texto extraído é muito curto - pode não conter dados suficientes');
    }

    return {
      isValid: errors.length === 0,
      errors,
      warnings
    };
  }

  /**
   * ✅ FUNÇÃO HÍBRIDA MELHORADA - Funciona com múltiplos formatos incluindo Nubank
   * @param {Object} rawData
   * @param {Object} context
   * @returns {Array<Object>}
   */
  parseTransactions(rawData, context = {}) {
    const { rawText, lines } = rawData;
    const {
      tipoImportacao = 'conta',
      contaId = '',
      cartaoId = '',
      faturaVencimento = ''
    } = context;

    console.log('🔄 PDFExtractor: Analisando transações - VERSÃO MELHORADA COM SUPORTE NUBANK');
    console.log('📄 Texto total extraído:', rawText ? rawText.length : 0, 'caracteres');

    // Detectar formato do PDF
    const formato = this._detectarFormato(rawText || lines.join('\n'));
    console.log('📋 Formato detectado:', formato);

    // Usar parser apropriado
    if (formato === 'nubank') {
      return this._analisarFaturaNubank(rawText || lines.join('\n'), context);
    } else if (formato === 'fatura_cartao') {
      return this._analisarFaturaCartao(rawText || lines.join('\n'), context);
    } else if (formato === 'tabular') {
      return this._analisarTransacoesTabular(rawText || lines.join('\n'), context);
    } else {
      return this._analisarTransacoesLinear(rawText || lines.join('\n'), context);
    }
  }

  /**
   * ✅ FUNÇÃO MELHORADA: Detecta o formato do PDF incluindo Nubank
   * @param {string} texto
   * @returns {string}
   */
  _detectarFormato(texto) {
    const linhas = texto.split('\n');
    let scoreNubank = 0;
    let scoreFaturaCartao = 0;
    let scoreTabular = 0;
    let scoreLinear = 0;

    for (const linha of linhas) {
      const linhaNorm = linha.toLowerCase().trim();

      // ✅ NOVO: Indicadores específicos do Nubank
      if (/nubank|nu pagamentos/.test(linhaNorm)) {
        scoreNubank += 5;
      }
      if (/\d{2}\s+(abr|mai|jun|jul|ago|set|out|nov|dez)\s+••••\s+\d{4}\s+/.test(linha)) {
        scoreNubank += 4;
      }
      if (/^\d{2}\s+(abr|mai|jun|jul|ago|set|out|nov|dez)\s+••••/.test(linha)) {
        scoreNubank += 3;
      }
      if (/douglas oliveira|fatura anterior|pagamento recebido/.test(linhaNorm)) {
        scoreNubank += 2;
      }
      if (/transações de \d{2} [a-z]{3} a \d{2} [a-z]{3}/i.test(linha)) {
        scoreNubank += 3;
      }

      // Indicadores de fatura de cartão (formato antigo)
      if (/\d{2}\/\d{2}\s+[A-Z\s]+\d{1,3}(?:\.\d{3})*,\d{2}/.test(linha)) {
        scoreFaturaCartao += 3;
      }
      if (/estabelecimento|alimentação|vestuário|hobby|saúde/.test(linhaNorm)) {
        scoreFaturaCartao += 2;
      }
      if (/mastercard|visa|cartão/.test(linhaNorm)) {
        scoreFaturaCartao += 2;
      }

      // Indicadores de formato tabular (outros formatos)
      if (/\d{1,2}\s*\/\s*(jan|fev|mar|abr|mai|jun|jul|ago|set|out|nov|dez)\s+.+?\s+R\$\s*\d{1,3}(?:\.\d{3})*,\d{2}/i.test(linha)) {
        scoreTabular += 2;
      }
      if (/data\s+lançamento\s+valor/i.test(linha)) {
        scoreTabular += 3;
      }

      // Indicadores de formato linear (formato antigo)
      if (/\d{2}\/\d{2}\s+[A-Z\s]+\d{2}\/\d{2}\s+\d{1,3}(?:\.\d{3})*,\d{2}/.test(linha)) {
        scoreLinear += 2;
      }
      if (/DATA\s+ESTABELECIMENTO\s+VALOR/i.test(linha)) {
        scoreLinear += 3;
      }
    }

    console.log('🔍 Scores de formato:', { scoreNubank, scoreFaturaCartao, scoreTabular, scoreLinear });

    if (scoreNubank > Math.max(scoreFaturaCartao, scoreTabular, scoreLinear)) {
      return 'nubank';
    } else if (scoreFaturaCartao > scoreTabular && scoreFaturaCartao > scoreLinear) {
      return 'fatura_cartao';
    } else if (scoreTabular > scoreLinear) {
      return 'tabular';
    } else {
      return 'linear';
    }
  }

  /**
   * ✅ NOVA FUNÇÃO HÍBRIDA: Parser que combina múltiplas estratégias SEM DUPLICATAS
   * @param {string} texto
   * @param {Object} context
   * @returns {Array}
   */
  _analisarFaturaNubank(texto, context = {}) {
    console.log('💜 ANALISANDO NUBANK - VERSÃO SEM DUPLICATAS');
    console.log('📄 TEXTO COMPLETO DO PDF:');
    console.log('='.repeat(50));
    console.log(texto);
    console.log('='.repeat(50));

    // ✅ ESTRATÉGIA 1: Análise linha por linha (mais precisa)
    const transacoesLinhaALinha = this._analisarNubankLinhaALinha(texto);
    console.log(`📋 Estratégia 1 (linha a linha): ${transacoesLinhaALinha.length} transações`);

    // ✅ ESTRATÉGIA 2: Regex globais (mais abrangente)
    const transacoesRegex = this._analisarNubankRegexGlobal(texto);
    console.log(`🔍 Estratégia 2 (regex global): ${transacoesRegex.length} transações`);

    // ✅ ESTRATÉGIA 3: Busca por padrões específicos conhecidos
    const transacoesEspecificas = this._analisarNubankPadroesEspecificos(texto);
    console.log(`🎯 Estratégia 3 (padrões específicos): ${transacoesEspecificas.length} transações`);

    // ✅ MESCLAR RESULTADOS COM ALGORITMO INTELIGENTE ANTI-DUPLICATAS
    const transacoesMescladas = this._mesclarTransacoesSemDuplicatas([
      ...transacoesLinhaALinha,
      ...transacoesRegex,
      ...transacoesEspecificas
    ]);

    // ✅ FILTRAR TRANSAÇÕES INVÁLIDAS
    const transacoesValidas = transacoesMescladas.filter(t => this._isTransacaoValidaNubank(t));

    console.log(`💜 RESULTADO FINAL: ${transacoesValidas.length} transações válidas`);

    // Mostrar transações finais para debug
    transacoesValidas.forEach((t, i) => {
      console.log(`${i+1}. ${t.data} | "${t.descricao}" | R$ ${t.valor.toFixed(2)}`);
    });

    return this._finalizarTransacoes(transacoesValidas, context);
  }

  /**
   * ✅ NOVA FUNÇÃO: Mescla transações removendo duplicatas inteligentemente
   * @param {Array} todasTransacoes
   * @returns {Array}
   */
  _mesclarTransacoesSemDuplicatas(todasTransacoes) {
    const transacoesUnicas = [];

    for (const transacao of todasTransacoes) {
      // Verificar se já existe uma transação muito similar
      const duplicataIndex = transacoesUnicas.findIndex(existente =>
        this._saoTransacoesDuplicatas(existente, transacao)
      );

      if (duplicataIndex === -1) {
        // Não é duplicata, adicionar
        transacoesUnicas.push(transacao);
        console.log(`➕ Nova: ${transacao.descricao} | R$ ${transacao.valor.toFixed(2)}`);
      } else {
        // É duplicata, manter a melhor descrição
        const existente = transacoesUnicas[duplicataIndex];
        if (this._qualTransacaoEhMelhor(transacao, existente)) {
          transacoesUnicas[duplicataIndex] = transacao;
          console.log(`🔄 Substituída: "${existente.descricao}" → "${transacao.descricao}"`);
        } else {
          console.log(`❌ Duplicata ignorada: ${transacao.descricao}`);
        }
      }
    }

    return transacoesUnicas;
  }

  /**
   * ✅ NOVA FUNÇÃO: Verifica se duas transações são duplicatas
   * @param {Object} t1
   * @param {Object} t2
   * @returns {boolean}
   */
  _saoTransacoesDuplicatas(t1, t2) {
    // 1. Mesma data
    if (t1.data !== t2.data) return false;

    // 2. Valores muito próximos (diferença menor que R$ 0.01)
    if (Math.abs(t1.valor - t2.valor) > 0.01) return false;

    // 3. Descrições similares
    return this._descricoesSaoSimilares(t1.descricao, t2.descricao);
  }

  /**
   * ✅ NOVA FUNÇÃO: Verifica se descrições são similares (melhorada)
   * @param {string} desc1
   * @param {string} desc2
   * @returns {boolean}
   */
  _descricoesSaoSimilares(desc1, desc2) {
    if (!desc1 || !desc2) return false;

    // Normalizar para comparação
    const normalize = (str) => str.toLowerCase()
      .replace(/[^a-z0-9]/g, '')
      .trim();

    const norm1 = normalize(desc1);
    const norm2 = normalize(desc2);

    // Exatamente iguais após normalização
    if (norm1 === norm2) return true;

    // Uma contém a outra (mínimo 80% de similaridade)
    const minLength = Math.min(norm1.length, norm2.length);
    if (minLength < 3) return false;

    const maxLength = Math.max(norm1.length, norm2.length);
    const similarity = minLength / maxLength;

    return similarity >= 0.8 && (norm1.includes(norm2) || norm2.includes(norm1));
  }

  /**
   * ✅ NOVA FUNÇÃO: Determina qual transação tem melhor qualidade
   * @param {Object} t1
   * @param {Object} t2
   * @returns {boolean} true se t1 é melhor que t2
   */
  _qualTransacaoEhMelhor(t1, t2) {
    // 1. Preferir descrição mais longa (mais completa)
    if (t1.descricao.length !== t2.descricao.length) {
      return t1.descricao.length > t2.descricao.length;
    }

    // 2. Preferir descrição que não seja fragmento óbvio
    const t1EhFragmento = /^[a-z]{1,3}$|^[a-z]*[0-9]+$/.test(t1.descricao);
    const t2EhFragmento = /^[a-z]{1,3}$|^[a-z]*[0-9]+$/.test(t2.descricao);

    if (t1EhFragmento !== t2EhFragmento) {
      return !t1EhFragmento; // Preferir a que NÃO é fragmento
    }

    // 3. Preferir descrição com mais informação (pontuação, espaços)
    const t1Info = (t1.descricao.match(/[.\-*/]/g) || []).length;
    const t2Info = (t2.descricao.match(/[.\-*/]/g) || []).length;

    return t1Info >= t2Info;
  }

  /**
   * ✅ NOVA FUNÇÃO: Valida se transação é legítima
   * @param {Object} transacao
   * @returns {boolean}
   */
  _isTransacaoValidaNubank(transacao) {
    if (!transacao || !transacao.descricao || !transacao.valor) return false;

    const desc = transacao.descricao.trim();

    // ✅ FILTROS RIGOROSOS PARA REMOVER LIXO
    const invalidPatterns = [
      // Cabeçalhos e totais
      /^(Douglas Oliveira|Fatura|Total|Subtotal|Saldo|Pagamento)$/i,
      /^(RESUMO DA FATURA|ATUAL|Limite total)/i,
      /^(TRANSAÇÕES|DE \d{2} [A-Z]{3} A \d{2})/i,

      // Datas isoladas
      /^\d{1,2}\s+(ABR|MAI|JUN|JUL|AGO|SET|OUT|NOV|DEZ)$/i,
      /^\d{2}\/\d{2}\/\d{4}$/,

      // Valores e códigos
      /^R\$\s*\d/,
      /^\d+$/,
      /^[R$\s\d,.-]+$/,

      // Fragmentos muito pequenos
      /^[a-z]{1,2}$/i,
      /^[aeiou]$/i,

      // Texto de cabeçalho específico do Nubank
      /^a \d{2} [A-Z]{3}$/i,
      /Limite total do cartão/i,
      /crédito:/i,
      /que o pagamento/i,
      /em aberto/i,
      /próxima fatura/i,

      // Códigos técnicos
      /^\d{4}$/,
      /^••••/,
      /^[A-Z]{2,}\d+$/
    ];

    // Verificar padrões inválidos
    if (invalidPatterns.some(pattern => pattern.test(desc))) {
      console.log(`❌ Transação inválida (padrão): "${desc}"`);
      return false;
    }

    // Deve ter pelo menos 2 caracteres alfanuméricos
    const alphanumeric = desc.replace(/[^a-zA-Z0-9]/g, '');
    if (alphanumeric.length < 2) {
      console.log(`❌ Transação inválida (muito curta): "${desc}"`);
      return false;
    }

    // Valor deve ser razoável (entre R$ 0.01 e R$ 50.000)
    if (transacao.valor < 0.01 || transacao.valor > 50000) {
      console.log(`❌ Transação inválida (valor): "${desc}" | R$ ${transacao.valor}`);
      return false;
    }

    return true;
  }

  /**
   * ✅ ESTRATÉGIA 1: Análise linha por linha
   * @param {string} texto
   * @returns {Array}
   */
  _analisarNubankLinhaALinha(texto) {
    const transacoes = [];
    const linhas = texto.split('\n');
    let dentroSecaoTransacoes = false;

    console.log('🔍 Analisando Nubank linha a linha...');

    for (let i = 0; i < linhas.length; i++) {
      const linha = linhas[i].trim();

      // Detectar início da seção de movimentações (conta corrente)
      if (/Movimentações/i.test(linha)) {
        dentroSecaoTransacoes = true;
        console.log('✅ Seção Movimentações encontrada!');
        continue;
      }

      // Detectar início da seção de transações (cartão de crédito)
      if (/TRANSAÇÕES.*DE \d{2} [A-Z]{3} A \d{2} [A-Z]{3}/i.test(linha) ||
          (linha.includes('TRANSAÇÕES') && linha.includes('Douglas'))) {
        dentroSecaoTransacoes = true;
        console.log('✅ Seção TRANSAÇÕES encontrada!');
        continue;
      }

      if (/Pagamentos e Financiamentos/i.test(linha)) {
        dentroSecaoTransacoes = false;
        break;
      }

      if (!dentroSecaoTransacoes || linha.length < 10) continue;

      if (/^(Douglas Oliveira|R\$ \d|O saldo)/i.test(linha)) continue;

      console.log(`🔍 Testando linha: "${linha}"`);

      // PADRÃO 1: Conta corrente - "08 MAI 2025 Total de entradas + 500,00"
      const matchConta = linha.match(/^(\d{1,2}\s+(?:JAN|FEV|MAR|ABR|MAI|JUN|JUL|AGO|SET|OUT|NOV|DEZ)\s+\d{4})\s+(.+?)\s*([+-])\s*(\d{1,3}(?:\.\d{3})*,\d{2})$/i);

      if (matchConta) {
        const [, dataStr, descricao, sinal, valorStr] = matchConta;
        console.log(`✅ Match conta: data="${dataStr}", desc="${descricao}", sinal="${sinal}", valor="${valorStr}"`);

        const transacao = this._criarTransacaoNubankConta(dataStr, descricao.trim(), valorStr, sinal);
        if (transacao) {
          transacoes.push(transacao);
        }
        continue;
      }

      // PADRÃO 2: Cartão de crédito - "DD MMM •••• NNNN DESCRIÇÃO R$ VALOR"
      const matchCartao = linha.match(/^(\d{1,2}\s+(?:ABR|MAI|JUN|JUL|AGO|SET|OUT|NOV|DEZ))\s+••••\s+\d{4}\s+(.+?)\s+R\$\s*(\d{1,3}(?:\.\d{3})*,\d{2})$/i);

      if (matchCartao) {
        const [, dataStr, descricao, valorStr] = matchCartao;
        console.log(`✅ Match cartão: data="${dataStr}", desc="${descricao}", valor="${valorStr}"`);

        const transacao = this._criarTransacaoNubankPrecisa(dataStr, descricao.trim(), valorStr);
        if (transacao) {
          transacoes.push(transacao);
        }
      }
    }

    console.log(`🎯 Linha a linha encontrou: ${transacoes.length} transações`);
    return transacoes;
  }

  /**
   * ✅ ESTRATÉGIA 2: Regex globais mais agressivas
   * @param {string} texto
   * @returns {Array}
   */
  _analisarNubankRegexGlobal(texto) {
    const transacoes = [];

    const padroes = [
      // PADRÕES PARA CONTA CORRENTE
      // Padrão 1: Conta - "08 MAI 2025 Total de entradas + 500,00"
      /(\d{1,2}\s+(?:JAN|FEV|MAR|ABR|MAI|JUN|JUL|AGO|SET|OUT|NOV|DEZ)\s+\d{4})\s+(.+?)\s*([+-])\s*(\d{1,3}(?:\.\d{3})*,\d{2})/gi,

      // PADRÕES PARA CARTÃO DE CRÉDITO
      // Padrão 2: Com cartão mascarado
      /(\d{1,2}\s+(?:ABR|MAI|JUN|JUL|AGO|SET|OUT|NOV|DEZ))\s+••••\s+\d{4}\s+([^R$\n]+?)\s+R\$\s*(\d{1,3}(?:\.\d{3})*,\d{2})/gi,

      // Padrão 3: IOF
      /(\d{1,2}\s+(?:ABR|MAI|JUN|JUL|AGO|SET|OUT|NOV|DEZ))\s+IOF de\s+"([^"]+)"\s+R\$\s*(\d{1,3}(?:\.\d{3})*,\d{2})/gi,

      // Padrão 4: Sem cartão mascarado (mais flexível)
      /(\d{1,2}\s+(?:ABR|MAI|JUN|JUL|AGO|SET|OUT|NOV|DEZ))\s+([A-Za-z][^R$\n]*?)\s+R\$\s*(\d{1,3}(?:\.\d{3})*,\d{2})/gi,

      // Padrão 5: Ainda mais flexível
      /(\d{1,2}\s+(?:ABR|MAI|JUN|JUL|AGO|SET|OUT|NOV|DEZ))\s+(.{3,50}?)\s+R\$\s*(\d{1,3}(?:\.\d{3})*,\d{2})/gi
    ];

    for (let i = 0; i < padroes.length; i++) {
      const padrao = padroes[i];
      const matches = [...texto.matchAll(padrao)];

      console.log(`🔍 Padrão ${i + 1}: ${matches.length} matches`);

      for (const match of matches) {
        if (i === 0) {
          // Padrão de conta corrente: [full, data, descricao, sinal, valor]
          const [, dataStr, descricaoBruta, sinal, valorStr] = match;

          console.log(`✅ Match conta: "${dataStr}" | "${descricaoBruta}" | "${sinal}" | "${valorStr}"`);

          let descricao = descricaoBruta.trim();

          if (descricao.length >= 2) {
            const transacao = this._criarTransacaoNubankConta(dataStr, descricao, valorStr, sinal);
            if (transacao) {
              transacoes.push(transacao);
            }
          }
        } else {
          // Padrões de cartão de crédito: [full, data, descricao, valor]
          const [, dataStr, descricaoBruta, valorStr] = match;

          console.log(`✅ Match cartão: "${dataStr}" | "${descricaoBruta}" | "${valorStr}"`);

          // Limpar descrição minimamente
          let descricao = descricaoBruta.trim()
            .replace(/••••\s*\d{4}\s*/, '')
            .replace(/IOF de\s*"?/, 'IOF - ')
            .replace(/"$/, '')
            .trim();

          if (descricao.length >= 2 && this._isValidDescricaoNubank(descricao)) {
            const transacao = this._criarTransacaoNubankPrecisa(dataStr, descricao, valorStr);
            if (transacao) {
              transacoes.push(transacao);
            }
          }
        }
      }
    }

    return transacoes;
  }

  /**
   * ✅ ESTRATÉGIA 3: Busca por padrões específicos conhecidos
   * @param {string} texto
   * @returns {Array}
   */
  _analisarNubankPadroesEspecificos(texto) {
    const transacoes = [];

    // Lista de estabelecimentos conhecidos que devem aparecer na fatura
    const estabelecimentosConhecidos = [
      'Azul Seguro Auto',
      'Amazon',
      'Mp \\*Palhacada',
      'O Tambore',
      'Apple\\.Com/Bill',
      'Tokio Marine\\*Auto',
      'Ppro \\*Microsoft',
      'Claude\\.Ai Subscription',
      'Uber\\* Trip'
    ];

    for (const estabelecimento of estabelecimentosConhecidos) {
      // Buscar padrão: DATA ... ESTABELECIMENTO ... VALOR
      const regex = new RegExp(
        `(\\d{1,2}\\s+(?:ABR|MAI|JUN|JUL|AGO|SET|OUT|NOV|DEZ))\\s+.*?${estabelecimento}.*?R\\$\\s*(\\d{1,3}(?:\\.\\d{3})*,\\d{2})`,
        'gi'
      );

      const matches = [...texto.matchAll(regex)];

      for (const match of matches) {
        const [textoCompleto, dataStr, valorStr] = match;

        // Extrair o nome do estabelecimento do texto completo
        const nomeMatch = textoCompleto.match(new RegExp(`(${estabelecimento}[^R$]*?)(?:\\s+R\\$|$)`, 'i'));
        const nomeEstabelecimento = nomeMatch ? nomeMatch[1].trim() : estabelecimento.replace(/\\/g, '');

        const transacao = this._criarTransacaoNubankPrecisa(dataStr, nomeEstabelecimento, valorStr);
        if (transacao) {
          transacoes.push(transacao);
        }
      }
    }

    return transacoes;
  }

  /**
   * ✅ NOVA FUNÇÃO: Cria transação Nubank sem limpeza agressiva
   * @param {string} dataStr
   * @param {string} descricao
   * @param {string} valorStr
   * @returns {Object|null}
   */
  _criarTransacaoNubankPrecisa(dataStr, descricao, valorStr) {
    try {
      const valor = this._parseValue(valorStr);
      if (valor <= 0) {
        console.log(`   ❌ Valor inválido: ${valor}`);
        return null;
      }

      const dataFormatada = this._converterDataNubank(dataStr);

      return {
        id: Date.now() + Math.random(),
        data: dataFormatada,
        descricao: descricao, // SEM LIMPEZA - exatamente como veio
        valor: Math.abs(valor),
        tipo: 'despesa',
        categoria_id: '',
        categoriaTexto: '',
        subcategoria_id: '',
        subcategoriaTexto: '',
        conta_id: '',
        efetivado: true,
        observacoes: 'Importado via PDF (fatura Nubank)',
        origem: 'PDF',
        validada: false
      };
    } catch (error) {
      console.warn('⚠️ Erro ao criar transação Nubank:', error.message);
      return null;
    }
  }

  /**
   * ✅ NOVA FUNÇÃO: Criar transação para conta corrente Nubank
   * @param {string} dataStr - Data no formato "08 MAI 2025"
   * @param {string} descricao - Descrição da transação
   * @param {string} valorStr - Valor no formato "500,00"
   * @param {string} sinal - "+" ou "-"
   * @returns {Object|null}
   */
  _criarTransacaoNubankConta(dataStr, descricao, valorStr, sinal) {
    try {
      const valor = this._parseValue(valorStr);
      if (valor <= 0) {
        console.log(`   ❌ Valor inválido: ${valor}`);
        return null;
      }

      const dataFormatada = this._converterDataNubank(dataStr);

      return {
        id: Date.now() + Math.random(),
        data: dataFormatada,
        descricao: descricao,
        valor: Math.abs(valor),
        tipo: sinal === '+' ? 'receita' : 'despesa',
        categoria_id: '',
        categoriaTexto: '',
        subcategoria_id: '',
        subcategoriaTexto: '',
        conta_id: '',
        efetivado: true,
        observacoes: 'Importado via PDF (conta Nubank)',
        origem: 'PDF',
        validada: false
      };
    } catch (error) {
      console.warn('⚠️ Erro ao criar transação Nubank conta:', error.message);
      return null;
    }
  }

  /**
   * ✅ NOVA FUNÇÃO: Validação mínima para descrições
   * @param {string} descricao
   * @returns {boolean}
   */
  _isValidDescricaoNubank(descricao) {
    if (!descricao || descricao.length < 2) return false;

    // Rejeitar apenas padrões óbvios que não são estabelecimentos
    const invalidPatterns = [
      /^(Douglas Oliveira|R\$ \d|Total|Subtotal|Pagamento)$/i,
      /^\d+$/,
      /^[R$\s\d,.-]+$/,
      /^[•\s]+$/
    ];

    return !invalidPatterns.some(pattern => pattern.test(descricao));
  }

  /**
   * ✅ NOVA FUNÇÃO: Converte data do Nubank (DD MMM para YYYY-MM-DD)
   * @param {string} dataStr
   * @returns {string}
   */
  _converterDataNubank(dataStr) {
    const [dia, mesAbrev] = dataStr.trim().split(/\s+/);

    const meses = {
      'ABR': '04', 'MAI': '05', 'JUN': '06', 'JUL': '07',
      'AGO': '08', 'SET': '09', 'OUT': '10', 'NOV': '11', 'DEZ': '12'
    };

    const mes = meses[mesAbrev.toUpperCase()];
    if (!mes) {
      console.warn('⚠️ Mês não reconhecido:', mesAbrev);
      return new Date().toISOString().split('T')[0]; // Fallback para hoje
    }

    const anoAtual = new Date().getFullYear();
    return `${anoAtual}-${mes}-${dia.padStart(2, '0')}`;
  }

  /**
   * ✅ FUNÇÃO ORIGINAL: Parser específico para fatura de cartão (baseado no PDF original)
   * @param {string} texto
   * @param {Object} context
   * @returns {Array}
   */
  _analisarFaturaCartao(texto, context = {}) {
    const transacoes = [];

    console.log('💳 Analisando FATURA DE CARTÃO');
    console.log('📄 Primeiros 500 caracteres do texto:');
    console.log(texto.substring(0, 500));

    // ✅ USAR REGEX GLOBAL NO TEXTO INTEIRO ao invés de processar linha por linha
    // Padrões para capturar transações diretamente do texto completo
    const padroes = [
      // Padrão 1: DD/MM ESTABELECIMENTO VALOR (formato principal)
      /(\d{2}\/\d{2})\s+([A-Z][A-Z\s\*\-\.0-9]+?)\s+(\d{1,3}(?:\.\d{3})*,\d{2})/g,

      // Padrão 2: DD/MM ESTABELECIMENTO VALOR com possíveis caracteres especiais
      /(\d{2}\/\d{2})\s+([A-Z\*][A-Z\s\*\-\.0-9\/]+?)\s+(\d{1,3}(?:\.\d{3})*,\d{2})/g,

      // Padrão 3: Mais flexível para capturar estabelecimentos com números
      /(\d{2}\/\d{2})\s+([A-Z][A-Z\s\*\-\.0-9\/]{3,50}?)\s+(\d{1,3}(?:\.\d{3})*,\d{2})/g
    ];

    console.log('🔍 Testando padrões regex...');

    for (let p = 0; p < padroes.length; p++) {
      const padrao = padroes[p];
      console.log(`\n🔍 Testando padrão ${p + 1}:`, padrao);

      const matches = [...texto.matchAll(padrao)];
      console.log(`   Encontrados ${matches.length} matches`);

      for (const match of matches) {
        try {
          const [textoCompleto, data, estabelecimento, valorStr] = match;

          console.log(`   📝 Match bruto: "${textoCompleto}"`);
          console.log(`   📅 Data: "${data}"`);
          console.log(`   🏪 Estabelecimento bruto: "${estabelecimento}"`);
          console.log(`   💰 Valor: "${valorStr}"`);

          // Limpar estabelecimento
          const estabelecimentoLimpo = this._limparEstabelecimento(estabelecimento);
          console.log(`   🧹 Estabelecimento limpo: "${estabelecimentoLimpo}"`);

          if (!this._isValidEstabelecimento(estabelecimentoLimpo)) {
            console.log(`   ❌ Estabelecimento inválido: "${estabelecimentoLimpo}"`);
            continue;
          }

          const valor = this._parseValue(valorStr);
          if (valor <= 0) {
            console.log(`   ❌ Valor inválido: ${valor}`);
            continue;
          }

          const dataFormatada = this._converterDataCartao(data);

          // ✅ NÃO capturar categoria - deixar sempre vazio conforme solicitado
          const categoria = ''; // Sempre vazio

          console.log(`   📂 Categoria: deixada vazia conforme solicitado`);

          const transacao = {
            id: Date.now() + Math.random(),
            data: dataFormatada,
            descricao: estabelecimentoLimpo,
            valor: Math.abs(valor),
            tipo: 'despesa',
            categoria_id: '',
            categoriaTexto: '', // Sempre vazio
            subcategoria_id: '',
            subcategoriaTexto: '',
            conta_id: context.contaId || '',
            cartao_id: context.cartaoId || '',
            fatura_vencimento: context.faturaVencimento || '',
            efetivado: true,
            observacoes: 'Importado via PDF (fatura cartão)',
            origem: 'PDF',
            validada: false
          };

          transacoes.push(transacao);

          console.log(`   ✅ Transação criada: ${dataFormatada} | ${estabelecimentoLimpo} | R$ ${valor}`);

        } catch (error) {
          console.warn('⚠️ Erro ao processar match de fatura:', error.message);
        }
      }

      // Se encontrou transações com este padrão, parar de testar outros
      if (transacoes.length > 0) {
        console.log(`✅ Padrão ${p + 1} funcionou! Encontradas ${transacoes.length} transações`);
        break;
      }
    }

    // ✅ FALLBACK: Se não encontrou nada, tentar padrão mais simples
    if (transacoes.length === 0) {
      console.log('🔄 Tentando padrão fallback mais simples...');

      const fallbackPadrao = /(\d{2}\/\d{2})\s+(.+?)\s+(\d{1,3}(?:\.\d{3})*,\d{2})/g;
      const fallbackMatches = [...texto.matchAll(fallbackPadrao)];

      console.log(`🔍 Padrão fallback encontrou ${fallbackMatches.length} matches`);

      for (const match of fallbackMatches.slice(0, 10)) { // Limitar a 10 para evitar spam
        const [textoCompleto, data, estabelecimento, valorStr] = match;

        const estabelecimentoLimpo = this._limparEstabelecimento(estabelecimento);

        if (this._isValidEstabelecimento(estabelecimentoLimpo) &&
            !this._isHeaderOrFooter(textoCompleto)) {

          const valor = this._parseValue(valorStr);
          if (valor > 0) {
            console.log(`🎯 Fallback match: ${data} | ${estabelecimentoLimpo} | ${valorStr}`);

            transacoes.push({
              id: Date.now() + Math.random(),
              data: this._converterDataCartao(data),
              descricao: estabelecimentoLimpo,
              valor: Math.abs(valor),
              tipo: 'despesa',
              categoria_id: '',
              categoriaTexto: '', // Sempre vazio
              subcategoria_id: '',
              subcategoriaTexto: '',
              conta_id: context.contaId || '',
              cartao_id: context.cartaoId || '',
              fatura_vencimento: context.faturaVencimento || '',
              efetivado: true,
              observacoes: 'Importado via PDF (fatura cartão - fallback)',
              origem: 'PDF',
              validada: false
            });
          }
        }
      }
    }

    return this._finalizarTransacoes(transacoes, context);
  }

  /**
   * ✅ FUNÇÃO MELHORADA: Parser para formato tabular (outros formatos)
   * @param {string} texto
   * @param {Object} context
   * @returns {Array}
   */
  _analisarTransacoesTabular(texto, context = {}) {
    const transacoes = [];

    console.log('📋 Analisando formato TABULAR');

    // Padrões mais específicos para formato tabular
    const padroes = [
      // Padrão 1: DD / MMM DESCRIÇÃO R$ VALOR
      {
        regex: /(\d{1,2})\s*\/\s*(jan|fev|mar|abr|mai|jun|jul|ago|set|out|nov|dez)\s+(.+?)\s+R\$?\s*(\d{1,3}(?:\.\d{3})*,\d{2})/gi,
        grupos: { dia: 1, mes: 2, descricao: 3, valor: 4 }
      },
      // Padrão 2: DD / MMM DESCRIÇÃO VALOR (sem R$)
      {
        regex: /(\d{1,2})\s*\/\s*(jan|fev|mar|abr|mai|jun|jul|ago|set|out|nov|dez)\s+(.+?)\s+(\d{1,3}(?:\.\d{3})*,\d{2})\s*$/gi,
        grupos: { dia: 1, mes: 2, descricao: 3, valor: 4 }
      }
    ];

    for (const padrao of padroes) {
      const matches = [...texto.matchAll(padrao.regex)];

      for (const match of matches) {
        try {
          const dia = match[padrao.grupos.dia].padStart(2, '0');
          const mesAbrev = match[padrao.grupos.mes].toLowerCase();
          const descricao = match[padrao.grupos.descricao].trim();
          const valorStr = match[padrao.grupos.valor];

          // Converter mês abreviado para número
          const meses = {
            'jan': '01', 'fev': '02', 'mar': '03', 'abr': '04',
            'mai': '05', 'jun': '06', 'jul': '07', 'ago': '08',
            'set': '09', 'out': '10', 'nov': '11', 'dez': '12'
          };

          const mes = meses[mesAbrev];
          if (!mes) continue;

          const descricaoLimpa = this._limparDescricao(descricao);
          if (!this._isValidDescription(descricaoLimpa)) continue;

          const valor = this._parseValue(valorStr);
          if (valor <= 0) continue;

          const anoAtual = new Date().getFullYear();
          const dataFormatada = `${anoAtual}-${mes}-${dia}`;
          const tipo = valor >= 0 ? 'despesa' : 'receita';

          transacoes.push({
            id: Date.now() + Math.random(),
            data: dataFormatada,
            descricao: descricaoLimpa,
            valor: Math.abs(valor),
            tipo: tipo,
            categoria_id: '',
            categoriaTexto: '',
            subcategoria_id: '',
            subcategoriaTexto: '',
            conta_id: context.contaId || '',
            cartao_id: context.cartaoId || '',
            fatura_vencimento: context.faturaVencimento || '',
            efetivado: true,
            observacoes: 'Importado via PDF (formato tabular)',
            origem: 'PDF',
            validada: false
          });

        } catch (error) {
          console.warn('⚠️ Erro ao processar match tabular:', error.message);
        }
      }
    }

    return this._finalizarTransacoes(transacoes, context);
  }

  /**
   * ✅ FUNÇÃO ORIGINAL: Parser para formato linear (formato antigo)
   * @param {string} texto
   * @param {Object} context
   * @returns {Array}
   */
  _analisarTransacoesLinear(texto, context = {}) {
    const transacoes = [];
    const linhas = texto.split('\n');

    console.log('📋 Analisando formato LINEAR -', linhas.length, 'linhas');

    // Padrões originais que funcionam
    const padroes = [
      /(\d{2}\/\d{2}\/\d{4})\s+(.+?)\s+([+-]?\d{1,3}(?:\.\d{3})*,\d{2})/g,
      /(\d{2}\/\d{2})\s+(.+?)\s+([+-]?\d{1,3}(?:\.\d{3})*,\d{2})/g,
      /([+-]?\d{1,3}(?:\.\d{3})*,\d{2})\s+(.+?)\s+(\d{2}\/\d{2})/g,
    ];

    for (const linha of linhas) {
      for (const padrao of padroes) {
        const matches = [...linha.matchAll(padrao)];

        for (const match of matches) {
          let data, descricao, valor;

          if (padrao === padroes[0]) {
            [, data, descricao, valor] = match;
          } else if (padrao === padroes[1]) {
            [, data, descricao, valor] = match;
            data = data + '/' + new Date().getFullYear();
          } else if (padrao === padroes[2]) {
            [, valor, descricao, data] = match;
            data = data + '/' + new Date().getFullYear();
          }

          descricao = descricao.trim().replace(/\s+/g, ' ');
          valor = parseFloat(valor.replace(/\./g, '').replace(',', '.'));

          const tipo = valor >= 0 ? 'receita' : 'despesa';
          valor = Math.abs(valor);

          if (valor > 0 && descricao.length > 3) {
            transacoes.push({
              id: Date.now() + Math.random(),
              data: this._converterData(data),
              descricao: descricao,
              valor: valor,
              tipo: tipo,
              categoria_id: '',
              categoriaTexto: '',
              subcategoria_id: '',
              subcategoriaTexto: '',
              conta_id: context.contaId || '',
              cartao_id: context.cartaoId || '',
              fatura_vencimento: context.faturaVencimento || '',
              efetivado: true,
              observacoes: 'Importado via PDF (formato linear)',
              origem: 'PDF',
              validada: false
            });
          }
        }
      }
    }

    return this._finalizarTransacoes(transacoes, context);
  }

  /**
   * ✅ FUNÇÃO MELHORADA: Limpa nome do estabelecimento
   * @param {string} estabelecimento
   * @returns {string}
   */
  _limparEstabelecimento(estabelecimento) {
    return estabelecimento
      .replace(/\d{1,3}(?:\.\d{3})*,\d{2}.*$/, '') // Remove valor monetário e tudo após
      .replace(/R\$.*$/, '') // Remove R$ e tudo após
      .replace(/\s+(ALIMENTAÇÃO|VESTUÁRIO|HOBBY|SAÚDE|DIVERSOS|VEÍCULOS|TURISMO).*$/i, '') // Remove categorias conhecidas
      .replace(/\s+\.[A-Z\s]+$/, '') // Remove categorias com ponto
      .replace(/\s+\d{2}\/\d{2}.*$/, '') // Remove datas extras
      .replace(/\s{2,}/g, ' ') // Normaliza espaços múltiplos
      .trim()
      .substring(0, 100); // Limita tamanho
  }

  /**
   * ✅ FUNÇÃO MELHORADA: Valida nome do estabelecimento
   * @param {string} estabelecimento
   * @returns {boolean}
   */
  _isValidEstabelecimento(estabelecimento) {
    if (!estabelecimento || estabelecimento.length < 2) return false;

    // Rejeitar se contém apenas números ou caracteres especiais
    if (/^[\d\s\.,\-\*]*$/.test(estabelecimento)) return false;

    // Rejeitar headers e footers conhecidos
    const invalidPatterns = [
      /^(data|estabelecimento|valor|total|subtotal)/i,
      /^(lançamento|compra|saque)/i,
      /^ismael/i,
      /^(continua|pc\s*-|personalité)/i,
      /^(limite|encargo|juros)/i,
      /^(mastercard|visa|cartão)/i,
      /^(titular|final)/i,
      /^[A-Z]{2,}\s*\d+/, // Códigos como "VK045"
      /^\d{5,}/, // Códigos numéricos longos
      /^(com|sem)\s+(seguro|vencimento)/i,
      /^(pagamento|parcela)/i
    ];

    // Deve ter pelo menos uma letra
    if (!/[A-Za-z]/.test(estabelecimento)) return false;

    return !invalidPatterns.some(pattern => pattern.test(estabelecimento));
  }

  /**
   * ✅ NOVA FUNÇÃO: Converte data de cartão (DD/MM para YYYY-MM-DD)
   * @param {string} dataStr
   * @returns {string}
   */
  _converterDataCartao(dataStr) {
    const [dia, mes] = dataStr.split('/');
    const anoAtual = new Date().getFullYear();
    return `${anoAtual}-${mes.padStart(2, '0')}-${dia.padStart(2, '0')}`;
  }

  /**
   * ✅ FUNÇÃO MELHORADA: Verifica se linha é cabeçalho ou rodapé
   * @param {string} linha
   * @returns {boolean}
   */
  _isHeaderOrFooter(linha) {
    const linhaNorm = linha.toLowerCase().trim();

    const excludePatterns = [
      /^(data|lançamento|valor|estabelecimento)/i,
      /^(total|subtotal|saldo)/i,
      /cartão.*final/i,
      /página\s*\d+/i,
      /titular/i,
      /^ismael da s/i,
      /mastercard|visa/i,
      /^\s*-?\s*$/,
      /fatura/i,
      /^(continua|pc\s*-|personalité)/i,
      /^\d{10,}/, // Códigos longos
      /^[A-Z]{2,}\s*\d+\s*[A-Z]+/, // Códigos tipo "VK045"
      /limite|encargo|juros/i,
      /nubank|transações/i // Para Nubank
    ];

    return excludePatterns.some(pattern => pattern.test(linhaNorm)) || linhaNorm.length < 5;
  }

  /**
   * ✅ FUNÇÃO MELHORADA: Limpa descrição
   * @param {string} descricao
   * @returns {string}
   */
  _limparDescricao(descricao) {
    return descricao
      .replace(/R\$\s*[\d.,]+/g, '') // Remove valores monetários
      .replace(/\d{2}\/\d{2}(?:\/\d{4})?/g, '') // Remove datas
      .replace(/\s+/g, ' ')
      .trim()
      .substring(0, 100);
  }

  /**
   * ✅ FUNÇÃO MELHORADA: Valida descrição
   * @param {string} descricao
   * @returns {boolean}
   */
  _isValidDescription(descricao) {
    if (!descricao || descricao.length < 3) return false;

    const invalidPatterns = [
      /^(total|subtotal|saldo|data|valor)/i,
      /^\d+$/,
      /^[^a-zA-Z]*$/,
      /^(lançamento|compra)/i
    ];

    return !invalidPatterns.some(pattern => pattern.test(descricao));
  }

  /**
   * ✅ FUNÇÃO MELHORADA: Parse de valor
   * @param {string} valorStr
   * @returns {number}
   */
  _parseValue(valorStr) {
    if (!valorStr) return 0;

    let valorLimpo = valorStr
      .replace(/R\$/g, '')
      .replace(/[^\d,.-]/g, '')
      .trim();

    const isNegativo = valorStr.includes('-') || valorStr.includes('(');
    valorLimpo = valorLimpo.replace(/[-()]/g, '');

    // Formato brasileiro: 1.234,56
    if (/\d+\.\d{3},\d{2}$/.test(valorLimpo) || /\d+,\d{2}$/.test(valorLimpo)) {
      valorLimpo = valorLimpo.replace(/\./g, '').replace(',', '.');
    }

    const valor = parseFloat(valorLimpo) || 0;
    return isNegativo ? -valor : valor;
  }

  /**
   * ✅ FUNÇÃO ORIGINAL: Converter data
   * @param {string} dataStr
   * @returns {string}
   */
  _converterData(dataStr) {
    const partes = dataStr.split('/');
    if (partes.length === 3) {
      return `${partes[2]}-${partes[1].padStart(2, '0')}-${partes[0].padStart(2, '0')}`;
    }
    return dataStr;
  }

  /**
   * ✅ FUNÇÃO MELHORADA: Finaliza processamento das transações
   * @param {Array} transacoes
   * @param {Object} context
   * @returns {Array}
   */
  _finalizarTransacoes(transacoes, context = {}) {
    // Aplicar contexto às transações
    const transacoesComContexto = transacoes.map(t => ({
      ...t,
      conta_id: t.conta_id || context.contaId || '',
      cartao_id: t.cartao_id || context.cartaoId || '',
      fatura_vencimento: t.fatura_vencimento || context.faturaVencimento || ''
    }));

    // Remover duplicatas
    const transacoesUnicas = transacoesComContexto.filter((transacao, index, self) =>
      index === self.findIndex(t =>
        t.data === transacao.data &&
        t.descricao === transacao.descricao &&
        Math.abs(t.valor - transacao.valor) < 0.01 // Comparação de float com tolerância
      )
    );

    console.log('📊 Resultado da análise melhorada:', {
      totalEncontradas: transacoes.length,
      totalUnicas: transacoesUnicas.length,
      duplicatasRemovidas: transacoes.length - transacoesUnicas.length
    });

    // Mostrar amostra das transações processadas
    if (transacoesUnicas.length > 0) {
      console.log('🔍 Amostra das transações processadas:');
      transacoesUnicas.slice(0, 5).forEach((t, i) => {
        console.log(`  ${i+1}. ${t.data} | ${t.descricao} | R$ ${t.valor.toFixed(2)} | ${t.tipo}`);
      });
    }

    return transacoesUnicas.sort((a, b) => new Date(a.data) - new Date(b.data));
  }

  /**
   * Gera estatísticas dos dados extraídos do PDF
   * @param {Object} rawData
   * @returns {Object}
   */
  static getStatistics(rawData) {
    const transactions = this.parseTransactions(rawData);
    const totalReceitas = transactions.filter(t => t.tipo === 'receita').reduce((sum, t) => sum + t.valor, 0);
    const totalDespesas = transactions.filter(t => t.tipo === 'despesa').reduce((sum, t) => sum + t.valor, 0);

    return {
      totalTextLength: rawData.rawText ? rawData.rawText.length : 0,
      totalLines: rawData.rawText ? rawData.rawText.split('\n').length : 0,
      parsedTransactions: transactions.length,
      totalReceitas: totalReceitas,
      totalDespesas: totalDespesas,
      saldoLiquido: totalReceitas - totalDespesas,
      receitas: transactions.filter(t => t.tipo === 'receita').length,
      despesas: transactions.filter(t => t.tipo === 'despesa').length
    };
  }

  // ============== MÉTODOS EXISTENTES PARA COMPATIBILIDADE ==============

  _mockPDFExtraction(fileName, base64Content) {
    // Simulação de extração de PDF
    // Em produção, use uma biblioteca real de PDF
    console.log('🔧 PDFExtractor: Simulando extração de PDF...');

    const mockContent = `
EXTRATO BANCÁRIO
Data: 01/05/2025 a 31/05/2025

Data       Descrição                    Valor
01/05/2025 PIX TRANSFERENCIA          -150.00
02/05/2025 MERCADO EXTRA               -89.50
03/05/2025 SALARIO EMPRESA XYZ       3500.00
05/05/2025 TED RECEBIDA                200.00
10/05/2025 UBER VIAGEM                 -25.30
15/05/2025 FARMACIA DROGASIL           -45.20
20/05/2025 FREELANCE PROJETO          1500.00
25/05/2025 SUPERMERCADO CARREFOUR     -120.75
30/05/2025 INVESTIMENTO APLICACAO      500.00
`;

    return mockContent;
  }

  _detectPDFType(lines) {
    const content = lines.join(' ').toLowerCase();

    if (content.includes('nubank') || content.includes('nu pagamentos')) {
      return 'fatura_nubank';
    } else if (content.includes('bradesco')) {
      return 'fatura_bradesco';
    } else if (content.includes('extrato') || content.includes('statement')) {
      return 'extrato_generic';
    }

    return 'generic_pdf';
  }

  _parseNubankInvoice(rawData, context) {
    console.log('💳 PDFExtractor: Processando fatura Nubank');
    return this._analisarFaturaNubank(rawData.rawText || rawData.lines.join('\n'), context);
  }

  _parseBradescoInvoice(rawData, context) {
    console.log('💳 PDFExtractor: Processando fatura Bradesco');
    return this._analisarFaturaCartao(rawData.rawText || rawData.lines.join('\n'), context);
  }

  _parseGenericStatement(rawData, context) {
    console.log('📄 PDFExtractor: Processando extrato genérico');
    return this._analisarTransacoesLinear(rawData.rawText || rawData.lines.join('\n'), context);
  }

  _parseGenericPDF(rawData, context) {
    return this._analisarTransacoesLinear(rawData.rawText || rawData.lines.join('\n'), context);
  }

  _extractTransactionFromLine(line) {
    // Método mantido para compatibilidade
    const patterns = [
      /(\d{2}\/\d{2}\/\d{4})\s+(.+?)\s+([-+]?\d+[.,]\d{2})$/,
      /(\d{2}\/\d{2})\s+(.+?)\s+([-+]?\d+[.,]\d{2})$/,
      /(.+?)\s+(\d{2}\/\d{2}\/\d{4})\s+([-+]?\d+[.,]\d{2})$/
    ];

    for (const pattern of patterns) {
      const match = line.match(pattern);
      if (match) {
        let data, descricao, valorStr;

        if (pattern.source.startsWith('(\\d{2}')) {
          data = match[1];
          descricao = match[2].trim();
          valorStr = match[3];
        } else {
          descricao = match[1].trim();
          data = match[2];
          valorStr = match[3];
        }

        let dataProcessada;
        try {
          if (data.length === 5) {
            const ano = new Date().getFullYear();
            dataProcessada = `${ano}-${data.substring(3,5)}-${data.substring(0,2)}`;
          } else {
            const parts = data.split('/');
            dataProcessada = `${parts[2]}-${parts[1]}-${parts[0]}`;
          }
        } catch (e) {
          dataProcessada = new Date().toISOString().substring(0, 10);
        }

        const valor = this._parseValue(valorStr);

        if (descricao && valor !== 0) {
          return {
            data: dataProcessada,
            descricao: descricao,
            valor: valor
          };
        }
      }
    }

    return null;
  }

  _getMetadata(fileName, content) {
    return {
      fileName: fileName,
      fileType: 'PDF',
      contentLength: content.length,
      extractedAt: new Date().toISOString(),
      version: '2.0'
    };
  }
}

// Exportar para uso global
if (typeof window !== 'undefined') {
  window.PDFExtractor = PDFExtractor;
}