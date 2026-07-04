# Wealth Flow

ETF, 개별주, 연금계좌, IRP, ISA처럼 장기 투자 자산을 수동 입력하고 미래 자산 흐름을 시뮬레이션하는 Flutter 앱 MVP입니다.

## 지금 구현된 것

- 보유 종목 수량과 현재가 수동 입력
- ETF, 국내주식, 해외주식, 연금, IRP, ISA 분류
- 총 평가금액과 15년 뒤 예상 자산 표시
- 연평균 수익률, 기간, 월 추가 투자금, 연간 투자금 증가율 조정
- 연도별 복리 시뮬레이션 차트
- 샘플 포트폴리오 기반 첫 화면

## 실행

현재 작업 환경에는 Flutter CLI가 설치되어 있지 않았습니다.

Flutter 설치 후 아래 명령으로 실행할 수 있습니다.

```bash
flutter pub get
flutter run
```

iPhone 실기기 테스트는 Xcode 설정과 Apple 개발자 계정 연결 후 가능합니다.

```bash
flutter devices
flutter run -d <device-id>
```

플랫폼 폴더가 필요하면 Flutter 설치 후 프로젝트 루트에서 아래 명령을 실행하세요.

```bash
flutter create .
```
