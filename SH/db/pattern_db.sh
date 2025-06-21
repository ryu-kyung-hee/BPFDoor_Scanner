#!/bin/bash
# 의심 프로세스 이름 및 경로 패턴 목록

SUSPICIOUS_NAMES_PATHS=(
    "hpasmmld"
    "smartadm"
    "hald-addon-volume"
    "dbus-srv"
    "gm"
    "rad$"
    "/dev/shm/."
    "/tmp/."
    "hpasmlited"
    "dbus-daemon"

)
