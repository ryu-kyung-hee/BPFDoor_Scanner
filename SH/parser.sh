#!/bin/bash

# ss 출력 한 줄을 파싱
extract_from_ss_line() {
    local line="$1"
    local state=$(echo "$line" | awk '{print $1}')
    local laddr=$(echo "$line" | grep -oP '\d{1,3}(\.\d{1,3}){3}:\d+' | head -n1)
    local raddr=$(echo "$line" | grep -oP '\d{1,3}(\.\d{1,3}){3}:\d+' | tail -n1)
    local pid=$(echo "$line" | grep -oP 'pid=\K[0-9]+')
    local pname=$(echo "$line" | grep -oP 'users:\(\("\K[^"]+')

    if [[ -n "$pid" && -n "$pname" ]]; then
        gen_log "WARN" "  PID: $pid | 프로세스: $pname | 상태: $state | 로컬: $laddr → 원격: $raddr"
    fi
}

# lsof 출력 라인에서 pid 추출 후 프로세스명 매핑
extract_from_lsof_pids() {
    local pids=("$@")
    for pid in "${pids[@]}"; do
        local proc_info
        proc_info=$(ps -p "$pid" -o pid,comm --no-headers 2>/dev/null)
        [[ -n "$proc_info" ]] && gen_log "WARN" "  $proc_info"
    done
}

# netstat 출력 라인 파싱
extract_from_netstat_line() {
    local line="$1"
    local proto=$(echo "$line" | awk '{print $1}')
    local laddr=$(echo "$line" | awk '{print $4}')
    local raddr=$(echo "$line" | awk '{print $5}')
    local pidprog=$(echo "$line" | awk '{print $7}')
    gen_log "WARN" "  프로토콜: $proto | 로컬: $laddr → 원격: $raddr | 프로세스: ${pidprog:-unknown}"
}
