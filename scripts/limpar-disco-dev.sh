#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Limpa caches de desenvolvimento do iPoupei que se REGENERAM sozinhos.
# 100% seguro: nunca apaga código, Archives (releases) nem o build/ (APK/IPA).
#
# Uso:  bash scripts/limpar-disco-dev.sh
#
# O que volta quando:
#   iOS DeviceSupport   → conectar um iPhone (1 vez)
#   Xcode DerivedData   → próximo build no Xcode
#   Gradle caches       → próximo build Android
#   CocoaPods (ios/Pods)→ pod install (o flutter build faz sozinho)
#   .dart_tool          → flutter pub get (o flutter build faz sozinho)
# ─────────────────────────────────────────────────────────────────────────────
set -uo pipefail

PROJETO="$(cd "$(dirname "$0")/.." && pwd)"

echo "── Espaço ANTES ──"
df -h / | awk 'NR==1 || NR==2'
echo

echo "→ iOS DeviceSupport  (Xcode rebaixa ao conectar um iPhone — 1x)"
rm -rf ~/Library/Developer/Xcode/"iOS DeviceSupport"/* 2>/dev/null || true

echo "→ Xcode DerivedData  (reconstrói no próximo build)"
rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null || true

echo "→ Gradle caches      (re-baixa no próximo build Android)"
rm -rf ~/.gradle/caches/* 2>/dev/null || true

echo "→ Simuladores indisponíveis (versões antigas de iOS)"
xcrun simctl delete unavailable 2>/dev/null || true

echo "→ [projeto] ios/Pods + .symlinks  (pod install refaz no próximo build)"
rm -rf "$PROJETO/ios/Pods" "$PROJETO/ios/.symlinks" 2>/dev/null || true

echo "→ [projeto] .dart_tool  (flutter pub get refaz no próximo build)"
rm -rf "$PROJETO/.dart_tool" 2>/dev/null || true

echo "→ [projeto] android/.gradle  (cache local do Gradle)"
rm -rf "$PROJETO/android/.gradle" 2>/dev/null || true

echo "→ [projeto] arquivos-lixo duplicados (.flutter-plugins-dependencies 2, 3...)"
find "$PROJETO" -maxdepth 1 -name ".flutter-plugins-dependencies *" -delete 2>/dev/null || true

echo
echo "── Espaço DEPOIS ──"
df -h / | awk 'NR==2'
echo
echo "OK. NÃO foram tocados: código, Archives, nem o build/ (APK/IPA/xcarchive)."
echo "Se precisar de MAIS espaço:"
echo "  • flutter clean   → libera o build/ (APAGA o APK/IPA local — copie antes)"
echo "  • Xcode → Organizer → apagar Archives antigos à mão (você escolhe)"
