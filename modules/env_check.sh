#!/bin/bash

check_bpfdoor_env_vars() {
    gen_log "INFO: BPFDoor 환경 변수 검사 시작"
    CHECK_ENV=("HOME=/tmp" "HISTFILE=/dev/null" "MYSQL_HISTFILE=/dev/null")

    for pid in $(ls /proc/ | grep -E '^[0-9]+$'); do
        if [ -r /proc/$pid/environ ]; then
            env_data=$(tr '\0' '\n' < /proc/$pid/environ)
            match_all=true
            for check_item in "${CHECK_ENV[@]}"; do
                if ! echo "$env_data" | grep -q "$check_item"; then
                    match_all=false
                    break
                fi
            done
            if [ "$match_all" = true ]; then
                gen_log "${RED}WARN: 의심되는 환경 변수가 설정된 프로세스 발견 (PID: $pid)${NC}"
                gen_log "$(ps -p $pid -o | user= | pid= | ppid= | cmd=)"
                return 1
            fi
        fi
    done

    gen_log "${GREEN}INFO: 의심되는 환경 변수가 설정된 프로세스 없음${NC}"
    return 0
}
