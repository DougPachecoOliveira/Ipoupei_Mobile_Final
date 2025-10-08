// Parse Utils - iPoupei Mobile
// Utilitários para parsing e processamento de dados
// Adaptado do projeto web para Flutter

// Parser de datas universais
const DateParser = {
  parse: (dateStr) => {
    if (!dateStr) return null;

    const cleaned = dateStr.trim().replace(/[^\d\/\-\.]/g, '');

    const formats = [
      { regex: /^(\d{2})\/(\d{2})\/(\d{4})$/, order: [3, 2, 1] }, // DD/MM/YYYY
      { regex: /^(\d{4})-(\d{2})-(\d{2})$/, order: [1, 2, 3] }, // YYYY-MM-DD
      { regex: /^(\d{2})-(\d{2})-(\d{4})$/, order: [3, 2, 1] }, // DD-MM-YYYY
      { regex: /^(\d{2})\.(\d{2})\.(\d{4})$/, order: [3, 2, 1] }  // DD.MM.YYYY
    ];

    for (const format of formats) {
      const match = cleaned.match(format.regex);
      if (match) {
        const year = match[format.order[0]];
        const month = match[format.order[1]].padStart(2, '0');
        const day = match[format.order[2]].padStart(2, '0');

        const date = new Date(year, month - 1, day);
        if (date.getFullYear() == year &&
            date.getMonth() == month - 1 &&
            date.getDate() == day) {
          return `${year}-${month}-${day}`;
        }
      }
    }

    return null;
  }
};

// Parser de valores monetários
const ValueParser = {
  parse: (valueStr) => {
    if (!valueStr) return 0;

    let cleaned = valueStr.toString().trim();

    if (!cleaned || cleaned === '0' || cleaned === '-' || cleaned === '') {
      return 0;
    }

    const isNegative = cleaned.includes('(') ||
                      cleaned.includes(')') ||
                      cleaned.startsWith('-');

    cleaned = cleaned.replace(/[^\d,.]/g, '');

    if (!cleaned) return 0;

    // Detectar formato brasileiro vs americano
    if (/,\d{2}$/.test(cleaned)) {
      // Formato brasileiro: 1.234,56
      cleaned = cleaned.replace(/\./g, '').replace(',', '.');
    } else if (/\.\d{2}$/.test(cleaned)) {
      // Formato americano: 1,234.56
      cleaned = cleaned.replace(/,/g, '');
    } else {
      // Ambíguo - assumir formato brasileiro se tiver vírgula
      if (cleaned.includes(',')) {
        cleaned = cleaned.replace(/\./g, '').replace(',', '.');
      }
    }

    const value = parseFloat(cleaned) || 0;
    return isNegative ? -value : value;
  }
};

// Detector de formato de arquivo
const FormatDetector = {
  detectCSVSeparator: (content) => {
    const lines = content.split('\n').filter(line => line.trim());
    if (lines.length === 0) return ',';

    const separators = [';', ',', '\t', '|'];
    let bestSeparator = ',';
    let maxColumns = 0;

    for (const sep of separators) {
      const columns = lines[0].split(sep);
      if (columns.length > maxColumns) {
        maxColumns = columns.length;
        bestSeparator = sep;
      }
    }

    return bestSeparator;
  },

  hasHeader: (content, separator) => {
    const lines = content.split('\n').filter(line => line.trim());
    if (lines.length === 0) return false;

    const firstLine = lines[0].toLowerCase();
    const headerKeywords = [
      'data', 'date', 'valor', 'value', 'descricao', 'description',
      'historico', 'credito', 'debito', 'saldo'
    ];

    return headerKeywords.some(keyword => firstLine.includes(keyword));
  },

  analyzeStructure: (content) => {
    const separator = FormatDetector.detectCSVSeparator(content);
    const hasHeader = FormatDetector.hasHeader(content, separator);
    const lines = content.split('\n').filter(line => line.trim());
    const columnCount = lines.length > 0 ? lines[0].split(separator).length : 0;

    return {
      separator,
      hasHeader,
      columnCount,
      lineCount: lines.length,
      encoding: 'UTF-8'
    };
  }
};

// Validador de transações
const TransactionValidator = {
  validate: (transaction) => {
    const errors = [];
    const warnings = [];

    if (!transaction.descricao || transaction.descricao.trim().length === 0) {
      errors.push('Descrição é obrigatória');
    }

    if (!transaction.valor || transaction.valor <= 0) {
      errors.push('Valor deve ser maior que zero');
    }

    if (!transaction.data) {
      errors.push('Data é obrigatória');
    } else {
      const date = new Date(transaction.data);
      if (isNaN(date.getTime())) {
        errors.push('Data inválida');
      } else if (date > new Date(Date.now() + 365 * 24 * 60 * 60 * 1000)) {
        warnings.push('Data muito no futuro');
      }
    }

    if (!transaction.tipo || !['receita', 'despesa'].includes(transaction.tipo)) {
      errors.push('Tipo deve ser receita ou despesa');
    }

    if (transaction.valor && transaction.valor > 1000000) {
      warnings.push('Valor muito alto');
    }

    return {
      isValid: errors.length === 0,
      errors,
      warnings
    };
  },

  validateBatch: (transactions) => {
    const results = transactions.map(t => TransactionValidator.validate(t));
    const totalErrors = results.reduce((sum, r) => sum + r.errors.length, 0);
    const totalWarnings = results.reduce((sum, r) => sum + r.warnings.length, 0);

    return {
      isValid: totalErrors === 0,
      totalErrors,
      totalWarnings,
      results
    };
  }
};

// Estatísticas de importação
const ImportStats = {
  calculate: (transactions) => {
    const receitas = transactions.filter(t => t.tipo === 'receita');
    const despesas = transactions.filter(t => t.tipo === 'despesa');

    const totalReceitas = receitas.reduce((sum, t) => sum + t.valor, 0);
    const totalDespesas = despesas.reduce((sum, t) => sum + t.valor, 0);

    const dates = transactions.map(t => new Date(t.data)).filter(d => !isNaN(d.getTime()));
    const minDate = dates.length > 0 ? new Date(Math.min(...dates)) : null;
    const maxDate = dates.length > 0 ? new Date(Math.max(...dates)) : null;

    return {
      total: transactions.length,
      receitas: {
        count: receitas.length,
        total: totalReceitas
      },
      despesas: {
        count: despesas.length,
        total: totalDespesas
      },
      saldo: totalReceitas - totalDespesas,
      periodo: {
        inicio: minDate,
        fim: maxDate,
        dias: minDate && maxDate ? Math.ceil((maxDate - minDate) / (24 * 60 * 60 * 1000)) : 0
      }
    };
  }
};

// Categorizador automático
const AutoCategorizer = {
  patterns: {
    // Receitas
    receita: {
      'Salário': ['salario', 'salário', 'pagamento', 'vencimento'],
      'Freelance': ['freelance', 'extra', 'consultoria', 'projeto'],
      'Transferência': ['pix', 'transferencia', 'ted', 'doc']
    },
    // Despesas
    despesa: {
      'Alimentação': ['ifood', 'rappi', 'uber eats', 'mercado', 'supermercado', 'padaria', 'açougue', 'restaurante'],
      'Transporte': ['uber', '99', 'cabify', 'taxi', 'posto', 'gasolina', 'etanol', 'combustivel'],
      'Lazer': ['netflix', 'spotify', 'amazon prime', 'disney', 'cinema', 'teatro'],
      'Saúde': ['farmacia', 'drogaria', 'hospital', 'clinica', 'medico', 'dentista'],
      'Casa': ['aluguel', 'condominio', 'energia', 'agua', 'gas', 'internet', 'telefone'],
      'Educação': ['escola', 'faculdade', 'curso', 'livro', 'material escolar']
    }
  },

  categorize: (description, type) => {
    const desc = description.toLowerCase();
    const typePatterns = AutoCategorizer.patterns[type];

    if (!typePatterns) return null;

    for (const [category, keywords] of Object.entries(typePatterns)) {
      if (keywords.some(keyword => desc.includes(keyword))) {
        return category;
      }
    }

    return null;
  },

  categorizeBatch: (transactions) => {
    return transactions.map(transaction => ({
      ...transaction,
      suggestedCategory: AutoCategorizer.categorize(transaction.descricao, transaction.tipo)
    }));
  }
};

// Exportar utilitários
if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    DateParser,
    ValueParser,
    FormatDetector,
    TransactionValidator,
    ImportStats,
    AutoCategorizer
  };
}