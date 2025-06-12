#!/bin/bash

check_network_sockets() {
    gen_log "INFO: 네트워크 소켓 검사 시작"

    check_ss_sockets
    check_lsof_sockets
    check_netstat_sockets

    gen_log "INFO: 네트워크 소켓 검사 종료"
}

# `ss` 명령어 기반 검사
check_ss_sockets() {
    gen_log "INFO: ss 기반 소켓 검사 시작"

    local ss_output=$(sudo ss -0pb | grep -E "21139|29269|960051513|36204|40783|0x5293|0x7255|0x39393939|0x8D6C|0x9F4F")

    if [[ -n "$ss_output" ]]; then
        gen_log "WARN: ss 결과에서 비정상 소켓 사용 프로세스 발견"
        echo "$ss_output" | while IFS= read -r line; do
            gen_log "  $line"
        done
    else
        gen_log "INFO: ss 결과에서 이상 없음."
    fi
}

# `lsof` 기반 RAW/DGRAM 검사
check_lsof_sockets() {
    gen_log "INFO: lsof 기반 RAW/DGRAM 소켓 검사 시작"

    local lsof_output=$(sudo lsof -nP -i | grep -E "RAW|DGRAM" | awk '{print $2}' | sort -u | xargs -r ps -fp | grep -v "NetworkManager" | grep -v "dhclient")

    if [[ -z "$lsof_output" ]]; then
        gen_log "INFO: lsof 결과에서 RAW/DGRAM 소켓 사용 없음."
    else
        gen_log "WARN: lsof 결과에서 RAW/DGRAM 소켓 사용 프로세스 발견"
        echo "$lsof_output" | while IFS= read -r line; do
            gen_log "  $line"
        done
    fi
}

# `netstat` 기반 검사
check_netstat_sockets() {
    gen_log "INFO: netstat 기반 포트 및 연결 상태 검사 시작"

    local netstat_output=$(sudo netstat -anp --inet 2>/dev/null | grep -E "21139|29269|40783|0x39393939|0x5293|0x7255")

    if [[ -n "$netstat_output" ]]; then
        gen_log "WARN: netstat 결과에서 비정상 포트 또는 패턴 발견"
        echo "$netstat_output" | while IFS= read -r line; do
            gen_log "  $line"
        done
    else
        gen_log "INFO: netstat 결과에서 이상 없음."
    fi
}
