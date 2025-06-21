#!/bin/bash

source "$SCRIPT_DIR/db/pattern_db.sh"

check_suspicious_processes_and_files() {
    gen_log "[INFO] 의심 프로세스 및 파일, 디렉토리 검사 시작"
    local found_suspicious_item=false
    local LIMITED_SEARCH_PATHS=(
        "/tmp" "/var/tmp" "/dev/shm" "/etc" "/run" "/usr/local/bin" "/usr/local/sbin"
    )

    for pattern in "${SUSPICIOUS_NAMES_PATHS[@]}"; do
        # 프로세스 검사
        if pgrep -fli "$pattern" &>/dev/null; then
            gen_log "${RED}[WARN]${NC} 의심 프로세스 발견: $pattern"
            pgrep -fli "$pattern" | while read -r line; do
                gen_log "  프로세스: $line"
            done
            found_suspicious_item=true
        fi

        # 파일 검사
        for s_path in "${LIMITED_SEARCH_PATHS[@]}"; do
            [ ! -d "$s_path" ] && continue
            find "$s_path" -name "$pattern" -print0 2>/dev/null | while IFS= read -r -d $'\0' found_file; do
                gen_log "${RED}[WARN]${NC} 의심 파일 발견: $found_file$"
                found_suspicious_item=true
            done
        done
    done

    if [ "$found_suspicious_item" = true ]; then
	gen_log "${RED}[WARN]${NC} 의심 프로세스 발견"
    else
	gen_log "${GREEN}[INFO]${NC} 의심 프로세스 및 파일 없음"
    fi
}
