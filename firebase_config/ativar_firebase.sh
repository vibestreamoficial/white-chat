#!/usr/bin/env bash
# ============================================================
# ATIVAR FIREBASE - WHITE CHAT
# ------------------------------------------------------------
# 1) Baixe o google-services.json do Firebase Console
#    (app Android com pacote com.whitechat.app)
# 2) Coloque o arquivo nesta pasta:  firebase_config/google-services.json
# 3) Rode:  bash firebase_config/ativar_firebase.sh
#
# O script copia o arquivo para android/app/, gera as chaves reais em
# lib/firebase_options.dart (sem placeholder) e recompila o APK.
# ============================================================
set -e
cd "$(dirname "$0")/.."

if [ ! -f firebase_config/google-services.json ]; then
  echo "❌ Coloque o arquivo google-services.json dentro de firebase_config/ primeiro."
  exit 1
fi

echo "1) Copiando google-services.json -> android/app/ ..."
python3 scripts/configurar_firebase.py firebase_config/google-services.json

echo "2) Firebase configurado (chaves reais em lib/firebase_options.dart)."

if command -v flutter >/dev/null 2>&1; then
  echo "3) Recompilando o APK (isso demora alguns minutos)..."
  flutter pub get
  flutter build apk --release
  echo ""
  echo "✅ APK pronto: build/app/outputs/flutter-apk/app-release.apk"
else
  echo ""
  echo "⚠️  Flutter nao encontrado nesta maquina."
  echo "    Recompile com: flutter build apk --release"
fi
