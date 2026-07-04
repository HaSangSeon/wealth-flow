# 웰스플로우 인앱 결제(RevenueCat) 연동 가이드 및 진행 상황

이 파일은 구글 플레이 콘솔 및 레버뉴캣(RevenueCat) 연동 작업의 진행 현황과, 본인 인증 승인 이후 이어서 진행해야 할 단계를 기록해둔 가이드 파일입니다.

---

## 1. 🛠️ 지금까지 완료된 작업 (코드 측면)

1. **앱 패키지명 변경 완료**
   - 기존의 `com.example.wealth_flow`에서 고유 패키지명인 **`com.hadoseo.wealthflow`**로 일괄 변경 완료 (Android 및 iOS 적용 완료).
2. **라이브러리 설치 완료**
   - 인앱 결제 모듈인 `purchases_flutter` 패키지 설치 완료.
3. **결제 매니저 코드 작성 완료**
   - [`lib/payment_service.dart`](file:///Users/hasangseon/wealth-flow/lib/payment_service.dart) 생성: 초기화, 평생권 구매(`purchasePremium`), 구매 내역 복구(`restorePurchases`) 기능 탑재.
4. **앱 구동 시 초기화 연동**
   - [`lib/main.dart`](file:///Users/hasangseon/wealth-flow/lib/main.dart)에 앱 실행 시 결제 상태를 자동 체크하는 초기화 코드 추가.
5. **프리미엄 화면 UI 연결**
   - [`lib/premium.dart`](file:///Users/hasangseon/wealth-flow/lib/premium.dart)의 '프리미엄 업그레이드' 및 '구매 복구' 버튼에 실제 결제 서비스 연동 완료. 결제 시 로딩 차단 화면 및 개발자용 프리미엄 토글 테스트 이스터에그(상단 타이틀 꾹 누르기) 추가 완료.

---

## 2. 📋 구글 계정 인증 완료 후 내가 이어서 해야 할 일

구글의 신원 확인(본인 인증) 승인이 완료되고 나면 아래 단계를 순서대로 진행해 주세요.

### [1단계] 구글 플레이 콘솔에 새 앱 등록하기
1. **[구글 플레이 콘솔](https://play.google.com/console/)**에 접속합니다.
2. 오른쪽 상단 **`[앱 만들기]`** 버튼을 클릭합니다.
   - **앱 이름:** `웰스플로우` (혹은 다른 이름)
   - **기본 언어:** `한국어`
   - **앱 또는 게임:** `앱` 선택
   - **무료 또는 유료:** **`무료`** 선택 (앱 다운로드는 무료이고 인앱 결제를 사용하기 때문)
3. 선언문 동의 체크 후 완료합니다.

### [2단계] RevenueCat에 구글 열쇠(JSON) 등록하고 API 키 복사하기
1. **[레버뉴캣 대시보드](https://app.revenuecat.com/)**에 로그인하고 `wealthflow` 프로젝트로 들어갑니다.
2. 왼쪽 아래 메뉴에서 **`[Apps]` -> `[Add App]` -> `[Play Store]`**를 클릭합니다.
3. 아래 정보들을 입력합니다:
   - **App Name:** `웰스플로우 안드로이드`
   - **Google Play Package Name:** **`com.hadoseo.wealthflow`** 입력
   - **Service Credentials JSON:** 이전에 구글 클라우드에서 다운로드받은 **JSON 파일**을 드래그해서 업로드합니다.
4. 아래 **`[Save]`** 버튼을 눌러 저장합니다. (구글에 앱이 정상 등록된 상태라면 녹색 `Active` 표시가 뜹니다.)
5. 저장이 완료되면 왼쪽 아래 메뉴에서 **`[API keys]`**를 클릭하여 발급된 **Public API key**(`goog_`로 시작하는 긴 코드)를 복사합니다.

### [3단계] 복사한 API 키를 코드에 반영하기
1. 프로젝트의 **[`lib/payment_service.dart`](file:///Users/hasangseon/wealth-flow/lib/payment_service.dart)** 파일을 엽니다.
2. 상단 6번째 라인 근처에 있는 `_googleApiKey` 변수에 복사한 키를 붙여넣습니다:
   ```dart
   // 변경 전
   static const String _googleApiKey = "goog_placeholder"; 
   
   // 변경 후 (복사한 키 입력)
   static const String _googleApiKey = "goog_abc123xyz..."; 
   ```

### [4단계] 구글 플레이 콘솔에 4,900원 상품 만들기
1. 구글 플레이 콘솔의 내 앱으로 들어갑니다.
2. 왼쪽 메뉴에서 **수익 창출 (Monetize) -> 인앱 상품 (In-app products)**으로 이동합니다.
3. **`[상품 만들기]`**를 누르고 다음 정보를 입력합니다:
   - **제품 ID (Product ID):** **`wealth_flow_premium_lifetime`** (소문자, 언더바 확인!)
   - **이름:** `평생 소장권`
   - **설명:** `웰스플로우의 모든 기능을 평생 제한 없이 이용해 보세요.`
   - **가격:** `4,900원`
4. 저장 후 **활성화(Activate)** 버튼을 클릭합니다.

---

이제 모든 준비가 끝났습니다! 기기에서 앱을 실행하여 결제를 테스트해 보실 수 있습니다.
가이드를 따라 진행하시다가 어려운 부분이 있으면 언제든 다시 저를 불러 질문해 주세요!
