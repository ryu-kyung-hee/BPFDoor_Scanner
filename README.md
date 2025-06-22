# Description
K-Shield Jr 14기 프로젝트 bpfdoor 악성코드 점검 스크립트 입니다.  
<br>
# Usage
main.sh 및 모듈 권한부여합니다.
`chmod +x [스크립트 명]`

각 모듈에 대한 설명입니다.
필요 시 `./main.sh --[Option]` 값을 부여해 개별로 실행할 수 있습니다.

| Module | Option | Description |
| --- | --- | --- |
| proc_check.sh | `--proc` | 주요 경로에서 의심되는 프로세스와 파일 이름을 확인합니다. |
| env_check.sh | `--env` |  명령어 기록을 회피하거나 비정상적인 환경에서 실행된 흔적을 확인합니다. | 
| hash_check.sh | `--hash` | 공개된 해시값 기반 경로 및 파일을 확인합니다. | 
| net_check.sh | `--net` | 네트워크 검사를 [ss, lsof, netstat] 해당 명령을 통해 확인합니다. |
| masq_check.sh | `--masq` | 프로세스 이름과 실행 경로가 일치하지 않는 위장 프로세스를 확인합니다. |
| c2_check.sh | `--ip` | 공개된 C2 IP를 기반으로 확인합니다. |
| preload_check.sh | `--preload` | LD_PRELOAD 환경변수 및 /etc/ld.so.preload 설정 여부를 통해 후킹 시도를 확인합니다. |
<br>

# Error
사용 중 발생한 에러는 deamondsjh@naver.com으로 메일을 보내주세요.
