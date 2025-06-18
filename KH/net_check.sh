#!/bin/bash

gen_log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# netstat 기반으로 해당 PID가 열고 있는 포트 확인
network_netstat_port_by_pid() {
    local pid=$1

    sudo netstat -nap 2>/dev/null | sed -E 's/\[\s*ACC\s*\]/[ACC]/g; s/\[\s*\]/[]/g' | tr -s ' ' | grep -E "tcp|udp" | grep "$pid/" | grep -v "NetworkManager" | grep -v "dhclient" | while read -r line; do

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


        gen_log "[PORT] PID=$pid_field | 프로세스=$pname_field | 프로토콜=$proto | 포트=${laddr} → ${raddr}"
    done
}

# ss 기반 의심 프로세스 탐지
network_ss_check() {
    gen_log "[INFO] ss 기반 소켓 검사 시작"

    sudo ss -0pb 2>/dev/null | paste - - | while read -r line; do
        if echo "$line" | grep -qE '21139|29269|36204|40783|0x5293|0x7255|0x39393939|0x8D6C|0x9F4F|5353|262144'; then
            laddr=$(echo "$line" | awk '{print $5}')
            raddr=$(echo "$line" | awk '{print $6}')
            pname=$(echo "$line" | grep -oP 'users:\(\("\K[^"]+')
            pid=$(echo "$line" | grep -oP 'pid=\K[0-9]+')

            pname=${pname:-N/A}
            pid=${pid:-N/A}
            laddr=${laddr:-0}
            raddr=${raddr:-0}

            gen_log "[WARN] ss: 의심 연결 감지 → PID=$pid | 프로세스=$pname | $laddr → $raddr"

            # 🔽 해당 PID의 포트 추가 확인
            network_netstat_port_by_pid "$pid" "$pname"
        fi
    done
}

# lsof 기반 RAW/DGRAM 소켓 탐지
network_lsof_check() {
    gen_log "[INFO] lsof 기반 RAW/DGRAM 소켓 검사 시작"

    local pids
    pids=$(sudo lsof 2>/dev/null | grep -E "SOCK_RAW|SOCK_DGRAM" | awk '{print $2}' | sort -u)

    if [[ -z "$pids" ]]; then
        gen_log "[INFO] RAW/DGRAM 소켓 사용하는 프로세스 없음"
        return
    fi

    for pid in $pids; do
        cmd=$(ps -p "$pid" -o comm=)
        [[ "$cmd" =~ NetworkManager|dhclient ]] && continue

        exe_path=$(readlink -f "/proc/$pid/exe")
        gen_log "[WARN] RAW/DGRAM 사용 프로세스 감지 → PID=$pid | 프로세스=$cmd | 실행 경로=$exe_path"

        # 🔽 해당 PID의 포트 추가 확인
        network_netstat_port_by_pid "$pid" "$cmd"
    done
}

# 통합 네트워크 점검 실행
run_network_check() {
   network_ss_check
   network_lsof_check
   network_netstat_port_by_pid
}

