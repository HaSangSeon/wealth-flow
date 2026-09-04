---
name: run-android-app
description: 안드로이드 에뮬레이터를 점검/실행하고 Flutter 앱을 에뮬레이터에 빌드 및 실행(flutter run -d emulator)합니다. "앱 실행", "앱 켜줘", "에뮬레이터 실행하고 앱 실행", "시작", "run" 요청 시 즉시 사용합니다.
---

# Run Android App Workflow

이 스킬은 사용자가 매번 긴 지시사항("에뮬레이터 켜고 앱 실행해줘")을 입력할 필요 없이, 간단한 한마디("앱 실행", "시작", "run")로 안드로이드 에뮬레이터를 확인/구동하고 앱을 실행하는 자동화 워크플로우입니다.

## 실행 절차

### 1단계: 연결된 에뮬레이터 확인
```bash
~/Library/Android/sdk/platform-tools/adb devices
```
- `emulator-5554` 등 활성 에뮬레이터가 이미 `device` 상태로 떠있는지 확인합니다.

### 2단계: 에뮬레이터가 꺼져 있다면 부팅
- 활성 에뮬레이터가 없다면 다음 명령어로 에뮬레이터를 백그라운드 기동합니다:
```bash
flutter emulators --launch Medium_Phone_API_36.1
```
- 기동 후 `~/Library/Android/sdk/platform-tools/adb devices`로 정상 연결(`device` 상태)될 때까지 확인합니다.

### 3단계: 앱 실행 (`flutter run -d emulator`)
- 이미 실행 중인 Flutter 프로세스가 없다면 워크스페이스 루트에서 앱을 실행합니다:
```bash
flutter run -d emulator
```
- 백그라운드 태스크로 실행하며, 기동 완료 후 핫 리로드(`r`) 및 핫 리스타트(`R`) 가능한 상태가 되었음을 사용자에게 알립니다.
