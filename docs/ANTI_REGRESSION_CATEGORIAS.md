# 🛡️ GUIA ANTI-REGRESSÃO: Filtros de Categoria

## 📋 RESUMO EXECUTIVO

Este documento estabelece **regras definitivas** para prevenir a reincidência de bugs relacionados a:

1. **Filtros indevidos** de categorias com valor zero
2. **Tree shaking** de ícones no iOS que causa falha na build
3. **Perda de informação valiosa** para tomada de decisão do usuário

## 🚨 REGRAS CRÍTICAS (NUNCA VIOLAR)

### ✅ REGRA #1: Categorias Zeradas Sempre Visíveis

```dart
// ✅ CORRETO: Mostrar todas as categorias ativas
List<CategoriaModel> _filtrarCategorias(List<CategoriaModel> categorias) {
  return categorias.where((categoria) => categoria.ativo).toList();
}

// ❌ PROIBIDO: Filtrar por valor > 0
List<CategoriaModel> _filtrarCategorias(List<CategoriaModel> categorias) {
  return categorias.where((categoria) =>
    categoria.ativo &&
    (valores[categoria.id] ?? 0.0) > 0.0  // ❌ NUNCA FAZER ISSO!
  ).toList();
}
```

### ✅ REGRA #2: Ícones Tree-Shake Safe

```dart
// ✅ CORRETO: Ícone fixo para categorias zeradas
Widget buildCategoriaIcon(CategoriaModel categoria, bool isZero) {
  if (isZero) {
    return Icon(Icons.remove_circle_outline); // Ícone fixo pré-registrado
  }
  return Icon(CategoriaIcons.getIconFromName(categoria.icone));
}

// ❌ PROIBIDO: Ícones dinâmicos
Widget buildCategoriaIcon(CategoriaModel categoria, double valor) {
  return Icon(valor > 0 ? Icons.check : Icons.warning); // ❌ Tree shaking!
}
```

### ✅ REGRA #3: Indicadores Visuais para Zeradas

```dart
// ✅ CORRETO: Diferenciação visual sem remoção
Container(
  color: isZero ? Colors.grey.withOpacity(0.05) : Colors.white,
  child: ListTile(
    leading: Container(
      decoration: BoxDecoration(
        color: isZero ? corCategoria.withOpacity(0.4) : corCategoria,
      ),
      child: Icon(
        isZero ? Icons.remove_circle_outline : getIconNormal(),
      ),
    ),
    title: Row(
      children: [
        Text(categoria.nome),
        if (isZero) Icon(Icons.info_outline), // Indicador
      ],
    ),
    subtitle: Text(
      isZero ? 'Sem movimento no período' : '${porcentagem}%',
    ),
  ),
)
```

## 🔧 IMPLEMENTAÇÃO OBRIGATÓRIA

### 1. Pré-carregamento de Ícones (main.dart)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ OBRIGATÓRIO para evitar tree shaking no iOS
  CategoriaIcons.preloadAllIcons();

  runApp(MyApp());
}
```

### 2. Validação Anti-Regressão

```dart
List<CategoriaModel> _filtrarCategorias(List<CategoriaModel> categorias) {
  final resultado = categorias.where((c) => c.ativo).toList();

  // ✅ OBRIGATÓRIO: Validação anti-regressão
  BusinessValidators.validateCategoriasNaoFiltradasPorValor(
    categorias,
    resultado,
    'NomeDoMetodo._filtrarCategorias'
  );

  return resultado;
}
```

### 3. Comentários Obrigatórios

```dart
/// Filtrar categorias por pesquisa
/// 🚨 REGRA ANTI-REGRESSÃO: NUNCA filtrar categorias por valor zero!
/// Categorias sem movimento são informação valiosa para o usuário.
List<CategoriaModel> _filtrarCategorias(List<CategoriaModel> categorias) {
  // NUNCA FAÇA: .where((c) => valor > 0.0)
  // ...
}
```

## 📊 CENÁRIOS COBERTOS

### ✅ Cenário 1: Categoria Zerada Individual
- **Situação**: Usuário não gastou com "Transporte" no mês
- **Resultado**: Categoria aparece com "R$ 0,00" e indicador visual
- **Benefício**: Usuário reflete sobre não usar a categoria

### ✅ Cenário 2: Todas Zeradas
- **Situação**: Usuário não teve movimento em nenhuma categoria
- **Resultado**: Todas aparecem com indicação "Sem movimento"
- **Benefício**: Usuário entende que não categorizou transações

### ✅ Cenário 3: Build iOS
- **Situação**: Flutter build iOS com ícones dinâmicos
- **Resultado**: Build completa sem erro "cannot tree shake fonts"
- **Benefício**: App funciona em produção iOS

## 🧪 TESTES OBRIGATÓRIOS

### 1. Teste Anti-Regressão Básico

```dart
test('Categorias zeradas devem aparecer na lista', () {
  final categorias = [
    CategoriaModel(nome: 'Alimentação', valor: 100.0),
    CategoriaModel(nome: 'Transporte', valor: 0.0),  // ← ZERO!
  ];

  final resultado = filtrarCategorias(categorias);

  expect(resultado.length, equals(2)); // Ambas devem aparecer
  expect(resultado.any((c) => c.nome == 'Transporte'), true);
});
```

### 2. Teste Tree Shaking

```dart
test('Ícones devem estar pré-registrados', () {
  expect(() => CategoriaIcons.preloadAllIcons(), returnsNormally);
  expect(() => CategoriaIcons.getIconFromName('remove_circle_outline'),
    returnsNormally);
});
```

### 3. Teste de Validação

```dart
test('Validação deve detectar filtro incorreto', () {
  final original = [categoria1, categoria2, categoria3];
  final filtrado = [categoria1]; // Removeu 2 incorretamente

  expect(() => BusinessValidators.validateCategoriasNaoFiltradasPorValor(
    original, filtrado, 'TEST'
  ), throwsA(anything));
});
```

## 🔍 CHECKLIST PARA CODE REVIEW

- [ ] Método de filtro **NÃO** usa `.where(valor > 0)`
- [ ] Categorias zeradas têm **indicadores visuais** diferentes
- [ ] Ícones são **pré-registrados** em CategoriaIcons
- [ ] **Comentários anti-regressão** presentes
- [ ] **Validação automática** implementada
- [ ] **Testes** cobrem cenários zerados

## 🚀 SCRIPTS DE VALIDAÇÃO

### Executar Validação Completa

```bash
# Verificar padrões perigosos
./scripts/validate_categoria_patterns.sh

# Executar testes anti-regressão
flutter test test/anti_regression/categorias_filtro_test.dart

# Testar build iOS (se possível)
flutter build ios --release
```

### CI/CD Pipeline

```yaml
# .github/workflows/anti_regression.yml
name: Anti-Regressão Categorias

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2

      - name: Validar padrões de categoria
        run: ./scripts/validate_categoria_patterns.sh

      - name: Executar testes anti-regressão
        run: flutter test test/anti_regression/
```

## 🎯 MÉTRICAS DE SUCESSO

### ✅ Indicadores de Implementação Correta
- **0 erros** no script de validação
- **100% cobertura** dos testes anti-regressão
- **Build iOS** completa sem tree shaking errors
- **Usuários relatam** ver categorias zeradas úteis

### 🚨 Sinais de Regressão
- Usuários reclamam de **categorias "sumiram"**
- **Builds iOS falham** com tree shaking
- **Script de validação** reporta erros críticos
- **Testes anti-regressão** falham

## 📞 CONTATO E SUPORTE

### Em caso de dúvidas:
1. **Revise este documento** completamente
2. **Execute os scripts** de validação
3. **Consulte os testes** de exemplo
4. **Verifique implementação** atual no código

### Em caso de regressão:
1. **Execute imediatamente**: `./scripts/validate_categoria_patterns.sh`
2. **Identifique o commit** que quebrou
3. **Revise as regras** deste documento
4. **Implemente correção** seguindo os padrões
5. **Valide com testes** anti-regressão

---

## 🏆 CONCLUSÃO

A implementação correta deste guia **garante**:

✅ **Categorias zeradas sempre visíveis** = Melhor UX e insights
✅ **Builds iOS estáveis** = Deploy sem problemas
✅ **Detecção automática** de regressões = Qualidade garantida
✅ **Padrões documentados** = Team alinhado

**Esta solução é definitiva e à prova de regressão.**