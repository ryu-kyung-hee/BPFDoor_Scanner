#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/parser.sh"

check_network_sockets() {
    gen_log "INFO" "네트워크 소켓 검사 시작"

    # SS 검사
    local ss_output
    ss_output=$(sudo ss -0pb 2>/dev/null | grep -E "21139|29269|0x5293|0x7255")
    echo "$ss_output" | grep "users:" | while IFS= read -r line; do
        extract_from_ss_line "$line"
    done
    [[ -z "$ss_output" ]] && gen_log "INFO" "ss 결과에서 이상 없음."

    # lsof 검사
    local lsof_output=$(sudo lsof -nP -i 2>/dev/null | grep -E "RAW|DGRAM")
    if [[ -n "$lsof_output" ]]; then
        local pids=($(echo "$lsof_output" | awk '{print $2}' | sort -u))
        extract_from_lsof_pids "${pids[@]}"
    else
        gen_log "INFO" "lsof 결과에서 RAW/DGRAM 소켓 사용 없음."
    fi

    # netstat 검사
    local netstat_output=$(sudo netstat -anp --inet 2>/dev/null | grep -E "21139|29269|0x5293|0x7255")
    echo "$netstat_output" | while IFS= read -r line; do
        extract_from_netstat_line "$line"
    done
    [[ -z "$netstat_output" ]] && gen_log "INFO" "netstat 결과에서 이상 없음."

    gen_log "INFO" "네트워크 소켓 검사 종료"
}
