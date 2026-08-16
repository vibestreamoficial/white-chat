#!/usr/bin/env bash
# Gera o APK debug e o APK release assinado do WHITE CHAT.
# Uso: bash scripts/build_apk.sh
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> Verificando Flutter..."
if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter nao encontrado. Instale com:"
  echo "  git clone https://github.com/flutter/flutter.git -b stable ~/flutter"
  echo "  export PATH=\"\$PATH:\$HOME/flutter/bin\""
  exit 1
fi

if [ ! -f android/app/google-services.json ]; then
  echo "!! Sem google-services.json: o APK sai em MODO DEMONSTRACAO"
  echo "   (abre com a tela de configuracao do Firebase). Para o app"
  echo "   completo, crie o projeto Firebase e baixe o arquivo."
fi

echo "==> flutter pub get"
flutter pub get

echo "==> APK debug"
flutter build apk --debug

echo "==> APK release assinado"
flutter build apk --release

echo
echo "APKs gerados:"
ls -lh build/app/outputs/flutter-apk/*.apk
echo
echo "Instalar no celular:"
echo "  adb install build/app/outputs/flutter-apk/app-release.apk"
