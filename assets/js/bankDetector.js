// Bank Detector - iPoupei Mobile
// Detector de banco baseado em conteúdo de arquivo
// Adaptado do projeto React para Flutter

class BankDetector {
  static detectFormat(fileName, content) {
    console.log('🔍 BankDetector: Detectando formato para:', fileName);

    const analysis = {
      bankName: 'Genérico',
      bankKey: 'generic',
      formatType: 'csv',
      confidence: 0.5,
      separator: ',',
      hasHeader: true
    };

    try {
      const contentLower = content.toLowerCase();
      const fileNameLower = fileName.toLowerCase();

      // Detectar OFX primeiro
      if (fileNameLower.endsWith('.ofx') || fileNameLower.endsWith('.qfx') || contentLower.includes('<ofx>')) {
        analysis.formatType = 'ofx';
        analysis.bankName = this._detectOFXBank(content);
        analysis.confidence = 0.9;
        return analysis;
      }

      // Detectar PDF
      if (fileNameLower.endsWith('.pdf')) {
        analysis.formatType = 'pdf';
        analysis.bankName = this._detectPDFBank(fileName, content);
        analysis.confidence = 0.8;
        return analysis;
      }

      // Detectar banco por CSV/TXT
      const bankDetection = this._detectCSVBank(fileName, content);
      if (bankDetection) {
        Object.assign(analysis, bankDetection);
      }

      console.log('✅ BankDetector: Formato detectado:', analysis);
      return analysis;

    } catch (error) {
      console.error('❌ BankDetector: Erro na detecção:', error);
      return analysis; // Retorna genérico em caso de erro
    }
  }

  static _detectOFXBank(content) {
    const contentUpper = content.toUpperCase();

    if (contentUpper.includes('NUBANK') || contentUpper.includes('NU PAGAMENTOS')) {
      return 'Nubank';
    } else if (contentUpper.includes('ITAU') || contentUpper.includes('ITAÚ')) {
      return 'Banco Itaú';
    } else if (contentUpper.includes('BRADESCO')) {
      return 'Banco Bradesco';
    } else if (contentUpper.includes('SANTANDER')) {
      return 'Banco Santander';
    } else if (contentUpper.includes('INTER')) {
      return 'Banco Inter';
    } else if (contentUpper.includes('C6 BANK') || contentUpper.includes('C6BANK')) {
      return 'C6 Bank';
    }

    return 'Banco (OFX)';
  }

  static _detectPDFBank(fileName, content) {
    const fileNameLower = fileName.toLowerCase();
    const contentLower = content.toLowerCase();

    if (fileNameLower.includes('nubank') || contentLower.includes('nubank')) {
      return 'Nubank';
    } else if (fileNameLower.includes('itau') || contentLower.includes('itaú') || contentLower.includes('itau')) {
      return 'Banco Itaú';
    } else if (fileNameLower.includes('bradesco') || contentLower.includes('bradesco')) {
      return 'Banco Bradesco';
    } else if (fileNameLower.includes('santander') || contentLower.includes('santander')) {
      return 'Banco Santander';
    }

    return 'Banco (PDF)';
  }

  static _detectCSVBank(fileName, content) {
    const fileNameLower = fileName.toLowerCase();
    const contentLower = content.toLowerCase();
    const lines = content.split('\n').filter(line => line.trim());

    if (lines.length === 0) return null;

    // Detectar separador
    const separator = this._detectSeparator(content);

    // Verificar se tem header
    const hasHeader = this._hasHeader(lines[0], separator);

    // Detectar Nubank
    if (fileNameLower.includes('nu_') ||
        contentLower.includes('nubank') ||
        (hasHeader && lines[0].toLowerCase().includes('identificador'))) {
      return {
        bankName: 'Nubank',
        bankKey: 'nubank',
        formatType: 'csv',
        confidence: 0.9,
        separator: separator,
        hasHeader: hasHeader
      };
    }

    // Detectar Bradesco (formato específico com TAB)
    if (separator === '\t' && lines.length > 1) {
      const firstDataLine = hasHeader ? lines[1] : lines[0];
      const parts = firstDataLine.split('\t');

      // Bradesco típico: Data | Histórico | Docto | Crédito | Débito | Saldo
      if (parts.length >= 5 && this._isDateLike(parts[0])) {
        return {
          bankName: 'Banco Bradesco',
          bankKey: 'bradesco',
          formatType: 'csv',
          confidence: 0.85,
          separator: separator,
          hasHeader: hasHeader
        };
      }
    }

    // Detectar Itaú
    if (fileNameLower.includes('itau') ||
        contentLower.includes('itaú') ||
        contentLower.includes('banco itau')) {
      return {
        bankName: 'Banco Itaú',
        bankKey: 'itau',
        formatType: 'csv',
        confidence: 0.8,
        separator: separator,
        hasHeader: hasHeader
      };
    }

    // Detectar Santander
    if (fileNameLower.includes('santander') ||
        contentLower.includes('santander')) {
      return {
        bankName: 'Banco Santander',
        bankKey: 'santander',
        formatType: 'csv',
        confidence: 0.8,
        separator: separator,
        hasHeader: hasHeader
      };
    }

    // Detectar Inter
    if (fileNameLower.includes('inter') ||
        contentLower.includes('banco inter')) {
      return {
        bankName: 'Banco Inter',
        bankKey: 'inter',
        formatType: 'csv',
        confidence: 0.8,
        separator: separator,
        hasHeader: hasHeader
      };
    }

    // Detectar C6
    if (fileNameLower.includes('c6') ||
        contentLower.includes('c6 bank')) {
      return {
        bankName: 'C6 Bank',
        bankKey: 'c6',
        formatType: 'csv',
        confidence: 0.8,
        separator: separator,
        hasHeader: hasHeader
      };
    }

    // Retornar detecção genérica
    return {
      bankName: 'CSV Genérico',
      bankKey: 'generic',
      formatType: 'csv',
      confidence: 0.6,
      separator: separator,
      hasHeader: hasHeader
    };
  }

  static _detectSeparator(content) {
    const lines = content.split('\n').filter(line => line.trim());
    if (lines.length === 0) return ',';

    const firstLine = lines[0];
    const separators = ['\t', ';', ',', '|'];

    let bestSeparator = ',';
    let maxCount = 0;

    for (const sep of separators) {
      const count = (firstLine.match(new RegExp('\\' + sep, 'g')) || []).length;
      if (count > maxCount) {
        maxCount = count;
        bestSeparator = sep;
      }
    }

    return bestSeparator;
  }

  static _hasHeader(firstLine, separator) {
    const firstLineLower = firstLine.toLowerCase();
    const headerKeywords = [
      'data', 'date', 'valor', 'value', 'descricao', 'description',
      'historico', 'credito', 'debito', 'saldo', 'identificador'
    ];

    return headerKeywords.some(keyword => firstLineLower.includes(keyword));
  }

  static _isDateLike(text) {
    const datePatterns = [
      /\d{1,2}[\/\-]\d{1,2}[\/\-]\d{4}/,  // DD/MM/YYYY ou DD-MM-YYYY
      /\d{4}[\/\-]\d{1,2}[\/\-]\d{1,2}/,  // YYYY-MM-DD
      /\d{1,2}\.\d{1,2}\.\d{4}/           // DD.MM.YYYY
    ];

    return datePatterns.some(pattern => pattern.test(text));
  }
}

// Exportar para uso global
if (typeof window !== 'undefined') {
  window.BankDetector = BankDetector;
}