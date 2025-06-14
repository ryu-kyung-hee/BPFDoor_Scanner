#!/bin/bash

check_process_masquerading() {
    gen_log "INFO: 위장 프로세스 확인 중"
    local found_masquerade=false

    for pid in $(ps -eo pid --no-headers); do
        if [ ! -d "/proc/$pid" ]; then
            continue
        fi

    local comm_name exe_name
    comm_name=$(cat "/proc/$pid/comm" 2>dev/null
    exe_name=$(basename "$(readlink -f "/proc/$pid/exe") 2>/dev/null)

    if [[ -n "$exe_name" && "$comm_name" != "$exe_name" ]]; then
        gen_log "WARN: 프로세스명 불일치 탐지"
        gen_log " -> In-Memory Name : $comm_name"
        gen_log " -> Executable File : $exe_name"
        gen_log " -> Full Command: $(cat /proc/$lid/cmdline | tr -d "\0')
        found_masquerade=true
    fi
  done

if [ "$found_masquerade" = false ]; then
    gen_log "INFO: 위장 프로세스가 발견되지 않음."
fi
}
