#!/bin/bash

# ==============================================================================
# [Vault Certificate Seeding Script]
# - 목적: 로컬의 인증서 파일을 Vault KV 엔진에 업로드
# - 소스 경로: ./certs/vault.crt, ./certs/vault.key (site.yml 실행 결과)
# - 타겟 경로: secret/data/certs/wildcard-infra
# - 키 이름: 'cert' (Fullchain), 'key' (Private Key)
# ==============================================================================

# Vault 설정 (환경에 맞게 수정)
export VAULT_ADDR="https://vlt.infra.lan:8200"
# export VAULT_SKIP_VERIFY=true # 필요 시 주석 해제

# 인증서 파일 경로 확인
CERT_FILE="./certs/vault.crt"
KEY_FILE="./certs/vault.key"

if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
  echo "❌ 오류: 인증서 파일을 찾을 수 없습니다."
  echo "   경로 확인: $CERT_FILE, $KEY_FILE"
  echo "   Tip: site.yml을 먼저 실행하여 인증서를 생성하세요."
  exit 1
fi

echo ">>> [1/2] Vault 상태 확인..."
if ! vault status >/dev/null 2>&1; then
  echo "ERROR: Vault에 연결할 수 없습니다. VAULT_ADDR 및 토큰을 확인하세요."
  exit 1
fi

echo ">>> [2/2] 인증서 업로드 (secret/certs/wildcard-infra)..."

# 파일 내용을 변수에 담기 (개행 문자 보존 중요)
# @심볼을 사용하여 파일 내용을 직접 전송합니다.
vault kv put secret/certs/wildcard-infra \
  cert=@$CERT_FILE \
  key=@$KEY_FILE

if [ $? -eq 0 ]; then
  echo "✅ 성공: 인증서가 Vault에 저장되었습니다."
  echo "   확인: vault kv get secret/certs/wildcard-infra"
else
  echo "❌ 실패: 업로드 중 오류가 발생했습니다."
fi
