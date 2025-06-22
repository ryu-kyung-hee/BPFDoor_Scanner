#!/bin/bash

source "$SCRIPT_DIR/db/hash.db"


check_files_by_hash() {
    gen_log "[INFO] 파일 해시 검사 시작"
    local found_suspicious_file=false
    local SEARCH_PATHS=("/bin" "/sbin" "/usr/bin" "/usr/sbin" "/lib" "/usr/lib" "/etc" "/tmp" "/var/tmp" "/dev/shm" "/opt" "/home")

    for search_dir in "${SEARCH_PATHS[@]}"; do
        find "$search_dir" -type f -perm /111 -print0 2>/dev/null |
        while IFS= read -r -d $'\0' file_path; do

            if file "$file_path" 2>/dev/null | grep -q -E "ELF|SCRIPT"; then
                [ ! -r "$file_path" ] && continue
                current_sha256=$(sha256sum "$file_path" 2>/dev/null | awk '{print $1}')
                [ -z "$current_sha256" ] && continue

            for hash_val in "${!MALWARE_HASHES[@]}"; do
                if [[ "$current_sha256" == "$hash_val" ]]; then
                    gen_log "${RED}[WARN]${NC} 의심 파일 발견: ${MALWARE_HASHES[$hash_val]}"
                    gen_log "경로: $file_path"
                    gen_log "SHA256: $current_sha256"
                    found_suspicious_file=true
                fi
            done
            fi
        done
    done

    if [ "$found_suspicious_file" = false ]; then
        gen_log "${RED}[WARN]${NC} 악성 해시와 일치하는 파일 있음."
    else
        gen_log "${GREEN}[INFO]${NC} 악성 해시와 일치하는 파일 없음."
    fi
}
