#!/bin/bash

check_process_masquerading() {
    echo "INFO: 위장 프로세스 확인 중"
    local found_masquerade=false
    local comm_name exe_name

    for pid in $(ps -eo pid --no-headers); do
        if [ ! -d "/proc/$pid" ]; then
            continue
        fi
        
        comm_name=$(cat "/proc/$pid/comm" 2>/dev/null)
        exe_name=$(basename "$(readlink -f "/proc/$pid/exe")" 2>/dev/null)

        if [[ -n "$exe_name" && "$comm_name" != "$exe_name" ]]; then
            # exe_name이 comm_name으로 시작하는 경우, 정상적인 이름 잘림(Truncation)으로 간주하고 무시
            if [[ "$exe_name" == "$comm_name"* ]]; then
                # 정상적인 이름 잘림이므로, 아무것도 하지 않고 넘어감
                :
            else
                echo "WARN: [의심] 프로세스명 불일치 탐지 (PID: $pid)"
                echo " -> In-Memory Name : $comm_name"
                echo " -> Executable File : $exe_name"
                echo " -> Full Command    : \"$(cat /proc/$pid/cmdline | tr -d '\0')\""
                found_masquerade=true
            fi
        fi
    done

if [ "$found_masquerade" = false ]; then
    echo "INFO: 위장 프로세스가 발견되지 않음."
fi
}
