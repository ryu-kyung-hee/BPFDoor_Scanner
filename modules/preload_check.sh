ld_preload_check() {
	gen_log "INFO: [LD_PRELOAD] LD_PRELOAD 탐지 시작"

	local found=false

	for pid in $(ls /proc | grep -E '^[0-9]+$'); do
		local env_file="/proc/$pid/environ"
		if [-r "$env_file"]; then
			local env_data=$(tr '\0' '\n' < "$env_file" 2>/dev/null)

			local preload=$(echo "$env_data" | grep 'LD_PRELOAD=')
			local libpath=$(echo "$env_data" | grep 'LD_LIBRARY_PATH=')
			local path=$(echo "$env_data" | grep 'PATH=')

			if [[ -n "$preload" || -n "$libpath" ]]; then
				found=true
				gen_log "의심되는 환경 변수가  발견(PID: $pid)"
				gen_log " -> $(ps -p $pid -o user=,pid=,ppid=,cmd= --no-headers)"

				[ -n "$preload" ] && gen_log "  LD_PRELOAD: $preload"
	        	        [ -n "$libpath" ] && gen_log "  LD_LIBRARY_PATH: $libpath"
        	        	[ -n "$path" ] && gen_log "  PATH: $path"
			fi
		fi

	done


	if [ -f "/etc/ld.so.preload" ]; then
		if [ -s "/etc/ld.so.preload" ]; then
			gen_log "WARN: /etc/ld.so.preload 파일이 비어있지 않음."
			gen_log "--- /etc/ld.so.preload content ---"
			while IFS= read -r line; do
				gen_log "	$line"
			done < /etc/ld.so.preload
			gen_log "--- End of /etc/ld.so.preload content ---"
			found=true
		else
			gen_log "INFO: /etc/ld.so.preload 파일이 존재하지만 비어 있음."
		fi
	fi

	if [ "$found" = true ]; then
		gen_log "WARN: LD_PRELOAD 에서 이상 징후 발견됨."
	else
	        gen_log "INFO: LD_PRELOAD 관련 의심 정황 없음."
    	fi
}
