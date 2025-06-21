#!/bin/bash

#필요시 변경. 현재 가상환경 공격자 IP로 설정
C2_IP="192.168.100.3"

check_c2_ip_connection() {
    gen_log "[INFO} C2 IP 연결 점검 시작"
    local found_c2_connection=false

    #ss 명령어 검사
    if command -v ss &>/dev/null; then
        if ss -ntup | grep -q "$C2_IP"; then
                found_c2_connection=true
                ss -ntup | grep "$C2_IP" | while read -r line; do
                        local proto=$(echo "$line" | awk '{print $1}')
                        local local_addr=$(echo "$line" | awk '{print $5}')
                        local remote_addr=$(echo "$line" | awk '{print $6}')
                        local pid=$(echo "$line" | grep -oP 'pid=\K[0-9]+' | sort -u)
                        local cmd=$(echo "$line" | grep -oP 'users:\(\("\K[^"]+' | sort -u)

                        gen_log "${RED}[WARN]${NC} C2 IP ($C2_IP) 주소에 대한 네트워크 연결 발견"
                        gen_log "$proto: $local_addr → $remote_addr (PID: ${pid:-N/A}, CMD: ${cmd:-N/A})"
               done
        fi

    #ss 명령어가 존재하지 않을 시 netstat 명령어 검사
    elif command -v netstat &>/dev/null; then
        if netstat -ntup 2>/dev/null | grep "$C2_IP"; then
                found_c2_connection=true
                netstat -ntup 2>/dev/null | grep "$C2_IP" | while -r line; do
                        gen_log " netstat: $line"
                done
        fi
    else
        gen_log "[INFO] 'ss'와 'netstat' 명령어가 존재하지 않음"
    fi


    if [ "$found_c2_connection" = false ]; then
        gen_log "${GREEN}[INFO]${NC} 연결된 C2 IP 없음"
    fi
}
