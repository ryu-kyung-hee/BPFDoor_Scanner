#!/bin/bash

check_suspicious_strings() {
    gen_log "INFO: 바이너리 파일 내에 의심스러운 문자열 검사 시작"
    local SUSPICIOUS_STRINGS=(
        "dev/ptm"
        "ptem"
        "idterm"
        "ttcompat"
    )
    local SEARCH_PATHS=(
    "/dev/shm/" "/tmp" "/var/tmp" "/bin/" "/sbin/" "/usr/bin/"
    "/usr/local/bin/" "/usr/local/sbin/" "/etc/" "/run/" "/root/" "/home/"
    )
    
for path in "${SEARCH_PATHS[@]}"; do
    if [ ! -d "$path" ]; then
        echo "WARN: 검색 경로를 찾을 수 없습니다: $path"
        continue
    fi

    find "$path" -type f -print0 2>/dev/null | while IFS= read -r -d $'\0' file; do
    for str in "${SUSPICIOUS_STRINGS[@]}"; do
        if grep -q -a -F -- "$str" "$file"; then
        gen_log "CRITICAL: 의심문자열'${str}'이(가) 파일 '${file}'에서 발견되었습니다."
        break
      fi
    done
  done
done

if  [ "$found_count" -eq 0 ]; then
    gen_log "INFO: 의심스러운 문자열이 포함된 파일이 없습니다."
else
    gen_log "WARN: 총 ${found_count} 개의 파일에서 의심스러운 문자열이 발견되었습니다."
fi
}
echo "INFO: 문자열 검색이 완료되었습니다."
