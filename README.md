# BPFDoor_Scanner
K-Shelid 주니어 14기 프로젝트 bpfdoor 악성코드 점검 스크립트 입니다.

1. main.sh 와 각 모듈에 실행 권한을 부여해주세요.
$chmod +x main.sh

2. 각 모듈에 대한 설명입니다.
필요 시 ./main.sh --@ 값을 부여해 개별로 실행할 수 있습니다.

env_check.sh --env
HOME=/tmp, HISTFILE=/dev/null, MYSQL_HISTFILE=/dev/null 으로 설정된 환경변수가 있는지 확인합니다.

hash_check.sh --hash
KISA 기준 주요 경로에서 파일 해시 검사를 진행합니다.
해시값은 현재 발표된 A 유형 기준이며, 추후 추가할 예정입니다.

proc_check.sh --proc
KISA 기준 주요 경로에서 의심되는 프로세스와 파일 이름을 확인합니다.

net_check.sh --net


masq_check.sh --masq


c2_check.sh --ip
현재 KISA에서 공개된 C2 IP는 165.232.174.130 로, 이 IP의 흔적이 있는지 확인합니다.

preload_check.sh --preload
