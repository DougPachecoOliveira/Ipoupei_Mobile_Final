# Raptor 3: experiência financeira

Este documento é o contrato visual e comportamental das telas principais do iPoupei.

## Confiança e sincronização

- Ações financeiras terminam quando a escrita local atômica termina.
- A interface nunca aguarda um `syncAll()` para confirmar pagamento, estorno ou reabertura.
- Offline não é erro: a mudança permanece na fila e o status mostra `Modo offline`.
- `Pagamento registrado` significa salvo localmente. Apenas o `SyncManager` pode afirmar o estado da nuvem.
- Downloads não podem sobrescrever registros com mudanças locais pendentes.
- Pagamento, estorno e reabertura passam por `FaturaOperationsService`.

## Linguagem visual

- A estrutura do app usa uma única cor de marca. Vermelho, âmbar e cores de bancos são semânticos ou acentos, nunca cores de navegação.
- Fundos e textos vêm de `ColorScheme`; branco e preto literais não entram em widgets novos.
- Cards usam raio de 20 px, contorno sutil e elevação visual baixa.
- A identidade do banco aparece no logo e em uma faixa de acento; o card inteiro não vira a cor do banco.
- Números importantes têm hierarquia forte, mas o card não mistura mais de dois níveis de informação.
- Estados vazios explicam o benefício e oferecem uma única ação principal.
- Gráficos sem dados viram orientação; nunca sobra um espaço vazio sem explicação.

## Componentes canônicos

- Tema: `lib/src/shared/theme/app_theme.dart`
- Superfície, estado vazio e progresso: `lib/src/shared/components/ui/raptor_ui.dart`
- Conta bancária: `lib/src/modules/contas/widgets/conta_card.dart`
- Resumo de contas: `lib/src/modules/contas/widgets/contas_resumo_card.dart`
- Planejamento: `lib/src/modules/planejamento/widgets/planejamento_card.dart`
- Resumo financeiro: `lib/src/modules/relatorios/widgets/resumo_financeiro_widget.dart`
- Status de nuvem: `lib/src/shared/components/ui/sync_status_indicator.dart`

## Gates obrigatórios

1. `tool/check_theme_diff.sh HEAD`
2. `flutter test --no-pub`
3. `flutter analyze --no-pub` sem erros
4. Golden tests Raptor em 320 px nos modos claro e escuro
5. Build Android e build do simulador iOS
