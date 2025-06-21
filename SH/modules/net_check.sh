#!/bin/bash


gen_log() {
local msg="$1"
    local color="${2:-$NC}"  # 기본색
    local timestamp="[$(date +'%Y-%m-%d %H:%M:%S')]"

    # 터미널에 컬러로 출력
    echo -e "${color}${timestamp} ${msg}${NC}"
    # 로그파일에는 ANSI 컬러 제거
    echo "${timestamp} ${msg}" >> "$LOG_FILE"
}

# netstat 기반으로 해당 PID가 열고 있는 포트 확인
network_netstat_check() {
    local pid=$1

    local found=false

    sudo netstat -nap 2>/dev/null \
    | sed -E 's/\[\s*ACC\s*\]/[ACC]/g; s/\[\s*\]/[]/g' \
    | tr -s ' ' \
    | grep -E "tcp|udp" \
    | grep "$pid/" \
    | grep -v "NetworkManager" | grep -v "dhclient" \
    | while read -r line; do

        # INFO 로그는 딱 한 번만 출력
        if [[ "$found" == false ]]; then
            gen_log "[INFO] netstat PID/PORT 확인"
            found=true
        fi

        set -- $line
        proto=$1
        recvq=$2
        sendq=$3
        laddr=$4
        raddr=$5
        sixth=$6
        seventh=$7

        if [[ "$sixth" =~ ^[0-9]+/.*$ ]]; then
            state="-"
            pid_info=$(echo "$line" | awk '{for (i=6; i<=NF; i++) printf $i " "; print ""}')
        else
            state="$sixth"
            pid_info=$(echo "$line" | awk '{for (i=7; i<=NF; i++) printf $i " "; print ""}')
        fi

        pid_field=$(echo "$pid_info" | cut -d'/' -f1 | xargs)
        pname_field=$(echo "$pid_info" | cut -d'/' -f2- | xargs)

        gen_log "$(printf "[PORT] PID=%-5s | 프로세스=%-20s | 프로토콜=%-5s | 포트=%-20s → %-20s\n" \
            "$pid_field" "$pname_field" "$proto" "$laddr" "$raddr")"
    done
}

# ss 기반 의심 프로세스 탐지
network_ss_check() {
    gen_log "[INFO] ss 기반 소켓 검사 시작"

    sudo ss -0pb | awk '
    {
        # 첫 번째 줄 처리: "NetworkManager"가 포함되면 건너뜀, 공백 줄도 건너뜀
        if ($0 ~ /NetworkManager/) next
        if ($0 ~ /^[ \t]*$/) next
        line1 = $0

        # 두 번째 줄 처리: BPF 필터가 있는 경우 두 번째 줄을 가져와서 출력
        getline
        if ($0 ~ /NetworkManager/) next
        if ($0 ~ /^[ \t]*$/) next
        line2 = $0

        print line1, line2
    }' | while read -r line; do
        # 특정 문자열이 포함된 줄만 출력
        if echo "$line" | grep -qE '21139|29269|36204|40783|0x5293|0x7255|0x39393939|0x8D6C|0x9F4F|5353|262144'; then
            laddr=$(echo "$line" | awk '{print $5}')
            raddr=$(echo "$line" | awk '{print $6}')
            pname=$(echo "$line" | grep -oP 'users:\(\("\K[^"]+')
            pid=$(echo "$line" | grep -oP 'pid=\K[0-9]+')

            pname=${pname:-N/A}
            pid=${pid:-N/A}
            laddr=${laddr:-0}
            raddr=${raddr:-0}

            gen_log "$(printf ${RED}[WARN]${NC}" ss: 의심 연결 감지 → PID=%-16s | 프로세스=%-15s " \
                "$pid" "$pname")"


#            gen_log "[WARN] ss: 의심 연결 감지 → PID=$pid | 프로세스=$pname "

            # 해당 PID의 포트 추가 확인
            network_netstat_check "$pid"
        fi
    done
}

# lsof 기반 RAW/DGRAM 소켓 탐지
network_lsof_check() {
    gen_log "[INFO] lsof 기반 RAW/DGRAM 소켓 검사 시작"

    local pids
    pids=$(sudo lsof 2>/dev/null | grep -E "SOCK_RAW|SOCK_DGRAM" | awk '{print $2}' | sort -u)

    if [[ -z "$pids" ]]; then
        gen_log "${GREEN}[INFO]${NC} RAW/DGRAM 소켓 사용하는 프로세스 없음"
        return
    fi

    for pid in $pids; do
        cmd=$(ps -p "$pid" -o comm=)
        [[ "$cmd" =~ NetworkManager|dhclient ]] && continue

        exe_path=$(readlink -f "/proc/$pid/exe")

        gen_log "$(printf ${RED}[WARN]${NC}" RAW/DGRAM 사용 프로세스 감지 → PID=%-6s | 프로세스=%-15s | 실행 경로=%-15s\n" \
                "$pid" "$cmd" "$exe_path")"


#       gen_log "[WARN] RAW/DGRAM 사용 프로세스 감지 → PID=$pid | 프로세스=$cmd | 실행 경로=$exe_path"

        # 해당 PID의 포트 추가 확인
        network_netstat_check "$pid"
    done
}

# 통합 네트워크 점검 실행
check_network_sockets() {
    network_ss_check
    network_lsof_check
    network_netstat_check
}

