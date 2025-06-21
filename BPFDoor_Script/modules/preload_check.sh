#!/bin/bash

check_ld_preload() {
    gen_log "[INFO] [LD_PRELOAD] LD_PRELOAD 탐지 시작"

    local found=false

    for pid in $(ls /proc | grep -E '^[0-9]+$'); do
        local env_file="/proc/$pid/environ"
        if [ -r "$env_file" ]; then
            local env_data
            env_data=$(tr '\0' '\n' < "$env_file" 2>/dev/null)

            local preload libpath path
            preload=$(echo "$env_data" | grep '^LD_PRELOAD=')
            libpath=$(echo "$env_data" | grep '^LD_LIBRARY_PATH=')
            path=$(echo "$env_data" | grep '^PATH=')

            if [[ -n "$preload" || -n "$libpath" ]]; then
                found=true
                gen_log "${YELLOW}의심되는 환경 변수가 발견됨 (PID: $pid)${NC}"

                # PID 정보 정리된 한 줄 출력
                read -r user pid_val ppid_val cmd_val <<< $(ps -p $pid -o user=,pid=,ppid=,cmd= --no-headers)
                gen_log "USER: $user | PID: $pid_val | PPID: $ppid_val | CMD: $cmd_val"

                if [ -n "$preload" ]; then
                    gen_log "${YELLOW}LD_PRELOAD:${NC}"
                    IFS=':' read -ra entries <<< "${preload#LD_PRELOAD=}"
                    for e in "${entries[@]}"; do
                        [ -n "$e" ] && gen_log "$e"
                    done
                fi

                if [ -n "$libpath" ]; then
                    gen_log "${YELLOW}LD_LIBRARY_PATH:${NC}"
                    IFS=':' read -ra entries <<< "${libpath#LD_LIBRARY_PATH=}"
                    for e in "${entries[@]}"; do
                        [ -n "$e" ] && gen_log "$e"
                    done
                fi

                if [ -n "$path" ]; then
                    gen_log "${YELLOW}PATH:${NC}"
                    IFS=':' read -ra entries <<< "${path#PATH=}"
                    for e in "${entries[@]}"; do
                        [ -n "$e" ] && gen_log "$e"
                    done
                fi
            fi
        fi
    done

    if [ -f "/etc/ld.so.preload" ]; then
        if [ -s "/etc/ld.so.preload" ]; then
            gen_log "${RED}[WARN]${NC} /etc/ld.so.preload 파일에 내용이 존재함"
            gen_log "--- /etc/ld.so.preload 내용 ---"
            while IFS= read -r line; do
                gen_log "  $line"
            done < /etc/ld.so.preload
            gen_log "-----------------------------"
            found=true
        else
            gen_log "${GREEN}[INFO]${NC} /etc/ld.so.preload 파일은 존재하지만 비어 있음"
        fi
    fi

    if [ "$found" = true ]; then
        gen_log "${RED}[WARN]${NC} LD_PRELOAD 관련 이상 징후 감지됨"
    else
        gen_log "${GREEN}[INFO]${NC} LD_PRELOAD 관련 의심 정황 없음"
    fi
}
