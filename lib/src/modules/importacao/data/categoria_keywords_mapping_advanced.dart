// 📂 lib\src\modules\importacao\data\categoria_keywords_mapping_advanced.dart
//
// 🚀 Sistema AVANÇADO de mapeamento de keywords para categorização automática
//
// ✨ Melhorias v2.0:
// - Normalização inteligente de texto
// - Suporte a RegEx para matches flexíveis
// - Aliases expandidos com erros comuns
// - Sistema de fallback com palavras genéricas
// - Scoring multi-nível (específico → genérico)
//
// 📌 Uso em conjunto com categoria_keywords_mapping.dart (fallback)

/// 🎯 Modelo AVANÇADO de keyword mapping com suporte a RegEx
class AdvancedKeywordMapping {
  final String keyword;
  final String categoria;
  final String subcategoria;
  final List<String> aliases;
  final double confidence;
  final String? regexPattern; // Novo: suporte a regex
  final KeywordType type; // Novo: tipo de keyword

  const AdvancedKeywordMapping({
    required this.keyword,
    required this.categoria,
    required this.subcategoria,
    this.aliases = const [],
    this.confidence = 0.9,
    this.regexPattern,
    this.type = KeywordType.especifica,
  });

  /// Verificar se a descrição corresponde a esta keyword
  bool matches(String descricaoNormalizada) {
    // 1. Tentar match por regex (mais flexível)
    if (regexPattern != null) {
      try {
        final regex = RegExp(regexPattern!, caseSensitive: false);
        if (regex.hasMatch(descricaoNormalizada)) {
          return true;
        }
      } catch (e) {
        // Regex inválido, continuar com match simples
      }
    }

    // 2. Match exato por keyword
    if (descricaoNormalizada.contains(keyword.toLowerCase())) {
      return true;
    }

    // 3. Match por aliases
    for (final alias in aliases) {
      if (descricaoNormalizada.contains(alias.toLowerCase())) {
        return true;
      }
    }

    return false;
  }
}

/// 🏷️ Tipo de keyword (para scoring hierárquico)
enum KeywordType {
  especifica, // Marca/empresa específica (ex: "carrefour")
  generica, // Palavra genérica (ex: "supermercado")
  contextual, // Contexto de uso (ex: "compra online")
}

/// 🧠 Serviço AVANÇADO de categorização automática
class AdvancedCategoriaKeywordsService {
  /// 📊 Base de dados AVANÇADA com RegEx e aliases expandidos
  static final List<AdvancedKeywordMapping> _advancedKeywords = [
    // ═══════════════════════════════════════════════════════════
    // 🍽️ ALIMENTAÇÃO - SUPERMERCADO
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'carrefour',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      regexPattern: r'carr?e?fou?r?\b',
      aliases: [
        'carrefour',
        'carrefur',
        'carrefor',
        'carrefou',
        'carrefu',
        'carrefour express',
        'carrefour bairro',
        'carrefour box',
        'compra carrefour',
        'supermercado carrefour',
        'mercado carrefour',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'assai',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      regexPattern: r'ass?a[íi]\b',
      aliases: [
        'assai',
        'assaí',
        'assay',
        'asai',
        'asaí',
        'atacadão assaí',
        'atacadao assai',
        'assai atacadista',
        'compra assai',
        'mercado assai',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'atacadao',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      regexPattern: r'atacad[aã]o\b',
      aliases: [
        'atacadao',
        'atacadão',
        'atcadao',
        'atacadao carrefour',
        'carrefour atacadão',
        'compra atacadao',
        'mercado atacadao',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'giga atacado',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      regexPattern: r'giga\s*(atacado)?',
      aliases: [
        'giga',
        'giga atacado',
        'gigaatacado',
        'giga atacadista',
        'compra giga',
        'mercado giga',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'mambo',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      regexPattern: r'mambo\b',
      aliases: ['mambo', 'supermercado mambo', 'compra mambo', 'mercado mambo'],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'st marche',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      regexPattern: r's[atã]o?\s*march[eé]\b',
      aliases: [
        'st marche',
        'saint marche',
        'stmarche',
        'sao marche',
        'são marche',
        'st march',
        'saint march',
        'compra st marche',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'pao de acucar',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      regexPattern: r'p[aã]o\s*de\s*a[cç][uú]car',
      aliases: [
        'pao de acucar',
        'pão de açúcar',
        'paodeacucar',
        'pda',
        'p.d.a',
        'compra pao de acucar',
        'supermercado pão de açúcar',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'extra',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      regexPattern: r'\bextra\s*(super|hiper|mercado)?\b',
      aliases: [
        'extra',
        'extra supermercado',
        'extra hiper',
        'extra hipermercado',
        'compra extra',
        'mercado extra',
      ],
      confidence: 0.88,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'walmart',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      regexPattern: r'wal\s*mart',
      aliases: [
        'walmart',
        'wal mart',
        'wal-mart',
        'wallmart',
        'compra walmart',
        'supermercado walmart',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    // Palavra GENÉRICA - supermercado (fallback)
    AdvancedKeywordMapping(
      keyword: 'supermercado',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      regexPattern: r'super\s*mercado|mercado|compras?\s*do\s*m[eê]s',
      aliases: [
        'supermercado',
        'super mercado',
        'mercado',
        'mercadinho',
        'compras do mes',
        'compras do mês',
        'feira do mes',
        'compra mensal',
        'compra semanal',
      ],
      confidence: 0.75,
      type: KeywordType.generica,
    ),

    // ═══════════════════════════════════════════════════════════
    // 🍕 ALIMENTAÇÃO - DELIVERY/FAST FOOD
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'ifood',
      categoria: 'Alimentação',
      subcategoria: 'Lanche/Fast Food/Delivery',
      regexPattern: r'i\s*f[ou]+d',
      aliases: [
        'ifood',
        'i-food',
        'i food',
        'ifod',
        'ifud',
        'ifoo',
        'ifoood',
        'ifd',
        'i*fod',
        'ifood*',
        'ifood *',
        '*ifood',
        'pelo ifood',
        'via ifood',
        'pagamento ifood',
        'pedido ifood',
        'compra ifood',
        'delivery ifood',
        'entrega ifood',
      ],
      confidence: 0.98,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'rappi',
      categoria: 'Alimentação',
      subcategoria: 'Lanche/Fast Food/Delivery',
      regexPattern: r'rap+i',
      aliases: [
        'rappi',
        'rapi',
        'rapp',
        'rappi *',
        '*rappi',
        'pelo rappi',
        'via rappi',
        'pagamento rappi',
        'pedido rappi',
        'compra rappi',
        'delivery rappi',
        'entrega rappi',
      ],
      confidence: 0.98,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'uber eats',
      categoria: 'Alimentação',
      subcategoria: 'Lanche/Fast Food/Delivery',
      regexPattern: r'uber\s*eats',
      aliases: [
        'uber eats',
        'ubereats',
        'uber-eats',
        'uber *eats',
        'uber* eats',
        'pelo uber eats',
        'via uber eats',
        'pedido uber eats',
        'delivery uber',
        'uber delivery',
      ],
      confidence: 0.98,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: '99 food',
      categoria: 'Alimentação',
      subcategoria: 'Lanche/Fast Food/Delivery',
      regexPattern: r'99\s*food',
      aliases: [
        '99 food',
        '99food',
        '99 *food',
        '99*food',
        'pelo 99 food',
        'via 99',
        'pedido 99',
      ],
      confidence: 0.98,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'mcdonalds',
      categoria: 'Alimentação',
      subcategoria: 'Lanche/Fast Food/Delivery',
      regexPattern: r'm[ck]\s*don?ald',
      aliases: [
        'mcdonalds',
        'mc donalds',
        "mc donald's",
        'mcdonald',
        'mc donald',
        'mcd',
        'mc',
        'mequi',
        'meq',
        'mac donalds',
        'macdonalds',
        'lanche mcdonalds',
        'pedido mcdonalds',
        'mc oferta',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'bobs',
      categoria: 'Alimentação',
      subcategoria: 'Lanche/Fast Food/Delivery',
      regexPattern: r"bob['s]*",
      aliases: [
        'bobs',
        "bob's",
        'bobsburger',
        'bob burger',
        'bobs burgers',
        'lanche bobs',
        'pedido bobs',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'burger king',
      categoria: 'Alimentação',
      subcategoria: 'Lanche/Fast Food/Delivery',
      regexPattern: r'burg[ue]r\s*king',
      aliases: [
        'burger king',
        'burgerking',
        'burguer king',
        'burguerking',
        'bk',
        'b.k',
        'lanche bk',
        'pedido burger',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'subway',
      categoria: 'Alimentação',
      subcategoria: 'Lanche/Fast Food/Delivery',
      regexPattern: r'sub\s*way',
      aliases: [
        'subway',
        'sub way',
        'subaway',
        'sub-way',
        'lanche subway',
        'pedido subway',
        'sanduiche subway',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'pizza hut',
      categoria: 'Alimentação',
      subcategoria: 'Lanche/Fast Food/Delivery',
      regexPattern: r'pizza\s*hut',
      aliases: [
        'pizza hut',
        'pizzahut',
        'pizza-hut',
        'piza hut',
        'pedido pizza hut',
        'delivery pizza hut',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'habib',
      categoria: 'Alimentação',
      subcategoria: 'Lanche/Fast Food/Delivery',
      regexPattern: r'hab[ií]b',
      aliases: [
        'habib',
        "habib's",
        'habibs',
        'habibe',
        'abib',
        'pedido habib',
        'esfiha habib',
        'lanche habib',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    // Palavras GENÉRICAS - delivery/lanche (fallback)
    AdvancedKeywordMapping(
      keyword: 'delivery',
      categoria: 'Alimentação',
      subcategoria: 'Lanche/Fast Food/Delivery',
      regexPattern: r'deliver[yi]|entrega\s*de\s*comida',
      aliases: [
        'delivery',
        'deliveri',
        'entrega',
        'entrega de comida',
        'pedido delivery',
        'comida delivery',
        'comida entrega',
      ],
      confidence: 0.75,
      type: KeywordType.generica,
    ),

    AdvancedKeywordMapping(
      keyword: 'lanche',
      categoria: 'Alimentação',
      subcategoria: 'Lanche/Fast Food/Delivery',
      regexPattern: r'lanch[eo]|hamburguer|pizza|sanduiche',
      aliases: [
        'lanche',
        'lanches',
        'lanchinho',
        'lancheria',
        'hamburguer',
        'hamburger',
        'x-burger',
        'xburger',
        'pizza',
        'sanduiche',
        'sanduba',
        'hot dog',
        'hotdog',
      ],
      confidence: 0.70,
      type: KeywordType.generica,
    ),

    // ═══════════════════════════════════════════════════════════
    // 🍴 ALIMENTAÇÃO - RESTAURANTE
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'outback',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      regexPattern: r'out\s*back',
      aliases: [
        'outback',
        'out back',
        'outback steakhouse',
        'out-back',
        'jantar outback',
        'almoco outback',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'madero',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      regexPattern: r'madero',
      aliases: [
        'madero',
        'madero container',
        'madero steak house',
        'madeiro',
        'jantar madero',
        'almoco madero',
        'lanche madero',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'spoleto',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      regexPattern: r'spol[ei]to',
      aliases: [
        'spoleto',
        'spolet',
        'spoletto',
        'espoleto',
        'massa spoleto',
        'almoco spoleto',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'restaurante',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      regexPattern: r'restaurante|almo[cç]o\s*fora|jantar\s*fora',
      aliases: [
        'restaurante',
        'rest',
        'restaurant',
        'resta',
        'almoco fora',
        'almoço fora',
        'jantar fora',
        'janta fora',
        'comida fora',
        'comer fora',
      ],
      confidence: 0.75,
      type: KeywordType.generica,
    ),

    // ═══════════════════════════════════════════════════════════
    // 🚗 TRANSPORTE - COMBUSTÍVEL
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'shell',
      categoria: 'Transporte',
      subcategoria: 'Combustível',
      regexPattern: r'\bshell\b',
      aliases: [
        'shell',
        'shell box',
        'posto shell',
        'shell select',
        'gasolina shell',
        'abastecimento shell',
        'combust shell',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'ipiranga',
      categoria: 'Transporte',
      subcategoria: 'Combustível',
      regexPattern: r'ipiranga|am\s*/?\s*pm',
      aliases: [
        'ipiranga',
        'posto ipiranga',
        'am/pm',
        'am pm',
        'ampm',
        'gasolina ipiranga',
        'abastecimento ipiranga',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'petrobras',
      categoria: 'Transporte',
      subcategoria: 'Combustível',
      regexPattern: r'petrobras|posto\s*br',
      aliases: [
        'petrobras',
        'br',
        'posto br',
        'petrobras distribuidora',
        'br petrobras',
        'gasolina br',
        'abastecimento br',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'gasolina',
      categoria: 'Transporte',
      subcategoria: 'Combustível',
      regexPattern: r'gasolin|combust[íi]vel|etanol|diesel|alcool|gnv',
      aliases: [
        'gasolina',
        'gas',
        'combustivel',
        'combustível',
        'etanol',
        'alcool',
        'álcool',
        'diesel',
        'gnv',
        'abastecimento',
        'abastecer',
        'abasteci',
        'posto',
        'posto de gasolina',
        'posto combustivel',
      ],
      confidence: 0.80,
      type: KeywordType.generica,
    ),

    // ═══════════════════════════════════════════════════════════
    // 🚖 TRANSPORTE - UBER/TAXI
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'uber',
      categoria: 'Transporte',
      subcategoria: 'Uber/Taxi',
      regexPattern: r'\buber\b',
      aliases: [
        'uber',
        'uber *',
        'uber trip',
        'uber viagem',
        'uber corrida',
        'corrida uber',
        'viagem uber',
        'pagamento uber',
      ],
      confidence: 0.98,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: '99',
      categoria: 'Transporte',
      subcategoria: 'Uber/Taxi',
      regexPattern: r'\b99\b|99\s*(taxi|pop|pay)',
      aliases: [
        '99',
        '99 taxi',
        '99 pop',
        '99pay',
        '99 *',
        '99*',
        'corrida 99',
        'viagem 99',
        'pagamento 99',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'taxi',
      categoria: 'Transporte',
      subcategoria: 'Uber/Taxi',
      regexPattern: r't[aá]xi|corrida\s*de\s*carro',
      aliases: [
        'taxi',
        'táxi',
        'taxista',
        'corrida taxi',
        'corrida táxi',
        'corrida de carro',
        'transporte particular',
      ],
      confidence: 0.85,
      type: KeywordType.generica,
    ),

    // ═══════════════════════════════════════════════════════════
    // 🏠 MORADIA - ENERGIA/ÁGUA/INTERNET
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'cpfl',
      categoria: 'Moradia',
      subcategoria: 'Energia Elétrica',
      regexPattern: r'\bcpfl\b',
      aliases: [
        'cpfl',
        'cpfl paulista',
        'cpfl piratininga',
        'cpfl energia',
        'conta cpfl',
        'luz cpfl',
        'energia cpfl',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'enel',
      categoria: 'Moradia',
      subcategoria: 'Energia Elétrica',
      regexPattern: r'\benel\b',
      aliases: [
        'enel',
        'enel sp',
        'enel rj',
        'enel ce',
        'enel goias',
        'conta enel',
        'luz enel',
        'energia enel',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'energia',
      categoria: 'Moradia',
      subcategoria: 'Energia Elétrica',
      regexPattern: r'energia\s*el[eé]trica|conta\s*de\s*luz',
      aliases: [
        'energia',
        'luz',
        'conta de luz',
        'energia elétrica',
        'energia eletrica',
        'conta energia',
        'pagamento luz',
      ],
      confidence: 0.80,
      type: KeywordType.generica,
    ),

    AdvancedKeywordMapping(
      keyword: 'sabesp',
      categoria: 'Moradia',
      subcategoria: 'Água',
      regexPattern: r'\bsabesp\b',
      aliases: [
        'sabesp',
        'sabesp saneamento',
        'conta sabesp',
        'agua sabesp',
        'água sabesp',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'agua',
      categoria: 'Moradia',
      subcategoria: 'Água',
      regexPattern: r'[aá]gua|conta\s*de\s*[aá]gua|saneamento',
      aliases: [
        'agua',
        'água',
        'conta de água',
        'conta de agua',
        'saneamento',
        'conta saneamento',
      ],
      confidence: 0.80,
      type: KeywordType.generica,
    ),

    AdvancedKeywordMapping(
      keyword: 'internet',
      categoria: 'Moradia',
      subcategoria: 'Internet',
      regexPattern: r'internet|wi\s*-?\s*fi|banda\s*larga',
      aliases: [
        'internet',
        'fibra',
        'banda larga',
        'wi-fi',
        'wifi',
        'wi fi',
        'internet fibra',
        'conta internet',
        'provedor',
      ],
      confidence: 0.75,
      type: KeywordType.generica,
    ),

    // ═══════════════════════════════════════════════════════════
    // 🏥 SAÚDE - FARMÁCIA/CONSULTAS
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'drogasil',
      categoria: 'Saúde',
      subcategoria: 'Medicamentos',
      regexPattern: r'droga\s*sil',
      aliases: [
        'drogasil',
        'droga sil',
        'drogaria sil',
        'drogasilraia',
        'compra drogasil',
        'farmacia drogasil',
        'remedios drogasil',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'raia',
      categoria: 'Saúde',
      subcategoria: 'Medicamentos',
      regexPattern: r'\braia\b',
      aliases: [
        'raia',
        'drogaria raia',
        'raia drogasil',
        'drogasil raia',
        'compra raia',
        'farmacia raia',
        'remedios raia',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'farmacia',
      categoria: 'Saúde',
      subcategoria: 'Medicamentos',
      regexPattern: r'farm[aá]cia|drogaria|rem[eé]dios?',
      aliases: [
        'farmacia',
        'farmácia',
        'drogaria',
        'remedios',
        'remédios',
        'medicamentos',
        'medicamento',
        'remedio',
        'compra farmacia',
      ],
      confidence: 0.80,
      type: KeywordType.generica,
    ),

    AdvancedKeywordMapping(
      keyword: 'consulta',
      categoria: 'Saúde',
      subcategoria: 'Consultas Médicas/Dentista',
      regexPattern: r'consulta|m[eé]dic[oa]|dentista',
      aliases: [
        'consulta',
        'consulta medica',
        'consulta médica',
        'médico',
        'medico',
        'doutor',
        'dr',
        'dra',
        'dentista',
        'consulta dentista',
      ],
      confidence: 0.85,
      type: KeywordType.generica,
    ),

    // ═══════════════════════════════════════════════════════════
    // 🎓 EDUCAÇÃO
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'mensalidade',
      categoria: 'Educação',
      subcategoria: 'Mensalidade',
      regexPattern: r'mensalidade|anuidade|semestralidade',
      aliases: [
        'mensalidade',
        'mensalidade escolar',
        'mensalidade faculdade',
        'anuidade',
        'semestralidade',
        'pagamento escola',
        'pagamento faculdade',
        'pagamento universidade',
      ],
      confidence: 0.85,
      type: KeywordType.generica,
    ),

    // ═══════════════════════════════════════════════════════════
    // 🎬 LAZER - STREAMING
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'netflix',
      categoria: 'Lazer',
      subcategoria: 'Streaming',
      regexPattern: r'net\s*fli?x',
      aliases: [
        'netflix',
        'netfix',
        'net flix',
        'net-flix',
        'netflixx',
        'assinatura netflix',
        'plano netflix',
        'pagamento netflix',
      ],
      confidence: 0.98,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'spotify',
      categoria: 'Lazer',
      subcategoria: 'Streaming',
      regexPattern: r'spot[yi]f?[yi]',
      aliases: [
        'spotify',
        'spotfy',
        'spot ify',
        'spotifi',
        'spotifai',
        'assinatura spotify',
        'plano spotify',
        'premium spotify',
      ],
      confidence: 0.98,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'streaming',
      categoria: 'Lazer',
      subcategoria: 'Streaming',
      regexPattern: r'streaming|assinatura\s*de\s*(video|musica)',
      aliases: [
        'streaming',
        'stream',
        'assinatura',
        'assinatura de video',
        'assinatura de musica',
        'plano streaming',
        'serviço streaming',
      ],
      confidence: 0.70,
      type: KeywordType.generica,
    ),

    // ═══════════════════════════════════════════════════════════
    // 👕 VESTUÁRIO
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'renner',
      categoria: 'Vestuário',
      subcategoria: 'Roupas',
      regexPattern: r'\brenner\b',
      aliases: [
        'renner',
        'lojas renner',
        'loja renner',
        'compra renner',
        'roupa renner',
        'vestuario renner',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'roupa',
      categoria: 'Vestuário',
      subcategoria: 'Roupas',
      regexPattern: r'roupas?|vestu[aá]rio|cal[cç]ados?|t[eê]nis',
      aliases: [
        'roupa',
        'roupas',
        'vestuario',
        'vestuário',
        'roupa nova',
        'calcado',
        'calçado',
        'sapato',
        'tenis',
        'tênis',
        'compra roupa',
        'loja de roupa',
      ],
      confidence: 0.75,
      type: KeywordType.generica,
    ),

    // ═══════════════════════════════════════════════════════════
    // 🐕 PETS
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'petz',
      categoria: 'Pets',
      subcategoria: 'Ração',
      regexPattern: r'\bpetz\b',
      aliases: [
        'petz',
        'pet shop petz',
        'petshop petz',
        'loja petz',
        'racao petz',
        'ração petz',
        'compra petz',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'pet',
      categoria: 'Pets',
      subcategoria: 'Acessórios',
      regexPattern: r'\bpet\b|pet\s*shop|ra[cç][aã]o|veterin[aá]rio',
      aliases: [
        'pet',
        'pet shop',
        'petshop',
        'racao',
        'ração',
        'veterinario',
        'veterinário',
        'cachorro',
        'gato',
        'animal',
        'bichinho',
      ],
      confidence: 0.70,
      type: KeywordType.generica,
    ),

    // ═══════════════════════════════════════════════════════════
    // 💰 RECEITAS - SALÁRIO
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'salario',
      categoria: 'Salário',
      subcategoria: 'Salário Principal',
      regexPattern: r'sal[aá]rio|pagamento|vencimento|ordenado',
      aliases: [
        'salario',
        'salário',
        'pagamento',
        'vencimento',
        'ordenado',
        'recebimento salario',
        'deposito salario',
        'salario depositado',
      ],
      confidence: 0.90,
      type: KeywordType.generica,
    ),
  ];

  // ═══════════════════════════════════════════════════════════
  // 🧮 UTILITÁRIOS DE NORMALIZAÇÃO
  // ═══════════════════════════════════════════════════════════

  /// 🔧 Normalizar texto para busca
  /// Remove acentos, símbolos especiais, espaços extras e converte para minúsculas
  static String normalizarTexto(String texto) {
    if (texto.isEmpty) return '';

    // 1. Converter para minúsculas
    String normalizado = texto.toLowerCase();

    // 2. Remover acentos
    const comAcento = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const semAcento = 'aaaaaeeeeiiiiooooouuuucn';

    for (int i = 0; i < comAcento.length; i++) {
      normalizado = normalizado.replaceAll(comAcento[i], semAcento[i]);
    }

    // 3. Remover símbolos especiais (exceto espaços e números)
    normalizado = normalizado.replaceAll(RegExp(r'[^\w\s]'), ' ');

    // 4. Remover espaços extras
    normalizado = normalizado.replaceAll(RegExp(r'\s+'), ' ').trim();

    return normalizado;
  }

  // ═══════════════════════════════════════════════════════════
  // 🔍 MÉTODOS DE BUSCA AVANÇADOS
  // ═══════════════════════════════════════════════════════════

  /// 🎯 Buscar melhor correspondência (com scoring hierárquico)
  static AdvancedKeywordMapping? buscarMelhorMatch(String descricao) {
    if (descricao.isEmpty) return null;

    final descricaoNormalizada = normalizarTexto(descricao);
    AdvancedKeywordMapping? melhorMatch;
    double melhorScore = 0.0;

    for (final mapping in _advancedKeywords) {
      if (mapping.matches(descricaoNormalizada)) {
        // Calcular score baseado no tipo + confidence
        double score = mapping.confidence;

        // Bonus por tipo específico
        switch (mapping.type) {
          case KeywordType.especifica:
            score *= 1.2; // +20% bonus
            break;
          case KeywordType.generica:
            score *= 1.0; // sem bonus
            break;
          case KeywordType.contextual:
            score *= 0.9; // -10% (menos prioritário)
            break;
        }

        if (score > melhorScore) {
          melhorMatch = mapping;
          melhorScore = score;
        }
      }
    }

    return melhorMatch;
  }

  /// 📊 Sugerir categoria e subcategoria
  static Map<String, String>? sugerirCategoria(String descricao) {
    final match = buscarMelhorMatch(descricao);

    if (match == null) return null;

    return {
      'categoria': match.categoria,
      'subcategoria': match.subcategoria,
      'confidence': match.confidence.toStringAsFixed(2),
      'keyword': match.keyword,
      'type': match.type.name,
    };
  }

  /// 🔎 Buscar todas as correspondências (ordenadas por score)
  static List<Map<String, dynamic>> buscarTodasCorrespondencias(
    String descricao,
  ) {
    if (descricao.isEmpty) return [];

    final descricaoNormalizada = normalizarTexto(descricao);
    final matches = <Map<String, dynamic>>[];

    for (final mapping in _advancedKeywords) {
      if (mapping.matches(descricaoNormalizada)) {
        // Calcular score
        double score = mapping.confidence;

        switch (mapping.type) {
          case KeywordType.especifica:
            score *= 1.2;
            break;
          case KeywordType.generica:
            score *= 1.0;
            break;
          case KeywordType.contextual:
            score *= 0.9;
            break;
        }

        matches.add({
          'mapping': mapping,
          'score': score,
          'categoria': mapping.categoria,
          'subcategoria': mapping.subcategoria,
          'keyword': mapping.keyword,
          'type': mapping.type.name,
        });
      }
    }

    // Ordenar por score (maior primeiro)
    matches.sort(
      (a, b) => (b['score'] as double).compareTo(a['score'] as double),
    );

    return matches;
  }

  /// 📈 Análise detalhada de descrição
  static Map<String, dynamic> analisarDescricao(String descricao) {
    final descricaoNormalizada = normalizarTexto(descricao);
    final match = buscarMelhorMatch(descricao);
    final todasCorrespondencias = buscarTodasCorrespondencias(descricao);

    return {
      'descricaoOriginal': descricao,
      'descricaoNormalizada': descricaoNormalizada,
      'temMatch': match != null,
      'melhorMatch': match != null
          ? {
              'keyword': match.keyword,
              'categoria': match.categoria,
              'subcategoria': match.subcategoria,
              'confidence': match.confidence,
              'type': match.type.name,
              'usouRegex': match.regexPattern != null,
            }
          : null,
      'totalCorrespondencias': todasCorrespondencias.length,
      'outrasCorrespondencias': todasCorrespondencias.skip(1).take(3).toList(),
    };
  }

  /// 📊 Estatísticas da base avançada
  static Map<String, dynamic> getStats() {
    final categorias = <String>{};
    final subcategorias = <String>{};
    int totalAliases = 0;
    int totalRegex = 0;
    int especificas = 0;
    int genericas = 0;
    int contextuais = 0;

    for (final mapping in _advancedKeywords) {
      categorias.add(mapping.categoria);
      subcategorias.add(mapping.subcategoria);
      totalAliases += mapping.aliases.length;

      if (mapping.regexPattern != null) totalRegex++;

      switch (mapping.type) {
        case KeywordType.especifica:
          especificas++;
          break;
        case KeywordType.generica:
          genericas++;
          break;
        case KeywordType.contextual:
          contextuais++;
          break;
      }
    }

    return {
      'totalKeywords': _advancedKeywords.length,
      'totalCategorias': categorias.length,
      'totalSubcategorias': subcategorias.length,
      'totalAliases': totalAliases,
      'totalRegex': totalRegex,
      'especificas': especificas,
      'genericas': genericas,
      'contextuais': contextuais,
      'mediaAliasesPorKeyword': (totalAliases / _advancedKeywords.length)
          .toStringAsFixed(2),
      'confidenceMedia':
          (_advancedKeywords.fold<double>(0, (sum, m) => sum + m.confidence) /
                  _advancedKeywords.length)
              .toStringAsFixed(2),
    };
  }

  /// ✅ Validar se descrição tem match
  static bool temMatch(String descricao) {
    return buscarMelhorMatch(descricao) != null;
  }

  // ═══════════════════════════════════════════════════════════
  // 🗃️ BASE DE DADOS EXPANDIDA (CONTINUAÇÃO)
  // ═══════════════════════════════════════════════════════════

  /// 📊 Lista EXPANDIDA com keywords adicionais (mantida separada para organização)
  static const List<AdvancedKeywordMapping> _advancedKeywordsExtended = [
    // ═══════════════════════════════════════════════════════════
    // 🥩 ALIMENTAÇÃO - AÇOUGUE/FEIRA (EXPANDIDO)
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'acougue',
      categoria: 'Alimentação',
      subcategoria: 'Açougue/Feira',
      regexPattern: r'a[cç]ougu[eê]',
      aliases: [
        'acougue',
        'açougue',
        'acougueiro',
        'acouge',
        'açouge',
        'casa de carne',
        'carneiro',
        'carnes',
        'carne',
        'compra açougue',
        'compra acougue',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'feira',
      categoria: 'Alimentação',
      subcategoria: 'Açougue/Feira',
      regexPattern: r'feira\s*(livre|org[aâ]nica)?',
      aliases: [
        'feira',
        'feira livre',
        'feirante',
        'feira organica',
        'feira orgânica',
        'feira de rua',
        'compra feira',
        'verduras feira',
        'legumes feira',
      ],
      confidence: 0.85,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'hortifruti',
      categoria: 'Alimentação',
      subcategoria: 'Açougue/Feira',
      regexPattern: r'horti\s*fru[th]i',
      aliases: [
        'hortifruti',
        'horti fruti',
        'hortifrut',
        'hortifrutti',
        'verduras e frutas',
        'verduras frutas',
        'compra hortifruti',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'sacolao',
      categoria: 'Alimentação',
      subcategoria: 'Açougue/Feira',
      regexPattern: r'sacol[aã]o',
      aliases: [
        'sacolao',
        'sacolão',
        'sacol',
        'verdurão',
        'verdurao',
        'compra sacolao',
        'compra sacolão',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'padaria',
      categoria: 'Alimentação',
      subcategoria: 'Açougue/Feira',
      regexPattern: r'padaria|panificadora|confeitaria|padoca',
      aliases: [
        'padaria',
        'padoca',
        'panificadora',
        'confeitaria',
        'pao',
        'pão',
        'paes',
        'pães',
        'pao frances',
        'pão francês',
        'compra padaria',
        'lanche padaria',
      ],
      confidence: 0.85,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'peixaria',
      categoria: 'Alimentação',
      subcategoria: 'Açougue/Feira',
      regexPattern: r'peixaria|pescado|frutos?\s*do\s*mar',
      aliases: [
        'peixaria',
        'peixe',
        'pescado',
        'pescados',
        'frutos do mar',
        'fruto do mar',
        'peixe fresco',
        'camarão',
        'camarao',
        'compra peixaria',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    // Palavras GENÉRICAS de alimentos frescos
    AdvancedKeywordMapping(
      keyword: 'verduras',
      categoria: 'Alimentação',
      subcategoria: 'Açougue/Feira',
      regexPattern: r'verduras?|legumes?|hortali[cç]as?',
      aliases: [
        'verduras',
        'verdura',
        'legumes',
        'legume',
        'hortaliças',
        'hortaliça',
        'salada',
        'vegetais',
        'compra verdura',
        'compra legumes',
      ],
      confidence: 0.80,
      type: KeywordType.generica,
    ),

    AdvancedKeywordMapping(
      keyword: 'frutas',
      categoria: 'Alimentação',
      subcategoria: 'Açougue/Feira',
      regexPattern: r'frutas?|frut',
      aliases: [
        'frutas',
        'fruta',
        'frut',
        'frutaria',
        'compra fruta',
        'compra frutas',
      ],
      confidence: 0.80,
      type: KeywordType.generica,
    ),

    // ═══════════════════════════════════════════════════════════
    // 🍕 RESTAURANTES EXPANDIDOS
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'applebees',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      regexPattern: r'apple\s*bee',
      aliases: [
        'applebees',
        "applebee's",
        'apple bees',
        'apple bee',
        'applebee',
        'jantar applebees',
        'almoco applebees',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'giraffas',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      regexPattern: r'giraf+as?',
      aliases: [
        'giraffas',
        'girafas',
        'giraffas restaurante',
        'girafa',
        'almoco giraffas',
        'lanche giraffas',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'ragazzo',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      regexPattern: r'ragaz+o',
      aliases: [
        'ragazzo',
        'ragazo',
        'ragazzo pizzaria',
        'ragazzo pizza',
        'pizza ragazzo',
        'jantar ragazzo',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'koni',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      regexPattern: r'\bkoni\b',
      aliases: [
        'koni',
        'koni store',
        'konistore',
        'koni sushi',
        'almoco koni',
        'jantar koni',
        'temaki koni',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'china in box',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      regexPattern: r'china\s*in\s*box',
      aliases: [
        'china in box',
        'chinainbox',
        'china box',
        'china-in-box',
        'pedido china in box',
        'delivery china in box',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'gendai',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      regexPattern: r'gendai',
      aliases: [
        'gendai',
        'gendai sushi',
        'gendai japonês',
        'gendai japones',
        'almoco gendai',
        'jantar gendai',
        'rodizio gendai',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'vivenda',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      regexPattern: r'vivenda',
      aliases: [
        'vivenda',
        'vivenda do camarão',
        'vivenda do camarao',
        'vivenda camarao',
        'jantar vivenda',
        'almoco vivenda',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'coco bambu',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      regexPattern: r'coco\s*bambu',
      aliases: [
        'coco bambu',
        'cocobambu',
        'coco bamboo',
        'coco-bambu',
        'jantar coco bambu',
        'almoco coco bambu',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'fogo de chao',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      regexPattern: r'fogo\s*de\s*ch[aã]o',
      aliases: [
        'fogo de chao',
        'fogo de chão',
        'fogodechao',
        'fogo-de-chao',
        'churrascaria fogo de chao',
        'jantar fogo de chao',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'griletto',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      regexPattern: r'gril+et+o',
      aliases: [
        'griletto',
        'grileto',
        'griletto restaurante',
        'almoco griletto',
        'lanche griletto',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'temakeria',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      regexPattern: r'temakeria|temaki',
      aliases: [
        'temakeria',
        'temaki',
        'temakeria e cia',
        'temakeria cia',
        'pedido temakeria',
        'jantar temakeria',
        'almoco temakeria',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    // Palavras GENÉRICAS - tipos de comida
    AdvancedKeywordMapping(
      keyword: 'sushi',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      regexPattern: r'sushi|japon[eê]s|japa',
      aliases: [
        'sushi',
        'sushiya',
        'sushibar',
        'sushi bar',
        'sushy',
        'comida japonesa',
        'japonês',
        'japones',
        'japa',
        'rodizio japones',
        'rodízio japonês',
      ],
      confidence: 0.82,
      type: KeywordType.generica,
    ),

    AdvancedKeywordMapping(
      keyword: 'churrascaria',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      regexPattern: r'churrascaria|churras|rod[ií]zio',
      aliases: [
        'churrascaria',
        'churras',
        'churrasco',
        'rodizio',
        'rodízio',
        'rodizio de carne',
        'rodízio de carne',
        'espeto corrido',
      ],
      confidence: 0.88,
      type: KeywordType.generica,
    ),

    AdvancedKeywordMapping(
      keyword: 'pizzaria',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      regexPattern: r'piz+aria|piz+a',
      aliases: [
        'pizzaria',
        'pizza',
        'pizz',
        'pizzeria',
        'pedido pizza',
        'delivery pizza',
        'pizza entrega',
      ],
      confidence: 0.85,
      type: KeywordType.generica,
    ),

    // ═══════════════════════════════════════════════════════════
    // 🍔 FAST FOOD EXPANDIDO
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'kfc',
      categoria: 'Alimentação',
      subcategoria: 'Lanche/Fast Food/Delivery',
      regexPattern: r'\bkfc\b|kentucky',
      aliases: [
        'kfc',
        'kentucky',
        'kentucky fried chicken',
        'kentucky fc',
        'lanche kfc',
        'pedido kfc',
        'frango kfc',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'dominos',
      categoria: 'Alimentação',
      subcategoria: 'Lanche/Fast Food/Delivery',
      regexPattern: r"domin[o's]*",
      aliases: [
        'dominos',
        "domino's",
        'domino pizza',
        'domino',
        'pizza dominos',
        'pedido dominos',
        'delivery dominos',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'popeyes',
      categoria: 'Alimentação',
      subcategoria: 'Lanche/Fast Food/Delivery',
      regexPattern: r'pop\s*eyes?',
      aliases: [
        'popeyes',
        'pop eyes',
        'popeye',
        'pop-eyes',
        'lanche popeyes',
        'frango popeyes',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'starbucks',
      categoria: 'Alimentação',
      subcategoria: 'Lanche/Fast Food/Delivery',
      regexPattern: r'star\s*bucks?',
      aliases: [
        'starbucks',
        'star bucks',
        'starbucks coffee',
        'star-bucks',
        'cafe starbucks',
        'café starbucks',
        'lanche starbucks',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'kopenhagen',
      categoria: 'Alimentação',
      subcategoria: 'Lanche/Fast Food/Delivery',
      regexPattern: r'kop[eé]nhag[eé]n',
      aliases: [
        'kopenhagen',
        'kopenhagem',
        'copenhagem',
        'copenhagen',
        'chocolates kopenhagen',
        'compra kopenhagen',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'cacau show',
      categoria: 'Alimentação',
      subcategoria: 'Lanche/Fast Food/Delivery',
      regexPattern: r'cacau\s*show',
      aliases: [
        'cacau show',
        'cacaushow',
        'cacau',
        'cacau-show',
        'chocolates cacau show',
        'compra cacau show',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'dunkin donuts',
      categoria: 'Alimentação',
      subcategoria: 'Lanche/Fast Food/Delivery',
      regexPattern: r'dunk[ií]n\s*don[uú]ts?',
      aliases: [
        'dunkin donuts',
        'dunkin',
        'dunkin donut',
        'dunkindonuts',
        'lanche dunkin',
        'cafe dunkin',
        'café dunkin',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'rei do mate',
      categoria: 'Alimentação',
      subcategoria: 'Lanche/Fast Food/Delivery',
      regexPattern: r'rei\s*do\s*mat[eé]',
      aliases: [
        'rei do mate',
        'reidomate',
        'rei do maté',
        'rei mate',
        'lanche rei do mate',
        'mate',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    // Palavras GENÉRICAS - fast food
    AdvancedKeywordMapping(
      keyword: 'fast food',
      categoria: 'Alimentação',
      subcategoria: 'Lanche/Fast Food/Delivery',
      regexPattern: r'fast\s*food|comida\s*r[aá]pida',
      aliases: [
        'fast food',
        'fastfood',
        'fast',
        'comida rapida',
        'comida rápida',
        'lanchonete',
        'lanchonete express',
      ],
      confidence: 0.75,
      type: KeywordType.generica,
    ),

    // ═══════════════════════════════════════════════════════════
    // 🚗 TRANSPORTE - COMBUSTÍVEL EXPANDIDO
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'ale',
      categoria: 'Transporte',
      subcategoria: 'Combustível',
      regexPattern: r'\bale\b',
      aliases: [
        'ale',
        'posto ale',
        'alesat',
        'ale combustivel',
        'gasolina ale',
        'abastecimento ale',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'raizen',
      categoria: 'Transporte',
      subcategoria: 'Combustível',
      regexPattern: r'ra[íi]zen',
      aliases: [
        'raizen',
        'raízen',
        'raizen energia',
        'posto raizen',
        'gasolina raizen',
        'abastecimento raizen',
        'shell raizen',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'vibra',
      categoria: 'Transporte',
      subcategoria: 'Combustível',
      regexPattern: r'\bvibra\b',
      aliases: [
        'vibra',
        'vibra energia',
        'posto vibra',
        'gasolina vibra',
        'abastecimento vibra',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'texaco',
      categoria: 'Transporte',
      subcategoria: 'Combustível',
      regexPattern: r'texaco',
      aliases: [
        'texaco',
        'posto texaco',
        'texaco combustivel',
        'gasolina texaco',
        'abastecimento texaco',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'esso',
      categoria: 'Transporte',
      subcategoria: 'Combustível',
      regexPattern: r'\besso\b',
      aliases: [
        'esso',
        'posto esso',
        'esso combustivel',
        'gasolina esso',
        'abastecimento esso',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'posto',
      categoria: 'Transporte',
      subcategoria: 'Combustível',
      regexPattern: r'posto\s*(de\s*)?(gasolina|combustivel)?',
      aliases: [
        'posto',
        'posto de gasolina',
        'posto de combustível',
        'posto combustivel',
        'posto gas',
      ],
      confidence: 0.78,
      type: KeywordType.generica,
    ),

    AdvancedKeywordMapping(
      keyword: 'abastecimento',
      categoria: 'Transporte',
      subcategoria: 'Combustível',
      regexPattern: r'abastecer|abastec[iî]',
      aliases: [
        'abastecimento',
        'abastecer',
        'abasteci',
        'abastecendo',
        'tanque cheio',
        'encher tanque',
        'completar tanque',
      ],
      confidence: 0.85,
      type: KeywordType.contextual,
    ),

    // ═══════════════════════════════════════════════════════════
    // 🚖 TRANSPORTE - APPS EXPANDIDO
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'cabify',
      categoria: 'Transporte',
      subcategoria: 'Uber/Taxi',
      regexPattern: r'cab[ií]fy',
      aliases: [
        'cabify',
        'cabi fy',
        'cabifi',
        'cabiffy',
        'corrida cabify',
        'viagem cabify',
        'pagamento cabify',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'indriver',
      categoria: 'Transporte',
      subcategoria: 'Uber/Taxi',
      regexPattern: r'in\s*driver',
      aliases: [
        'indriver',
        'in driver',
        'indrive',
        'in-driver',
        'corrida indriver',
        'viagem indriver',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'lady driver',
      categoria: 'Transporte',
      subcategoria: 'Uber/Taxi',
      regexPattern: r'lady\s*driver',
      aliases: [
        'lady driver',
        'ladydriver',
        'lady-driver',
        'corrida lady driver',
        'viagem lady driver',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'corrida',
      categoria: 'Transporte',
      subcategoria: 'Uber/Taxi',
      regexPattern: r'corrida\s*(de\s*)?(carro|taxi|uber)?',
      aliases: [
        'corrida',
        'corrida de carro',
        'corrida uber',
        'corrida 99',
        'viagem',
        'transporte app',
        'transporte particular',
      ],
      confidence: 0.70,
      type: KeywordType.contextual,
    ),

    // ═══════════════════════════════════════════════════════════
    // 🚌 TRANSPORTE - TRANSPORTE PÚBLICO EXPANDIDO
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'bilhete unico',
      categoria: 'Transporte',
      subcategoria: 'Transporte Público',
      regexPattern: r'bilhete\s*[uú]nico?',
      aliases: [
        'bilhete unico',
        'bilhete único',
        'bilhete-unico',
        'cartao transporte',
        'cartão transporte',
        'recarga bilhete',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'metro',
      categoria: 'Transporte',
      subcategoria: 'Transporte Público',
      regexPattern: r'metr[oô]|metropolitano',
      aliases: [
        'metro',
        'metrô',
        'metropolitano',
        'metroviario',
        'passagem metro',
        'passagem metrô',
        'bilhete metro',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'onibus',
      categoria: 'Transporte',
      subcategoria: 'Transporte Público',
      regexPattern: r'[oô]nibus|bus\b',
      aliases: [
        'onibus',
        'ônibus',
        'onib',
        'bus',
        'busao',
        'busão',
        'passagem onibus',
        'passagem ônibus',
        'bilhete onibus',
      ],
      confidence: 0.85,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'brt',
      categoria: 'Transporte',
      subcategoria: 'Transporte Público',
      regexPattern: r'\bbrt\b',
      aliases: [
        'brt',
        'bus rapid transit',
        'transito rapido',
        'passagem brt',
        'bilhete brt',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'cptm',
      categoria: 'Transporte',
      subcategoria: 'Transporte Público',
      regexPattern: r'\bcptm\b',
      aliases: [
        'cptm',
        'trem',
        'trem metropolitano',
        'passagem cptm',
        'bilhete cptm',
        'passagem trem',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'vlt',
      categoria: 'Transporte',
      subcategoria: 'Transporte Público',
      regexPattern: r'\bvlt\b',
      aliases: [
        'vlt',
        'veiculo leve sobre trilhos',
        'trem leve',
        'passagem vlt',
        'bilhete vlt',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'recarga transporte',
      categoria: 'Transporte',
      subcategoria: 'Transporte Público',
      regexPattern: r'recarga\s*(cart[aã]o|bilhete|transporte)',
      aliases: [
        'recarga',
        'recarga cartao',
        'recarga cartão',
        'recarga bilhete',
        'credito transporte',
        'crédito transporte',
        'recarga onibus',
        'recarga metro',
      ],
      confidence: 0.85,
      type: KeywordType.contextual,
    ),

    // ═══════════════════════════════════════════════════════════
    // 🔧 TRANSPORTE - MANUTENÇÃO EXPANDIDO
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'oficina',
      categoria: 'Transporte',
      subcategoria: 'Manutenção Veículo',
      regexPattern: r'oficina\s*(mec[aâ]nica)?',
      aliases: [
        'oficina',
        'oficina mecanica',
        'oficina mecânica',
        'mecanica',
        'mecânica',
        'auto center',
        'autocenter',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'mecanico',
      categoria: 'Transporte',
      subcategoria: 'Manutenção Veículo',
      regexPattern: r'mec[aâ]nico|conserto\s*(de\s*)?carro',
      aliases: [
        'mecanico',
        'mecânico',
        'conserto',
        'conserto carro',
        'reparo',
        'reparo carro',
        'manutencao carro',
      ],
      confidence: 0.85,
      type: KeywordType.generica,
    ),

    AdvancedKeywordMapping(
      keyword: 'revisao',
      categoria: 'Transporte',
      subcategoria: 'Manutenção Veículo',
      regexPattern: r'revis[aã]o|manuten[cç][aã]o',
      aliases: [
        'revisao',
        'revisão',
        'revisao carro',
        'revisão carro',
        'manutencao',
        'manutenção',
        'inspecao',
        'inspeção',
      ],
      confidence: 0.90,
      type: KeywordType.contextual,
    ),

    AdvancedKeywordMapping(
      keyword: 'troca de oleo',
      categoria: 'Transporte',
      subcategoria: 'Manutenção Veículo',
      regexPattern: r'troca\s*de\s*[oó]leo|[oó]leo\s*motor',
      aliases: [
        'troca de oleo',
        'troca de óleo',
        'oleo motor',
        'óleo motor',
        'oleo',
        'óleo',
        'lubrificante',
        'lubrificação',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'pneu',
      categoria: 'Transporte',
      subcategoria: 'Manutenção Veículo',
      regexPattern: r'pneus?|borracharia|calibragem',
      aliases: [
        'pneu',
        'pneus',
        'borracharia',
        'calibragem',
        'troca pneu',
        'conserto pneu',
        'remendo pneu',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'alinhamento',
      categoria: 'Transporte',
      subcategoria: 'Manutenção Veículo',
      regexPattern: r'alinhamento|balanceamento|geometria',
      aliases: [
        'alinhamento',
        'balanceamento',
        'geometria',
        'alinhamento balanceamento',
        'alinha e balanceia',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'bateria',
      categoria: 'Transporte',
      subcategoria: 'Manutenção Veículo',
      regexPattern: r'bateria\s*(carro|automotiva)?',
      aliases: [
        'bateria',
        'bateria carro',
        'bateria automotiva',
        'troca bateria',
        'bateria nova',
        'bateria descarregada',
      ],
      confidence: 0.85,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'lava jato',
      categoria: 'Transporte',
      subcategoria: 'Manutenção Veículo',
      regexPattern: r'lava\s*jato|lavagem\s*(de\s*)?carro',
      aliases: [
        'lava jato',
        'lavajato',
        'lavagem',
        'lavagem carro',
        'lavar carro',
        'limpeza carro',
        'lavacao',
        'lavação',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'funilaria',
      categoria: 'Transporte',
      subcategoria: 'Manutenção Veículo',
      regexPattern: r'funilaria|pintura\s*carro|lataria',
      aliases: [
        'funilaria',
        'pintura',
        'pintura carro',
        'lataria',
        'conserto lataria',
        'reparo lataria',
        'amassado',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'vidracaria',
      categoria: 'Transporte',
      subcategoria: 'Manutenção Veículo',
      regexPattern: r'vidra[cç]aria|para\s*brisa',
      aliases: [
        'vidracaria',
        'vidraçaria',
        'para brisa',
        'parabrisa',
        'trinca vidro',
        'conserto vidro',
        'vidro carro',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'insulfilm',
      categoria: 'Transporte',
      subcategoria: 'Manutenção Veículo',
      regexPattern: r'insulfilm|pel[íi]cula',
      aliases: [
        'insulfilm',
        'pelicula',
        'película',
        'pelicula automotiva',
        'insulfilm carro',
        'pelicula vidro',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    // ═══════════════════════════════════════════════════════════
    // 🅿️ TRANSPORTE - ESTACIONAMENTO EXPANDIDO
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'estacionamento',
      categoria: 'Transporte',
      subcategoria: 'Estacionamento',
      regexPattern: r'estacionamento|parking|garage|garagem',
      aliases: [
        'estacionamento',
        'estacion',
        'parking',
        'garage',
        'garagem',
        'estac',
        'vaga',
        'mensalidade estacionamento',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'zona azul',
      categoria: 'Transporte',
      subcategoria: 'Estacionamento',
      regexPattern: r'zona\s*azul',
      aliases: [
        'zona azul',
        'zona-azul',
        'zonaazul',
        'credito zona azul',
        'crédito zona azul',
        'recarga zona azul',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'valet',
      categoria: 'Transporte',
      subcategoria: 'Estacionamento',
      regexPattern: r'valet|manobrista',
      aliases: [
        'valet',
        'manobrista',
        'valet parking',
        'valet service',
        'serviço de valet',
        'gorjeta valet',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'pedagio',
      categoria: 'Transporte',
      subcategoria: 'Estacionamento',
      regexPattern: r'ped[aá]gio|sem\s*parar|conectcar|veloe',
      aliases: [
        'pedagio',
        'pedágio',
        'sem parar',
        'conectcar',
        'veloe',
        'tag pedagio',
        'tag pedágio',
        'recarga pedagio',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'sem parar',
      categoria: 'Transporte',
      subcategoria: 'Estacionamento',
      regexPattern: r'sem\s*parar',
      aliases: [
        'sem parar',
        'semparar',
        'sem-parar',
        'recarga sem parar',
        'tag sem parar',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'conectcar',
      categoria: 'Transporte',
      subcategoria: 'Estacionamento',
      regexPattern: r'conect\s*car',
      aliases: [
        'conectcar',
        'conect car',
        'conecta car',
        'recarga conectcar',
        'tag conectcar',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'veloe',
      categoria: 'Transporte',
      subcategoria: 'Estacionamento',
      regexPattern: r'velo[eé]',
      aliases: ['veloe', 'veloé', 'tag veloe', 'recarga veloe'],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    // ═══════════════════════════════════════════════════════════
    // 🏠 MORADIA - ALUGUEL EXPANDIDO
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'aluguel',
      categoria: 'Moradia',
      subcategoria: 'Aluguel',
      regexPattern: r'alugu[eé]l|loca[cç][aã]o',
      aliases: [
        'aluguel',
        'aluguer',
        'locação',
        'locacao',
        'pagamento aluguel',
        'mensalidade aluguel',
        'rent',
        'aluguel casa',
        'aluguel apartamento',
        'aluguel imovel',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'imobiliaria',
      categoria: 'Moradia',
      subcategoria: 'Aluguel',
      regexPattern: r'imobili[aá]ria|administradora|corretora',
      aliases: [
        'imobiliaria',
        'imobiliária',
        'administradora',
        'corretora',
        'corretora imoveis',
        'administradora imoveis',
        'taxa imobiliaria',
        'taxa administração',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'garantia',
      categoria: 'Moradia',
      subcategoria: 'Aluguel',
      regexPattern: r'garantia\s*(locaticia|aluguel)?|caucao|cau[cç][aã]o',
      aliases: [
        'garantia',
        'garantia locaticia',
        'garantia aluguel',
        'caucao',
        'caução',
        'deposito caucao',
        'depósito caução',
      ],
      confidence: 0.88,
      type: KeywordType.contextual,
    ),

    AdvancedKeywordMapping(
      keyword: 'iptu',
      categoria: 'Moradia',
      subcategoria: 'Aluguel',
      regexPattern: r'\biptu\b',
      aliases: [
        'iptu',
        'imposto predial',
        'imposto territorial',
        'pagamento iptu',
        'taxa iptu',
        'iptu parcelado',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    // ═══════════════════════════════════════════════════════════
    // 🏢 MORADIA - CONDOMÍNIO EXPANDIDO
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'condominio',
      categoria: 'Moradia',
      subcategoria: 'Condomínio',
      regexPattern: r'condom[íi]nio|cond\b',
      aliases: [
        'condominio',
        'condomínio',
        'cond',
        'taxa condominio',
        'taxa de condomínio',
        'mensalidade condominio',
        'pagamento condominio',
        'boleto condominio',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'sindico',
      categoria: 'Moradia',
      subcategoria: 'Condomínio',
      regexPattern: r's[íi]ndico|administradora\s*condom',
      aliases: [
        'sindico',
        'síndico',
        'administradora condominio',
        'administradora condominial',
        'gestao condominio',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'taxa extra',
      categoria: 'Moradia',
      subcategoria: 'Condomínio',
      regexPattern: r'taxa\s*extra|rateio|fundo\s*(de\s*)?reserva',
      aliases: [
        'taxa extra',
        'taxa extraordinaria',
        'taxa extraordinária',
        'rateio',
        'fundo de reserva',
        'obra condominio',
      ],
      confidence: 0.88,
      type: KeywordType.contextual,
    ),

    // ═══════════════════════════════════════════════════════════
    // ⚡ MORADIA - ENERGIA EXPANDIDO
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'light',
      categoria: 'Moradia',
      subcategoria: 'Energia Elétrica',
      regexPattern: r'\blight\b',
      aliases: [
        'light',
        'light rio',
        'light sa',
        'light rj',
        'conta light',
        'luz light',
        'energia light',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'cemig',
      categoria: 'Moradia',
      subcategoria: 'Energia Elétrica',
      regexPattern: r'\bcemig\b',
      aliases: [
        'cemig',
        'cemig distribuição',
        'cemig mg',
        'conta cemig',
        'luz cemig',
        'energia cemig',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'copel',
      categoria: 'Moradia',
      subcategoria: 'Energia Elétrica',
      regexPattern: r'\bcopel\b',
      aliases: [
        'copel',
        'copel distribuição',
        'copel pr',
        'conta copel',
        'luz copel',
        'energia copel',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'eletropaulo',
      categoria: 'Moradia',
      subcategoria: 'Energia Elétrica',
      regexPattern: r'eletropaulo|aes\s*eletropaulo',
      aliases: [
        'eletropaulo',
        'aes eletropaulo',
        'aes',
        'conta eletropaulo',
        'luz eletropaulo',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'celpe',
      categoria: 'Moradia',
      subcategoria: 'Energia Elétrica',
      regexPattern: r'\bcelpe\b',
      aliases: [
        'celpe',
        'celpe pernambuco',
        'celpe pe',
        'conta celpe',
        'luz celpe',
        'energia celpe',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'coelba',
      categoria: 'Moradia',
      subcategoria: 'Energia Elétrica',
      regexPattern: r'\bcoelba\b',
      aliases: [
        'coelba',
        'coelba bahia',
        'coelba ba',
        'conta coelba',
        'luz coelba',
        'energia coelba',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'coelce',
      categoria: 'Moradia',
      subcategoria: 'Energia Elétrica',
      regexPattern: r'\bcoelce\b',
      aliases: [
        'coelce',
        'coelce ceara',
        'coelce ce',
        'conta coelce',
        'luz coelce',
        'energia coelce',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'energisa',
      categoria: 'Moradia',
      subcategoria: 'Energia Elétrica',
      regexPattern: r'energisa',
      aliases: [
        'energisa',
        'energisa se',
        'energisa pb',
        'energisa mt',
        'conta energisa',
        'luz energisa',
        'energia energisa',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'eletrobras',
      categoria: 'Moradia',
      subcategoria: 'Energia Elétrica',
      regexPattern: r'eletrobr[aá]s',
      aliases: [
        'eletrobras',
        'eletrobrás',
        'conta eletrobras',
        'luz eletrobras',
        'energia eletrobras',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    // ═══════════════════════════════════════════════════════════
    // 💧 MORADIA - ÁGUA EXPANDIDO
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'cedae',
      categoria: 'Moradia',
      subcategoria: 'Água',
      regexPattern: r'\bcedae\b',
      aliases: [
        'cedae',
        'cedae rio',
        'cedae rj',
        'conta cedae',
        'agua cedae',
        'água cedae',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'sanepar',
      categoria: 'Moradia',
      subcategoria: 'Água',
      regexPattern: r'\bsanepar\b',
      aliases: [
        'sanepar',
        'saneamento do paraná',
        'sanepar pr',
        'conta sanepar',
        'agua sanepar',
        'água sanepar',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'copasa',
      categoria: 'Moradia',
      subcategoria: 'Água',
      regexPattern: r'\bcopasa\b',
      aliases: [
        'copasa',
        'copasa mg',
        'copasa minas',
        'conta copasa',
        'agua copasa',
        'água copasa',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'caesb',
      categoria: 'Moradia',
      subcategoria: 'Água',
      regexPattern: r'\bcaesb\b',
      aliases: [
        'caesb',
        'caesb df',
        'caesb brasilia',
        'conta caesb',
        'agua caesb',
        'água caesb',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'cagece',
      categoria: 'Moradia',
      subcategoria: 'Água',
      regexPattern: r'\bcagece\b',
      aliases: [
        'cagece',
        'cagece ce',
        'cagece ceara',
        'conta cagece',
        'agua cagece',
        'água cagece',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'embasa',
      categoria: 'Moradia',
      subcategoria: 'Água',
      regexPattern: r'\bembasa\b',
      aliases: [
        'embasa',
        'embasa ba',
        'embasa bahia',
        'conta embasa',
        'agua embasa',
        'água embasa',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    // ═══════════════════════════════════════════════════════════
    // 🌐 MORADIA - INTERNET/TV EXPANDIDO
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'vivo fibra',
      categoria: 'Moradia',
      subcategoria: 'Internet',
      regexPattern: r'vivo\s*(fibra|internet|tv)',
      aliases: [
        'vivo',
        'vivo fibra',
        'vivo internet',
        'vivo tv',
        'vivo banda larga',
        'conta vivo',
        'fatura vivo',
      ],
      confidence: 0.92,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'claro net',
      categoria: 'Moradia',
      subcategoria: 'Internet',
      regexPattern: r'claro|net\s*(claro)?',
      aliases: [
        'claro',
        'claro internet',
        'net claro',
        'claro tv',
        'net',
        'net virtua',
        'conta claro',
        'fatura claro',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'oi fibra',
      categoria: 'Moradia',
      subcategoria: 'Internet',
      regexPattern: r'\boi\b.*?(fibra|internet|tv)',
      aliases: [
        'oi',
        'oi fibra',
        'oi internet',
        'oi tv',
        'oi velox',
        'conta oi',
        'fatura oi',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'tim live',
      categoria: 'Moradia',
      subcategoria: 'Internet',
      regexPattern: r'tim\s*(live|fibra|internet)?',
      aliases: [
        'tim',
        'tim live',
        'tim fibra',
        'tim internet',
        'tim ultrafibra',
        'conta tim',
        'fatura tim',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'sky',
      categoria: 'Moradia',
      subcategoria: 'Internet',
      regexPattern: r'\bsky\b',
      aliases: [
        'sky',
        'sky tv',
        'sky banda larga',
        'sky internet',
        'conta sky',
        'fatura sky',
        'assinatura sky',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'directv',
      categoria: 'Moradia',
      subcategoria: 'Internet',
      regexPattern: r'direct\s*tv',
      aliases: [
        'directv',
        'direct tv',
        'directv go',
        'conta directv',
        'fatura directv',
        'assinatura directv',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'algar',
      categoria: 'Moradia',
      subcategoria: 'Internet',
      regexPattern: r'\balgar\b',
      aliases: [
        'algar',
        'algar telecom',
        'algar fibra',
        'conta algar',
        'fatura algar',
        'internet algar',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'brisanet',
      categoria: 'Moradia',
      subcategoria: 'Internet',
      regexPattern: r'brisa\s*net',
      aliases: [
        'brisanet',
        'brisa net',
        'brisanet fibra',
        'conta brisanet',
        'internet brisanet',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'intelig',
      categoria: 'Moradia',
      subcategoria: 'Internet',
      regexPattern: r'intelig',
      aliases: [
        'intelig',
        'intelig telecom',
        'intelig fibra',
        'conta intelig',
        'internet intelig',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    // ═══════════════════════════════════════════════════════════
    // 🔥 MORADIA - GÁS EXPANDIDO
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'ultragaz',
      categoria: 'Moradia',
      subcategoria: 'Gás',
      regexPattern: r'ultra\s*g[aá]s',
      aliases: [
        'ultragaz',
        'ultra gaz',
        'ultragás',
        'ultra-gaz',
        'botijao ultragaz',
        'botijão ultragaz',
        'gas ultragaz',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'liquigas',
      categoria: 'Moradia',
      subcategoria: 'Gás',
      regexPattern: r'liqui\s*g[aá]s',
      aliases: [
        'liquigas',
        'liquigás',
        'liqui gas',
        'liqui-gas',
        'botijao liquigas',
        'botijão liquigas',
        'gas liquigas',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'supergasbras',
      categoria: 'Moradia',
      subcategoria: 'Gás',
      regexPattern: r'super\s*g[aá]s\s*bras',
      aliases: [
        'supergasbras',
        'supergás',
        'super gas',
        'super gasbras',
        'botijao supergasbras',
        'gas supergasbras',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'nacional gas',
      categoria: 'Moradia',
      subcategoria: 'Gás',
      regexPattern: r'nacional\s*g[aá]s',
      aliases: [
        'nacional gas',
        'nacional gás',
        'nacionalgas',
        'botijao nacional',
        'gas nacional',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'consigaz',
      categoria: 'Moradia',
      subcategoria: 'Gás',
      regexPattern: r'consig[aá]s',
      aliases: [
        'consigaz',
        'consigás',
        'consigas',
        'botijao consigaz',
        'gas consigaz',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'botijao',
      categoria: 'Moradia',
      subcategoria: 'Gás',
      regexPattern: r'botij[aã]o|gas\s*de\s*cozinha',
      aliases: [
        'botijao',
        'botijão',
        'gas de cozinha',
        'gás de cozinha',
        'glp',
        'gas',
        'gás',
        'recarga gas',
        'troca botijao',
      ],
      confidence: 0.80,
      type: KeywordType.generica,
    ),

    // ═══════════════════════════════════════════════════════════
    // 🏥 SAÚDE - CONSULTAS EXPANDIDO
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'consulta medica',
      categoria: 'Saúde',
      subcategoria: 'Consultas Médicas/Dentista',
      regexPattern: r'consulta\s*m[eé]dica?',
      aliases: [
        'consulta',
        'consulta medica',
        'consulta médica',
        'médico',
        'medico',
        'doutor',
        'dr',
        'dra',
        'atendimento medico',
        'retorno medico',
      ],
      confidence: 0.85,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'dentista',
      categoria: 'Saúde',
      subcategoria: 'Consultas Médicas/Dentista',
      regexPattern: r'dentista|odonto',
      aliases: [
        'dentista',
        'odontologica',
        'odontológica',
        'odonto',
        'dente',
        'consulta dentista',
        'tratamento dentario',
        'limpeza dental',
        'clareamento',
        'aparelho dentario',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'clinica',
      categoria: 'Saúde',
      subcategoria: 'Consultas Médicas/Dentista',
      regexPattern: r'cl[íi]nica\s*(m[eé]dica|odonto)?',
      aliases: [
        'clinica',
        'clínica',
        'clinic',
        'clinica medica',
        'clinica odontologica',
        'centro medico',
      ],
      confidence: 0.80,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'hospital',
      categoria: 'Saúde',
      subcategoria: 'Consultas Médicas/Dentista',
      regexPattern: r'hospital|pronto\s*socorro',
      aliases: [
        'hospital',
        'pronto socorro',
        'ps',
        'emergencia',
        'emergência',
        'atendimento hospitalar',
        'internação',
      ],
      confidence: 0.85,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'psicologo',
      categoria: 'Saúde',
      subcategoria: 'Consultas Médicas/Dentista',
      regexPattern: r'psic[oó]logo|terapeuta|terapia',
      aliases: [
        'psicologo',
        'psicólogo',
        'terapeuta',
        'terapia',
        'psicoterapia',
        'consulta psicologo',
        'sessao terapia',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'fisioterapia',
      categoria: 'Saúde',
      subcategoria: 'Consultas Médicas/Dentista',
      regexPattern: r'fisioterapia|fisio',
      aliases: [
        'fisioterapia',
        'fisio',
        'fisioterapeuta',
        'sessao fisioterapia',
        'sessão fisio',
        'reabilitação',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    // ═══════════════════════════════════════════════════════════
    // 💊 SAÚDE - MEDICAMENTOS/FARMÁCIA EXPANDIDO
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'sao paulo farmacia',
      categoria: 'Saúde',
      subcategoria: 'Medicamentos',
      regexPattern: r's[aã]o\s*paulo\s*(farm|drog)',
      aliases: [
        'sao paulo',
        'são paulo',
        'drogaria são paulo',
        'farmacia sao paulo',
        'dpsp',
        'droga são paulo',
        'compra são paulo',
        'remedios são paulo',
      ],
      confidence: 0.85,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'pacheco',
      categoria: 'Saúde',
      subcategoria: 'Medicamentos',
      regexPattern: r'\bpacheco\b',
      aliases: [
        'pacheco',
        'drogaria pacheco',
        'farmacia pacheco',
        'dp',
        'compra pacheco',
        'remedios pacheco',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'pague menos',
      categoria: 'Saúde',
      subcategoria: 'Medicamentos',
      regexPattern: r'pague\s*menos',
      aliases: [
        'pague menos',
        'paguemenos',
        'drogaria pague menos',
        'farmacia pague menos',
        'compra pague menos',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'ultrafarma',
      categoria: 'Saúde',
      subcategoria: 'Medicamentos',
      regexPattern: r'ultra\s*farma',
      aliases: [
        'ultrafarma',
        'ultra farma',
        'ultrafarma online',
        'compra ultrafarma',
        'remedios ultrafarma',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'panvel',
      categoria: 'Saúde',
      subcategoria: 'Medicamentos',
      regexPattern: r'\bpanvel\b',
      aliases: [
        'panvel',
        'farmacia panvel',
        'drogaria panvel',
        'compra panvel',
        'remedios panvel',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'drogasmil',
      categoria: 'Saúde',
      subcategoria: 'Medicamentos',
      regexPattern: r'drogas\s*mil',
      aliases: [
        'drogasmil',
        'drogas mil',
        'drogaria mil',
        'compra drogasmil',
        'remedios drogasmil',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'venancio',
      categoria: 'Saúde',
      subcategoria: 'Medicamentos',
      regexPattern: r'ven[aâ]ncio',
      aliases: [
        'venancio',
        'venâncio',
        'drogaria venancio',
        'farmacia venancio',
        'compra venancio',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'medicamento',
      categoria: 'Saúde',
      subcategoria: 'Medicamentos',
      regexPattern: r'medicamentos?|rem[eé]dios?',
      aliases: [
        'medicamento',
        'medicamentos',
        'remedio',
        'remédio',
        'remedios',
        'remédios',
        'compra remedio',
        'compra medicamento',
      ],
      confidence: 0.78,
      type: KeywordType.generica,
    ),

    // ═══════════════════════════════════════════════════════════
    // 🩺 SAÚDE - EXAMES/LABORATÓRIOS EXPANDIDO
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'fleury',
      categoria: 'Saúde',
      subcategoria: 'Exames',
      regexPattern: r'\bfleury\b',
      aliases: [
        'fleury',
        'grupo fleury',
        'laboratorio fleury',
        'exame fleury',
        'lab fleury',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'dasa',
      categoria: 'Saúde',
      subcategoria: 'Exames',
      regexPattern: r'\bdasa\b',
      aliases: [
        'dasa',
        'laboratorio dasa',
        'grupo dasa',
        'exame dasa',
        'lab dasa',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'lavoisier',
      categoria: 'Saúde',
      subcategoria: 'Exames',
      regexPattern: r'lavoisier',
      aliases: [
        'lavoisier',
        'laboratorio lavoisier',
        'exame lavoisier',
        'lab lavoisier',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'hermes pardini',
      categoria: 'Saúde',
      subcategoria: 'Exames',
      regexPattern: r'hermes\s*pardini',
      aliases: [
        'hermes pardini',
        'hermespardini',
        'pardini',
        'laboratorio hermes pardini',
        'exame pardini',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'sabin',
      categoria: 'Saúde',
      subcategoria: 'Exames',
      regexPattern: r'\bsabin\b',
      aliases: [
        'sabin',
        'laboratorio sabin',
        'lab sabin',
        'exame sabin',
        'grupo sabin',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'laboratorio',
      categoria: 'Saúde',
      subcategoria: 'Exames',
      regexPattern: r'laborat[oó]rio|exames?|an[aá]lises?\s*cl[íi]nicas?',
      aliases: [
        'laboratorio',
        'laboratório',
        'lab',
        'exame',
        'exames',
        'analises clinicas',
        'análises clínicas',
        'check up',
      ],
      confidence: 0.80,
      type: KeywordType.generica,
    ),

    // ═══════════════════════════════════════════════════════════
    // 🏥 SAÚDE - PLANOS DE SAÚDE EXPANDIDO
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'unimed',
      categoria: 'Saúde',
      subcategoria: 'Plano de Saúde',
      regexPattern: r'\bunimed\b',
      aliases: [
        'unimed',
        'unimedsp',
        'unimed-',
        'unimed sp',
        'unimed rj',
        'mensalidade unimed',
        'plano unimed',
        'convenio unimed',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'amil',
      categoria: 'Saúde',
      subcategoria: 'Plano de Saúde',
      regexPattern: r'\bamil\b',
      aliases: [
        'amil',
        'plano amil',
        'mensalidade amil',
        'convenio amil',
        'amil one',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'bradesco saude',
      categoria: 'Saúde',
      subcategoria: 'Plano de Saúde',
      regexPattern: r'bradesco\s*sa[uú]de',
      aliases: [
        'bradesco saude',
        'bradesco saúde',
        'bradesco seguro saúde',
        'mensalidade bradesco saude',
        'plano bradesco',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'sulamerica',
      categoria: 'Saúde',
      subcategoria: 'Plano de Saúde',
      regexPattern: r'sulam[eé]rica',
      aliases: [
        'sulamerica',
        'sulamérica',
        'sul america',
        'sul américa',
        'mensalidade sulamerica',
        'plano sulamerica',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'notredame',
      categoria: 'Saúde',
      subcategoria: 'Plano de Saúde',
      regexPattern: r'notre\s*dame|intermédica',
      aliases: [
        'notredame',
        'notre dame',
        'intermédica',
        'intermedica',
        'mensalidade notredame',
        'plano notredame',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'hapvida',
      categoria: 'Saúde',
      subcategoria: 'Plano de Saúde',
      regexPattern: r'hap\s*vida',
      aliases: [
        'hapvida',
        'hap vida',
        'mensalidade hapvida',
        'plano hapvida',
        'convenio hapvida',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'prevent senior',
      categoria: 'Saúde',
      subcategoria: 'Plano de Saúde',
      regexPattern: r'prevent\s*senior',
      aliases: [
        'prevent senior',
        'preventsenior',
        'prevent',
        'mensalidade prevent',
        'plano prevent',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'golden cross',
      categoria: 'Saúde',
      subcategoria: 'Plano de Saúde',
      regexPattern: r'golden\s*cross',
      aliases: [
        'golden cross',
        'goldencross',
        'golden',
        'mensalidade golden cross',
        'plano golden',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'plano de saude',
      categoria: 'Saúde',
      subcategoria: 'Plano de Saúde',
      regexPattern: r'plano\s*de\s*sa[uú]de|conv[eê]nio\s*m[eé]dico',
      aliases: [
        'plano de saude',
        'plano de saúde',
        'convenio',
        'convênio',
        'convenio medico',
        'convênio médico',
        'mensalidade plano',
      ],
      confidence: 0.80,
      type: KeywordType.generica,
    ),

    // ═══════════════════════════════════════════════════════════
    // 🎓 EDUCAÇÃO - UNIVERSIDADES/FACULDADES EXPANDIDO
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'usp',
      categoria: 'Educação',
      subcategoria: 'Mensalidade',
      regexPattern: r'\busp\b',
      aliases: [
        'usp',
        'universidade de são paulo',
        'universidade de sao paulo',
        'mensalidade usp',
        'taxa usp',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'unip',
      categoria: 'Educação',
      subcategoria: 'Mensalidade',
      regexPattern: r'\bunip\b',
      aliases: [
        'unip',
        'universidade paulista',
        'mensalidade unip',
        'faculdade unip',
        'boleto unip',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'anhembi morumbi',
      categoria: 'Educação',
      subcategoria: 'Mensalidade',
      regexPattern: r'anhembi\s*morumbi',
      aliases: [
        'anhembi',
        'anhembi morumbi',
        'anhembimorumbi',
        'mensalidade anhembi',
        'faculdade anhembi',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'mackenzie',
      categoria: 'Educação',
      subcategoria: 'Mensalidade',
      regexPattern: r'mackenzie',
      aliases: [
        'mackenzie',
        'universidade mackenzie',
        'mack',
        'mensalidade mackenzie',
        'faculdade mackenzie',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'estacio',
      categoria: 'Educação',
      subcategoria: 'Mensalidade',
      regexPattern: r'est[aá]cio',
      aliases: [
        'estacio',
        'estácio',
        'universidade estacio',
        'mensalidade estacio',
        'faculdade estacio',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'uninove',
      categoria: 'Educação',
      subcategoria: 'Mensalidade',
      regexPattern: r'uninove',
      aliases: [
        'uninove',
        'universidade nove de julho',
        'mensalidade uninove',
        'faculdade uninove',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'fmu',
      categoria: 'Educação',
      subcategoria: 'Mensalidade',
      regexPattern: r'\bfmu\b',
      aliases: [
        'fmu',
        'faculdades metropolitanas unidas',
        'mensalidade fmu',
        'faculdade fmu',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'puc',
      categoria: 'Educação',
      subcategoria: 'Mensalidade',
      regexPattern: r'\bpuc\b',
      aliases: [
        'puc',
        'pontificia universidade catolica',
        'mensalidade puc',
        'faculdade puc',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'fgv',
      categoria: 'Educação',
      subcategoria: 'Mensalidade',
      regexPattern: r'\bfgv\b',
      aliases: [
        'fgv',
        'fundacao getulio vargas',
        'fundação getúlio vargas',
        'mensalidade fgv',
        'curso fgv',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'impacta',
      categoria: 'Educação',
      subcategoria: 'Mensalidade',
      regexPattern: r'impacta',
      aliases: [
        'impacta',
        'faculdade impacta',
        'mensalidade impacta',
        'curso impacta',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    // ═══════════════════════════════════════════════════════════
    // 🎓 EDUCAÇÃO - CURSOS ONLINE EXPANDIDO
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'udemy',
      categoria: 'Educação',
      subcategoria: 'Cursos',
      regexPattern: r'udemy',
      aliases: [
        'udemy',
        'ude my',
        'curso udemy',
        'assinatura udemy',
        'compra udemy',
        'udemy business',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'coursera',
      categoria: 'Educação',
      subcategoria: 'Cursos',
      regexPattern: r'coursera',
      aliases: [
        'coursera',
        'course ra',
        'curso coursera',
        'assinatura coursera',
        'coursera plus',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'alura',
      categoria: 'Educação',
      subcategoria: 'Cursos',
      regexPattern: r'\balura\b',
      aliases: [
        'alura',
        'curso alura',
        'assinatura alura',
        'alura cursos',
        'mensalidade alura',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'descomplica',
      categoria: 'Educação',
      subcategoria: 'Cursos',
      regexPattern: r'descomplica',
      aliases: [
        'descomplica',
        'des complica',
        'curso descomplica',
        'assinatura descomplica',
        'mensalidade descomplica',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'hotmart',
      categoria: 'Educação',
      subcategoria: 'Cursos',
      regexPattern: r'hotmart',
      aliases: [
        'hotmart',
        'hot mart',
        'curso hotmart',
        'compra hotmart',
        'produto hotmart',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'eduzz',
      categoria: 'Educação',
      subcategoria: 'Cursos',
      regexPattern: r'eduzz',
      aliases: [
        'eduzz',
        'curso eduzz',
        'compra eduzz',
        'produto eduzz',
        'assinatura eduzz',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'domestika',
      categoria: 'Educação',
      subcategoria: 'Cursos',
      regexPattern: r'domestika',
      aliases: [
        'domestika',
        'curso domestika',
        'compra domestika',
        'assinatura domestika',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'skillshare',
      categoria: 'Educação',
      subcategoria: 'Cursos',
      regexPattern: r'skill\s*share',
      aliases: [
        'skillshare',
        'skill share',
        'curso skillshare',
        'assinatura skillshare',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'linkedin learning',
      categoria: 'Educação',
      subcategoria: 'Cursos',
      regexPattern: r'linkedin\s*learning',
      aliases: [
        'linkedin learning',
        'linkedinlearning',
        'lynda',
        'curso linkedin',
        'assinatura linkedin learning',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'duolingo',
      categoria: 'Educação',
      subcategoria: 'Cursos',
      regexPattern: r'duolingo',
      aliases: [
        'duolingo',
        'duo lingo',
        'duolingo plus',
        'duolingo super',
        'assinatura duolingo',
        'curso idioma',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'babbel',
      categoria: 'Educação',
      subcategoria: 'Cursos',
      regexPattern: r'babbel',
      aliases: [
        'babbel',
        'babel',
        'curso babbel',
        'assinatura babbel',
        'idiomas babbel',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'wizard',
      categoria: 'Educação',
      subcategoria: 'Cursos',
      regexPattern: r'wizard',
      aliases: [
        'wizard',
        'wizard idiomas',
        'curso wizard',
        'mensalidade wizard',
        'ingles wizard',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'ccaa',
      categoria: 'Educação',
      subcategoria: 'Cursos',
      regexPattern: r'\bccaa\b',
      aliases: [
        'ccaa',
        'cultura inglesa ccaa',
        'curso ccaa',
        'mensalidade ccaa',
        'ingles ccaa',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'cultura inglesa',
      categoria: 'Educação',
      subcategoria: 'Cursos',
      regexPattern: r'cultura\s*inglesa',
      aliases: [
        'cultura inglesa',
        'culturainglesa',
        'curso cultura inglesa',
        'mensalidade cultura inglesa',
        'ingles cultura',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'kumon',
      categoria: 'Educação',
      subcategoria: 'Cursos',
      regexPattern: r'kumon',
      aliases: [
        'kumon',
        'curso kumon',
        'mensalidade kumon',
        'matematica kumon',
        'portugues kumon',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'curso',
      categoria: 'Educação',
      subcategoria: 'Cursos',
      regexPattern: r'curso|aula|treinamento|capacita[cç][aã]o',
      aliases: [
        'curso',
        'aula',
        'treinamento',
        'capacitação',
        'capacitacao',
        'workshop',
        'palestra',
        'formação',
        'formacao',
      ],
      confidence: 0.70,
      type: KeywordType.generica,
    ),

    // ═══════════════════════════════════════════════════════════
    // 📚 EDUCAÇÃO - LIVROS/MATERIAL EXPANDIDO
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'amazon livros',
      categoria: 'Educação',
      subcategoria: 'Livros',
      regexPattern: r'amazon|kindle',
      aliases: [
        'amazon',
        'amazon.com',
        'amazon br',
        'kindle',
        'livro amazon',
        'compra amazon',
        'ebook kindle',
      ],
      confidence: 0.85,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'saraiva',
      categoria: 'Educação',
      subcategoria: 'Livros',
      regexPattern: r'saraiva',
      aliases: [
        'saraiva',
        'livraria saraiva',
        'livro saraiva',
        'compra saraiva',
        'editora saraiva',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'cultura livraria',
      categoria: 'Educação',
      subcategoria: 'Livros',
      regexPattern: r'livraria\s*cultura',
      aliases: [
        'cultura',
        'livraria cultura',
        'livro cultura',
        'compra cultura',
        'loja cultura',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'fnac',
      categoria: 'Educação',
      subcategoria: 'Livros',
      regexPattern: r'\bfnac\b',
      aliases: [
        'fnac',
        'fnac brasil',
        'livro fnac',
        'compra fnac',
        'livraria fnac',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'travessa',
      categoria: 'Educação',
      subcategoria: 'Livros',
      regexPattern: r'travessa',
      aliases: [
        'travessa',
        'livraria da travessa',
        'livro travessa',
        'compra travessa',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'estante virtual',
      categoria: 'Educação',
      subcategoria: 'Livros',
      regexPattern: r'estante\s*virtual',
      aliases: [
        'estante virtual',
        'estantevirtual',
        'livro usado',
        'compra estante virtual',
        'sebo online',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'livro',
      categoria: 'Educação',
      subcategoria: 'Livros',
      regexPattern: r'livros?|livraria|apostila|ebook',
      aliases: [
        'livro',
        'livros',
        'livraria',
        'apostila',
        'apostilas',
        'ebook',
        'e-book',
        'compra livro',
      ],
      confidence: 0.78,
      type: KeywordType.generica,
    ),

    AdvancedKeywordMapping(
      keyword: 'kalunga',
      categoria: 'Educação',
      subcategoria: 'Material Escolar',
      regexPattern: r'kalunga',
      aliases: [
        'kalunga',
        'papelaria kalunga',
        'material kalunga',
        'compra kalunga',
        'loja kalunga',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'americanas material',
      categoria: 'Educação',
      subcategoria: 'Material Escolar',
      regexPattern: r'americanas',
      aliases: [
        'americanas',
        'lojas americanas',
        'americanas.com',
        'material escolar americanas',
      ],
      confidence: 0.85,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'material escolar',
      categoria: 'Educação',
      subcategoria: 'Material Escolar',
      regexPattern: r'material\s*escolar|papelaria|caderno|l[aá]pis',
      aliases: [
        'material escolar',
        'papelaria',
        'caderno',
        'cadernos',
        'lapis',
        'lápis',
        'caneta',
        'mochila',
        'estojo',
      ],
      confidence: 0.80,
      type: KeywordType.generica,
    ),

    // ═══════════════════════════════════════════════════════════
    // 🎬 LAZER - STREAMING EXPANDIDO
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'amazon prime',
      categoria: 'Lazer',
      subcategoria: 'Streaming',
      regexPattern: r'amazon\s*prime|prime\s*video',
      aliases: [
        'amazon prime',
        'prime video',
        'amazon video',
        'assinatura prime',
        'mensalidade prime',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'disney',
      categoria: 'Lazer',
      subcategoria: 'Streaming',
      regexPattern: r'disney\s*\+?|disney\s*plus',
      aliases: [
        'disney',
        'disney+',
        'disney plus',
        'disneyplus',
        'assinatura disney',
        'mensalidade disney',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'hbo max',
      categoria: 'Lazer',
      subcategoria: 'Streaming',
      regexPattern: r'hbo\s*max?',
      aliases: [
        'hbo',
        'hbo max',
        'hbomax',
        'assinatura hbo',
        'mensalidade hbo',
        'hbo go',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'paramount',
      categoria: 'Lazer',
      subcategoria: 'Streaming',
      regexPattern: r'paramount\s*\+?',
      aliases: [
        'paramount',
        'paramount+',
        'paramount plus',
        'paramountplus',
        'assinatura paramount',
        'mensalidade paramount',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'star+',
      categoria: 'Lazer',
      subcategoria: 'Streaming',
      regexPattern: r'star\s*\+',
      aliases: [
        'star+',
        'star plus',
        'starplus',
        'star +',
        'assinatura star',
        'mensalidade star',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'globoplay',
      categoria: 'Lazer',
      subcategoria: 'Streaming',
      regexPattern: r'globo\s*play',
      aliases: [
        'globoplay',
        'globo play',
        'globo +',
        'globo+',
        'assinatura globoplay',
        'mensalidade globoplay',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'telecine',
      categoria: 'Lazer',
      subcategoria: 'Streaming',
      regexPattern: r'telecine',
      aliases: [
        'telecine',
        'telecine play',
        'telecineplay',
        'assinatura telecine',
        'mensalidade telecine',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'apple tv',
      categoria: 'Lazer',
      subcategoria: 'Streaming',
      regexPattern: r'apple\s*tv\s*\+?',
      aliases: [
        'apple tv',
        'apple tv+',
        'apple tv plus',
        'appletv',
        'assinatura apple tv',
        'mensalidade apple',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'crunchyroll',
      categoria: 'Lazer',
      subcategoria: 'Streaming',
      regexPattern: r'crunchyroll',
      aliases: [
        'crunchyroll',
        'crunchyrol',
        'crunchy roll',
        'assinatura crunchyroll',
        'anime streaming',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'deezer',
      categoria: 'Lazer',
      subcategoria: 'Streaming',
      regexPattern: r'deezer',
      aliases: [
        'deezer',
        'dezer',
        'deezer premium',
        'assinatura deezer',
        'musica deezer',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'youtube premium',
      categoria: 'Lazer',
      subcategoria: 'Streaming',
      regexPattern: r'youtube\s*(premium|music)',
      aliases: [
        'youtube premium',
        'youtube music',
        'yt premium',
        'assinatura youtube',
        'mensalidade youtube',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'tidal',
      categoria: 'Lazer',
      subcategoria: 'Streaming',
      regexPattern: r'\btidal\b',
      aliases: [
        'tidal',
        'tidal music',
        'assinatura tidal',
        'mensalidade tidal',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    // ═══════════════════════════════════════════════════════════
    // 🎬 LAZER - CINEMA/TEATRO EXPANDIDO
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'cinemark',
      categoria: 'Lazer',
      subcategoria: 'Cinema/Teatro',
      regexPattern: r'cine\s*mark',
      aliases: [
        'cinemark',
        'cine mark',
        'ingresso cinemark',
        'cinema cinemark',
        'filme cinemark',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'uci',
      categoria: 'Lazer',
      subcategoria: 'Cinema/Teatro',
      regexPattern: r'\buci\b',
      aliases: [
        'uci',
        'uci cinemas',
        'ingresso uci',
        'cinema uci',
        'filme uci',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'kinoplex',
      categoria: 'Lazer',
      subcategoria: 'Cinema/Teatro',
      regexPattern: r'kinoplex',
      aliases: [
        'kinoplex',
        'kino plex',
        'ingresso kinoplex',
        'cinema kinoplex',
        'filme kinoplex',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'moviecom',
      categoria: 'Lazer',
      subcategoria: 'Cinema/Teatro',
      regexPattern: r'moviecom',
      aliases: [
        'moviecom',
        'movie com',
        'ingresso moviecom',
        'cinema moviecom',
        'filme moviecom',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'ingresso.com',
      categoria: 'Lazer',
      subcategoria: 'Cinema/Teatro',
      regexPattern: r'ingresso\s*\.?\s*com',
      aliases: [
        'ingresso.com',
        'ingressocom',
        'ingresso com',
        'compra ingresso',
        'ingresso online',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'sympla',
      categoria: 'Lazer',
      subcategoria: 'Cinema/Teatro',
      regexPattern: r'sympla',
      aliases: [
        'sympla',
        'ingresso sympla',
        'evento sympla',
        'compra sympla',
        'ticket sympla',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'eventim',
      categoria: 'Lazer',
      subcategoria: 'Cinema/Teatro',
      regexPattern: r'eventim',
      aliases: [
        'eventim',
        'ingresso eventim',
        'evento eventim',
        'compra eventim',
        'ticket eventim',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'cinema',
      categoria: 'Lazer',
      subcategoria: 'Cinema/Teatro',
      regexPattern: r'cinema|filme|ingresso\s*(de\s*)?filme',
      aliases: [
        'cinema',
        'filme',
        'ingresso',
        'ingresso filme',
        'ingresso cinema',
        'sessao cinema',
        'bilheteria',
      ],
      confidence: 0.82,
      type: KeywordType.generica,
    ),

    AdvancedKeywordMapping(
      keyword: 'teatro',
      categoria: 'Lazer',
      subcategoria: 'Cinema/Teatro',
      regexPattern: r'teatro|pe[cç]a|espet[aá]culo',
      aliases: [
        'teatro',
        'peça',
        'peca',
        'espetáculo',
        'espetaculo',
        'ingresso teatro',
        'show teatro',
      ],
      confidence: 0.88,
      type: KeywordType.generica,
    ),

    // ═══════════════════════════════════════════════════════════
    // ✈️ LAZER - VIAGENS EXPANDIDO
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'decolar',
      categoria: 'Lazer',
      subcategoria: 'Viagens',
      regexPattern: r'decolar',
      aliases: [
        'decolar',
        'decolar.com',
        'decolar com',
        'passagem decolar',
        'hotel decolar',
        'viagem decolar',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'booking',
      categoria: 'Lazer',
      subcategoria: 'Viagens',
      regexPattern: r'booking',
      aliases: [
        'booking',
        'booking.com',
        'bookingcom',
        'hotel booking',
        'reserva booking',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'airbnb',
      categoria: 'Lazer',
      subcategoria: 'Viagens',
      regexPattern: r'airbnb',
      aliases: [
        'airbnb',
        'air bnb',
        'air b&b',
        'hospedagem airbnb',
        'reserva airbnb',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'expedia',
      categoria: 'Lazer',
      subcategoria: 'Viagens',
      regexPattern: r'expedia',
      aliases: [
        'expedia',
        'expedia.com',
        'passagem expedia',
        'hotel expedia',
        'viagem expedia',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'trivago',
      categoria: 'Lazer',
      subcategoria: 'Viagens',
      regexPattern: r'trivago',
      aliases: ['trivago', 'tri vago', 'hotel trivago', 'reserva trivago'],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'maxmilhas',
      categoria: 'Lazer',
      subcategoria: 'Viagens',
      regexPattern: r'max\s*milhas',
      aliases: [
        'maxmilhas',
        'max milhas',
        'passagem maxmilhas',
        'viagem maxmilhas',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'viajanet',
      categoria: 'Lazer',
      subcategoria: 'Viagens',
      regexPattern: r'viaja\s*net',
      aliases: [
        'viajanet',
        'viaja net',
        'passagem viajanet',
        'hotel viajanet',
        'viagem viajanet',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'cvc',
      categoria: 'Lazer',
      subcategoria: 'Viagens',
      regexPattern: r'\bcvc\b',
      aliases: [
        'cvc',
        'cvc viagens',
        'cvc turismo',
        'pacote cvc',
        'viagem cvc',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'gol linhas aereas',
      categoria: 'Lazer',
      subcategoria: 'Viagens',
      regexPattern: r'\bgol\b.*?(linhas|aereas|voo)',
      aliases: [
        'gol',
        'gol linhas aereas',
        'gol linhas aéreas',
        'voegol',
        'voe gol',
        'passagem gol',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'latam',
      categoria: 'Lazer',
      subcategoria: 'Viagens',
      regexPattern: r'\blatam\b',
      aliases: [
        'latam',
        'latam airlines',
        'latam linhas aereas',
        'passagem latam',
        'voo latam',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'azul linhas aereas',
      categoria: 'Lazer',
      subcategoria: 'Viagens',
      regexPattern: r'\bazul\b.*?(linhas|aereas|voo)',
      aliases: [
        'azul',
        'azul linhas aereas',
        'azul linhas aéreas',
        'voeazul',
        'voe azul',
        'passagem azul',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'hotel',
      categoria: 'Lazer',
      subcategoria: 'Viagens',
      regexPattern: r'hot[eé]is?|hospedagem|pousada',
      aliases: [
        'hotel',
        'hoteis',
        'hotéis',
        'hospedagem',
        'pousada',
        'resort',
        'reserva hotel',
      ],
      confidence: 0.82,
      type: KeywordType.generica,
    ),

    AdvancedKeywordMapping(
      keyword: 'passagem aerea',
      categoria: 'Lazer',
      subcategoria: 'Viagens',
      regexPattern: r'passagem\s*a[eé]rea|voo|avi[aã]o',
      aliases: [
        'passagem',
        'passagem aerea',
        'passagem aérea',
        'voo',
        'aviao',
        'avião',
        'bilhete aereo',
      ],
      confidence: 0.85,
      type: KeywordType.generica,
    ),

    // ═══════════════════════════════════════════════════════════
    // 🎮 LAZER - GAMES/HOBBIES EXPANDIDO
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'steam',
      categoria: 'Lazer',
      subcategoria: 'Hobbies',
      regexPattern: r'\bsteam\b',
      aliases: [
        'steam',
        'steam games',
        'valve',
        'steam wallet',
        'jogo steam',
        'compra steam',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'playstation',
      categoria: 'Lazer',
      subcategoria: 'Hobbies',
      regexPattern: r'play\s*station|psn|ps\s*(store|plus)',
      aliases: [
        'playstation',
        'psn',
        'ps store',
        'ps plus',
        'ps+',
        'playstation network',
        'jogo ps',
        'assinatura ps',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'xbox',
      categoria: 'Lazer',
      subcategoria: 'Hobbies',
      regexPattern: r'xbox',
      aliases: [
        'xbox',
        'xbox live',
        'xbox game pass',
        'gamepass',
        'jogo xbox',
        'assinatura xbox',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'nintendo',
      categoria: 'Lazer',
      subcategoria: 'Hobbies',
      regexPattern: r'nintendo',
      aliases: [
        'nintendo',
        'switch',
        'eshop',
        'e-shop',
        'jogo nintendo',
        'nintendo eshop',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'nuuvem',
      categoria: 'Lazer',
      subcategoria: 'Hobbies',
      regexPattern: r'nuuvem',
      aliases: [
        'nuuvem',
        'nuvem',
        'loja nuuvem',
        'jogo nuuvem',
        'compra nuuvem',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'epic games',
      categoria: 'Lazer',
      subcategoria: 'Hobbies',
      regexPattern: r'epic\s*games',
      aliases: [
        'epic games',
        'epicgames',
        'epic store',
        'jogo epic',
        'compra epic',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'smartfit',
      categoria: 'Lazer',
      subcategoria: 'Hobbies',
      regexPattern: r'smart\s*fit',
      aliases: [
        'smartfit',
        'smart fit',
        'smart-fit',
        'academia smart fit',
        'mensalidade smart fit',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'bio ritmo',
      categoria: 'Lazer',
      subcategoria: 'Hobbies',
      regexPattern: r'bio\s*ritmo',
      aliases: [
        'bio ritmo',
        'bioritmo',
        'bio-ritmo',
        'academia bio ritmo',
        'mensalidade bio ritmo',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'bodytech',
      categoria: 'Lazer',
      subcategoria: 'Hobbies',
      regexPattern: r'body\s*tech',
      aliases: [
        'bodytech',
        'body tech',
        'body-tech',
        'academia bodytech',
        'mensalidade bodytech',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'bluefit',
      categoria: 'Lazer',
      subcategoria: 'Hobbies',
      regexPattern: r'blue\s*fit',
      aliases: [
        'bluefit',
        'blue fit',
        'blue-fit',
        'academia bluefit',
        'mensalidade bluefit',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'academia',
      categoria: 'Lazer',
      subcategoria: 'Hobbies',
      regexPattern: r'academia|gym|muscula[cç][aã]o',
      aliases: [
        'academia',
        'gym',
        'ginasio',
        'ginásio',
        'musculacao',
        'musculação',
        'mensalidade academia',
      ],
      confidence: 0.80,
      type: KeywordType.generica,
    ),

    // ═══════════════════════════════════════════════════════════
    // 👕 VESTUÁRIO EXPANDIDO
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'renner',
      categoria: 'Vestuário',
      subcategoria: 'Roupas',
      regexPattern: r'\brenner\b',
      aliases: [
        'renner',
        'lojas renner',
        'loja renner',
        'compra renner',
        'roupa renner',
        'vestuario renner',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'riachuelo',
      categoria: 'Vestuário',
      subcategoria: 'Roupas',
      regexPattern: r'riachuelo',
      aliases: [
        'riachuelo',
        'lojas riachuelo',
        'loja riachuelo',
        'compra riachuelo',
        'roupa riachuelo',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'marisa',
      categoria: 'Vestuário',
      subcategoria: 'Roupas',
      regexPattern: r'\bmarisa\b',
      aliases: [
        'marisa',
        'lojas marisa',
        'loja marisa',
        'compra marisa',
        'roupa marisa',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'c&a',
      categoria: 'Vestuário',
      subcategoria: 'Roupas',
      regexPattern: r'c\s*&\s*a|cea\b',
      aliases: ['c&a', 'cea', 'c e a', 'c & a', 'compra c&a', 'roupa c&a'],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'zara',
      categoria: 'Vestuário',
      subcategoria: 'Roupas',
      regexPattern: r'\bzara\b',
      aliases: ['zara', 'zara store', 'loja zara', 'compra zara', 'roupa zara'],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'hm',
      categoria: 'Vestuário',
      subcategoria: 'Roupas',
      regexPattern: r'\bh\s*&\s*m\b|h\s*m\b',
      aliases: ['h&m', 'hm', 'h & m', 'h e m', 'compra h&m', 'roupa h&m'],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'hering',
      categoria: 'Vestuário',
      subcategoria: 'Roupas',
      regexPattern: r'hering',
      aliases: [
        'hering',
        'cia hering',
        'companhia hering',
        'compra hering',
        'roupa hering',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'lacoste',
      categoria: 'Vestuário',
      subcategoria: 'Roupas',
      regexPattern: r'lacoste',
      aliases: [
        'lacoste',
        'loja lacoste',
        'compra lacoste',
        'roupa lacoste',
        'camisa lacoste',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'tommy hilfiger',
      categoria: 'Vestuário',
      subcategoria: 'Roupas',
      regexPattern: r'tommy\s*hilfiger',
      aliases: [
        'tommy hilfiger',
        'tommy',
        'tommyhilfiger',
        'compra tommy',
        'roupa tommy',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'nike',
      categoria: 'Vestuário',
      subcategoria: 'Roupas',
      regexPattern: r'\bnike\b',
      aliases: [
        'nike',
        'nike store',
        'loja nike',
        'compra nike',
        'tenis nike',
        'roupa nike',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'adidas',
      categoria: 'Vestuário',
      subcategoria: 'Roupas',
      regexPattern: r'adidas',
      aliases: [
        'adidas',
        'adidas store',
        'loja adidas',
        'compra adidas',
        'tenis adidas',
        'roupa adidas',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'puma',
      categoria: 'Vestuário',
      subcategoria: 'Roupas',
      regexPattern: r'\bpuma\b',
      aliases: [
        'puma',
        'puma store',
        'loja puma',
        'compra puma',
        'tenis puma',
        'roupa puma',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'centauro',
      categoria: 'Vestuário',
      subcategoria: 'Roupas',
      regexPattern: r'centauro',
      aliases: [
        'centauro',
        'loja centauro',
        'compra centauro',
        'esporte centauro',
        'tenis centauro',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'netshoes',
      categoria: 'Vestuário',
      subcategoria: 'Calçados',
      regexPattern: r'net\s*shoes',
      aliases: [
        'netshoes',
        'net shoes',
        'compra netshoes',
        'tenis netshoes',
        'calcado netshoes',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'zattini',
      categoria: 'Vestuário',
      subcategoria: 'Calçados',
      regexPattern: r'zattini',
      aliases: [
        'zattini',
        'compra zattini',
        'calcado zattini',
        'sapato zattini',
        'tenis zattini',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'shein',
      categoria: 'Vestuário',
      subcategoria: 'Roupas',
      regexPattern: r'shein',
      aliases: ['shein', 'she in', 'compra shein', 'roupa shein', 'site shein'],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'aliexpress',
      categoria: 'Vestuário',
      subcategoria: 'Roupas',
      regexPattern: r'ali\s*express',
      aliases: [
        'aliexpress',
        'ali express',
        'compra aliexpress',
        'roupa aliexpress',
        'site aliexpress',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    // ═══════════════════════════════════════════════════════════
    // 🐕 PETS EXPANDIDO
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'petz',
      categoria: 'Pets',
      subcategoria: 'Ração',
      regexPattern: r'\bpetz\b',
      aliases: [
        'petz',
        'pet shop petz',
        'petshop petz',
        'loja petz',
        'racao petz',
        'ração petz',
        'compra petz',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'cobasi',
      categoria: 'Pets',
      subcategoria: 'Ração',
      regexPattern: r'cobasi',
      aliases: [
        'cobasi',
        'cobasi pet shop',
        'petshop cobasi',
        'racao cobasi',
        'ração cobasi',
        'compra cobasi',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'petlove',
      categoria: 'Pets',
      subcategoria: 'Ração',
      regexPattern: r'pet\s*love',
      aliases: [
        'petlove',
        'pet love',
        'racao petlove',
        'ração petlove',
        'compra petlove',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'petco',
      categoria: 'Pets',
      subcategoria: 'Ração',
      regexPattern: r'\bpetco\b',
      aliases: [
        'petco',
        'pet shop petco',
        'racao petco',
        'ração petco',
        'compra petco',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'zee.dog',
      categoria: 'Pets',
      subcategoria: 'Acessórios',
      regexPattern: r'zee\s*\.?\s*dog',
      aliases: [
        'zee.dog',
        'zeedog',
        'zee dog',
        'coleira zee.dog',
        'acessorio zee.dog',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'racao',
      categoria: 'Pets',
      subcategoria: 'Ração',
      regexPattern:
          r'ra[cç][aã]o|alimento\s*pet|comida\s*(de\s*)?(cachorro|gato)',
      aliases: [
        'racao',
        'ração',
        'comida pet',
        'alimento pet',
        'comida cachorro',
        'comida gato',
        'alimentação pet',
      ],
      confidence: 0.85,
      type: KeywordType.generica,
    ),

    AdvancedKeywordMapping(
      keyword: 'veterinario',
      categoria: 'Pets',
      subcategoria: 'Veterinário',
      regexPattern: r'veterin[aá]rio|vet\b|cl[íi]nica\s*veterin',
      aliases: [
        'veterinario',
        'veterinário',
        'vet',
        'clinica veterinaria',
        'clínica veterinária',
        'consulta vet',
        'medico veterinario',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'banho e tosa',
      categoria: 'Pets',
      subcategoria: 'Acessórios',
      regexPattern: r'banho\s*(e|&)?\s*tosa|pet\s*grooming',
      aliases: [
        'banho e tosa',
        'banho tosa',
        'pet grooming',
        'tosa',
        'banho pet',
        'estetica pet',
      ],
      confidence: 0.92,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'vacina pet',
      categoria: 'Pets',
      subcategoria: 'Veterinário',
      regexPattern: r'vacina\s*pet|vacina[cç][aã]o\s*pet',
      aliases: [
        'vacina pet',
        'vacinação pet',
        'vacina cachorro',
        'vacina gato',
        'antirrábica',
        'v10',
        'v8',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'castracao',
      categoria: 'Pets',
      subcategoria: 'Veterinário',
      regexPattern: r'castra[cç][aã]o|esteriliza[cç][aã]o',
      aliases: [
        'castracao',
        'castração',
        'esterilização',
        'esterilizacao',
        'castrar',
        'esterilizar',
        'cirurgia pet',
      ],
      confidence: 0.92,
      type: KeywordType.especifica,
    ),

    // ═══════════════════════════════════════════════════════════
    // 💎 BENS E PATRIMÔNIO - SEÇÃO COMPLETA
    // ═══════════════════════════════════════════════════════════
    //
    // Subcategorias:
    // - Eletrônicos
    // - Eletrodomésticos
    // - Móveis e Decoração
    // - Veículo
    // - Imóvel
    // - Ferramentas e Equipamentos
    // - Reformas e Materiais
    //
    // Total: ~150 keywords avançadas
    // ═══════════════════════════════════════════════════════════

    // ───────────────────────────────────────────────────────────
    // 📱 ELETRÔNICOS - Marcas e Produtos
    // ───────────────────────────────────────────────────────────

    AdvancedKeywordMapping(
      keyword: 'samsung',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrônicos',
      regexPattern: r'samsung',
      aliases: [
        'samsung', 'samsung brasil', 'tv samsung', 'celular samsung',
        'notebook samsung', 'galaxy', 'galaxy s', 'galaxy a',
        'compra samsung', 'nota samsung',
      ],
      confidence: 0.92,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'lg eletronicos',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrônicos',
      regexPattern: r'\blg\b',
      aliases: [
        'lg', 'lg brasil', 'tv lg', 'monitor lg',
        'compra lg', 'nota lg', 'lg oled',
      ],
      confidence: 0.88,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'apple',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrônicos',
      regexPattern: r'apple|iphone|ipad|macbook',
      aliases: [
        'apple', 'apple store', 'iphone', 'ipad', 'macbook',
        'apple watch', 'airpods', 'compra apple', 'mac',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'sony',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrônicos',
      regexPattern: r'\bsony\b',
      aliases: [
        'sony', 'sony brasil', 'tv sony', 'camera sony',
        'playstation', 'ps5', 'compra sony',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'dell',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrônicos',
      regexPattern: r'\bdell\b',
      aliases: [
        'dell', 'notebook dell', 'computador dell',
        'monitor dell', 'compra dell',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'lenovo',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrônicos',
      regexPattern: r'lenovo',
      aliases: [
        'lenovo', 'notebook lenovo', 'thinkpad',
        'ideapad', 'compra lenovo',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'hp',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrônicos',
      regexPattern: r'\bhp\b',
      aliases: [
        'hp', 'hewlett packard', 'notebook hp',
        'impressora hp', 'compra hp',
      ],
      confidence: 0.85,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'asus',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrônicos',
      regexPattern: r'asus',
      aliases: [
        'asus', 'notebook asus', 'rog asus',
        'monitor asus', 'compra asus',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'xiaomi',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrônicos',
      regexPattern: r'xiaomi',
      aliases: [
        'xiaomi', 'redmi', 'poco', 'mi', 'celular xiaomi',
        'compra xiaomi', 'nota xiaomi',
      ],
      confidence: 0.92,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'motorola',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrônicos',
      regexPattern: r'motorola|moto\s*g|moto\s*e',
      aliases: [
        'motorola', 'moto g', 'moto e', 'edge',
        'celular motorola', 'compra motorola',
      ],
      confidence: 0.92,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'philips eletronicos',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrônicos',
      regexPattern: r'philips',
      aliases: [
        'philips', 'tv philips', 'monitor philips',
        'compra philips', 'nota philips',
      ],
      confidence: 0.88,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'jbl',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrônicos',
      regexPattern: r'\bjbl\b',
      aliases: [
        'jbl', 'caixa jbl', 'fone jbl', 'speaker jbl',
        'compra jbl', 'nota jbl',
      ],
      confidence: 0.92,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'bose',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrônicos',
      regexPattern: r'bose',
      aliases: [
        'bose', 'fone bose', 'caixa bose', 'speaker bose',
        'compra bose', 'nota bose',
      ],
      confidence: 0.92,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'logitech',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrônicos',
      regexPattern: r'logitech',
      aliases: [
        'logitech', 'mouse logitech', 'teclado logitech',
        'webcam logitech', 'compra logitech',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'canon',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrônicos',
      regexPattern: r'canon',
      aliases: [
        'canon', 'camera canon', 'impressora canon',
        'compra canon', 'nota canon',
      ],
      confidence: 0.92,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'nikon',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrônicos',
      regexPattern: r'nikon',
      aliases: [
        'nikon', 'camera nikon', 'lente nikon',
        'compra nikon', 'nota nikon',
      ],
      confidence: 0.92,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'gopro',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrônicos',
      regexPattern: r'gopro',
      aliases: [
        'gopro', 'go pro', 'camera gopro', 'action cam',
        'compra gopro',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'eletronico',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrônicos',
      regexPattern: r'eletr[oô]nicos?|celular|notebook|computador|tv\b',
      aliases: [
        'eletronico', 'eletrônico', 'celular', 'smartphone',
        'notebook', 'laptop', 'computador', 'pc', 'tv',
        'televisao', 'televisão', 'monitor', 'tablet',
        'camera', 'câmera', 'fone', 'headphone', 'caixa de som',
      ],
      confidence: 0.75,
      type: KeywordType.generica,
    ),

    // ───────────────────────────────────────────────────────────
    // 🏠 ELETRODOMÉSTICOS - Marcas e Produtos
    // ───────────────────────────────────────────────────────────

    AdvancedKeywordMapping(
      keyword: 'brastemp',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrodomésticos',
      regexPattern: r'brastemp',
      aliases: [
        'brastemp', 'geladeira brastemp', 'fogao brastemp',
        'lavadora brastemp', 'micro-ondas brastemp',
        'compra brastemp', 'nota brastemp',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'consul',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrodomésticos',
      regexPattern: r'consul',
      aliases: [
        'consul', 'geladeira consul', 'fogao consul',
        'lavadora consul', 'freezer consul',
        'compra consul', 'nota consul',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'electrolux',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrodomésticos',
      regexPattern: r'electrolux',
      aliases: [
        'electrolux', 'geladeira electrolux', 'lavadora electrolux',
        'aspirador electrolux', 'compra electrolux',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'lg eletrodomesticos',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrodomésticos',
      regexPattern: r'\blg\b',
      aliases: [
        'lg', 'geladeira lg', 'lavadora lg',
        'micro-ondas lg', 'compra lg',
      ],
      confidence: 0.85,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'midea',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrodomésticos',
      regexPattern: r'midea',
      aliases: [
        'midea', 'ar condicionado midea', 'lavadora midea',
        'compra midea', 'nota midea',
      ],
      confidence: 0.92,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'philco',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrodomésticos',
      regexPattern: r'philco',
      aliases: [
        'philco', 'geladeira philco', 'ar condicionado philco',
        'compra philco', 'nota philco',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'britania',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrodomésticos',
      regexPattern: r'brit[aâ]nia',
      aliases: [
        'britania', 'britânia', 'ventilador britania',
        'liquidificador britania', 'compra britania',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'arno',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrodomésticos',
      regexPattern: r'\barno\b',
      aliases: [
        'arno', 'liquidificador arno', 'batedeira arno',
        'ferro arno', 'compra arno',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'mondial',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrodomésticos',
      regexPattern: r'mondial',
      aliases: [
        'mondial', 'ventilador mondial', 'air fryer mondial',
        'compra mondial', 'nota mondial',
      ],
      confidence: 0.88,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'cadence',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrodomésticos',
      regexPattern: r'cadence',
      aliases: [
        'cadence', 'air fryer cadence', 'liquidificador cadence',
        'compra cadence',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'tramontina',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrodomésticos',
      regexPattern: r'tramontina',
      aliases: [
        'tramontina', 'panela tramontina', 'air fryer tramontina',
        'compra tramontina',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'gree',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrodomésticos',
      regexPattern: r'\bgree\b',
      aliases: [
        'gree', 'ar condicionado gree', 'compra gree',
      ],
      confidence: 0.92,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'springer',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrodomésticos',
      regexPattern: r'springer',
      aliases: [
        'springer', 'ar condicionado springer', 'compra springer',
      ],
      confidence: 0.92,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'eletrodomestico',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrodomésticos',
      regexPattern: r'eletrodom[eé]sticos?|geladeira|fog[aã]o|lavadora|ar\s*condicionado',
      aliases: [
        'eletrodomestico', 'eletrodoméstico', 'geladeira', 'refrigerador',
        'fogao', 'fogão', 'lavadora', 'maquina lavar', 'máquina lavar',
        'micro-ondas', 'microondas', 'ar condicionado', 'arcondicionado',
        'freezer', 'lava louça', 'lava-louça', 'secadora',
        'aspirador', 'ventilador', 'air fryer', 'airfryer',
      ],
      confidence: 0.78,
      type: KeywordType.generica,
    ),

    // ───────────────────────────────────────────────────────────
    // 🛋️ MÓVEIS E DECORAÇÃO
    // ───────────────────────────────────────────────────────────

    AdvancedKeywordMapping(
      keyword: 'tok stok',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Móveis e Decoração',
      regexPattern: r'tok\s*stok',
      aliases: [
        'tok stok', 'tokstok', 'tok&stok', 'tok & stok',
        'moveis tok stok', 'decoracao tok stok',
        'compra tok stok',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'etna',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Móveis e Decoração',
      regexPattern: r'\betna\b',
      aliases: [
        'etna', 'moveis etna', 'sofa etna',
        'compra etna', 'nota etna',
      ],
      confidence: 0.92,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'madesa',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Móveis e Decoração',
      regexPattern: r'madesa',
      aliases: [
        'madesa', 'moveis madesa', 'armario madesa',
        'guarda roupa madesa', 'compra madesa',
      ],
      confidence: 0.92,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'mobly',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Móveis e Decoração',
      regexPattern: r'mobly',
      aliases: [
        'mobly', 'moveis mobly', 'sofa mobly',
        'compra mobly', 'site mobly',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'madeiramadeira',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Móveis e Decoração',
      regexPattern: r'madeira\s*madeira',
      aliases: [
        'madeiramadeira', 'madeira madeira', 'moveis madeiramadeira',
        'compra madeiramadeira', 'site madeiramadeira',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'camicado',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Móveis e Decoração',
      regexPattern: r'camicado',
      aliases: [
        'camicado', 'decoracao camicado', 'cama mesa banho',
        'compra camicado',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'moveis',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Móveis e Decoração',
      regexPattern: r'm[oó]veis?|sof[aá]|cama|mesa|cadeira',
      aliases: [
        'moveis', 'móveis', 'sofa', 'sofá', 'cama',
        'mesa', 'cadeira', 'armario', 'armário', 'estante',
        'guarda roupa', 'guarda-roupa', 'rack', 'comoda', 'cômoda',
      ],
      confidence: 0.75,
      type: KeywordType.generica,
    ),

    AdvancedKeywordMapping(
      keyword: 'decoracao',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Móveis e Decoração',
      regexPattern: r'decora[cç][aã]o|quadro|tapete|cortina',
      aliases: [
        'decoracao', 'decoração', 'quadro', 'tapete',
        'cortina', 'persiana', 'almofada', 'planta',
        'vaso', 'luminaria', 'luminária', 'enfeite',
      ],
      confidence: 0.75,
      type: KeywordType.generica,
    ),

    // ───────────────────────────────────────────────────────────
    // 🚗 VEÍCULO - Peças e Acessórios
    // ───────────────────────────────────────────────────────────

    AdvancedKeywordMapping(
      keyword: 'peca carro',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Veículo',
      regexPattern: r'pe[cç]a\s*(carro|automotiva)|auto\s*pe[cç]a',
      aliases: [
        'peca carro', 'peça carro', 'peca automotiva', 'peça automotiva',
        'auto peca', 'auto peça', 'autopeca', 'autopeça',
      ],
      confidence: 0.88,
      type: KeywordType.generica,
    ),

    AdvancedKeywordMapping(
      keyword: 'acessorio carro',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Veículo',
      regexPattern: r'acess[oó]rio\s*(carro|automotivo)|tapete\s*carro',
      aliases: [
        'acessorio carro', 'acessório carro', 'tapete carro',
        'capa banco', 'protetor', 'suporte celular carro',
      ],
      confidence: 0.82,
      type: KeywordType.generica,
    ),

    AdvancedKeywordMapping(
      keyword: 'som automotivo',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Veículo',
      regexPattern: r'som\s*automotivo|som\s*carro|auto\s*radio',
      aliases: [
        'som automotivo', 'som carro', 'auto radio', 'autorádio',
        'alto falante carro', 'subwoofer', 'amplificador carro',
      ],
      confidence: 0.88,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'alarme carro',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Veículo',
      regexPattern: r'alarme\s*(carro|automotivo)|rastreador',
      aliases: [
        'alarme carro', 'alarme automotivo', 'rastreador',
        'rastreador gps', 'bloqueador', 'trava',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'insulfilm',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Veículo',
      regexPattern: r'insulfilm|pel[íi]cula\s*carro',
      aliases: [
        'insulfilm', 'pelicula carro', 'película carro',
        'insulfilm vidro', 'pelicula automotiva',
      ],
      confidence: 0.92,
      type: KeywordType.especifica,
    ),

    // ───────────────────────────────────────────────────────────
    // 🏠 IMÓVEL - Sem Reformas (apenas manutenção)
    // ───────────────────────────────────────────────────────────

    AdvancedKeywordMapping(
      keyword: 'manutencao imovel',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Imóvel',
      regexPattern: r'manuten[cç][aã]o\s*(casa|im[oó]vel)',
      aliases: [
        'manutencao casa', 'manutenção casa', 'manutencao imovel',
        'manutenção imóvel', 'reparo casa', 'conserto casa',
      ],
      confidence: 0.85,
      type: KeywordType.generica,
    ),

    AdvancedKeywordMapping(
      keyword: 'pintura',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Imóvel',
      regexPattern: r'pintura|tinta|pintor',
      aliases: [
        'pintura', 'tinta', 'pintor', 'pintura casa',
        'pintura parede', 'tinta parede', 'massa corrida',
      ],
      confidence: 0.88,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'hidraulica',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Imóvel',
      regexPattern: r'hidr[aá]ulica|encanamento|encanador',
      aliases: [
        'hidraulica', 'hidráulica', 'encanamento', 'encanador',
        'torneira', 'registro', 'cano', 'tubulação',
        'vazamento', 'reparo hidraulico',
      ],
      confidence: 0.88,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'eletrica',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Imóvel',
      regexPattern: r'el[eé]trica|eletricista|fia[cç][aã]o',
      aliases: [
        'eletrica', 'elétrica', 'eletricista', 'fiacao', 'fiação',
        'tomada', 'interruptor', 'disjuntor', 'instalacao eletrica',
        'reparo eletrico',
      ],
      confidence: 0.88,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'vidracaria',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Imóvel',
      regexPattern: r'vidra[cç]aria|vidro|espelho',
      aliases: [
        'vidracaria', 'vidraçaria', 'vidro', 'espelho',
        'box banheiro', 'janela vidro', 'porta vidro',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    // ───────────────────────────────────────────────────────────
    // 🔧 FERRAMENTAS E EQUIPAMENTOS
    // ───────────────────────────────────────────────────────────

    AdvancedKeywordMapping(
      keyword: 'bosch ferramentas',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Ferramentas e Equipamentos',
      regexPattern: r'bosch',
      aliases: [
        'bosch', 'ferramenta bosch', 'furadeira bosch',
        'parafusadeira bosch', 'compra bosch',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'dewalt',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Ferramentas e Equipamentos',
      regexPattern: r'dewalt',
      aliases: [
        'dewalt', 'de walt', 'ferramenta dewalt',
        'furadeira dewalt', 'compra dewalt',
      ],
      confidence: 0.92,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'makita',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Ferramentas e Equipamentos',
      regexPattern: r'makita',
      aliases: [
        'makita', 'ferramenta makita', 'furadeira makita',
        'serra makita', 'compra makita',
      ],
      confidence: 0.92,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'black decker',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Ferramentas e Equipamentos',
      regexPattern: r'black\s*decker',
      aliases: [
        'black decker', 'blackdecker', 'black & decker',
        'ferramenta black decker', 'compra black decker',
      ],
      confidence: 0.92,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'vonder',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Ferramentas e Equipamentos',
      regexPattern: r'vonder',
      aliases: [
        'vonder', 'ferramenta vonder', 'compra vonder',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'ferramentas',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Ferramentas e Equipamentos',
      regexPattern: r'ferrament|furadeira|parafusadeira|serra',
      aliases: [
        'ferramenta', 'ferramentas', 'furadeira', 'parafusadeira',
        'serra', 'serra eletrica', 'chave', 'martelo',
        'alicate', 'chave fenda', 'chave philips',
        'equipamento', 'kit ferramentas',
      ],
      confidence: 0.78,
      type: KeywordType.generica,
    ),

    AdvancedKeywordMapping(
      keyword: 'jardim',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Ferramentas e Equipamentos',
      regexPattern: r'jardim|jardinagem|cortador\s*grama',
      aliases: [
        'jardim', 'jardinagem', 'cortador grama', 'cortador de grama',
        'aparador', 'roçadeira', 'mangueira', 'aspersor',
        'ferramenta jardim',
      ],
      confidence: 0.82,
      type: KeywordType.generica,
    ),

    // ───────────────────────────────────────────────────────────
    // 🏗️ REFORMAS E MATERIAIS (Nova Subcategoria)
    // ───────────────────────────────────────────────────────────

    AdvancedKeywordMapping(
      keyword: 'leroy merlin',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Reformas e Materiais',
      regexPattern: r'leroy\s*merlin',
      aliases: [
        'leroy merlin', 'leroy', 'leroymerlin',
        'material construcao leroy', 'reforma leroy',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'telhanorte',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Reformas e Materiais',
      regexPattern: r'telha\s*norte',
      aliases: [
        'telhanorte', 'telha norte', 'material construcao telhanorte',
        'compra telhanorte',
      ],
      confidence: 0.92,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'dicico',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Reformas e Materiais',
      regexPattern: r'dicico',
      aliases: [
        'dicico', 'material construcao dicico', 'compra dicico',
      ],
      confidence: 0.92,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'reforma',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Reformas e Materiais',
      regexPattern: r'reforma|constru[cç][aã]o|renova[cç][aã]o',
      aliases: [
        'reforma', 'construcao', 'construção', 'renovacao', 'renovação',
        'obra', 'reforma casa', 'reforma apartamento',
      ],
      confidence: 0.85,
      type: KeywordType.generica,
    ),

    AdvancedKeywordMapping(
      keyword: 'pedreiro',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Reformas e Materiais',
      regexPattern: r'pedreiro|alvenaria',
      aliases: [
        'pedreiro', 'alvenaria', 'obra',
        'reboco', 'massa', 'cimento', 'tijolo',
      ],
      confidence: 0.88,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'piso',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Reformas e Materiais',
      regexPattern: r'piso|porcelanato|cer[aâ]mica|revestimento',
      aliases: [
        'piso', 'porcelanato', 'ceramica', 'cerâmica',
        'revestimento', 'azulejo', 'piso laminado',
        'piso vinilico', 'piso vinílico',
      ],
      confidence: 0.85,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'marcenaria',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Reformas e Materiais',
      regexPattern: r'marcenaria|marceneiro',
      aliases: [
        'marcenaria', 'marceneiro', 'madeira',
        'armario planejado', 'armário planejado', 'moveis planejados',
        'cozinha planejada',
      ],
      confidence: 0.88,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'serralheria',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Reformas e Materiais',
      regexPattern: r'serralheria|serralheiro|port[aã]o',
      aliases: [
        'serralheria', 'serralheiro', 'portao', 'portão',
        'grade', 'cerca', 'ferro', 'aluminio', 'alumínio',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'material construcao',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Reformas e Materiais',
      regexPattern: r'material\s*constru[cç][aã]o|cimento|areia|brita',
      aliases: [
        'material construcao', 'material construção', 'cimento',
        'areia', 'brita', 'pedra', 'tijolo', 'telha',
      ],
      confidence: 0.85,
      type: KeywordType.generica,
    ),

    // ───────────────────────────────────────────────────────────
    // 🏪 LOJAS GERAIS - CONTEXTO (podem vender múltiplos itens)
    // ───────────────────────────────────────────────────────────

    AdvancedKeywordMapping(
      keyword: 'casas bahia',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrônicos',
      regexPattern: r'casas\s*bahia',
      aliases: [
        'casas bahia', 'casasbahia', 'casa bahia',
        'compra casas bahia', 'eletro casas bahia',
      ],
      confidence: 0.82,
      type: KeywordType.contextual,
    ),

    AdvancedKeywordMapping(
      keyword: 'magazine luiza',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrônicos',
      regexPattern: r'magazine\s*luiza|magalu',
      aliases: [
        'magazine luiza', 'magalu', 'magazine', 'mag luiza',
        'compra magazine', 'eletro magalu',
      ],
      confidence: 0.82,
      type: KeywordType.contextual,
    ),

    AdvancedKeywordMapping(
      keyword: 'ponto frio',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrodomésticos',
      regexPattern: r'ponto\s*frio',
      aliases: [
        'ponto frio', 'pontofrio', 'ponto-frio',
        'compra ponto frio', 'eletro ponto frio',
      ],
      confidence: 0.82,
      type: KeywordType.contextual,
    ),

    AdvancedKeywordMapping(
      keyword: 'fast shop',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrônicos',
      regexPattern: r'fast\s*shop',
      aliases: [
        'fast shop', 'fastshop', 'fast-shop',
        'compra fast shop', 'eletro fast shop',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'extra',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrônicos',
      regexPattern: r'\bextra\b',
      aliases: [
        'extra', 'extra hipermercado', 'extra eletro',
        'compra extra',
      ],
      confidence: 0.75,
      type: KeywordType.contextual,
    ),

    // ═══════════════════════════════════════════════════════════
    // 💰 RECEITAS - SALÁRIO EXPANDIDO
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'salario',
      categoria: 'Salário',
      subcategoria: 'Salário Principal',
      regexPattern: r'sal[aá]rio|pagamento|ordenado|vencimento',
      aliases: [
        'salario',
        'salário',
        'pagamento',
        'vencimento',
        'ordenado',
        'recebimento salario',
        'deposito salario',
        'salario depositado',
        'contracheque',
        'holerite',
      ],
      confidence: 0.88,
      type: KeywordType.generica,
    ),

    AdvancedKeywordMapping(
      keyword: '13 salario',
      categoria: 'Salário',
      subcategoria: '13º Salário',
      regexPattern: r'13\s*[oº°]?\s*sal[aá]rio|d[eé]cimo\s*terceiro',
      aliases: [
        '13 salario',
        '13º salário',
        'decimo terceiro',
        '13o',
        '13º',
        'gratificacao natalina',
        'gratificação natalina',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'ferias',
      categoria: 'Salário',
      subcategoria: 'Bonificação',
      regexPattern: r'f[eé]rias|ter[cç]o\s*de\s*f[eé]rias',
      aliases: [
        'ferias',
        'férias',
        'terço de ferias',
        'terço de férias',
        '1/3 de ferias',
        'abono ferias',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'bonus',
      categoria: 'Salário',
      subcategoria: 'Bonificação',
      regexPattern: r'b[oô]nus|bonifica[cç][aã]o|gratifica[cç][aã]o',
      aliases: [
        'bonus',
        'bônus',
        'bonificação',
        'bonificacao',
        'gratificação',
        'gratificacao',
        'premiação',
        'premiacao',
      ],
      confidence: 0.85,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'hora extra',
      categoria: 'Salário',
      subcategoria: 'Horas Extras',
      regexPattern: r'hora\s*extra|horas\s*extras|h\s*e\b',
      aliases: [
        'hora extra',
        'horas extras',
        'he',
        'adicional noturno',
        'sobreaviso',
        'plantão',
      ],
      confidence: 0.88,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'comissao',
      categoria: 'Salário',
      subcategoria: 'Bonificação',
      regexPattern: r'comiss[aã]o|comissionamento',
      aliases: [
        'comissao',
        'comissão',
        'comissionamento',
        'comissão de vendas',
        'recebimento comissao',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    // ═══════════════════════════════════════════════════════════
    // 💼 RECEITAS - FREELANCE/AUTÔNOMO EXPANDIDO
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'freelancer',
      categoria: 'Freelance',
      subcategoria: 'Projetos',
      regexPattern: r'freelanc?er|freela|aut[oô]nomo',
      aliases: [
        'freelancer',
        'freela',
        'free lancer',
        'autonomo',
        'autônomo',
        'trabalho freelancer',
        'projeto freelancer',
      ],
      confidence: 0.82,
      type: KeywordType.generica,
    ),

    AdvancedKeywordMapping(
      keyword: 'upwork',
      categoria: 'Freelance',
      subcategoria: 'Projetos',
      regexPattern: r'upwork',
      aliases: [
        'upwork',
        'up work',
        'recebimento upwork',
        'pagamento upwork',
        'projeto upwork',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'fiverr',
      categoria: 'Freelance',
      subcategoria: 'Projetos',
      regexPattern: r'fiverr',
      aliases: [
        'fiverr',
        'fiver',
        'recebimento fiverr',
        'pagamento fiverr',
        'gig fiverr',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'workana',
      categoria: 'Freelance',
      subcategoria: 'Projetos',
      regexPattern: r'workana',
      aliases: [
        'workana',
        'work ana',
        'recebimento workana',
        'pagamento workana',
        'projeto workana',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: '99freelas',
      categoria: 'Freelance',
      subcategoria: 'Projetos',
      regexPattern: r'99\s*freelas',
      aliases: [
        '99freelas',
        '99 freelas',
        'recebimento 99freelas',
        'pagamento 99freelas',
        'projeto 99freelas',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'paypal',
      categoria: 'Freelance',
      subcategoria: 'Projetos',
      regexPattern: r'pay\s*pal',
      aliases: [
        'paypal',
        'pay pal',
        'paypal *',
        'recebimento paypal',
        'transferencia paypal',
        'saldo paypal',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'mercado pago',
      categoria: 'Freelance',
      subcategoria: 'Projetos',
      regexPattern: r'mercado\s*pago|mp\s*\*',
      aliases: [
        'mercado pago',
        'mercadopago',
        'mp *',
        'mp',
        'recebimento mercado pago',
        'transferencia mp',
      ],
      confidence: 0.85,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'consultoria',
      categoria: 'Freelance',
      subcategoria: 'Consultoria',
      regexPattern: r'consultoria|assessoria|consultor',
      aliases: [
        'consultoria',
        'consultor',
        'consultora',
        'assessoria',
        'serviço consultoria',
        'trabalho consultoria',
      ],
      confidence: 0.82,
      type: KeywordType.generica,
    ),

    // ═══════════════════════════════════════════════════════════
    // 📈 RECEITAS - INVESTIMENTOS EXPANDIDO
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'dividendo',
      categoria: 'Investimentos',
      subcategoria: 'Dividendos',
      regexPattern: r'dividendos?|proventos?',
      aliases: [
        'dividendo',
        'dividendos',
        'proventos',
        'provento',
        'div',
        'recebimento dividendo',
        'pagamento dividendo',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'jcp',
      categoria: 'Investimentos',
      subcategoria: 'Dividendos',
      regexPattern: r'\bjcp\b|juros\s*capital\s*pr[oó]prio',
      aliases: [
        'jcp',
        'juros capital proprio',
        'juros sobre capital',
        'juros capital próprio',
        'recebimento jcp',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'rendimento',
      categoria: 'Investimentos',
      subcategoria: 'Juros',
      regexPattern: r'rendimentos?|juros|yield',
      aliases: [
        'rendimento',
        'rendimentos',
        'juros',
        'yield',
        'recebimento rendimento',
        'juros recebidos',
      ],
      confidence: 0.78,
      type: KeywordType.generica,
    ),

    AdvancedKeywordMapping(
      keyword: 'cdb',
      categoria: 'Investimentos',
      subcategoria: 'Rendimentos CDB',
      regexPattern: r'\bcdb\b|certificado\s*dep[oó]sito',
      aliases: [
        'cdb',
        'certificado deposito',
        'certificado depósito',
        'renda fixa',
        'rendimento cdb',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'tesouro direto',
      categoria: 'Investimentos',
      subcategoria: 'Rendimentos CDB',
      regexPattern: r'tesouro\s*direto|t[íi]tulo\s*p[uú]blico',
      aliases: [
        'tesouro direto',
        'tesouro',
        'td',
        'titulo publico',
        'título público',
        'tesouro selic',
        'tesouro ipca',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'fii',
      categoria: 'Investimentos',
      subcategoria: 'Fundos',
      regexPattern: r'\bfii\b|fundos?\s*imobili[aá]rios?',
      aliases: [
        'fii',
        'fundos imobiliarios',
        'fundos imobiliários',
        'fundo imobiliario',
        'recebimento fii',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'acao',
      categoria: 'Investimentos',
      subcategoria: 'Dividendos',
      regexPattern: r'a[cç][oõ]es?|bolsa\s*de\s*valores',
      aliases: [
        'acao',
        'ações',
        'ação',
        'bolsa de valores',
        'bovespa',
        'b3',
        'venda acao',
        'venda ações',
      ],
      confidence: 0.82,
      type: KeywordType.generica,
    ),

    // ═══════════════════════════════════════════════════════════
    // 🛍️ RECEITAS - VENDAS EXPANDIDO
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'mercado livre',
      categoria: 'Vendas',
      subcategoria: 'Produtos',
      regexPattern: r'mercado\s*livre|meli',
      aliases: [
        'mercado livre',
        'mercadolivre',
        'ml',
        'meli',
        'venda mercado livre',
        'recebimento mercado livre',
        'pagamento ml',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'olx',
      categoria: 'Vendas',
      subcategoria: 'Usados',
      regexPattern: r'\bolx\b',
      aliases: [
        'olx',
        'olx brasil',
        'venda olx',
        'recebimento olx',
        'produto olx',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'shopee',
      categoria: 'Vendas',
      subcategoria: 'Produtos',
      regexPattern: r'shopee',
      aliases: [
        'shopee',
        'shope',
        'shopee brasil',
        'venda shopee',
        'recebimento shopee',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'enjoei',
      categoria: 'Vendas',
      subcategoria: 'Usados',
      regexPattern: r'enjoei',
      aliases: [
        'enjoei',
        'enjoei.com',
        'venda enjoei',
        'recebimento enjoei',
        'produto enjoei',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'elo7',
      categoria: 'Vendas',
      subcategoria: 'Artesanato',
      regexPattern: r'elo\s*7',
      aliases: [
        'elo7',
        'elo 7',
        'venda elo7',
        'recebimento elo7',
        'artesanato elo7',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'etsy',
      categoria: 'Vendas',
      subcategoria: 'Artesanato',
      regexPattern: r'etsy',
      aliases: [
        'etsy',
        'venda etsy',
        'recebimento etsy',
        'artesanato etsy',
        'handmade etsy',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'vinted',
      categoria: 'Vendas',
      subcategoria: 'Usados',
      regexPattern: r'vinted',
      aliases: [
        'vinted',
        'venda vinted',
        'recebimento vinted',
        'roupa usada vinted',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'facebook marketplace',
      categoria: 'Vendas',
      subcategoria: 'Usados',
      regexPattern: r'facebook\s*marketplace|marketplace',
      aliases: [
        'facebook marketplace',
        'marketplace',
        'fb marketplace',
        'venda facebook',
        'venda marketplace',
      ],
      confidence: 0.88,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'venda',
      categoria: 'Vendas',
      subcategoria: 'Produtos',
      regexPattern: r'vendas?|com[eé]rcio|recebimento\s*venda',
      aliases: [
        'venda',
        'vendas',
        'comercio',
        'comércio',
        'recebimento venda',
        'pagamento venda',
        'receita venda',
      ],
      confidence: 0.70,
      type: KeywordType.generica,
    ),

    AdvancedKeywordMapping(
      keyword: 'brecho',
      categoria: 'Vendas',
      subcategoria: 'Usados',
      regexPattern: r'brech[oó]|bazar|usado',
      aliases: [
        'brechó',
        'brecho',
        'bazar',
        'usado',
        'usados',
        'venda brechó',
        'venda usado',
        'roupa usada',
      ],
      confidence: 0.85,
      type: KeywordType.generica,
    ),

    AdvancedKeywordMapping(
      keyword: 'artesanato',
      categoria: 'Vendas',
      subcategoria: 'Artesanato',
      regexPattern: r'artesanato|artesanal|handmade|feito\s*[aà]\s*m[aã]o',
      aliases: [
        'artesanato',
        'artesanal',
        'handmade',
        'feito a mão',
        'venda artesanato',
        'trabalho artesanal',
      ],
      confidence: 0.85,
      type: KeywordType.generica,
    ),

    // ═══════════════════════════════════════════════════════════
    // 💸 RECEITAS - OUTROS EXPANDIDO
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'presente',
      categoria: 'Outros',
      subcategoria: 'Presente',
      regexPattern: r'presente|gift|doa[cç][aã]o\s*recebida',
      aliases: [
        'presente',
        'gift',
        'doação recebida',
        'doacao recebida',
        'recebimento presente',
        'dinheiro presente',
      ],
      confidence: 0.78,
      type: KeywordType.generica,
    ),

    AdvancedKeywordMapping(
      keyword: 'reembolso',
      categoria: 'Outros',
      subcategoria: 'Reembolso',
      regexPattern: r'reembolso|estorno|devolu[cç][aã]o|ressarcimento',
      aliases: [
        'reembolso',
        'estorno',
        'devolução',
        'devolucao',
        'ressarcimento',
        'reembolso despesa',
        'estorno compra',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'cashback',
      categoria: 'Outros',
      subcategoria: 'Reembolso',
      regexPattern: r'cash\s*back|dinheiro\s*de\s*volta',
      aliases: [
        'cashback',
        'cash back',
        'dinheiro de volta',
        'cashback cartao',
        'cashback cartão',
        'recompensa',
      ],
      confidence: 0.92,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'premio',
      categoria: 'Outros',
      subcategoria: 'Prêmio',
      regexPattern: r'pr[eê]mio|sorteio|loteria|rifa',
      aliases: [
        'premio',
        'prêmio',
        'sorteio',
        'loteria',
        'rifa',
        'ganho sorteio',
        'ganho loteria',
      ],
      confidence: 0.85,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'pix recebido',
      categoria: 'Outros',
      subcategoria: 'Reembolso',
      regexPattern: r'pix\s*recebido|transfer[eê]ncia\s*recebida',
      aliases: [
        'pix recebido',
        'transferencia recebida',
        'transferência recebida',
        'ted recebido',
        'doc recebido',
        'recebimento pix',
      ],
      confidence: 0.65,
      type: KeywordType.contextual,
    ),

    AdvancedKeywordMapping(
      keyword: 'aluguel recebido',
      categoria: 'Outros',
      subcategoria: 'Reembolso',
      regexPattern: r'alugu[eé]l\s*recebido|renda\s*aluguel',
      aliases: [
        'aluguel recebido',
        'aluguer recebido',
        'renda aluguel',
        'recebimento aluguel',
        'locação recebida',
      ],
      confidence: 0.88,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'pensao',
      categoria: 'Outros',
      subcategoria: 'Presente',
      regexPattern: r'pens[aã]o|aposentadoria|inss',
      aliases: [
        'pensao',
        'pensão',
        'aposentadoria',
        'inss',
        'recebimento pensao',
        'recebimento aposentadoria',
        'beneficio inss',
        'benefício inss',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'auxilio',
      categoria: 'Outros',
      subcategoria: 'Presente',
      regexPattern: r'aux[íi]lio|benef[íi]cio|ajuda',
      aliases: [
        'auxilio',
        'auxílio',
        'beneficio',
        'benefício',
        'ajuda',
        'auxilio emergencial',
        'bolsa familia',
        'bolsa família',
        'auxilio brasil',
      ],
      confidence: 0.85,
      type: KeywordType.especifica,
    ),

    // ═══════════════════════════════════════════════════════════
    // 🏦 KEYWORDS DE BANCOS/FINANCEIRAS (Para contexto)
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'itau',
      categoria: 'Outros',
      subcategoria: 'Reembolso',
      regexPattern: r'ita[uú]',
      aliases: [
        'itau',
        'itaú',
        'banco itau',
        'itaucard',
        'itau unibanco',
        'conta itau',
      ],
      confidence: 0.75,
      type: KeywordType.contextual,
    ),

    AdvancedKeywordMapping(
      keyword: 'bradesco',
      categoria: 'Outros',
      subcategoria: 'Reembolso',
      regexPattern: r'bradesco',
      aliases: [
        'bradesco',
        'banco bradesco',
        'bradesco cartoes',
        'bradesco cartões',
        'conta bradesco',
      ],
      confidence: 0.75,
      type: KeywordType.contextual,
    ),

    AdvancedKeywordMapping(
      keyword: 'santander',
      categoria: 'Outros',
      subcategoria: 'Reembolso',
      regexPattern: r'santander',
      aliases: [
        'santander',
        'banco santander',
        'santander brasil',
        'conta santander',
      ],
      confidence: 0.75,
      type: KeywordType.contextual,
    ),

    AdvancedKeywordMapping(
      keyword: 'banco do brasil',
      categoria: 'Outros',
      subcategoria: 'Reembolso',
      regexPattern: r'banco\s*do\s*brasil|\bbb\b',
      aliases: [
        'banco do brasil',
        'bb',
        'bancodobrasil',
        'conta bb',
        'ourocard',
      ],
      confidence: 0.70,
      type: KeywordType.contextual,
    ),

    AdvancedKeywordMapping(
      keyword: 'caixa',
      categoria: 'Outros',
      subcategoria: 'Reembolso',
      regexPattern: r'caixa\s*econ[oô]mica|\bcef\b',
      aliases: [
        'caixa',
        'caixa economica',
        'caixa econômica',
        'cef',
        'conta caixa',
      ],
      confidence: 0.70,
      type: KeywordType.contextual,
    ),

    AdvancedKeywordMapping(
      keyword: 'nubank',
      categoria: 'Outros',
      subcategoria: 'Reembolso',
      regexPattern: r'nubank|roxinho',
      aliases: [
        'nubank',
        'nu bank',
        'nu',
        'roxinho',
        'conta nubank',
        'cartao nubank',
      ],
      confidence: 0.78,
      type: KeywordType.contextual,
    ),

    AdvancedKeywordMapping(
      keyword: 'inter',
      categoria: 'Outros',
      subcategoria: 'Reembolso',
      regexPattern: r'banco\s*inter|\binter\b',
      aliases: [
        'inter',
        'banco inter',
        'inter bank',
        'conta inter',
        'cartao inter',
      ],
      confidence: 0.75,
      type: KeywordType.contextual,
    ),

    AdvancedKeywordMapping(
      keyword: 'c6 bank',
      categoria: 'Outros',
      subcategoria: 'Reembolso',
      regexPattern: r'c6\s*bank|\bc6\b',
      aliases: ['c6', 'c6 bank', 'banco c6', 'c6bank', 'conta c6', 'cartao c6'],
      confidence: 0.80,
      type: KeywordType.contextual,
    ),

    AdvancedKeywordMapping(
      keyword: 'original',
      categoria: 'Outros',
      subcategoria: 'Reembolso',
      regexPattern: r'banco\s*original',
      aliases: [
        'original',
        'banco original',
        'conta original',
        'cartao original',
      ],
      confidence: 0.75,
      type: KeywordType.contextual,
    ),

    AdvancedKeywordMapping(
      keyword: 'picpay',
      categoria: 'Outros',
      subcategoria: 'Reembolso',
      regexPattern: r'pic\s*pay',
      aliases: [
        'picpay',
        'pic pay',
        'pic-pay',
        'conta picpay',
        'cartao picpay',
      ],
      confidence: 0.82,
      type: KeywordType.contextual,
    ),

    AdvancedKeywordMapping(
      keyword: 'next',
      categoria: 'Outros',
      subcategoria: 'Reembolso',
      regexPattern: r'\bnext\b.*?(bank|banco)',
      aliases: ['next', 'next bank', 'banco next', 'conta next', 'cartao next'],
      confidence: 0.75,
      type: KeywordType.contextual,
    ),

    AdvancedKeywordMapping(
      keyword: 'neon',
      categoria: 'Outros',
      subcategoria: 'Reembolso',
      regexPattern: r'\bneon\b',
      aliases: ['neon', 'banco neon', 'conta neon', 'cartao neon'],
      confidence: 0.78,
      type: KeywordType.contextual,
    ),

    AdvancedKeywordMapping(
      keyword: 'will bank',
      categoria: 'Outros',
      subcategoria: 'Reembolso',
      regexPattern: r'will\s*bank',
      aliases: ['will bank', 'will', 'banco will', 'conta will'],
      confidence: 0.80,
      type: KeywordType.contextual,
    ),

    AdvancedKeywordMapping(
      keyword: 'pagseguro',
      categoria: 'Freelance',
      subcategoria: 'Projetos',
      regexPattern: r'pag\s*seguro',
      aliases: [
        'pagseguro',
        'pag seguro',
        'pagbank',
        'recebimento pagseguro',
        'transferencia pagseguro',
      ],
      confidence: 0.85,
      type: KeywordType.especifica,
    ),

    // ═══════════════════════════════════════════════════════════
    // 📱 TELEFONIA/SERVIÇOS DIGITAIS EXPANDIDO
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'vivo movel',
      categoria: 'Moradia',
      subcategoria: 'Internet',
      regexPattern: r'vivo.*?(m[oó]vel|celular|pre)',
      aliases: [
        'vivo movel',
        'vivo móvel',
        'vivo celular',
        'vivo pre',
        'vivo pré',
        'recarga vivo',
      ],
      confidence: 0.88,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'claro movel',
      categoria: 'Moradia',
      subcategoria: 'Internet',
      regexPattern: r'claro.*?(m[oó]vel|celular|pre)',
      aliases: [
        'claro movel',
        'claro móvel',
        'claro celular',
        'claro pre',
        'claro pré',
        'recarga claro',
      ],
      confidence: 0.88,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'tim movel',
      categoria: 'Moradia',
      subcategoria: 'Internet',
      regexPattern: r'tim.*?(m[oó]vel|celular|pre)',
      aliases: [
        'tim movel',
        'tim móvel',
        'tim celular',
        'tim pre',
        'tim pré',
        'recarga tim',
      ],
      confidence: 0.88,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'oi movel',
      categoria: 'Moradia',
      subcategoria: 'Internet',
      regexPattern: r'\boi\b.*?(m[oó]vel|celular)',
      aliases: [
        'oi movel',
        'oi móvel',
        'oi celular',
        'recarga oi',
        'credito oi',
      ],
      confidence: 0.88,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'recarga celular',
      categoria: 'Moradia',
      subcategoria: 'Internet',
      regexPattern: r'recarga\s*(celular|cr[eé]dito)|cr[eé]dito\s*celular',
      aliases: [
        'recarga celular',
        'recarga',
        'credito celular',
        'crédito celular',
        'recarga telefone',
        'recarga credito',
      ],
      confidence: 0.82,
      type: KeywordType.generica,
    ),

    AdvancedKeywordMapping(
      keyword: 'google play',
      categoria: 'Lazer',
      subcategoria: 'Hobbies',
      regexPattern: r'google\s*play|play\s*store',
      aliases: [
        'google play',
        'googleplay',
        'play store',
        'playstore',
        'compra google play',
        'app google play',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'app store',
      categoria: 'Lazer',
      subcategoria: 'Hobbies',
      regexPattern: r'app\s*store|apple\s*store',
      aliases: [
        'app store',
        'appstore',
        'apple app',
        'apple store',
        'compra app store',
        'aplicativo apple',
      ],
      confidence: 0.90,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'icloud',
      categoria: 'Lazer',
      subcategoria: 'Hobbies',
      regexPattern: r'icloud',
      aliases: [
        'icloud',
        'i cloud',
        'armazenamento icloud',
        'assinatura icloud',
        'icloud+',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'google one',
      categoria: 'Lazer',
      subcategoria: 'Hobbies',
      regexPattern: r'google\s*one',
      aliases: [
        'google one',
        'googleone',
        'armazenamento google',
        'assinatura google one',
        'google storage',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'dropbox',
      categoria: 'Lazer',
      subcategoria: 'Hobbies',
      regexPattern: r'dropbox',
      aliases: [
        'dropbox',
        'drop box',
        'assinatura dropbox',
        'armazenamento dropbox',
        'dropbox plus',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'onedrive',
      categoria: 'Lazer',
      subcategoria: 'Hobbies',
      regexPattern: r'one\s*drive',
      aliases: [
        'onedrive',
        'one drive',
        'assinatura onedrive',
        'microsoft onedrive',
        'armazenamento microsoft',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'adobe',
      categoria: 'Lazer',
      subcategoria: 'Hobbies',
      regexPattern: r'adobe',
      aliases: [
        'adobe',
        'adobe creative cloud',
        'creative cloud',
        'photoshop',
        'illustrator',
        'assinatura adobe',
      ],
      confidence: 0.92,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'canva',
      categoria: 'Lazer',
      subcategoria: 'Hobbies',
      regexPattern: r'canva',
      aliases: ['canva', 'canva pro', 'assinatura canva', 'canva premium'],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'zoom',
      categoria: 'Educação',
      subcategoria: 'Cursos',
      regexPattern: r'\bzoom\b',
      aliases: [
        'zoom',
        'zoom meeting',
        'zoom pro',
        'assinatura zoom',
        'videoconferencia zoom',
      ],
      confidence: 0.85,
      type: KeywordType.especifica,
    ),

    AdvancedKeywordMapping(
      keyword: 'microsoft 365',
      categoria: 'Lazer',
      subcategoria: 'Hobbies',
      regexPattern: r'microsoft\s*365|office\s*365',
      aliases: [
        'microsoft 365',
        'office 365',
        'microsoft365',
        'office365',
        'assinatura microsoft',
        'office',
      ],
      confidence: 0.95,
      type: KeywordType.especifica,
    ),

    // ═══════════════════════════════════════════════════════════
    // 🎯 KEYWORDS CONTEXTUAIS FINAIS
    // ═══════════════════════════════════════════════════════════
    AdvancedKeywordMapping(
      keyword: 'mensalidade',
      categoria: 'Educação',
      subcategoria: 'Mensalidade',
      regexPattern: r'mensalidade|anuidade',
      aliases: [
        'mensalidade',
        'anuidade',
        'semestralidade',
        'pagamento mensal',
        'boleto mensalidade',
      ],
      confidence: 0.65,
      type: KeywordType.contextual,
    ),

    AdvancedKeywordMapping(
      keyword: 'assinatura',
      categoria: 'Lazer',
      subcategoria: 'Streaming',
      regexPattern: r'assinatura|subscription',
      aliases: [
        'assinatura',
        'subscription',
        'renovacao assinatura',
        'renovação assinatura',
        'plano mensal',
      ],
      confidence: 0.60,
      type: KeywordType.contextual,
    ),

    AdvancedKeywordMapping(
      keyword: 'taxa',
      categoria: 'Moradia',
      subcategoria: 'Condomínio',
      regexPattern: r'\btaxa\b',
      aliases: [
        'taxa',
        'tarifa',
        'cobranca',
        'cobrança',
        'taxa mensal',
        'taxa anual',
      ],
      confidence: 0.55,
      type: KeywordType.contextual,
    ),
  ];

  /// 🔗 Getter que combina todas as keywords (base + estendida)
  static List<AdvancedKeywordMapping> get allKeywords => [
    ..._advancedKeywords,
    ..._advancedKeywordsExtended,
  ];

  // ═══════════════════════════════════════════════════════════
  // 📊 MÉTODOS FINAIS DE ANÁLISE E ESTATÍSTICAS
  // ═══════════════════════════════════════════════════════════

  /// 🎯 Buscar com múltiplos critérios (mais sofisticado)
  static AdvancedKeywordMapping? buscarComCriterios({
    required String descricao,
    KeywordType? tipoPriorizado,
    double confidenceMinima = 0.0,
  }) {
    if (descricao.isEmpty) return null;

    final descricaoNormalizada = normalizarTexto(descricao);
    final matches = <Map<String, dynamic>>[];

    for (final mapping in _advancedKeywords) {
      if (mapping.matches(descricaoNormalizada)) {
        // Calcular score com bônus por tipo
        double score = mapping.confidence;

        // Aplicar bônus por tipo
        switch (mapping.type) {
          case KeywordType.especifica:
            score *= 1.2;
            break;
          case KeywordType.generica:
            score *= 1.0;
            break;
          case KeywordType.contextual:
            score *= 0.9;
            break;
        }

        // Bônus adicional se é o tipo priorizado
        if (tipoPriorizado != null && mapping.type == tipoPriorizado) {
          score *= 1.15;
        }

        // Aplicar filtro de confidence mínima
        if (score >= confidenceMinima) {
          matches.add({'mapping': mapping, 'score': score});
        }
      }
    }

    if (matches.isEmpty) return null;

    // Ordenar por score e retornar o melhor
    matches.sort(
      (a, b) => (b['score'] as double).compareTo(a['score'] as double),
    );
    return matches.first['mapping'] as AdvancedKeywordMapping;
  }

  /// 📈 Análise completa com sugestões alternativas
  static Map<String, dynamic> analisarComSugestoes(String descricao) {
    final descricaoNormalizada = normalizarTexto(descricao);
    final todasCorrespondencias = buscarTodasCorrespondencias(descricao);
    final melhorMatch = buscarMelhorMatch(descricao);

    // Agrupar por categoria
    final porCategoria = <String, List<Map<String, dynamic>>>{};
    for (final match in todasCorrespondencias) {
      final categoria = match['categoria'] as String;
      porCategoria.putIfAbsent(categoria, () => []);
      porCategoria[categoria]!.add(match);
    }

    return {
      'descricaoOriginal': descricao,
      'descricaoNormalizada': descricaoNormalizada,
      'temMatch': melhorMatch != null,
      'melhorSugestao': melhorMatch != null
          ? {
              'keyword': melhorMatch.keyword,
              'categoria': melhorMatch.categoria,
              'subcategoria': melhorMatch.subcategoria,
              'confidence': melhorMatch.confidence,
              'type': melhorMatch.type.name,
              'score': _calcularScore(melhorMatch),
            }
          : null,
      'totalMatches': todasCorrespondencias.length,
      'matchesPorCategoria': porCategoria.map((k, v) => MapEntry(k, v.length)),
      'sugestoesAlternativas': todasCorrespondencias.take(5).toList(),
      'categoriasMaisProvaveis': _getCategoriasMaisProvaveis(
        todasCorrespondencias,
      ),
    };
  }

  /// Calcular score de um mapping
  static double _calcularScore(AdvancedKeywordMapping mapping) {
    double score = mapping.confidence;

    switch (mapping.type) {
      case KeywordType.especifica:
        score *= 1.2;
        break;
      case KeywordType.generica:
        score *= 1.0;
        break;
      case KeywordType.contextual:
        score *= 0.9;
        break;
    }

    return score;
  }

  /// Obter categorias mais prováveis
  static List<Map<String, dynamic>> _getCategoriasMaisProvaveis(
    List<Map<String, dynamic>> matches,
  ) {
    final categoriaScores = <String, double>{};

    for (final match in matches) {
      final categoria = match['categoria'] as String;
      final score = match['score'] as double;
      categoriaScores[categoria] = (categoriaScores[categoria] ?? 0.0) + score;
    }

    final sorted = categoriaScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted
        .take(3)
        .map(
          (e) => {
            'categoria': e.key,
            'scoreTotal': e.value,
            'matches': matches.where((m) => m['categoria'] == e.key).length,
          },
        )
        .toList();
  }

  /// 🔢 Estatísticas finais expandidas
  static Map<String, dynamic> getStatsExpandidas() {
    final stats = getStats();

    // Contar por tipo
    final porTipo = <String, int>{};
    for (final mapping in _advancedKeywords) {
      final tipo = mapping.type.name;
      porTipo[tipo] = (porTipo[tipo] ?? 0) + 1;
    }

    // Contar por categoria
    final porCategoria = <String, int>{};
    for (final mapping in _advancedKeywords) {
      final categoria = mapping.categoria;
      porCategoria[categoria] = (porCategoria[categoria] ?? 0) + 1;
    }

    // Adicionar estatísticas expandidas
    return {
      ...stats,
      'porTipo': porTipo,
      'porCategoria': porCategoria,
      'categorias': porCategoria.keys.toList(),
      'totalTipos': porTipo.length,
    };
  }

  /// 📊 Relatório de cobertura
  static Map<String, dynamic> getRelatorioCobertura() {
    final porCategoria = <String, Map<String, int>>{};

    for (final mapping in _advancedKeywords) {
      final categoria = mapping.categoria;
      final tipo = mapping.type.name;

      porCategoria.putIfAbsent(
        categoria,
        () => {'especifica': 0, 'generica': 0, 'contextual': 0, 'total': 0},
      );

      porCategoria[categoria]![tipo] =
          (porCategoria[categoria]![tipo] ?? 0) + 1;
      porCategoria[categoria]!['total'] =
          (porCategoria[categoria]!['total'] ?? 0) + 1;
    }

    return {
      'totalKeywords': _advancedKeywords.length,
      'coberturaDetalhada': porCategoria,
      'categoriasMaisCoberta': _getCategoriaComMaisKeywords(porCategoria),
      'categoriasMenosCoberta': _getCategoriaComMenosKeywords(porCategoria),
    };
  }

  static String _getCategoriaComMaisKeywords(
    Map<String, Map<String, int>> porCategoria,
  ) {
    var maxCount = 0;
    var categoria = '';

    porCategoria.forEach((cat, stats) {
      final total = stats['total'] ?? 0;
      if (total > maxCount) {
        maxCount = total;
        categoria = cat;
      }
    });

    return '$categoria ($maxCount keywords)';
  }

  static String _getCategoriaComMenosKeywords(
    Map<String, Map<String, int>> porCategoria,
  ) {
    var minCount = 999999;
    var categoria = '';

    porCategoria.forEach((cat, stats) {
      final total = stats['total'] ?? 0;
      if (total < minCount) {
        minCount = total;
        categoria = cat;
      }
    });

    return '$categoria ($minCount keywords)';
  }
}
