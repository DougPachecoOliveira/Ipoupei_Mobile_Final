import re
import sys

# Encoding fix for Windows
sys.stdout.reconfigure(encoding='utf-8')

# Valid combinations from categorias_sugeridas.dart
VALID_COMBINATIONS = {
    # DESPESAS
    ("Alimentação", "Supermercado"),
    ("Alimentação", "Restaurante"),
    ("Alimentação", "Lanche/Fast Food/Delivery"),
    ("Alimentação", "Açougue/Feira"),

    ("Transporte", "Combustível"),
    ("Transporte", "Uber/Taxi"),
    ("Transporte", "Transporte Público"),
    ("Transporte", "Manutenção Veículo"),
    ("Transporte", "Estacionamento"),
    ("Transporte", "Pedágio"),

    ("Moradia", "Aluguel"),
    ("Moradia", "Condomínio"),
    ("Moradia", "Energia Elétrica"),
    ("Moradia", "Água"),
    ("Moradia", "Internet"),
    ("Moradia", "Gás"),
    ("Moradia", "Outros"),

    ("Saúde", "Consultas Médicas/Dentista"),
    ("Saúde", "Medicamentos"),
    ("Saúde", "Exames"),
    ("Saúde", "Plano de Saúde"),
    ("Saúde", "Higiene"),

    ("Educação", "Cursos"),
    ("Educação", "Livros"),
    ("Educação", "Material Escolar"),
    ("Educação", "Mensalidade"),

    ("Lazer", "Cinema/Teatro"),
    ("Lazer", "Viagens"),
    ("Lazer", "Hobbies"),
    ("Lazer", "Streaming"),

    ("Vestuário", "Roupas"),
    ("Vestuário", "Calçados"),
    ("Vestuário", "Acessórios"),

    ("Pets", "Ração"),
    ("Pets", "Veterinário"),
    ("Pets", "Medicamentos Pet"),
    ("Pets", "Acessórios"),

    ("Bens e Patrimônio", "Eletrônicos"),
    ("Bens e Patrimônio", "Eletrodomésticos"),
    ("Bens e Patrimônio", "Móveis e Decoração"),
    ("Bens e Patrimônio", "Veículo"),
    ("Bens e Patrimônio", "Imóvel"),
    ("Bens e Patrimônio", "Ferramentas e Equipamentos"),
    ("Bens e Patrimônio", "Reformas e Materiais"),

    # RECEITAS
    ("Salário", "Salário Principal"),
    ("Salário", "Horas Extras"),
    ("Salário", "Bonificação"),
    ("Salário", "13º Salário"),

    ("Freelance", "Projetos"),
    ("Freelance", "Consultoria"),
    ("Freelance", "Serviços"),

    ("Investimentos", "Dividendos"),
    ("Investimentos", "Juros"),
    ("Investimentos", "Rendimentos CDB"),
    ("Investimentos", "Fundos"),

    ("Vendas", "Produtos"),
    ("Vendas", "Usados"),
    ("Vendas", "Artesanato"),

    ("Outros", "Presente"),
    ("Outros", "Reembolso"),
    ("Outros", "Prêmio"),
}

def extract_mappings(file_path):
    """Extract all categoria/subcategoria pairs from the file"""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Pattern to find categoria: 'X', subcategoria: 'Y'
    pattern = r"categoria:\s*['\"]([^'\"]+)['\"],?\s*subcategoria:\s*['\"]([^'\"]+)['\"]"
    mappings = re.findall(pattern, content)

    return mappings

def validate_mappings(file_path):
    """Validate all mappings in the file"""
    print("=" * 80)
    print("VALIDAÇÃO DE MAPEAMENTOS - categoria_keywords_mapping_advanced.dart")
    print("=" * 80)
    print()

    mappings = extract_mappings(file_path)

    invalid_mappings = []
    valid_count = 0

    for cat, subcat in mappings:
        if (cat, subcat) in VALID_COMBINATIONS:
            valid_count += 1
        else:
            invalid_mappings.append((cat, subcat))

    print(f"✅ Total de mapeamentos encontrados: {len(mappings)}")
    print(f"✅ Mapeamentos válidos: {valid_count}")
    print(f"❌ Mapeamentos inválidos: {len(invalid_mappings)}")
    print()

    if invalid_mappings:
        print("🔴 MAPEAMENTOS INVÁLIDOS ENCONTRADOS:")
        print("-" * 80)
        for cat, subcat in invalid_mappings:
            print(f"  ❌ categoria: '{cat}', subcategoria: '{subcat}'")
        print()
        print("CORREÇÕES NECESSÁRIAS:")
        print("-" * 80)

        # Group by category for easier fixing
        by_category = {}
        for cat, subcat in invalid_mappings:
            if cat not in by_category:
                by_category[cat] = []
            by_category[cat].append(subcat)

        for cat, subcats in by_category.items():
            # Find valid subcategories for this category
            valid_for_cat = [s for c, s in VALID_COMBINATIONS if c == cat]
            if valid_for_cat:
                print(f"\n{cat}:")
                print(f"  Subcategorias válidas: {', '.join(valid_for_cat)}")
                print(f"  Subcategorias inválidas encontradas: {', '.join(subcats)}")

        return False
    else:
        print("🎯 ✅ VALIDAÇÃO COMPLETA - 100% CORRETO")
        print()
        print("Todas as combinações categoria-subcategoria são válidas!")
        return True

if __name__ == "__main__":
    file_path = r"C:\Projetos Flutter\ipoupei_mobile\lib\src\modules\importacao\data\categoria_keywords_mapping_advanced.dart"
    validate_mappings(file_path)
