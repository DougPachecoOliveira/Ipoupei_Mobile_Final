#!/bin/bash

# 🔍 SCRIPT DE VALIDAÇÃO: Padrões de Categoria Anti-Regressão
#
# Este script detecta padrões perigosos no código que podem causar:
# 1. Filtros indevidos de categorias com valor zero
# 2. Problemas de tree shaking com ícones dinâmicos
# 3. Violações das regras UX estabelecidas
#
# USO:
#   ./scripts/validate_categoria_patterns.sh
#   (rodar no pre-commit ou CI/CD)

set -e

echo "🔍 Validando padrões de categoria anti-regressão..."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Contadores
ERRORS=0
WARNINGS=0

# Função para reportar erro
report_error() {
    echo -e "${RED}❌ ERRO:${NC} $1"
    ((ERRORS++))
}

# Função para reportar warning
report_warning() {
    echo -e "${YELLOW}⚠️ WARNING:${NC} $1"
    ((WARNINGS++))
}

# Função para reportar sucesso
report_success() {
    echo -e "${GREEN}✅${NC} $1"
}

echo ""
echo "📋 VERIFICANDO PADRÕES PERIGOSOS..."

# ===============================================
# 1. DETECTAR FILTROS POR VALOR ZERO
# ===============================================

echo ""
echo "🔍 1. Verificando filtros por valor zero..."

# Padrões perigosos que podem filtrar categorias zeradas
DANGEROUS_VALUE_PATTERNS=(
    "\.where.*valor.*>\s*0"
    "\.where.*total.*>\s*0"
    "\.filter.*valor.*>\s*0"
    "valor\s*>\s*0\.0"
    "total_valor.*>\s*0"
    "item\['valor'\].*>\s*0"
    "item\['total_valor'\].*>\s*0"
)

for pattern in "${DANGEROUS_VALUE_PATTERNS[@]}"; do
    echo "  Procurando padrão: $pattern"

    # Buscar em arquivos Dart exceto testes e comentários
    matches=""
    while IFS= read -r file; do
        # Filtrar apenas linhas que NÃO são comentários
        dangerous_lines=$(grep -E "$pattern" "$file" 2>/dev/null | grep -v "^\s*//" | grep -v "// REMOVIDO" | grep -v "// NUNCA FAÇA" || true)
        if [ -n "$dangerous_lines" ]; then
            matches="$matches$file\n"
        fi
    done < <(find lib -name "*.dart" -not -path "*/test/*" 2>/dev/null)

    if [ -n "$matches" ]; then
        report_error "Padrão perigoso '$pattern' encontrado em:"
        echo -e "$matches" | while read -r file; do
            if [ -n "$file" ]; then
                echo "    📁 $file"
                grep -n -E "$pattern" "$file" 2>/dev/null | grep -v "^\s*//" | grep -v "// REMOVIDO" | grep -v "// NUNCA FAÇA" | head -3 | while IFS= read -r line; do
                    echo "      📄 $line"
                done
            fi
        done
        echo ""
    fi
done

# ===============================================
# 2. VERIFICAR ÍCONES DINÂMICOS (TREE SHAKING)
# ===============================================

echo ""
echo "🔍 2. Verificando ícones dinâmicos perigosos..."

# Padrões de ícones que podem causar tree shaking
DANGEROUS_ICON_PATTERNS=(
    "Icons\.\$"
    "Icons\.\w+.*\?"
    "IconData\(.*\?"
    "icon.*\?.*:"
    "getIcon.*\?"
)

for pattern in "${DANGEROUS_ICON_PATTERNS[@]}"; do
    echo "  Procurando padrão: $pattern"

    matches=$(find lib -name "*.dart" -not -path "*/test/*" -exec grep -l -E "$pattern" {} \; 2>/dev/null || true)

    if [ -n "$matches" ]; then
        report_warning "Possível ícone dinâmico '$pattern' em:"
        echo "$matches" | while read -r file; do
            echo "    📁 $file"
            grep -n -E "$pattern" "$file" 2>/dev/null | head -2 | while IFS= read -r line; do
                echo "      📄 $line"
            done
        done
        echo ""
    fi
done

# ===============================================
# 3. VERIFICAR USO CORRETO DE CategoriaIcons
# ===============================================

echo ""
echo "🔍 3. Verificando uso correto de CategoriaIcons..."

# Verificar se CategoriaIcons.preloadAllIcons() é chamado no main()
if ! grep -q "CategoriaIcons.preloadAllIcons()" lib/main.dart 2>/dev/null; then
    report_error "CategoriaIcons.preloadAllIcons() não encontrado em lib/main.dart"
    echo "    💡 Adicione no método main() para evitar tree shaking no iOS"
else
    report_success "CategoriaIcons.preloadAllIcons() encontrado em main.dart"
fi

# Verificar import do BusinessValidators
validators_imported=$(find lib -name "*.dart" -exec grep -l "business_validators.dart" {} \; 2>/dev/null | wc -l)
if [ "$validators_imported" -eq 0 ]; then
    report_warning "BusinessValidators não está sendo importado em nenhum arquivo"
    echo "    💡 Considere usar validações anti-regressão em filtros críticos"
fi

# ===============================================
# 4. VERIFICAR COMENTÁRIOS ANTI-REGRESSÃO
# ===============================================

echo ""
echo "🔍 4. Verificando comentários anti-regressão..."

# Verificar se há comentários explicativos em métodos de filtro
filtro_methods=$(find lib -name "*.dart" -exec grep -l "_filtrar.*Categoria" {} \; 2>/dev/null || true)

if [ -n "$filtro_methods" ]; then
    for file in $filtro_methods; do
        echo "  Verificando comentários em: $file"

        # Verificar se tem comentário sobre não filtrar por valor zero
        if ! grep -B5 -A5 "_filtrar.*Categoria" "$file" | grep -q -i "zero\|valor.*0\|anti.*regress" 2>/dev/null; then
            report_warning "Método de filtro em $file sem comentário anti-regressão"
            echo "    💡 Adicione comentário explicando que não deve filtrar por valor zero"
        else
            report_success "Comentário anti-regressão encontrado em $file"
        fi
    done
else
    echo "  Nenhum método de filtro encontrado"
fi

# ===============================================
# 5. VERIFICAR ESTRUTURA DE TESTES
# ===============================================

echo ""
echo "🔍 5. Verificando testes anti-regressão..."

if [ ! -f "test/anti_regression/categorias_filtro_test.dart" ]; then
    report_error "Arquivo de teste anti-regressão não encontrado: test/anti_regression/categorias_filtro_test.dart"
else
    report_success "Arquivo de teste anti-regressão encontrado"

    # Verificar se os testes cobrem cenários críticos
    test_file="test/anti_regression/categorias_filtro_test.dart"

    critical_tests=(
        "valor zero"
        "tree shaking"
        "filtro incorreto"
        "categoria.*zerada"
    )

    for test_pattern in "${critical_tests[@]}"; do
        if grep -q -i "$test_pattern" "$test_file" 2>/dev/null; then
            report_success "Teste para '$test_pattern' encontrado"
        else
            report_warning "Teste para '$test_pattern' não encontrado"
        fi
    done
fi

# ===============================================
# 6. VERIFICAR PROBLEMAS DE SQL/QUERY
# ===============================================

echo ""
echo "🔍 6. Verificando queries SQL perigosas..."

# Procurar por queries que filtram por valor > 0
sql_files=$(find lib -name "*.dart" -exec grep -l "rawQuery\|SELECT.*FROM" {} \; 2>/dev/null || true)

if [ -n "$sql_files" ]; then
    for file in $sql_files; do
        echo "  Verificando SQL em: $file"

        # Verificar se há WHERE valor > 0 ou similar
        dangerous_sql=$(grep -n -i "WHERE.*valor.*>\|WHERE.*total.*>" "$file" 2>/dev/null || true)
        if [ -n "$dangerous_sql" ]; then
            report_warning "Query SQL possivelmente filtrando valores > 0 em $file:"
            echo "$dangerous_sql" | while IFS= read -r line; do
                echo "      📄 $line"
            done
            echo "    💡 Verifique se não está filtrando categorias zeradas incorretamente"
        fi
    done
fi

# ===============================================
# 7. RELATÓRIO FINAL
# ===============================================

echo ""
echo "==============================================="
echo "📊 RELATÓRIO FINAL DA VALIDAÇÃO"
echo "==============================================="

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}🎉 PERFEITO: Nenhum problema encontrado!${NC}"
    echo ""
    echo "✅ Filtros de categoria seguem padrões corretos"
    echo "✅ Ícones são tree-shake safe"
    echo "✅ Comentários anti-regressão presentes"
    echo "✅ Testes de proteção implementados"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️ WARNINGS: $WARNINGS problemas menores encontrados${NC}"
    echo ""
    echo "Os problemas encontrados são warnings que devem ser revisados"
    echo "mas não impedem o funcionamento da aplicação."
    exit 0
else
    echo -e "${RED}❌ ERROS CRÍTICOS: $ERRORS problemas encontrados${NC}"
    echo -e "${YELLOW}⚠️ Warnings: $WARNINGS${NC}"
    echo ""
    echo "AÇÃO NECESSÁRIA:"
    echo "1. Corrija os erros críticos listados acima"
    echo "2. Revise os warnings para melhorar a qualidade"
    echo "3. Execute os testes anti-regressão: flutter test test/anti_regression/"
    echo "4. Execute build iOS para verificar tree shaking: flutter build ios"
    exit 1
fi