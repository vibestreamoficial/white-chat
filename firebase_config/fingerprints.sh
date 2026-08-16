#!/usr/bin/env bash
# ============================================================
# IMPRESSOES DIGITAIS (SHA-1 / SHA-256) PARA O FIREBASE
# ------------------------------------------------------------
# Cadastre as 4 impressoes abaixo no Firebase Console:
#   Project Settings -> Seu app Android -> Adicionar impressao digital
# Isso corrige o erro 10 do Google Sign-In.
# ============================================================
set -e
cd "$(dirname "$0")/.."

echo "== DEBUG (signing do debug) =="
if [ -f "$HOME/.android/debug.keystore" ]; then
  keytool -list -v -keystore "$HOME/.android/debug.keystore" \
    -alias androiddebugkey -storepass android 2>/dev/null \
    | grep -E "SHA1|SHA256" | sed 's/^ *//'
else
  echo "debug.keystore nao encontrado em ~/.android/"
fi

echo ""
echo "== RELEASE (whitechat-release.jks) =="
if [ -f whitechat-release.jks ]; then
  keytool -list -v -keystore whitechat-release.jks \
    -alias whitechat -storepass whitechat123 2>/dev/null \
    | grep -E "SHA1|SHA256" | sed 's/^ *//'
else
  echo "whitechat-release.jks nao encontrado."
fi
