// 📂 lib\src\modules\importacao\datacategoria_keywords_mapping.dart
//
// 🎯 Mapeamento de palavras-chave, marcas e empresas para categorização automática
//
// Uso: Detecta automaticamente categoria/subcategoria baseado em descrição de transação
// Exemplo: "Compra Carrefour" → Alimentação / Supermercado

/// Modelo de keyword mapping
class KeywordMapping {
  final String keyword;
  final String categoria;
  final String subcategoria;
  final List<String> aliases;
  final double confidence;

  const KeywordMapping({
    required this.keyword,
    required this.categoria,
    required this.subcategoria,
    this.aliases = const [],
    this.confidence = 0.9,
  });
}

/// Serviço de mapeamento de keywords para categorização automática
class CategoriaKeywordsService {
  
  /// 🔍 Base de dados de keywords (300+ referências)
  static const List<KeywordMapping> _keywords = [
    
    // ═══════════════════════════════════════════════════════════
    // 🍽️ ALIMENTAÇÃO - SUPERMERCADO (70+ referências)
    // ═══════════════════════════════════════════════════════════
    
    KeywordMapping(
      keyword: 'carrefour',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      aliases: ['carrefour', 'carrefur', 'carrefor', 'carrefour express', 'carrefour bairro'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'assai',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      aliases: ['assai', 'assaí', 'assay', 'atacadão assaí'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'atacadao',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      aliases: ['atacadao', 'atacadão', 'atcadao', 'carrefour atacadão'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'giga atacado',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      aliases: ['giga', 'giga atacado', 'gigaatacado'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'mambo',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      aliases: ['mambo', 'supermercado mambo'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'st marche',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      aliases: ['st marche', 'saint marche', 'stmarche', 'sao marche'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'pao de acucar',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      aliases: ['pao de acucar', 'pão de açúcar', 'paodeacucar', 'pda'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'extra',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      aliases: ['extra', 'extra supermercado', 'extra hiper'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'walmart',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      aliases: ['walmart', 'wal mart', 'wal-mart'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'big',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      aliases: ['big', 'big bompreço', 'bompreco'],
      confidence: 0.85,
    ),
    KeywordMapping(
      keyword: 'mercadao',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      aliases: ['mercadao', 'mercadão', 'mercadao sao luis'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'savegnago',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      aliases: ['savegnago', 'save gnago', 'savegnago supermercados'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'sonda',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      aliases: ['sonda', 'supermercado sonda', 'sonda supermercados'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'condor',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      aliases: ['condor', 'supermercado condor', 'condor super center'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'festval',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      aliases: ['festval', 'festival', 'supermercado festval'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'angeloni',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      aliases: ['angeloni', 'supermercados angeloni'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'koch',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      aliases: ['koch', 'supermercado koch', 'koch hipermercado'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'zona sul',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      aliases: ['zona sul', 'zonasul', 'zona-sul', 'supermercado zona sul'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'guanabara',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      aliases: ['guanabara', 'supermercado guanabara', 'guanabara supermercados'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'mundial',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      aliases: ['mundial', 'supermercado mundial', 'supermercados mundial'],
      confidence: 0.85,
    ),
    KeywordMapping(
      keyword: 'fort',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      aliases: ['fort atacadista', 'fort', 'fort atacado'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'tenda',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      aliases: ['tenda', 'tenda atacado', 'supermercado tenda'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'dia',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      aliases: ['dia', 'dia supermercado', 'supermercado dia', 'dia%'],
      confidence: 0.80,
    ),
    KeywordMapping(
      keyword: 'aldi',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      aliases: ['aldi', 'aldi supermercado'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'lidl',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      aliases: ['lidl', 'lidl supermercado'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'mercadorama',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      aliases: ['mercadorama', 'mercado rama'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'oba',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      aliases: ['oba', 'oba hortifruti', 'oba supermercado'],
      confidence: 0.85,
    ),
    KeywordMapping(
      keyword: 'verdemar',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      aliases: ['verdemar', 'verde mar'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'prezunic',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      aliases: ['prezunic', 'prezunic supermercados'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'supermercado',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      aliases: ['supermercado', 'super mercado', 'mercado'],
      confidence: 0.80,
    ),
    KeywordMapping(
      keyword: 'atacado',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      aliases: ['atacado', 'atacadista', 'atac'],
      confidence: 0.75,
    ),
    
    // ═══════════════════════════════════════════════════════════
    // 🍕 ALIMENTAÇÃO - RESTAURANTE (50+ referências)
    // ═══════════════════════════════════════════════════════════
    
    KeywordMapping(
      keyword: 'outback',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      aliases: ['outback', 'out back', 'outback steakhouse'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'applebees',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      aliases: ['applebees', "applebee's", 'apple bees'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'madero',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      aliases: ['madero', 'madero container', 'madero steak house'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'giraffas',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      aliases: ['giraffas', 'girafas', 'giraffas restaurante'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'ragazzo',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      aliases: ['ragazzo', 'ragazzo pizzaria'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'spoleto',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      aliases: ['spoleto', 'spolet'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'koni',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      aliases: ['koni', 'koni store', 'konistore'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'china in box',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      aliases: ['china in box', 'chinainbox', 'china box'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'gendai',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      aliases: ['gendai', 'gendai sushi', 'gendai japonês'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'temakeria',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      aliases: ['temakeria', 'temaki', 'temakeria e cia'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'sushi',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      aliases: ['sushi', 'sushiya', 'sushibar', 'sushi bar'],
      confidence: 0.85,
    ),
    KeywordMapping(
      keyword: 'churrascaria',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      aliases: ['churrascaria', 'churras', 'churrasco', 'rodizio'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'fogo de chao',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      aliases: ['fogo de chao', 'fogo de chão', 'fogodechao'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'griletto',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      aliases: ['griletto', 'grileto'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'vivenda',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      aliases: ['vivenda', 'vivenda do camarão', 'vivenda do camarao'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'coco bambu',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      aliases: ['coco bambu', 'cocobambu', 'coco bamboo'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'restaurante',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      aliases: ['restaurante', 'rest', 'restaurant'],
      confidence: 0.75,
    ),
    KeywordMapping(
      keyword: 'pizzaria',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      aliases: ['pizzaria', 'pizza', 'pizz'],
      confidence: 0.85,
    ),
    KeywordMapping(
      keyword: 'lanchonete',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      aliases: ['lanchonete', 'lanches', 'lanche'],
      confidence: 0.80,
    ),
    KeywordMapping(
      keyword: 'gelateria',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      aliases: ['gelateria', 'gelataria', 'gelato', 'sorveteria', 'sorvete'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'hamburguer',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      aliases: ['hamburguer', 'hamburgueria', 'burguer', 'burger', 'hamburgaria'],
      confidence: 0.85,
    ),
    KeywordMapping(
      keyword: 'doceria',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      aliases: ['doceria', 'bomboniere', 'bombonière', 'confeitaria', 'doce'],
      confidence: 0.85,
    ),
    KeywordMapping(
      keyword: 'cantina',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      aliases: ['cantina', 'cantinas', 'italiano', 'italiana'],
      confidence: 0.80,
    ),
    KeywordMapping(
      keyword: 'hotdog',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      aliases: ['hotdog', 'hot dog', 'cachorro quente'],
      confidence: 0.85,
    ),
    KeywordMapping(
      keyword: 'cannoleria',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      aliases: ['cannoleria', 'canoleria', 'cannoli'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'frutaria',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      aliases: ['frutaria', 'fruteiras', 'hortifruti', 'quitanda'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'tasca',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      aliases: ['tasca', 'bar', 'taberna'],
      confidence: 0.80,
    ),
    KeywordMapping(
      keyword: 'cacau',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      aliases: ['cacau', 'cacau show', 'cacaushow', 'chocolate'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'bacio',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      aliases: ['bacio', 'bacio di latte'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'kombina',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      aliases: ['kombina', 'kombi'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'daiso',
      categoria: 'Alimentação',
      subcategoria: 'Supermercado',
      aliases: ['daiso', 'daiso brasil'],
      confidence: 0.85,
    ),
    
    // ═══════════════════════════════════════════════════════════
    // 🍔 ALIMENTAÇÃO - FAST FOOD/DELIVERY (40+ referências)
    // ═══════════════════════════════════════════════════════════
    
    KeywordMapping(
      keyword: 'ifood',
      categoria: 'Alimentação',
      subcategoria: 'Lanche/Fast Food/Delivery',
      aliases: ['ifood', 'i-food', 'i food', 'ifood *'],
      confidence: 0.98,
    ),
    KeywordMapping(
      keyword: 'rappi',
      categoria: 'Alimentação',
      subcategoria: 'Lanche/Fast Food/Delivery',
      aliases: ['rappi', 'rapi', 'rappi *'],
      confidence: 0.98,
    ),
    KeywordMapping(
      keyword: 'uber eats',
      categoria: 'Alimentação',
      subcategoria: 'Lanche/Fast Food/Delivery',
      aliases: ['uber eats', 'ubereats', 'uber-eats', 'uber *eats'],
      confidence: 0.98,
    ),
    KeywordMapping(
      keyword: '99 food',
      categoria: 'Alimentação',
      subcategoria: 'Lanche/Fast Food/Delivery',
      aliases: ['99 food', '99food', '99 *food'],
      confidence: 0.98,
    ),
    KeywordMapping(
      keyword: 'mcdonalds',
      categoria: 'Alimentação',
      subcategoria: 'Lanche/Fast Food/Delivery',
      aliases: ['mcdonalds', 'mc donalds', "mc donald's", 'mcd', 'mc'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'bobs',
      categoria: 'Alimentação',
      subcategoria: 'Lanche/Fast Food/Delivery',
      aliases: ['bobs', "bob's", 'bobsburger'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'burger king',
      categoria: 'Alimentação',
      subcategoria: 'Lanche/Fast Food/Delivery',
      aliases: ['burger king', 'burgerking', 'bk', 'burguer king'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'subway',
      categoria: 'Alimentação',
      subcategoria: 'Lanche/Fast Food/Delivery',
      aliases: ['subway', 'sub way'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'kfc',
      categoria: 'Alimentação',
      subcategoria: 'Lanche/Fast Food/Delivery',
      aliases: ['kfc', 'kentucky', 'kentucky fried chicken'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'pizza hut',
      categoria: 'Alimentação',
      subcategoria: 'Lanche/Fast Food/Delivery',
      aliases: ['pizza hut', 'pizzahut', 'pizza-hut'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'dominos',
      categoria: 'Alimentação',
      subcategoria: 'Lanche/Fast Food/Delivery',
      aliases: ['dominos', "domino's", 'domino pizza'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'habib',
      categoria: 'Alimentação',
      subcategoria: 'Lanche/Fast Food/Delivery',
      aliases: ['habib', "habib's", 'habibs'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'popeyes',
      categoria: 'Alimentação',
      subcategoria: 'Lanche/Fast Food/Delivery',
      aliases: ['popeyes', 'pop eyes', 'popeye'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'starbucks',
      categoria: 'Alimentação',
      subcategoria: 'Lanche/Fast Food/Delivery',
      aliases: ['starbucks', 'star bucks', 'starbucks coffee'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'kopenhagen',
      categoria: 'Alimentação',
      subcategoria: 'Lanche/Fast Food/Delivery',
      aliases: ['kopenhagen', 'kopenhagem', 'chocolates kopenhagen'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'cacau show',
      categoria: 'Alimentação',
      subcategoria: 'Lanche/Fast Food/Delivery',
      aliases: ['cacau show', 'cacaushow', 'cacau'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'delivery',
      categoria: 'Alimentação',
      subcategoria: 'Lanche/Fast Food/Delivery',
      aliases: ['delivery', 'entrega', 'deliveri'],
      confidence: 0.80,
    ),
    KeywordMapping(
      keyword: 'fast food',
      categoria: 'Alimentação',
      subcategoria: 'Lanche/Fast Food/Delivery',
      aliases: ['fast food', 'fastfood', 'fast'],
      confidence: 0.80,
    ),
    KeywordMapping(
      keyword: 'lanche',
      categoria: 'Alimentação',
      subcategoria: 'Lanche/Fast Food/Delivery',
      aliases: ['lanche', 'lanches', 'lanchinho'],
      confidence: 0.75,
    ),
    KeywordMapping(
      keyword: 'bullguer',
      categoria: 'Alimentação',
      subcategoria: 'Lanche/Fast Food/Delivery',
      aliases: ['bullguer', 'bull guer', 'burguer'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'chocolat',
      categoria: 'Alimentação',
      subcategoria: 'Restaurante',
      aliases: ['chocolat', 'chocolate', 'chocolateria'],
      confidence: 0.90,
    ),

    // ═══════════════════════════════════════════════════════════
    // 🥩 ALIMENTAÇÃO - AÇOUGUE/FEIRA (15+ referências)
    // ═══════════════════════════════════════════════════════════
    
    KeywordMapping(
      keyword: 'acougue',
      categoria: 'Alimentação',
      subcategoria: 'Açougue/Feira',
      aliases: ['acougue', 'açougue', 'acougueiro'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'feira',
      categoria: 'Alimentação',
      subcategoria: 'Açougue/Feira',
      aliases: ['feira', 'feira livre', 'feirante'],
      confidence: 0.85,
    ),
    KeywordMapping(
      keyword: 'hortifruti',
      categoria: 'Alimentação',
      subcategoria: 'Açougue/Feira',
      aliases: ['hortifruti', 'horti fruti', 'hortifrut', 'hortifrtuti', 'hortifrutti'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'sacolao',
      categoria: 'Alimentação',
      subcategoria: 'Açougue/Feira',
      aliases: ['sacolao', 'sacolão', 'sacol'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'verduras',
      categoria: 'Alimentação',
      subcategoria: 'Açougue/Feira',
      aliases: ['verduras', 'verdura', 'legumes', 'hortaliças'],
      confidence: 0.85,
    ),
    KeywordMapping(
      keyword: 'frutas',
      categoria: 'Alimentação',
      subcategoria: 'Açougue/Feira',
      aliases: ['frutas', 'fruta', 'frut'],
      confidence: 0.85,
    ),
    KeywordMapping(
      keyword: 'peixaria',
      categoria: 'Alimentação',
      subcategoria: 'Açougue/Feira',
      aliases: ['peixaria', 'peixe', 'pescado', 'frutos do mar'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'padaria',
      categoria: 'Alimentação',
      subcategoria: 'Açougue/Feira',
      aliases: ['padaria', 'padoca', 'panificadora', 'confeitaria'],
      confidence: 0.85,
    ),
    
    // ═══════════════════════════════════════════════════════════
    // 🚗 TRANSPORTE - COMBUSTÍVEL (30+ referências)
    // ═══════════════════════════════════════════════════════════
    
    KeywordMapping(
      keyword: 'shell',
      categoria: 'Transporte',
      subcategoria: 'Combustível',
      aliases: ['shell', 'shell box', 'posto shell'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'ipiranga',
      categoria: 'Transporte',
      subcategoria: 'Combustível',
      aliases: ['ipiranga', 'posto ipiranga', 'am/pm'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'petrobras',
      categoria: 'Transporte',
      subcategoria: 'Combustível',
      aliases: ['petrobras', 'br', 'posto br', 'petrobras distribuidora'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'ale',
      categoria: 'Transporte',
      subcategoria: 'Combustível',
      aliases: ['ale', 'posto ale', 'alesat'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'raizen',
      categoria: 'Transporte',
      subcategoria: 'Combustível',
      aliases: ['raizen', 'raízen', 'posto raizen'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'vibra',
      categoria: 'Transporte',
      subcategoria: 'Combustível',
      aliases: ['vibra', 'vibra energia'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'texaco',
      categoria: 'Transporte',
      subcategoria: 'Combustível',
      aliases: ['texaco', 'posto texaco'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'esso',
      categoria: 'Transporte',
      subcategoria: 'Combustível',
      aliases: ['esso', 'posto esso'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'posto',
      categoria: 'Transporte',
      subcategoria: 'Combustível',
      aliases: ['posto', 'posto de gasolina', 'posto de combustível'],
      confidence: 0.80,
    ),
    KeywordMapping(
      keyword: 'gasolina',
      categoria: 'Transporte',
      subcategoria: 'Combustível',
      aliases: ['gasolina', 'etanol', 'alcool', 'diesel'], // Removido 'combustivel' e 'gas' genéricos
      confidence: 0.85,
    ),
    KeywordMapping(
      keyword: 'abastecimento',
      categoria: 'Transporte',
      subcategoria: 'Combustível',
      aliases: ['abastecimento', 'abastecer', 'abasteci'],
      confidence: 0.85,
    ),
    KeywordMapping(
      keyword: 'auto posto',
      categoria: 'Transporte',
      subcategoria: 'Combustível',
      aliases: ['auto posto', 'autoposto', 'fila dupla', 'auto posto fila dupla'],
      confidence: 0.95,
    ),

    // ═══════════════════════════════════════════════════════════
    // 🚖 TRANSPORTE - UBER/TAXI (15+ referências)
    // ═══════════════════════════════════════════════════════════
    
    KeywordMapping(
      keyword: 'uber',
      categoria: 'Transporte',
      subcategoria: 'Uber/Taxi',
      aliases: ['uber', 'uber *', 'uber trip', 'uber viagem'],
      confidence: 0.98,
    ),
    KeywordMapping(
      keyword: '99',
      categoria: 'Transporte',
      subcategoria: 'Uber/Taxi',
      aliases: ['99', '99 taxi', '99 pop', '99pay', '99 *'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'cabify',
      categoria: 'Transporte',
      subcategoria: 'Uber/Taxi',
      aliases: ['cabify', 'cabi fy'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'taxi',
      categoria: 'Transporte',
      subcategoria: 'Uber/Taxi',
      aliases: ['taxi', 'táxi', 'taxista', 'corrida taxi'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'indriver',
      categoria: 'Transporte',
      subcategoria: 'Uber/Taxi',
      aliases: ['indriver', 'in driver', 'indrive'],
      confidence: 0.95,
    ),
    
    // ═══════════════════════════════════════════════════════════
    // 🚌 TRANSPORTE - TRANSPORTE PÚBLICO (10+ referências)
    // ═══════════════════════════════════════════════════════════
    
    KeywordMapping(
      keyword: 'bilhete unico',
      categoria: 'Transporte',
      subcategoria: 'Transporte Público',
      aliases: ['bilhete unico', 'bilhete único', 'bilhete-unico'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'metro',
      categoria: 'Transporte',
      subcategoria: 'Transporte Público',
      aliases: ['metro', 'metrô', 'metropolitano'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'onibus',
      categoria: 'Transporte',
      subcategoria: 'Transporte Público',
      aliases: ['onibus', 'ônibus', 'onib', 'bus'],
      confidence: 0.85,
    ),
    KeywordMapping(
      keyword: 'brt',
      categoria: 'Transporte',
      subcategoria: 'Transporte Público',
      aliases: ['brt', 'bus rapid transit'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'cptm',
      categoria: 'Transporte',
      subcategoria: 'Transporte Público',
      aliases: ['cptm', 'trem'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'recarga',
      categoria: 'Transporte',
      subcategoria: 'Transporte Público',
      aliases: ['recarga', 'recarga cartao', 'recarga bilhete'],
      confidence: 0.80,
    ),
    KeywordMapping(
      keyword: 'totalpass',
      categoria: 'Transporte',
      subcategoria: 'Transporte Público',
      aliases: ['totalpass', 'total pass', 'total-pass'],
      confidence: 0.95,
    ),
    
    // ═══════════════════════════════════════════════════════════
    // 🔧 TRANSPORTE - MANUTENÇÃO VEÍCULO (20+ referências)
    // ═══════════════════════════════════════════════════════════
    
    KeywordMapping(
      keyword: 'oficina',
      categoria: 'Transporte',
      subcategoria: 'Manutenção Veículo',
      aliases: ['oficina', 'oficina mecanica', 'mecânica'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'mecanico',
      categoria: 'Transporte',
      subcategoria: 'Manutenção Veículo',
      aliases: ['mecanico', 'mecânico', 'conserto'],
      confidence: 0.85,
    ),
    KeywordMapping(
      keyword: 'revisao',
      categoria: 'Transporte',
      subcategoria: 'Manutenção Veículo',
      aliases: ['revisao', 'revisão', 'revisão carro'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'troca de oleo',
      categoria: 'Transporte',
      subcategoria: 'Manutenção Veículo',
      aliases: ['troca de oleo', 'troca de óleo', 'oleo motor'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'pneu',
      categoria: 'Transporte',
      subcategoria: 'Manutenção Veículo',
      aliases: ['pneu', 'pneus', 'borracharia', 'calibragem'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'alinhamento',
      categoria: 'Transporte',
      subcategoria: 'Manutenção Veículo',
      aliases: ['alinhamento', 'balanceamento', 'geometria'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'bateria',
      categoria: 'Transporte',
      subcategoria: 'Manutenção Veículo',
      aliases: ['bateria', 'bateria carro', 'bateria automotiva'],
      confidence: 0.85,
    ),
    KeywordMapping(
      keyword: 'lava jato',
      categoria: 'Transporte',
      subcategoria: 'Manutenção Veículo',
      aliases: ['lava jato', 'lavajato', 'lavagem', 'lavagem carro'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'funilaria',
      categoria: 'Transporte',
      subcategoria: 'Manutenção Veículo',
      aliases: ['funilaria', 'pintura', 'lataria'],
      confidence: 0.95,
    ),
    
    // ═══════════════════════════════════════════════════════════
    // 🅿️ TRANSPORTE - ESTACIONAMENTO (10+ referências)
    // ═══════════════════════════════════════════════════════════
    
    KeywordMapping(
      keyword: 'estacionamento',
      categoria: 'Transporte',
      subcategoria: 'Estacionamento',
      aliases: ['estacionamento', 'estacion', 'parking', 'garage', 'estac', 'estacionar', 'park', 'power center', 'stapar'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'zona azul',
      categoria: 'Transporte',
      subcategoria: 'Estacionamento',
      aliases: ['zona azul', 'zona-azul', 'zonaazul'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'valet',
      categoria: 'Transporte',
      subcategoria: 'Estacionamento',
      aliases: ['valet', 'manobrista', 'valet parking'],
      confidence: 0.90,
    ),

    // ═══════════════════════════════════════════════════════════
    // 🛣️ TRANSPORTE - PEDÁGIO (10+ referências)
    // ═══════════════════════════════════════════════════════════

    KeywordMapping(
      keyword: 'pedagio',
      categoria: 'Transporte',
      subcategoria: 'Pedágio',
      aliases: ['pedagio', 'pedágio', 'toll'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'sem parar',
      categoria: 'Transporte',
      subcategoria: 'Pedágio',
      aliases: ['sem parar', 'semparar', 'sem-parar'],
      confidence: 0.98,
    ),
    KeywordMapping(
      keyword: 'conectcar',
      categoria: 'Transporte',
      subcategoria: 'Pedágio',
      aliases: ['conectcar', 'conect car', 'conectc', 'conect'],
      confidence: 0.98,
    ),
    KeywordMapping(
      keyword: 'veloe',
      categoria: 'Transporte',
      subcategoria: 'Pedágio',
      aliases: ['veloe', 'velo e', 'veloe pedagio'],
      confidence: 0.98,
    ),
    KeywordMapping(
      keyword: 'movida',
      categoria: 'Transporte',
      subcategoria: 'Pedágio',
      aliases: ['movida', 'movida pedagio'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'taggy',
      categoria: 'Transporte',
      subcategoria: 'Pedágio',
      aliases: ['taggy', 'taggy pedagio'],
      confidence: 0.98,
    ),

    // ═══════════════════════════════════════════════════════════
    // 🏠 MORADIA - ALUGUEL (5+ referências)
    // ═══════════════════════════════════════════════════════════
    
    KeywordMapping(
      keyword: 'aluguel',
      categoria: 'Moradia',
      subcategoria: 'Aluguel',
      aliases: ['aluguel', 'aluguer', 'locação', 'locacao'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'imobiliaria',
      categoria: 'Moradia',
      subcategoria: 'Aluguel',
      aliases: ['imobiliaria', 'imobiliária', 'administradora', 'corretora'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'imovel',
      categoria: 'Moradia',
      subcategoria: 'Aluguel',
      aliases: ['imovel', 'imóvel', 'casa', 'apartamento', 'apto'],
      confidence: 0.75,
    ),
    
    // ═══════════════════════════════════════════════════════════
    // 🏢 MORADIA - CONDOMÍNIO (5+ referências)
    // ═══════════════════════════════════════════════════════════
    
    KeywordMapping(
      keyword: 'condominio',
      categoria: 'Moradia',
      subcategoria: 'Condomínio',
      aliases: ['condominio', 'condomínio', 'cond', 'taxa de condominio'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'sindico',
      categoria: 'Moradia',
      subcategoria: 'Condomínio',
      aliases: ['sindico', 'síndico', 'administradora condominio'],
      confidence: 0.90,
    ),
    
    // ═══════════════════════════════════════════════════════════
    // ⚡ MORADIA - ENERGIA ELÉTRICA (10+ referências)
    // ═══════════════════════════════════════════════════════════
    
    KeywordMapping(
      keyword: 'cpfl',
      categoria: 'Moradia',
      subcategoria: 'Energia Elétrica',
      aliases: ['cpfl', 'cpfl paulista', 'cpfl piratininga'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'enel',
      categoria: 'Moradia',
      subcategoria: 'Energia Elétrica',
      aliases: ['enel', 'enel sp', 'enel rj', 'enel ce'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'light',
      categoria: 'Moradia',
      subcategoria: 'Energia Elétrica',
      aliases: ['light', 'light rio', 'light sa'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'cemig',
      categoria: 'Moradia',
      subcategoria: 'Energia Elétrica',
      aliases: ['cemig', 'cemig distribuição'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'copel',
      categoria: 'Moradia',
      subcategoria: 'Energia Elétrica',
      aliases: ['copel', 'copel distribuição'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'eletropaulo',
      categoria: 'Moradia',
      subcategoria: 'Energia Elétrica',
      aliases: ['eletropaulo', 'aes eletropaulo'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'energia',
      categoria: 'Moradia',
      subcategoria: 'Energia Elétrica',
      aliases: ['energia', 'luz', 'conta de luz', 'energia elétrica'],
      confidence: 0.80,
    ),
    
    // ═══════════════════════════════════════════════════════════
    // 💧 MORADIA - ÁGUA (8+ referências)
    // ═══════════════════════════════════════════════════════════
    
    KeywordMapping(
      keyword: 'sabesp',
      categoria: 'Moradia',
      subcategoria: 'Água',
      aliases: ['sabesp', 'sabesp saneamento'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'cedae',
      categoria: 'Moradia',
      subcategoria: 'Água',
      aliases: ['cedae', 'cedae rio'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'sanepar',
      categoria: 'Moradia',
      subcategoria: 'Água',
      aliases: ['sanepar', 'saneamento do paraná'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'copasa',
      categoria: 'Moradia',
      subcategoria: 'Água',
      aliases: ['copasa', 'copasa mg'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'agua',
      categoria: 'Moradia',
      subcategoria: 'Água',
      aliases: ['agua', 'água', 'conta de água', 'saneamento'],
      confidence: 0.80,
    ),
    
    // ═══════════════════════════════════════════════════════════
    // 🌐 MORADIA - INTERNET (15+ referências)
    // ═══════════════════════════════════════════════════════════
    
    KeywordMapping(
      keyword: 'vivo',
      categoria: 'Moradia',
      subcategoria: 'Internet',
      aliases: ['vivo', 'vivo fibra', 'vivo internet'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'claro',
      categoria: 'Moradia',
      subcategoria: 'Internet',
      aliases: ['claro', 'claro internet', 'net claro', 'claro tv'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'oi',
      categoria: 'Moradia',
      subcategoria: 'Internet',
      aliases: ['oi', 'oi fibra', 'oi internet', 'oi tv'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'tim',
      categoria: 'Moradia',
      subcategoria: 'Internet',
      aliases: ['tim', 'tim live', 'tim fibra', 'tim internet'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'sky',
      categoria: 'Moradia',
      subcategoria: 'Internet',
      aliases: ['sky', 'sky tv', 'sky banda larga'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'internet',
      categoria: 'Moradia',
      subcategoria: 'Internet',
      aliases: ['internet', 'fibra', 'banda larga', 'wi-fi', 'wifi'],
      confidence: 0.75,
    ),
    KeywordMapping(
      keyword: 'vindi',
      categoria: 'Moradia',
      subcategoria: 'Internet',
      aliases: ['vindi', 'vindi*'],
      confidence: 0.85,
    ),

    // ═══════════════════════════════════════════════════════════
    // 🔥 MORADIA - GÁS (8+ referências)
    // ═══════════════════════════════════════════════════════════
    
    KeywordMapping(
      keyword: 'ultragaz',
      categoria: 'Moradia',
      subcategoria: 'Gás',
      aliases: ['ultragaz', 'ultra gaz', 'ultragás'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'liquigas',
      categoria: 'Moradia',
      subcategoria: 'Gás',
      aliases: ['liquigas', 'liquigás', 'liqui gas'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'supergasbras',
      categoria: 'Moradia',
      subcategoria: 'Gás',
      aliases: ['supergasbras', 'supergás', 'super gas'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'nacional gas',
      categoria: 'Moradia',
      subcategoria: 'Gás',
      aliases: ['nacional gas', 'nacional gás', 'nacionalgas'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'gas',
      categoria: 'Moradia',
      subcategoria: 'Gás',
      aliases: ['gas', 'gás', 'botijao', 'botijão', 'glp'],
      confidence: 0.80,
    ),
    KeywordMapping(
      keyword: 'madeiramadeira',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Móveis e Decoração',
      aliases: ['madeiramadeira', 'madeira madeira', 'moveis madeiramadeira'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'leroy',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Reformas e Materiais',
      aliases: ['leroy', 'leroy merlin', 'leroymerlin'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'c&c',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Reformas e Materiais',
      aliases: ['c&c', 'cc', 'c e c', 'casa construcao'],
      confidence: 0.90,
    ),
    
    // ═══════════════════════════════════════════════════════════
    // 🏥 SAÚDE - CONSULTAS (10+ referências)
    // ═══════════════════════════════════════════════════════════
    
    KeywordMapping(
      keyword: 'consulta',
      categoria: 'Saúde',
      subcategoria: 'Consultas Médicas/Dentista',
      aliases: ['consulta', 'consulta medica', 'consulta médica', 'médico'],
      confidence: 0.85,
    ),
    KeywordMapping(
      keyword: 'dentista',
      categoria: 'Saúde',
      subcategoria: 'Consultas Médicas/Dentista',
      aliases: ['dentista', 'odontologica', 'odontológica', 'dente'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'clinica',
      categoria: 'Saúde',
      subcategoria: 'Consultas Médicas/Dentista',
      aliases: ['clinica', 'clínica', 'clinic'],
      confidence: 0.80,
    ),
    KeywordMapping(
      keyword: 'hospital',
      categoria: 'Saúde',
      subcategoria: 'Consultas Médicas/Dentista',
      aliases: ['hospital', 'pronto socorro', 'ps'],
      confidence: 0.85,
    ),
    
    // ═══════════════════════════════════════════════════════════
    // 💊 SAÚDE - MEDICAMENTOS (15+ referências)
    // ═══════════════════════════════════════════════════════════
    
    KeywordMapping(
      keyword: 'drogasil',
      categoria: 'Saúde',
      subcategoria: 'Medicamentos',
      aliases: ['drogasil', 'droga sil', 'drogaria sil'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'raia',
      categoria: 'Saúde',
      subcategoria: 'Medicamentos',
      aliases: ['raia', 'drogaria raia', 'raia drogasil'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'sao paulo',
      categoria: 'Saúde',
      subcategoria: 'Medicamentos',
      aliases: ['sao paulo', 'são paulo', 'drogaria são paulo', 'dpsp'],
      confidence: 0.85,
    ),
    KeywordMapping(
      keyword: 'pacheco',
      categoria: 'Saúde',
      subcategoria: 'Medicamentos',
      aliases: ['pacheco', 'drogaria pacheco', 'dp'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'pague menos',
      categoria: 'Saúde',
      subcategoria: 'Medicamentos',
      aliases: ['pague menos', 'paguemenos', 'drogaria pague menos'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'ultrafarma',
      categoria: 'Saúde',
      subcategoria: 'Medicamentos',
      aliases: ['ultrafarma', 'ultra farma'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'farmacia',
      categoria: 'Saúde',
      subcategoria: 'Medicamentos',
      aliases: ['farmacia', 'farmácia', 'drogaria', 'remedios', 'remédios', 'drog'],
      confidence: 0.85,
    ),
    KeywordMapping(
      keyword: 'perfumaria',
      categoria: 'Saúde',
      subcategoria: 'Higiene',
      aliases: ['perfumaria', 'perfume', 'cosmetico', 'cosmético', 'higiene'],
      confidence: 0.85,
    ),
    KeywordMapping(
      keyword: 'princesa',
      categoria: 'Saúde',
      subcategoria: 'Higiene',
      aliases: ['princesa', 'perfumaria princesa'],
      confidence: 0.90,
    ),

    // ═══════════════════════════════════════════════════════════
    // 🩺 SAÚDE - EXAMES (5+ referências)
    // ═══════════════════════════════════════════════════════════
    
    KeywordMapping(
      keyword: 'laboratorio',
      categoria: 'Saúde',
      subcategoria: 'Exames',
      aliases: ['laboratorio', 'laboratório', 'lab', 'exame'],
      confidence: 0.85,
    ),
    KeywordMapping(
      keyword: 'fleury',
      categoria: 'Saúde',
      subcategoria: 'Exames',
      aliases: ['fleury', 'grupo fleury'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'dasa',
      categoria: 'Saúde',
      subcategoria: 'Exames',
      aliases: ['dasa', 'laboratorio dasa'],
      confidence: 0.95,
    ),
    
    // ═══════════════════════════════════════════════════════════
    // 🏥 SAÚDE - PLANO DE SAÚDE (10+ referências)
    // ═══════════════════════════════════════════════════════════
    
    KeywordMapping(
      keyword: 'unimed',
      categoria: 'Saúde',
      subcategoria: 'Plano de Saúde',
      aliases: ['unimed', 'unimedsp', 'unimed-'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'amil',
      categoria: 'Saúde',
      subcategoria: 'Plano de Saúde',
      aliases: ['amil', 'plano amil'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'bradesco saude',
      categoria: 'Saúde',
      subcategoria: 'Plano de Saúde',
      aliases: ['bradesco saude', 'bradesco saúde', 'bradesco seguro saúde'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'sulamerica',
      categoria: 'Saúde',
      subcategoria: 'Plano de Saúde',
      aliases: ['sulamerica', 'sulamérica', 'sul america'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'plano de saude',
      categoria: 'Saúde',
      subcategoria: 'Plano de Saúde',
      aliases: ['plano de saude', 'plano de saúde', 'convenio', 'convênio'],
      confidence: 0.85,
    ),
    
    // ═══════════════════════════════════════════════════════════
    // 🎓 EDUCAÇÃO - CURSOS/MENSALIDADE (20+ referências)
    // ═══════════════════════════════════════════════════════════
    
    KeywordMapping(
      keyword: 'usp',
      categoria: 'Educação',
      subcategoria: 'Mensalidade',
      aliases: ['usp', 'universidade de são paulo'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'unip',
      categoria: 'Educação',
      subcategoria: 'Mensalidade',
      aliases: ['unip', 'universidade paulista'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'anhembi',
      categoria: 'Educação',
      subcategoria: 'Mensalidade',
      aliases: ['anhembi', 'anhembi morumbi'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'mackenzie',
      categoria: 'Educação',
      subcategoria: 'Mensalidade',
      aliases: ['mackenzie', 'universidade mackenzie'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'estacio',
      categoria: 'Educação',
      subcategoria: 'Mensalidade',
      aliases: ['estacio', 'estácio', 'universidade estacio'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'mensalidade',
      categoria: 'Educação',
      subcategoria: 'Mensalidade',
      aliases: ['mensalidade', 'mensalidade escolar', 'mensalidade faculdade'],
      confidence: 0.85,
    ),
    KeywordMapping(
      keyword: 'colegio',
      categoria: 'Educação',
      subcategoria: 'Mensalidade',
      aliases: ['colegio', 'colégio', 'escola', 'ensino'],
      confidence: 0.80,
    ),
    KeywordMapping(
      keyword: 'curso',
      categoria: 'Educação',
      subcategoria: 'Cursos',
      aliases: ['curso', 'aula', 'treinamento', 'capacitação'],
      confidence: 0.75,
    ),
    KeywordMapping(
      keyword: 'udemy',
      categoria: 'Educação',
      subcategoria: 'Cursos',
      aliases: ['udemy', 'ude my'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'coursera',
      categoria: 'Educação',
      subcategoria: 'Cursos',
      aliases: ['coursera', 'course ra'],
      confidence: 0.95,
    ),
    
    // ═══════════════════════════════════════════════════════════
    // 📚 EDUCAÇÃO - LIVROS/MATERIAL (10+ referências)
    // ═══════════════════════════════════════════════════════════
    
    KeywordMapping(
      keyword: 'amazon',
      categoria: 'Educação',
      subcategoria: 'Livros',
      aliases: ['amazon', 'amazon.com', 'amazon br', 'kindle'],
      confidence: 0.85,
    ),
    KeywordMapping(
      keyword: 'saraiva',
      categoria: 'Educação',
      subcategoria: 'Livros',
      aliases: ['saraiva', 'livraria saraiva'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'cultura',
      categoria: 'Educação',
      subcategoria: 'Livros',
      aliases: ['cultura', 'livraria cultura'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'fnac',
      categoria: 'Educação',
      subcategoria: 'Livros',
      aliases: ['fnac', 'fnac brasil'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'livro',
      categoria: 'Educação',
      subcategoria: 'Livros',
      aliases: ['livro', 'livros', 'livraria', 'apostila'],
      confidence: 0.80,
    ),
    KeywordMapping(
      keyword: 'material escolar',
      categoria: 'Educação',
      subcategoria: 'Material Escolar',
      aliases: ['material escolar', 'papelaria', 'caderno', 'lapis'],
      confidence: 0.85,
    ),
    
    // ═══════════════════════════════════════════════════════════
    // 🎬 LAZER - CINEMA/STREAMING (15+ referências)
    // ═══════════════════════════════════════════════════════════
    
    KeywordMapping(
      keyword: 'netflix',
      categoria: 'Lazer',
      subcategoria: 'Streaming',
      aliases: ['netflix', 'netfix', 'net flix'],
      confidence: 0.98,
    ),
    KeywordMapping(
      keyword: 'spotify',
      categoria: 'Lazer',
      subcategoria: 'Streaming',
      aliases: ['spotify', 'spotfy', 'spot ify'],
      confidence: 0.98,
    ),
    KeywordMapping(
      keyword: 'amazon prime',
      categoria: 'Lazer',
      subcategoria: 'Streaming',
      aliases: ['amazon prime', 'prime video', 'amazon video'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'disney',
      categoria: 'Lazer',
      subcategoria: 'Streaming',
      aliases: ['disney', 'disney+', 'disney plus', 'disneyplus'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'hbo',
      categoria: 'Lazer',
      subcategoria: 'Streaming',
      aliases: ['hbo', 'hbo max', 'hbomax'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'globoplay',
      categoria: 'Lazer',
      subcategoria: 'Streaming',
      aliases: ['globoplay', 'globo play', 'globo +'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'youtube',
      categoria: 'Lazer',
      subcategoria: 'Streaming',
      aliases: ['youtube', 'youtube premium', 'youtube music', 'google youtube'],
      confidence: 0.98,
    ),
    KeywordMapping(
      keyword: 'cinema',
      categoria: 'Lazer',
      subcategoria: 'Cinema/Teatro',
      aliases: ['cinema', 'cinemark', 'uci', 'ingresso', 'filme'],
      confidence: 0.85,
    ),
    KeywordMapping(
      keyword: 'teatro',
      categoria: 'Lazer',
      subcategoria: 'Cinema/Teatro',
      aliases: ['teatro', 'peça', 'espetáculo'],
      confidence: 0.90,
    ),
    
    // ═══════════════════════════════════════════════════════════
    // ✈️ LAZER - VIAGENS (15+ referências)
    // ═══════════════════════════════════════════════════════════
    
    KeywordMapping(
      keyword: 'decolar',
      categoria: 'Lazer',
      subcategoria: 'Viagens',
      aliases: ['decolar', 'decolar.com', 'decolar com'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'booking',
      categoria: 'Lazer',
      subcategoria: 'Viagens',
      aliases: ['booking', 'booking.com', 'bookingcom'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'airbnb',
      categoria: 'Lazer',
      subcategoria: 'Viagens',
      aliases: ['airbnb', 'air bnb'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'hotel',
      categoria: 'Lazer',
      subcategoria: 'Viagens',
      aliases: ['hotel', 'hoteis', 'hotéis', 'hospedagem'],
      confidence: 0.85,
    ),
    KeywordMapping(
      keyword: 'gol',
      categoria: 'Lazer',
      subcategoria: 'Viagens',
      aliases: ['gol', 'gol linhas aereas', 'voegol'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'latam',
      categoria: 'Lazer',
      subcategoria: 'Viagens',
      aliases: ['latam', 'latam airlines'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'azul',
      categoria: 'Lazer',
      subcategoria: 'Viagens',
      aliases: ['azul', 'azul linhas aereas', 'voeazul'],
      confidence: 0.90,
    ),
    
    // ═══════════════════════════════════════════════════════════
    // 👕 VESTUÁRIO (15+ referências)
    // ═══════════════════════════════════════════════════════════
    
    KeywordMapping(
      keyword: 'renner',
      categoria: 'Vestuário',
      subcategoria: 'Roupas',
      aliases: ['renner', 'lojas renner'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'riachuelo',
      categoria: 'Vestuário',
      subcategoria: 'Roupas',
      aliases: ['riachuelo', 'lojas riachuelo'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'marisa',
      categoria: 'Vestuário',
      subcategoria: 'Roupas',
      aliases: ['marisa', 'lojas marisa'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'c&a',
      categoria: 'Vestuário',
      subcategoria: 'Roupas',
      aliases: ['c&a', 'cea', 'c e a'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'zara',
      categoria: 'Vestuário',
      subcategoria: 'Roupas',
      aliases: ['zara', 'zara store'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'hering',
      categoria: 'Vestuário',
      subcategoria: 'Roupas',
      aliases: ['hering', 'cia hering'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'nike',
      categoria: 'Vestuário',
      subcategoria: 'Roupas',
      aliases: ['nike', 'nike store'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'adidas',
      categoria: 'Vestuário',
      subcategoria: 'Roupas',
      aliases: ['adidas', 'adidas store'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'centauro',
      categoria: 'Vestuário',
      subcategoria: 'Calçados',
      aliases: ['centauro', 'loja centauro', 'centauro com', 'centauro br'],
      confidence: 0.98, // 🔥 Alta prioridade para evitar conflito com "combustível"
    ),
    KeywordMapping(
      keyword: 'netshoes',
      categoria: 'Vestuário',
      subcategoria: 'Calçados',
      aliases: ['netshoes', 'net shoes'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'shopee',
      categoria: 'Vestuário',
      subcategoria: 'Roupas',
      aliases: ['shopee', 'shop', 'shopee *'],
      confidence: 0.85,
    ),
    KeywordMapping(
      keyword: 'mercadolivre',
      categoria: 'Vestuário',
      subcategoria: 'Acessórios',
      aliases: ['mercadolivre', 'mercado livre', 'mercadopago', 'mlp*', 'mp *'],
      confidence: 0.80,
    ),
    KeywordMapping(
      keyword: 'bonasecco',
      categoria: 'Vestuário',
      subcategoria: 'Roupas',
      aliases: ['bonasecco', 'bona secco'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'camiseta',
      categoria: 'Vestuário',
      subcategoria: 'Roupas',
      aliases: ['camiseta', 'camisa', 'blusa', 'hotrod'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'fila',
      categoria: 'Vestuário',
      subcategoria: 'Roupas',
      aliases: ['fila', 'fila br', 'fila rb'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'calcado',
      categoria: 'Vestuário',
      subcategoria: 'Calçados',
      aliases: ['calcado', 'calçado', 'sapato', 'tenis', 'tênis', 'sandalia'],
      confidence: 0.85,
    ),
    KeywordMapping(
      keyword: 'roupa',
      categoria: 'Vestuário',
      subcategoria: 'Roupas',
      aliases: ['roupa', 'roupas', 'vestuario', 'vestuário'],
      confidence: 0.80,
    ),
    KeywordMapping(
      keyword: 'niazi',
      categoria: 'Vestuário',
      subcategoria: 'Roupas',
      aliases: ['niazi', 'niazi chohfi', 'chohfi'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'indigo',
      categoria: 'Vestuário',
      subcategoria: 'Roupas',
      aliases: ['indigo'],
      confidence: 0.85,
    ),

    // ═══════════════════════════════════════════════════════════
    // 🐕 PETS (20+ referências)
    // ═══════════════════════════════════════════════════════════
    
    KeywordMapping(
      keyword: 'petz',
      categoria: 'Pets',
      subcategoria: 'Ração',
      aliases: ['petz', 'pet shop petz'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'cobasi',
      categoria: 'Pets',
      subcategoria: 'Ração',
      aliases: ['cobasi', 'cobasi pet shop'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'petlove',
      categoria: 'Pets',
      subcategoria: 'Ração',
      aliases: ['petlove', 'pet love'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'pet shop',
      categoria: 'Pets',
      subcategoria: 'Acessórios',
      aliases: ['pet shop', 'petshop', 'pet'],
      confidence: 0.85,
    ),
    KeywordMapping(
      keyword: 'racao',
      categoria: 'Pets',
      subcategoria: 'Ração',
      aliases: ['racao', 'ração', 'comida pet', 'alimento pet'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'veterinario',
      categoria: 'Pets',
      subcategoria: 'Veterinário',
      aliases: ['veterinario', 'veterinário', 'vet', 'clinica veterinaria'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'banho e tosa',
      categoria: 'Pets',
      subcategoria: 'Acessórios',
      aliases: ['banho e tosa', 'pet grooming', 'tosa'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'vacina pet',
      categoria: 'Pets',
      subcategoria: 'Veterinário',
      aliases: ['vacina pet', 'vacinação pet', 'vacina cachorro', 'vacina gato'],
      confidence: 0.95,
    ),

    // ═══════════════════════════════════════════════════════════
    // 💎 BENS E PATRIMÔNIO - ELETRÔNICOS (50+ referências)
    // ═══════════════════════════════════════════════════════════

    KeywordMapping(
      keyword: 'samsung',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrônicos',
      aliases: ['samsung', 'galaxy', 'tv samsung', 'celular samsung'],
      confidence: 0.92,
    ),
    KeywordMapping(
      keyword: 'apple',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrônicos',
      aliases: ['apple', 'iphone', 'ipad', 'macbook', 'apple watch'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'lg eletronicos',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrônicos',
      aliases: ['lg', 'tv lg', 'monitor lg'],
      confidence: 0.88,
    ),
    KeywordMapping(
      keyword: 'sony',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrônicos',
      aliases: ['sony', 'tv sony', 'playstation', 'ps5'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'dell',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrônicos',
      aliases: ['dell', 'notebook dell', 'computador dell'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'lenovo',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrônicos',
      aliases: ['lenovo', 'notebook lenovo', 'thinkpad'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'xiaomi',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrônicos',
      aliases: ['xiaomi', 'redmi', 'poco', 'celular xiaomi'],
      confidence: 0.92,
    ),
    KeywordMapping(
      keyword: 'motorola',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrônicos',
      aliases: ['motorola', 'moto g', 'moto e'],
      confidence: 0.92,
    ),
    KeywordMapping(
      keyword: 'jbl',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrônicos',
      aliases: ['jbl', 'caixa jbl', 'fone jbl'],
      confidence: 0.92,
    ),
    KeywordMapping(
      keyword: 'logitech',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrônicos',
      aliases: ['logitech', 'mouse logitech', 'teclado logitech'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'eletronico',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrônicos',
      aliases: ['eletronico', 'celular', 'notebook', 'tv', 'computador', 'tablet'],
      confidence: 0.75,
    ),

    // ═══════════════════════════════════════════════════════════
    // 💎 BENS E PATRIMÔNIO - ELETRODOMÉSTICOS (30+ referências)
    // ═══════════════════════════════════════════════════════════

    KeywordMapping(
      keyword: 'brastemp',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrodomésticos',
      aliases: ['brastemp', 'geladeira brastemp', 'fogao brastemp', 'lavadora brastemp'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'consul',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrodomésticos',
      aliases: ['consul', 'geladeira consul', 'fogao consul', 'freezer consul'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'electrolux',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrodomésticos',
      aliases: ['electrolux', 'geladeira electrolux', 'lavadora electrolux'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'lg eletrodomesticos',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrodomésticos',
      aliases: ['geladeira lg', 'lavadora lg', 'micro-ondas lg'],
      confidence: 0.85,
    ),
    KeywordMapping(
      keyword: 'midea',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrodomésticos',
      aliases: ['midea', 'ar condicionado midea', 'lavadora midea'],
      confidence: 0.92,
    ),
    KeywordMapping(
      keyword: 'philco',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrodomésticos',
      aliases: ['philco', 'geladeira philco', 'ar condicionado philco'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'britania',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrodomésticos',
      aliases: ['britania', 'ventilador britania', 'liquidificador britania'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'arno',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrodomésticos',
      aliases: ['arno', 'liquidificador arno', 'batedeira arno'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'mondial',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrodomésticos',
      aliases: ['mondial', 'ventilador mondial', 'air fryer mondial'],
      confidence: 0.88,
    ),
    KeywordMapping(
      keyword: 'cadence',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrodomésticos',
      aliases: ['cadence', 'air fryer cadence'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'gree',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrodomésticos',
      aliases: ['gree', 'ar condicionado gree'],
      confidence: 0.92,
    ),
    KeywordMapping(
      keyword: 'eletrodomestico',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrodomésticos',
      aliases: ['eletrodomestico', 'geladeira', 'fogao', 'lavadora', 'ar condicionado', 'micro-ondas'],
      confidence: 0.78,
    ),

    // ═══════════════════════════════════════════════════════════
    // 💎 BENS E PATRIMÔNIO - MÓVEIS E DECORAÇÃO (20+ referências)
    // ═══════════════════════════════════════════════════════════

    KeywordMapping(
      keyword: 'tok stok',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Móveis e Decoração',
      aliases: ['tok stok', 'tokstok', 'tok&stok'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'etna',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Móveis e Decoração',
      aliases: ['etna', 'moveis etna'],
      confidence: 0.92,
    ),
    KeywordMapping(
      keyword: 'madesa',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Móveis e Decoração',
      aliases: ['madesa', 'moveis madesa', 'armario madesa'],
      confidence: 0.92,
    ),
    KeywordMapping(
      keyword: 'mobly',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Móveis e Decoração',
      aliases: ['mobly', 'moveis mobly'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'camicado',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Móveis e Decoração',
      aliases: ['camicado', 'cama mesa banho'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'moveis',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Móveis e Decoração',
      aliases: ['moveis', 'sofa', 'cama', 'mesa', 'cadeira', 'armario', 'estante'],
      confidence: 0.75,
    ),
    KeywordMapping(
      keyword: 'decoracao',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Móveis e Decoração',
      aliases: ['decoracao', 'quadro', 'tapete', 'cortina', 'luminaria'],
      confidence: 0.75,
    ),

    // ═══════════════════════════════════════════════════════════
    // 💎 BENS E PATRIMÔNIO - VEÍCULO (15+ referências)
    // ═══════════════════════════════════════════════════════════

    KeywordMapping(
      keyword: 'peca carro',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Veículo',
      aliases: ['peca carro', 'peca automotiva', 'auto peca'],
      confidence: 0.88,
    ),
    KeywordMapping(
      keyword: 'acessorio carro',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Veículo',
      aliases: ['acessorio carro', 'tapete carro', 'capa banco'],
      confidence: 0.82,
    ),
    KeywordMapping(
      keyword: 'som automotivo',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Veículo',
      aliases: ['som automotivo', 'som carro', 'auto radio'],
      confidence: 0.88,
    ),
    KeywordMapping(
      keyword: 'alarme carro',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Veículo',
      aliases: ['alarme carro', 'rastreador', 'bloqueador'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'insulfilm',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Veículo',
      aliases: ['insulfilm', 'pelicula carro'],
      confidence: 0.92,
    ),

    // ═══════════════════════════════════════════════════════════
    // 💎 BENS E PATRIMÔNIO - IMÓVEL (15+ referências)
    // ═══════════════════════════════════════════════════════════

    KeywordMapping(
      keyword: 'pintura',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Imóvel',
      aliases: ['pintura', 'tinta', 'pintor', 'pintura casa'],
      confidence: 0.88,
    ),
    KeywordMapping(
      keyword: 'hidraulica',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Imóvel',
      aliases: ['hidraulica', 'encanamento', 'encanador', 'torneira'],
      confidence: 0.88,
    ),
    KeywordMapping(
      keyword: 'eletrica',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Imóvel',
      aliases: ['eletrica', 'eletricista', 'fiacao', 'tomada'],
      confidence: 0.88,
    ),
    KeywordMapping(
      keyword: 'vidracaria',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Imóvel',
      aliases: ['vidracaria', 'vidro', 'espelho', 'box banheiro'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'manutencao casa',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Imóvel',
      aliases: ['manutencao casa', 'reparo casa', 'conserto casa'],
      confidence: 0.85,
    ),

    // ═══════════════════════════════════════════════════════════
    // 💎 BENS E PATRIMÔNIO - FERRAMENTAS (20+ referências)
    // ═══════════════════════════════════════════════════════════

    KeywordMapping(
      keyword: 'bosch',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Ferramentas e Equipamentos',
      aliases: ['bosch', 'furadeira bosch', 'parafusadeira bosch'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'dewalt',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Ferramentas e Equipamentos',
      aliases: ['dewalt', 'de walt', 'furadeira dewalt'],
      confidence: 0.92,
    ),
    KeywordMapping(
      keyword: 'makita',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Ferramentas e Equipamentos',
      aliases: ['makita', 'furadeira makita', 'serra makita'],
      confidence: 0.92,
    ),
    KeywordMapping(
      keyword: 'black decker',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Ferramentas e Equipamentos',
      aliases: ['black decker', 'blackdecker', 'black & decker'],
      confidence: 0.92,
    ),
    KeywordMapping(
      keyword: 'ferramentas',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Ferramentas e Equipamentos',
      aliases: ['ferramenta', 'furadeira', 'parafusadeira', 'serra', 'martelo'],
      confidence: 0.78,
    ),
    KeywordMapping(
      keyword: 'jardim',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Ferramentas e Equipamentos',
      aliases: ['jardim', 'jardinagem', 'cortador grama', 'aparador'],
      confidence: 0.82,
    ),

    // ═══════════════════════════════════════════════════════════
    // 💎 BENS E PATRIMÔNIO - REFORMAS (25+ referências)
    // ═══════════════════════════════════════════════════════════

    KeywordMapping(
      keyword: 'leroy merlin',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Reformas e Materiais',
      aliases: ['leroy merlin', 'leroy', 'leroymerlin'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'telhanorte',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Reformas e Materiais',
      aliases: ['telhanorte', 'telha norte'],
      confidence: 0.92,
    ),
    KeywordMapping(
      keyword: 'dicico',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Reformas e Materiais',
      aliases: ['dicico'],
      confidence: 0.92,
    ),
    KeywordMapping(
      keyword: 'reforma',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Reformas e Materiais',
      aliases: ['reforma', 'construcao', 'obra', 'renovacao'],
      confidence: 0.85,
    ),
    KeywordMapping(
      keyword: 'pedreiro',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Reformas e Materiais',
      aliases: ['pedreiro', 'alvenaria', 'reboco', 'cimento'],
      confidence: 0.88,
    ),
    KeywordMapping(
      keyword: 'piso',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Reformas e Materiais',
      aliases: ['piso', 'porcelanato', 'ceramica', 'azulejo'],
      confidence: 0.85,
    ),
    KeywordMapping(
      keyword: 'marcenaria',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Reformas e Materiais',
      aliases: ['marcenaria', 'marceneiro', 'armario planejado', 'moveis planejados'],
      confidence: 0.88,
    ),
    KeywordMapping(
      keyword: 'serralheria',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Reformas e Materiais',
      aliases: ['serralheria', 'serralheiro', 'portao', 'grade'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'material construcao',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Reformas e Materiais',
      aliases: ['material construcao', 'cimento', 'areia', 'brita', 'tijolo'],
      confidence: 0.85,
    ),

    // ═══════════════════════════════════════════════════════════
    // 💎 BENS E PATRIMÔNIO - LOJAS CONTEXTUAIS (10+ referências)
    // ═══════════════════════════════════════════════════════════

    KeywordMapping(
      keyword: 'casas bahia',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrônicos',
      aliases: ['casas bahia', 'casasbahia'],
      confidence: 0.82,
    ),
    KeywordMapping(
      keyword: 'magazine luiza',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrônicos',
      aliases: ['magazine luiza', 'magalu'],
      confidence: 0.82,
    ),
    KeywordMapping(
      keyword: 'ponto frio',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrodomésticos',
      aliases: ['ponto frio', 'pontofrio'],
      confidence: 0.82,
    ),
    KeywordMapping(
      keyword: 'fast shop',
      categoria: 'Bens e Patrimônio',
      subcategoria: 'Eletrônicos',
      aliases: ['fast shop', 'fastshop'],
      confidence: 0.90,
    ),

    // ═══════════════════════════════════════════════════════════
    // 💰 RECEITAS - SALÁRIO (10+ referências)
    // ═══════════════════════════════════════════════════════════
    
    KeywordMapping(
      keyword: 'salario',
      categoria: 'Salário',
      subcategoria: 'Salário Principal',
      aliases: ['salario', 'salário', 'pagamento', 'vencimento'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'pix recebido',
      categoria: 'Salário',
      subcategoria: 'Salário Principal',
      aliases: ['pix recebido', 'transferencia recebida', 'ted recebido'],
      confidence: 0.70,
    ),
    KeywordMapping(
      keyword: 'deposito',
      categoria: 'Salário',
      subcategoria: 'Salário Principal',
      aliases: ['deposito', 'depósito', 'dep', 'deposito em conta'],
      confidence: 0.65,
    ),
    KeywordMapping(
      keyword: '13 salario',
      categoria: 'Salário',
      subcategoria: '13º Salário',
      aliases: ['13 salario', '13º salário', 'decimo terceiro', '13o'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'ferias',
      categoria: 'Salário',
      subcategoria: 'Bonificação',
      aliases: ['ferias', 'férias', 'terço de ferias'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'bonus',
      categoria: 'Salário',
      subcategoria: 'Bonificação',
      aliases: ['bonus', 'bônus', 'bonificação', 'gratificação'],
      confidence: 0.85,
    ),
    KeywordMapping(
      keyword: 'hora extra',
      categoria: 'Salário',
      subcategoria: 'Horas Extras',
      aliases: ['hora extra', 'horas extras', 'he'],
      confidence: 0.90,
    ),
    
    // ═══════════════════════════════════════════════════════════
    // 💼 RECEITAS - FREELANCE (15+ referências)
    // ═══════════════════════════════════════════════════════════
    
    KeywordMapping(
      keyword: 'freelancer',
      categoria: 'Freelance',
      subcategoria: 'Projetos',
      aliases: ['freelancer', 'freela', 'free lancer', 'autonomo'],
      confidence: 0.85,
    ),
    KeywordMapping(
      keyword: 'projeto',
      categoria: 'Freelance',
      subcategoria: 'Projetos',
      aliases: ['projeto', 'trabalho', 'job', 'bico'],
      confidence: 0.70,
    ),
    KeywordMapping(
      keyword: 'consultoria',
      categoria: 'Freelance',
      subcategoria: 'Consultoria',
      aliases: ['consultoria', 'consultor', 'assessoria'],
      confidence: 0.85,
    ),
    KeywordMapping(
      keyword: 'servico',
      categoria: 'Freelance',
      subcategoria: 'Serviços',
      aliases: ['servico', 'serviço', 'prestação de serviço'],
      confidence: 0.75,
    ),
    KeywordMapping(
      keyword: 'paypal',
      categoria: 'Freelance',
      subcategoria: 'Projetos',
      aliases: ['paypal', 'pay pal', 'paypal *'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'mercado pago',
      categoria: 'Freelance',
      subcategoria: 'Projetos',
      aliases: ['mercado pago', 'mercadopago', 'mp *'],
      confidence: 0.85,
    ),
    
    // ═══════════════════════════════════════════════════════════
    // 📈 RECEITAS - INVESTIMENTOS (15+ referências)
    // ═══════════════════════════════════════════════════════════
    
    KeywordMapping(
      keyword: 'dividendo',
      categoria: 'Investimentos',
      subcategoria: 'Dividendos',
      aliases: ['dividendo', 'dividendos', 'proventos', 'div'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'jcp',
      categoria: 'Investimentos',
      subcategoria: 'Dividendos',
      aliases: ['jcp', 'juros capital proprio', 'juros sobre capital'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'rendimento',
      categoria: 'Investimentos',
      subcategoria: 'Juros',
      aliases: ['rendimento', 'rendimentos', 'juros', 'yield'],
      confidence: 0.80,
    ),
    KeywordMapping(
      keyword: 'cdb',
      categoria: 'Investimentos',
      subcategoria: 'Rendimentos CDB',
      aliases: ['cdb', 'certificado deposito', 'renda fixa'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'tesouro direto',
      categoria: 'Investimentos',
      subcategoria: 'Rendimentos CDB',
      aliases: ['tesouro direto', 'tesouro', 'td', 'titulo publico'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'fundo',
      categoria: 'Investimentos',
      subcategoria: 'Fundos',
      aliases: ['fundo', 'fundos', 'fii', 'fundos imobiliarios'],
      confidence: 0.80,
    ),
    KeywordMapping(
      keyword: 'btg',
      categoria: 'Investimentos',
      subcategoria: 'Juros',
      aliases: ['btg', 'btg pactual', 'btg+'],
      confidence: 0.85,
    ),
    KeywordMapping(
      keyword: 'xp',
      categoria: 'Investimentos',
      subcategoria: 'Juros',
      aliases: ['xp', 'xp investimentos', 'xpi'],
      confidence: 0.85,
    ),
    KeywordMapping(
      keyword: 'nubank',
      categoria: 'Investimentos',
      subcategoria: 'Juros',
      aliases: ['nubank', 'nu invest', 'nuinvest', 'roxinho'],
      confidence: 0.80,
    ),
    
    // ═══════════════════════════════════════════════════════════
    // 🛍️ RECEITAS - VENDAS (15+ referências)
    // ═══════════════════════════════════════════════════════════
    
    KeywordMapping(
      keyword: 'mercado livre',
      categoria: 'Vendas',
      subcategoria: 'Produtos',
      aliases: ['mercado livre', 'mercadolivre', 'ml', 'meli'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'olx',
      categoria: 'Vendas',
      subcategoria: 'Usados',
      aliases: ['olx', 'olx brasil'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'shopee',
      categoria: 'Vendas',
      subcategoria: 'Produtos',
      aliases: ['shopee', 'shope', 'shopee brasil'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'venda',
      categoria: 'Vendas',
      subcategoria: 'Produtos',
      aliases: ['venda', 'vendas', 'comercio'],
      confidence: 0.75,
    ),
    KeywordMapping(
      keyword: 'enjoei',
      categoria: 'Vendas',
      subcategoria: 'Usados',
      aliases: ['enjoei', 'enjoei.com'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'brechó',
      categoria: 'Vendas',
      subcategoria: 'Usados',
      aliases: ['brechó', 'brecho', 'bazar'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'artesanato',
      categoria: 'Vendas',
      subcategoria: 'Artesanato',
      aliases: ['artesanato', 'artesanal', 'handmade', 'feito a mão'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'elo7',
      categoria: 'Vendas',
      subcategoria: 'Artesanato',
      aliases: ['elo7', 'elo 7'],
      confidence: 0.95,
    ),
    
    // ═══════════════════════════════════════════════════════════
    // 💸 RECEITAS - OUTROS (10+ referências)
    // ═══════════════════════════════════════════════════════════
    
    KeywordMapping(
      keyword: 'presente',
      categoria: 'Outros',
      subcategoria: 'Presente',
      aliases: ['presente', 'gift', 'doação recebida'],
      confidence: 0.80,
    ),
    KeywordMapping(
      keyword: 'reembolso',
      categoria: 'Outros',
      subcategoria: 'Reembolso',
      aliases: ['reembolso', 'estorno', 'devolução', 'ressarcimento'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'premio',
      categoria: 'Outros',
      subcategoria: 'Prêmio',
      aliases: ['premio', 'prêmio', 'sorteio', 'loteria'],
      confidence: 0.85,
    ),
    KeywordMapping(
      keyword: 'cashback',
      categoria: 'Outros',
      subcategoria: 'Reembolso',
      aliases: ['cashback', 'cash back', 'dinheiro de volta'],
      confidence: 0.90,
    ),
    
    // ═══════════════════════════════════════════════════════════
    // 🎮 LAZER - HOBBIES/GAMES (15+ referências)
    // ═══════════════════════════════════════════════════════════
    
    KeywordMapping(
      keyword: 'steam',
      categoria: 'Lazer',
      subcategoria: 'Hobbies',
      aliases: ['steam', 'steam games', 'valve'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'playstation',
      categoria: 'Lazer',
      subcategoria: 'Hobbies',
      aliases: ['playstation', 'psn', 'ps store', 'ps plus'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'xbox',
      categoria: 'Lazer',
      subcategoria: 'Hobbies',
      aliases: ['xbox', 'xbox live', 'xbox game pass'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'nintendo',
      categoria: 'Lazer',
      subcategoria: 'Hobbies',
      aliases: ['nintendo', 'switch', 'eshop'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'academia',
      categoria: 'Lazer',
      subcategoria: 'Hobbies',
      aliases: ['academia', 'gym', 'smart fit', 'bio ritmo'],
      confidence: 0.85,
    ),
    KeywordMapping(
      keyword: 'smartfit',
      categoria: 'Lazer',
      subcategoria: 'Hobbies',
      aliases: ['smartfit', 'smart fit', 'smart-fit'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'cinemark',
      categoria: 'Lazer',
      subcategoria: 'Cinema/Teatro',
      aliases: ['cinemark', 'cine mark'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'ingresso.com',
      categoria: 'Lazer',
      subcategoria: 'Cinema/Teatro',
      aliases: ['ingresso.com', 'ingressocom', 'ingresso com'],
      confidence: 0.95,
    ),
    
    // ═══════════════════════════════════════════════════════════
    // 🏪 COMPRAS GERAIS (20+ referências)
    // ═══════════════════════════════════════════════════════════
    
    KeywordMapping(
      keyword: 'magazine luiza',
      categoria: 'Vestuário',
      subcategoria: 'Acessórios',
      aliases: ['magazine luiza', 'magalu', 'magazine', 'mag luiza'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'americanas',
      categoria: 'Vestuário',
      subcategoria: 'Acessórios',
      aliases: ['americanas', 'lojas americanas', 'americanas.com'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'casas bahia',
      categoria: 'Vestuário',
      subcategoria: 'Acessórios',
      aliases: ['casas bahia', 'casasbahia', 'casa bahia'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'ponto frio',
      categoria: 'Vestuário',
      subcategoria: 'Acessórios',
      aliases: ['ponto frio', 'pontofrio', 'ponto-frio'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'submarino',
      categoria: 'Vestuário',
      subcategoria: 'Acessórios',
      aliases: ['submarino', 'submarino.com'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'kalunga',
      categoria: 'Educação',
      subcategoria: 'Material Escolar',
      aliases: ['kalunga', 'papelaria kalunga'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'leroy merlin',
      categoria: 'Moradia',
      subcategoria: 'Condomínio',
      aliases: ['leroy merlin', 'leroy', 'leroymerlin'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'tok stok',
      categoria: 'Moradia',
      subcategoria: 'Condomínio',
      aliases: ['tok stok', 'tokstok', 'tok&stok'],
      confidence: 0.95,
    ),
    KeywordMapping(
      keyword: 'ikea',
      categoria: 'Moradia',
      subcategoria: 'Condomínio',
      aliases: ['ikea', 'ikea brasil'],
      confidence: 0.95,
    ),
    
    // ═══════════════════════════════════════════════════════════
    // 🏦 BANCOS E FINANCEIRAS (20+ referências)
    // ═══════════════════════════════════════════════════════════
    
    KeywordMapping(
      keyword: 'itau',
      categoria: 'Outros',
      subcategoria: 'Reembolso',
      aliases: ['itau', 'itaú', 'banco itau', 'itaucard'],
      confidence: 0.80,
    ),
    KeywordMapping(
      keyword: 'bradesco',
      categoria: 'Outros',
      subcategoria: 'Reembolso',
      aliases: ['bradesco', 'banco bradesco', 'bradesco cartoes'],
      confidence: 0.80,
    ),
    KeywordMapping(
      keyword: 'santander',
      categoria: 'Outros',
      subcategoria: 'Reembolso',
      aliases: ['santander', 'banco santander', 'santander brasil'],
      confidence: 0.80,
    ),
    KeywordMapping(
      keyword: 'banco do brasil',
      categoria: 'Outros',
      subcategoria: 'Reembolso',
      aliases: ['banco do brasil', 'bb', 'bancodobrasil'],
      confidence: 0.80,
    ),
    KeywordMapping(
      keyword: 'caixa',
      categoria: 'Outros',
      subcategoria: 'Reembolso',
      aliases: ['caixa', 'caixa economica', 'cef'],
      confidence: 0.75,
    ),
    KeywordMapping(
      keyword: 'inter',
      categoria: 'Outros',
      subcategoria: 'Reembolso',
      aliases: ['inter', 'banco inter', 'inter bank'],
      confidence: 0.80,
    ),
    KeywordMapping(
      keyword: 'c6',
      categoria: 'Outros',
      subcategoria: 'Reembolso',
      aliases: ['c6', 'c6 bank', 'banco c6'],
      confidence: 0.85,
    ),
    KeywordMapping(
      keyword: 'original',
      categoria: 'Outros',
      subcategoria: 'Reembolso',
      aliases: ['original', 'banco original'],
      confidence: 0.80,
    ),
    KeywordMapping(
      keyword: 'picpay',
      categoria: 'Outros',
      subcategoria: 'Reembolso',
      aliases: ['picpay', 'pic pay', 'pic-pay'],
      confidence: 0.85,
    ),
    
    // ═══════════════════════════════════════════════════════════
    // 📱 TELEFONIA/CELULAR (15+ referências)
    // ═══════════════════════════════════════════════════════════
    
    KeywordMapping(
      keyword: 'vivo movel',
      categoria: 'Moradia',
      subcategoria: 'Internet',
      aliases: ['vivo movel', 'vivo móvel', 'vivo celular', 'vivo pre'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'claro movel',
      categoria: 'Moradia',
      subcategoria: 'Internet',
      aliases: ['claro movel', 'claro móvel', 'claro celular', 'claro pre'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'tim movel',
      categoria: 'Moradia',
      subcategoria: 'Internet',
      aliases: ['tim movel', 'tim móvel', 'tim celular', 'tim pre'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'oi movel',
      categoria: 'Moradia',
      subcategoria: 'Internet',
      aliases: ['oi movel', 'oi móvel', 'oi celular'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'recarga celular',
      categoria: 'Moradia',
      subcategoria: 'Internet',
      aliases: ['recarga celular', 'recarga', 'credito celular'],
      confidence: 0.85,
    ),
    KeywordMapping(
      keyword: 'apple',
      categoria: 'Vestuário',
      subcategoria: 'Acessórios',
      aliases: ['apple', 'apple store', 'iphone', 'icloud'],
      confidence: 0.85,
    ),
    KeywordMapping(
      keyword: 'google play',
      categoria: 'Lazer',
      subcategoria: 'Hobbies',
      aliases: ['google play', 'googleplay', 'play store'],
      confidence: 0.90,
    ),
    KeywordMapping(
      keyword: 'app store',
      categoria: 'Lazer',
      subcategoria: 'Hobbies',
      aliases: ['app store', 'appstore', 'apple app'],
      confidence: 0.90,
    ),
  ];

  /// 🔍 BUSCAR CATEGORIA POR KEYWORD
  /// 
  /// Busca a melhor correspondência de categoria baseada em uma string de descrição
  /// Retorna o KeywordMapping com maior confidence que corresponder
  static KeywordMapping? buscarPorDescricao(String descricao, {String? tipo}) {
    if (descricao.isEmpty) return null;

    final descricaoLower = descricao.toLowerCase();
    KeywordMapping? melhorMatch;
    double melhorConfidence = 0.0;

    // 🎯 MARKETPLACES ESPECIAIS: Shopee, MercadoLivre
    // Se for RECEITA → priorizar Vendas/Produtos
    // Se for DESPESA → priorizar Vestuário/outros
    final isMarketplace = descricaoLower.contains('shopee') ||
                          descricaoLower.contains('mercadolivre') ||
                          descricaoLower.contains('mercado livre');

    for (final mapping in _keywords) {
      bool match = false;

      // Verificar keyword principal
      if (descricaoLower.contains(mapping.keyword.toLowerCase())) {
        match = true;
      }

      // Verificar aliases
      if (!match) {
        for (final alias in mapping.aliases) {
          if (descricaoLower.contains(alias.toLowerCase())) {
            match = true;
            break;
          }
        }
      }

      if (match) {
        double confidenceAjustada = mapping.confidence;

        // ⭐ AJUSTE ESPECIAL PARA MARKETPLACES
        if (isMarketplace && tipo != null) {
          // Se for RECEITA e mapping for de Vendas → BOOST +0.50
          if (tipo == 'receita' && mapping.categoria == 'Vendas') {
            confidenceAjustada += 0.50;
          }
          // Se for DESPESA e mapping for de Vendas → PENALIDADE -0.30
          else if (tipo == 'despesa' && mapping.categoria == 'Vendas') {
            confidenceAjustada -= 0.30;
          }
        }

        if (confidenceAjustada > melhorConfidence) {
          melhorMatch = mapping;
          melhorConfidence = confidenceAjustada;
        }
      }
    }

    return melhorMatch;
  }

  /// 🎯 SUGERIR CATEGORIA E SUBCATEGORIA
  /// 
  /// Retorna um Map com categoria e subcategoria sugeridas
  /// Retorna null se nenhuma correspondência for encontrada
  static Map<String, String>? sugerirCategoria(String descricao) {
    final match = buscarPorDescricao(descricao);
    
    if (match == null) return null;

    return {
      'categoria': match.categoria,
      'subcategoria': match.subcategoria,
      'confidence': match.confidence.toString(),
      'keyword': match.keyword,
    };
  }

  /// 📊 BUSCAR MÚLTIPLAS CORRESPONDÊNCIAS
  /// 
  /// Retorna todas as correspondências encontradas, ordenadas por confidence
  static List<KeywordMapping> buscarTodasCorrespondencias(String descricao) {
    if (descricao.isEmpty) return [];

    final descricaoLower = descricao.toLowerCase();
    final matches = <KeywordMapping>[];

    for (final mapping in _keywords) {
      bool encontrou = false;

      // Verificar keyword principal
      if (descricaoLower.contains(mapping.keyword.toLowerCase())) {
        encontrou = true;
      }

      // Verificar aliases
      if (!encontrou) {
        for (final alias in mapping.aliases) {
          if (descricaoLower.contains(alias.toLowerCase())) {
            encontrou = true;
            break;
          }
        }
      }

      if (encontrou) {
        matches.add(mapping);
      }
    }

    // Ordenar por confidence (maior primeiro)
    matches.sort((a, b) => b.confidence.compareTo(a.confidence));

    return matches;
  }

  /// 📋 LISTAR TODAS AS KEYWORDS
  static List<KeywordMapping> getAllKeywords() {
    return List.unmodifiable(_keywords);
  }

  /// 🔢 ESTATÍSTICAS DA BASE DE KEYWORDS
  static Map<String, dynamic> getStats() {
    final categorias = <String>{};
    final subcategorias = <String>{};
    int totalAliases = 0;

    for (final mapping in _keywords) {
      categorias.add(mapping.categoria);
      subcategorias.add(mapping.subcategoria);
      totalAliases += mapping.aliases.length;
    }

    return {
      'totalKeywords': _keywords.length,
      'totalCategorias': categorias.length,
      'totalSubcategorias': subcategorias.length,
      'totalAliases': totalAliases,
      'mediaAliasesPorKeyword': (totalAliases / _keywords.length).toStringAsFixed(2),
      'confidenceMedia': (_keywords.fold<double>(0, (sum, m) => sum + m.confidence) / _keywords.length).toStringAsFixed(2),
    };
  }

  /// 🏷️ LISTAR KEYWORDS POR CATEGORIA
  static List<KeywordMapping> getByCategoria(String categoria) {
    return _keywords.where((m) => m.categoria == categoria).toList();
  }

  /// 🎯 LISTAR KEYWORDS POR SUBCATEGORIA
  static List<KeywordMapping> getBySubcategoria(String subcategoria) {
    return _keywords.where((m) => m.subcategoria == subcategoria).toList();
  }

  /// 🔍 BUSCAR KEYWORDS COM CONFIDENCE MÍNIMA
  static List<KeywordMapping> getByMinConfidence(double minConfidence) {
    return _keywords.where((m) => m.confidence >= minConfidence).toList();
  }

  /// 🌟 TOP KEYWORDS (maiores confidence)
  static List<KeywordMapping> getTopKeywords({int limit = 10}) {
    final sorted = List<KeywordMapping>.from(_keywords);
    sorted.sort((a, b) => b.confidence.compareTo(a.confidence));
    return sorted.take(limit).toList();
  }

  /// 🔤 VALIDAR SE DESCRIÇÃO TEM MATCH
  static bool temMatch(String descricao) {
    return buscarPorDescricao(descricao) != null;
  }

  /// 📊 ANÁLISE DE DESCRIÇÃO (debug/desenvolvimento)
  static Map<String, dynamic> analisarDescricao(String descricao) {
    final match = buscarPorDescricao(descricao);
    final todasCorrespondencias = buscarTodasCorrespondencias(descricao);

    return {
      'descricao': descricao,
      'temMatch': match != null,
      'melhorMatch': match != null ? {
        'keyword': match.keyword,
        'categoria': match.categoria,
        'subcategoria': match.subcategoria,
        'confidence': match.confidence,
      } : null,
      'totalCorrespondencias': todasCorrespondencias.length,
      'outrasCorrespondencias': todasCorrespondencias.skip(1).take(3).map((m) => {
        'keyword': m.keyword,
        'categoria': m.categoria,
        'confidence': m.confidence,
      }).toList(),
    };
  }
}

/// 🧪 EXEMPLOS DE USO
/// 
/// ```dart
/// // 1. Buscar categoria automaticamente
/// final sugestao = CategoriaKeywordsService.sugerirCategoria('Compra Carrefour');
/// print(sugestao); 
/// // {categoria: 'Alimentação', subcategoria: 'Supermercado', confidence: '0.95', keyword: 'carrefour'}
/// 
/// // 2. Verificar se tem match
/// final temMatch = CategoriaKeywordsService.temMatch('uber');
/// print(temMatch); // true
/// 
/// // 3. Análise detalhada
/// final analise = CategoriaKeywordsService.analisarDescricao('ifood delivery');
/// print(analise);
/// 
/// // 4. Estatísticas
/// final stats = CategoriaKeywordsService.getStats();
/// print(stats); // {totalKeywords: 300+, totalCategorias: 13, ...}
/// 
/// // 5. Buscar keywords de uma categoria específica
/// final alimentacao = CategoriaKeywordsService.getByCategoria('Alimentação');
/// print('Total de keywords em Alimentação: ${alimentacao.length}');
/// ```