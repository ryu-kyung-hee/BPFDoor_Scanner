#!/bin/bash

check__ss__sockets() {
	gen_log "INFO: ss 기반 소켓 검사 시작"
	
	local ss_output
	ss_output=$(sudo ss -0pb 2>/dev/null | grep -E "21139|29269|960051513|36204|40783|0x5293|0x7255|0x39393939|0x8D6C|0x9F4F")



