# HANDOFF MULTI-MÁQUINA — iPoupei Mobile

> **Para o Claude Code em qualquer máquina**: este arquivo é o canal de
> continuidade entre computadores. A memória persistente do Claude é local a
> cada máquina — o que viaja é ESTE arquivo, via git. Leia tudo antes de
> trabalhar e ATUALIZE o Diário (última seção) antes de encerrar cada sessão.

## Protocolo

1. **Início de sessão**: `git pull` antes de qualquer coisa. Ler este arquivo
   inteiro + o Diário no final.
2. **Fim de sessão**: tudo commitado e pushado (nunca deixar trabalho solto no
   working tree de uma máquina); acrescentar entrada no Diário dizendo o que
   foi feito, o que ficou pendente e qualquer decisão nova do Doug.
3. **Commits**: mensagem em pt-BR no padrão `tipo(escopo): resumo`. Um commit
   por lote coeso. Push só depois de ok do Doug em mudança visual/de marca
   (lição do ícone em 12/07: nada de identidade visual sem aprovação).
4. **Antes de codar, investigar** — este projeto tem código morto e histórico
   de revert; conferir se um arquivo é realmente usado antes de mexer/deletar.

## O projeto em uma dose

App Flutter de finanças pessoais (`ipoupei_mobile`, versão `1.0.0+6`).
Backend Supabase (projeto `ykifgrblmicoymavcqnu`) — URL e anon key têm
default hardcoded em `lib/src/auth_integration.dart`, então **clone → run
funciona sem nenhum segredo externo** (aceita override por
`--dart-define=SUPABASE_URL/SUPABASE_ANON_KEY`).

**Invariante central de sync (não violar)**: a fila de sync é a ÚNICA fonte
de escrita remota. UI confirma na escrita local (offline-first);
`requestSync()` consolida em background (debounced). Nenhum service escreve
direto no Supabase — `f4be690` fechou o último (transacao_service).

## Estado em 07/09/2026

- **main pushado até o handoff** — inclui a fornada de 12/07: fix saldo
  (`b383512`, cherry-pick do `ac6ddd1` que tinha se perdido em revert),
  guards de sync (`45bea5c`), splash nativa + redesign da abertura
  (`8ee87d3`/`624a422`/`bdbeb81`), ícone real da marca (`f48ab12`/`25706dd`,
  build 5→6), sync só pela fila (`f4be690`), script limpeza caches
  (`524f02c`).
- **Archive iOS gerado em 12/07, upload via Xcode Organizer PENDENTE** —
  só dá para fazer no Mac.
- **Branches no origin**: `main`, `backup/before-fatura-concept-fix`,
  `stash/raptor3-redesign` (ver abaixo).
- **Stash Raptor 3 preservado como branch remoto** `stash/raptor3-redesign`
  (redesign visual + melhoria sync, a revisar com calma). Para recuperar em
  qualquer máquina: `git fetch && git stash apply origin/stash/raptor3-redesign`
  (commit tem forma de stash; apply funciona direto). Os outros 2 stashes do
  Mac são lixo histórico e ficaram só locais.

## Avisos que economizam horas (não "consertar" sem querer)

- `flutter analyze` tem **48 erros PRÉ-EXISTENTES**, todos donos:
  `pagar_fatura_page.dart` e `fatura_detalhada_page.dart` — ninguém importa
  esses arquivos (código morto a deletar, junto com
  `transacao_service_simple`). Não são regressão sua.
- `widget_test.dart` ("iPoupei app loads") **já falhava** no commit de
  03/06. Também não é regressão sua.
- `pagamento_fatura_service` **NÃO é código morto** (usado por
  `gestao_cartoes_mobile`) — não deletar.

## Pendências (fila)

1. Upload da build 6 via Xcode Organizer (Mac; archive já gerado).
2. `conta_service`: 2 writes remotos diretos da flag `conta_principal`
   (violação leve do invariante de sync; não crítico).
3. Deletar código morto: `transacao_service_simple`, `pagar_fatura_page`,
   `fatura_detalhada_page` (leva junto os 48 erros de analyze).
4. Fases 2-3 do plano de sync: conflict resolution por `updated_at`, UTC,
   centavos inteiros, Supabase Realtime.
5. Revisar o branch `stash/raptor3-redesign` com calma (não aplicar em bloco;
   em 12/07 só a parte de sync foi resgatada dele).

## Comandos e ambiente

- Rodar: `flutter run` (Android/emulador) ou `flutter run -d chrome`.
- Setup máquina nova (Windows/Linux): git clone → Flutter estável recente
  (Dart >=3.8.1; no Mac roda com 3.35.x) → `flutter pub get`. Sem segredos
  externos. Sem Mac só não compila/envia iOS — Android e web funcionam
  integralmente.
- Release: `build_release.sh` (Mac). Ícones/splash: `flutter_launcher_icons`
  e splash nativa já configurados nos targets Android/iOS/Web.

## Diário multi-máquina (acrescentar no fim, nunca reescrever)

- **07/09 (Mac, saída para o Windows)** — Doug vai trabalhar dias num PC
  Windows; handoff criado. Pushados os 9 commits de 12/07 que aguardavam ok +
  daily log + schema subscriptions + Podfile.lock. Stash Raptor 3
  materializado em `stash/raptor3-redesign` e branch
  `backup/before-fatura-concept-fix` publicado — nada ficou preso no Mac
  exceto o upload iOS (exige Xcode). AO VOLTAR AO MAC: `git pull` + ler este
  Diário + fazer o upload da build 6 se ainda pendente.
