#!/bin/bash

check_unknown_BPF () {
    echo "INFO: UNKNOWN BPF를 확인 중"

    if ! command -v bpftool &>/dev/null; then
        echo "WARN: bpftool이 없습니다."
        return
    fi

    local unknown_BPF=false

    if sudo bpftool prog show 2>/dev/null | grep -E -q "name\s*<unknown>"; then
        echo "WARN: 이름이 없는 BPF 프로그램이 발견되었습니다"
        unknown_BPF=true
    fi

    if [ "$unknown_BPF" = false ]; then
        echo "INFO: 의심스러운 BPF 아티팩트가 없습니다."
    fi
}

check_unknown_BPF
