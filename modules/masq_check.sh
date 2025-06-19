#!/bin/bash

# 위장 프로세스 점검 함수
check_process_masquerading() {
    gen_log "INFO: 위장 프로세스 점검 시작"
    local found_masquerade=false

    local masquerade_output_tmp="/tmp/masquerade_report.log"
    > "$masquerade_output_tmp"  # 이전 로그 초기화

    for pid_path in /proc/[0-9]*; do
        [ ! -d "$pid_path" ] && continue
        
        local pid=$(basename "$pid_path")
        local comm_file="$pid_path/comm"
        local cmdline_file="$pid_path/cmdline"

        # 파일 읽기 권한 확인
        if [[ -r "$comm_file" && -r "$cmdline_file" && -s "$cmdline_file" ]]; then
            local comm_val=$(cat "$comm_file" 2>/dev/null)
            local cmd_first_arg=$(tr '\0' '\n' < "$cmdline_file" | head -n 1)
            local base_cmd=$(basename "$cmd_first_arg" 2>/dev/null)
            local full_cmd=$(tr '\0' ' ' < "$cmdline_file" | head -c 256)

            # 핵심 비교 로직
            if [[ -n "$comm_val" && -n "$base_cmd" && "$comm_val" != "$base_cmd" ]]; then
                # 오탐 제거 필터 (파이오링크 필터링 기준)
                if ! [[ "$comm_val" == "["*"]" || "$base_cmd" == "["*"]" ]] &&
                   ! ( [[ "$comm_val" == "java" && "$base_cmd" =~ ^java ]] ||
                       [[ "$comm_val" == "python"* && "$base_cmd" =~ ^python ]] ||
                       [[ "$comm_val" == "bash" && "$base_cmd" == "bash" ]] ||
                       [[ "$comm_val" == "sh" && "$base_cmd" == "sh" ]] ) &&
                   ! [[ "$base_cmd" == "$comm_val"* ]]; then
                    
                    # 로그 기록
                    echo "[!] Suspected masquerading process detected:" >> "$masquerade_output_tmp"
                    echo "  [33m→ PID: $pid[0m, COMM: $comm_val, CMD_BASE: $base_cmd" >> "$masquerade_output_tmp"
                    found_masquerade=true
                fi
            fi
        fi
    done

    # 결과 보고
    if [ "$found_masquerade" = true ]; then
        gen_log "[31mWARN: 의심 프로세스 발견[0m"
        gen_log "--- 검출된 위장 프로세스 목록 ---"
        cat "$masquerade_output_tmp" | while read -r line; do gen_log "$line"; done
    else
        gen_log "INFO: 위장 프로세스 없음."
    fi
}
