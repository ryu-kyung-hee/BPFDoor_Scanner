#!/bin/bash

#KISA에서 발표된 공격자  IP IOC(현재는 유일한 IP IOC다.)
C2_IP="165.232.174.130"

check_c2_ip_connection() {
	gen_log "INFO: 연결된 C2 IP 주소 검사 시작 (C2 IP: $C2_IP)..."
	local found_c2_connection=false
	if command -v ss &>/dev/null; then
		if ss -ntp | grep -q "$C2_IP"; then
			gen_log "WARN: C2 IP ($C2_IP) 주소에 대한 네트워크 연결 발견"
			ss -ntp | grep "$C2_IP" | while read -r line; do gen_log " 	Connection: $line"; done
			found_c2_connection=true
		fi
	elif command -v netstat &>/dev/null; then
		if netstat -ntp | grep -q "$C2_IP"; then
			gen_log "WARN: C2 IP ($C2_IP) 주소에 대한 네트워크 연결 발견"
			netstat -ntp | grep "$C2_IP" | while read -r line; do gen_log "		Connection: $line"; done
		fi
	else
		gen_log "WARN: 'ss' 또는 'netstat' 명령을 찾을 수 없으므로 네트워크 연결 검사를 건너뛸 수 있음."

	fi
    	[ "$found_c2_connection" = false ] && gen_log "INFO: C2 IP ($C2_IP) 에 대해 활성화된 연결 없음."
}


