#!/bin/bash

gen_log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

network_ss_check() {
    gen_log "[INFO] ss 기반 소켓 검사 시작"

    # ss 출력 두 줄을 하나로 붙여 처리
    sudo ss -0pb 2>/dev/null | paste - - | while read -r line; do

        # BPF 또는 의심 키워드 포함 여부
        if echo "$line" | grep -qE '21139|29269|36204|40783|0x5293|0x7255|0x39393939|0x8D6C|0x9F4F|5353|262144'; then

            # 필드 추출
            laddr=$(echo "$line" | awk '{print $5}')
            raddr=$(echo "$line" | awk '{print $6}')

            # PID 및 프로세스명 추출
            pname=$(echo "$line" | grep -oP 'users:\(\("\K[^"]+')
            pid=$(echo "$line" | grep -oP 'pid=\K[0-9]+')

            # 기본값 처리
            pname=${pname:-N/A}
            pid=${pid:-N/A}
            laddr=${laddr:-0}
            raddr=${raddr:-0}

            gen_log "[WARN] ss: 의심 연결 감지 → PID=$pid | 프로세스=$pname | $laddr → $raddr"
        fi
    done
}

# 함수 실행
network_ss_check
