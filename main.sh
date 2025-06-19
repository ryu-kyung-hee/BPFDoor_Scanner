#!/bin/bash

RED='\033[0;31m' #WARN
YELLOW='\033[1;33m' #SUSPECT
NC='\033[0m' #default
BLUE='\033[0;34m' #??
GREEN='\033[0;32m' #GOOD


# 경로 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$SCRIPT_DIR:$PATH"

# 시스템 정보
HOSTNAME=$(hostname)
OS_VERSION=$(grep '^NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
LOG_FILE="${HOSTNAME}_${OS_VERSION}_$(date +%Y%m%d%H%M%S)_bpfscan.log"

# 점검 모듈 로딩
source "$SCRIPT_DIR/modules/env_check.sh"
source "$SCRIPT_DIR/modules/c2_check.sh"
source "$SCRIPT_DIR/modules/preload_check.sh"
source "$SCRIPT_DIR/modules/hash_check.sh"
source "$SCRIPT_DIR/modules/proc_check.sh"
source "$SCRIPT_DIR/modules/net_check.sh"
source "$SCRIPT_DIR/modules/masq_check.sh"

# 로그 출력 함수
gen_log() {
    local timestamp="[$(date +'%Y-%m-%d %H:%M:%S')]"
    echo -e "${timestamp} $1"
    # 로그 값 앞: ${색상}, 마지막: ${NC} 시 색상 코드 없이 출력
    echo -e "${timestamp} $(echo "$1" | sed 's/\x1B\[[0-9;]*[mK]//g')" >> "$LOG_FILE"
}

# 점검 항목별 실행 플래그
run_env=false
run_c2=false
run_preload=false
run_hash=false
run_proc=false
run_net=false
run_masq=false


# 인자 없이 실행 → 전체 점검
if [ $# -eq 0 ]; then
    run_env=true
    run_c2=true
    run_preload=true
    run_hash=true
    run_proc=true
    run_net=true
    run_masq=true
else
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --env) run_env=true ;;
            --ip) run_c2=true ;;
            --preload) run_preload=true ;;
            --hash) run_hash=true ;;
            --proc) run_proc=true ;;
            --net) run_net=true ;;
	    --masq) run_masq=true ;;
            --help|-h)
                echo "사용법: $0 [옵션]"
                echo "  --env      환경 변수 점검"
                echo "  --ip       공격자 IP 점검"
		echo "  --preload  LD_PRELOAD 값 점검"
                echo "  --hash     악성 해시 점검"
                echo "  --proc     의심 프로세스 점검"
                echo "  --net      네트워크 연결/소켓 점검"
		echo "  --masq     프로세스 위장 점검"
                echo "  (옵션 없으면 전체 점검 수행)"
                exit 0
                ;; 
            *)
                echo "알 수 없는 옵션: $1"
                echo "도움말: $0 --help"
                exit 1
                ;;
        esac
        shift
    done
fi


# 실행
gen_log "========== 스캔 시작 =========="

$run_env && { gen_log "[*] 환경 변수 점검 시작"; check_bpfdoor_env_vars; }
$run_c2 && { gen_log "[*] 공격자 IP 점검 시작"; check_c2_ip_connection; }
$run_preload && { gen_log "[*] LD_PRELOAD 점검 시작"; check_ld_preload; }
$run_hash && { gen_log "[*] 파일 해시 점검 시작"; check_files_by_hash; }
$run_proc && { gen_log "[*] 의심 프로세스 점검 시작"; check_suspicious_processes_and_files; }
$run_net && { gen_log "[*] 네트워크 점검 시작"; check_network_sockets; }
$run_masq && { gen_log "[*] 위장 프로세스 점검 시작"; check_process_masquerading; }


gen_log "========== 스캔 완료 =========="

# 결과 요약
if grep -qE "WARN|CRITICAL" "$LOG_FILE"; then
    gen_log "${RED}검사결과: 취약 항목 발견${NC}"
else
    gen_log "${GREEN}검사결과: 이상 없음${NC}"
fi


sync
exit 0
