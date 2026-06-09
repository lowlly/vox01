학습 내용을 음성으로 듣는 AI APP을 하이브리드 앱 개발 계획

## 1. 프로젝트 개요
- **대상 URL**: `https://vox01.appstudy.co.kr/Study/index.asp`
- **목표**: 해당 웹 서비스를 WebView 기반의 안드로이드 앱으로 패키징하고 스토어 등록 준비를 마침.
- **기술 스택**: 
  - Cross-platform: Flutter 또는 React Native (선택 필요)
  - WebView: 공식 WebView 플러그인 사용
  - TTS 구현의 핵심: flutter_tts

## 2. 주요 기능 요구사항
1. **WebView 통합**: 지정된 URL을 풀스크린으로 렌더링.
2. **권한 설정**: 카메라, 앨범, 알림 등 필요한 권한 사전 구성.
3. **네이티브 기능**: 
   - 뒤로가기 버튼 처리 (안드로이드)
   - 로딩 스플래시 화면(Splash Screen) 구현
   - (옵션) 푸시 알림 수신 설정

## 3. 작업 단계 (Claude Code 지시용)

### 🏗️ 1단계: 프로젝트 초기화
- 선택한 프레임워크(Flutter/RN)를 사용하여 새 프로젝트 생성.
- `pubspec.yaml` 또는 `package.json`에 필수 의존성(WebView) 추가.

### ⚙️ 2단계: 플랫폼별 설정
  - `AndroidManifest.xml` 내 인터넷 권한 및 `usesCleartextTraffic` 확인.
  - 패키지명(Bundle ID) 설정.

### 🎨 3단계: UI/UX 구현
- 메인 WebView 위젯 배치.
- 앱 아이콘 및 스플래시 이미지 에셋 연결.

### 🚀 4단계: 스토어 등록 준비 (Deployment)
-릴리스용 Keystore 생성 및 App Bundle(AAB) 빌드 스크립트 작성.