# 기본 작업 규칙 (Global Working Rules)

- **앱 실행 환경 우선순위**: 앞으로 앱 빌드 및 테스트 작업을 수행할 때는 **iOS(아이폰) 기기보다 Android 에뮬레이터를 최우선으로 타겟팅**하여 실행(`flutter run -d emulator`)할 것.
- **동시 반영 규칙**: 코드를 수정 및 적용한 후에는 **항상 Android 에뮬레이터 핫 리로드(Hot Reload)와 아이폰 기기 릴리즈 빌드 전송(`flutter run --release`)을 동시에** 수행하여 두 환경 모두에서 변경 사항을 바로 확인할 수 있도록 할 것.
