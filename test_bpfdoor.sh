#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$SCRIPT_DIR:$PATH"

# 로그 파일 및 시스템 정보 설정
HOSTNAME=$(hostname)
OS_VERSION=$(grep '^NAME' /etc/os-release | cut -d= -f2 | tr -d '"')
LOG_FILE="${HOSTNAME}_${OS_VERSION}_$(date +%Y%m%d%H%M%S)_bpfscan.txt"

# 공통 설정 및 모듈 로딩
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/modules/env_check.sh"
source "$SCRIPT_DIR/modules/hash_check.sh"
source "$SCRIPT_DIR/modules/proc_check.sh"
source "$SCRIPT_DIR/modules/net_check.sh"

# 공통 로그 함수 정의
gen_log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
    echo "[$(date +'%Y%m%d%H%M%S')] $1" >> "$LOG_FILE"
}

# 실행
gen_log "========== 검사 시작 =========="
check_bpfdoor_env_vars
check_files_by_hash
check_suspicious_processes_and_files
check_network_sockets
gen_log "========== 검사 완료 =========="

# 결과 판별
if grep -q "WARN" "$LOG_FILE" || grep -q "CRITICAL" "$LOG_FILE"; then
    gen_log "검사결과: 취약"
else
    gen_log "검사결과: 양호"
fi

# 결과 복사 및 저장
RESULT_FILE="${HOSTNAME}_${OS_VERSION}_$(date +%Y%m%d%H%M%S)_bpfscan.txt"
cat "$LOG_FILE" >> "$RESULT_FILE"
sync
exit 0
