#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Configura o Firebase do WHITE CHAT a partir do google-services.json.

Uso:
    python3 scripts/configurar_firebase.py /caminho/para/google-services.json

O que ele faz:
  1. Copia o arquivo para android/app/google-services.json
  2. Gera lib/firebase_options.dart com as chaves reais
  3. Preenche o default_web_client_id (Google Sign-In) em strings.xml
  4. Mostra um resumo do que esta configurado
"""
import json
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

def main():
    if len(sys.argv) < 2:
        print("Uso: python3 scripts/configurar_firebase.py <google-services.json>")
        sys.exit(1)

    src = Path(sys.argv[1])
    data = json.loads(src.read_text(encoding="utf-8"))

    client = next(c for c in data["client"] if "android_client_info" in c)
    api_key = next(k["current_key"] for k in client["api_key"])
    app_id = client["client_info"]["mobilesdk_app_id"]
    project_id = data["project_info"]["project_id"]
    storage = data["project_info"]["storage_bucket"]
    sender = data["project_info"]["project_number"]

    # Web client ID usado no Google Sign-In (client_type 3)
    web_client = None
    for c in data["client"]:
        for o in c.get("oauth_client", []):
            if o.get("client_type") == 3 and o.get("client_id"):
                web_client = o["client_id"]
                break
        if web_client:
            break

    db_url = f"https://{project_id}-default-rtdb.firebaseio.com"

    # 1) google-services.json
    dest = ROOT / "android" / "app" / "google-services.json"
    shutil.copyfile(src, dest)
    print("1. google-services.json ->", dest)

    # 2) firebase_options.dart
    opts = ROOT / "lib" / "firebase_options.dart"
    content = f"""import 'package:firebase_core/firebase_core.dart';

// Gerado por scripts/configurar_firebase.py (nao edite manualmente).
class DefaultFirebaseOptions {{
  DefaultFirebaseOptions._();

  static const FirebaseOptions initial = FirebaseOptions(
    apiKey: '{api_key}',
    appId: '{app_id}',
    messagingSenderId: '{sender}',
    projectId: '{project_id}',
    storageBucket: '{storage}',
    databaseURL: '{db_url}',
  );
}}
"""
    opts.write_text(content, encoding="utf-8")
    print("2. lib/firebase_options.dart atualizado")

    # 3) strings.xml (default_web_client_id)
    strings = ROOT / "android" / "app" / "src" / "main" / "res" / "values" / "strings.xml"
    if web_client:
        text = strings.read_text(encoding="utf-8")
        text = text.replace("SEU_WEB_CLIENT_ID", web_client)
        strings.write_text(text, encoding="utf-8")
        print("3. default_web_client_id definido:", web_client)
    else:
        print("3. AVISO: nenhum OAuth web client encontrado no google-services.json.")

    print("\n=== RESUMO ===")
    print("projectId   :", project_id)
    print("appId       :", app_id)
    print("apiKey      :", api_key)
    print("senderId    :", sender)
    print("databaseURL :", db_url)
    print("storageBucket:", storage)

if __name__ == "__main__":
    main()
