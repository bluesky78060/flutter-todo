# iOS Widget Extension Setup Guide

이 가이드는 Xcode에서 Widget Extension을 추가하는 방법을 설명합니다.

## 1. Xcode에서 Widget Extension Target 추가

1. Xcode에서 `ios/Runner.xcworkspace` 열기
2. File > New > Target... 선택
3. "Widget Extension" 선택 후 Next
4. 다음 정보 입력:
   - **Product Name**: `TodoWidgets`
   - **Team**: 개발자 팀 선택
   - **Organization Identifier**: `kr.bluesky.dodo`
   - **Bundle Identifier**: `kr.bluesky.dodo.TodoWidgets`
   - **Include Configuration Intent**: 체크 해제
   - **Include Live Activity**: 체크 해제
5. Finish 클릭

## 2. 기존 Widget 파일 대체

새로 생성된 TodoWidgets 폴더의 기본 파일들을 삭제하고, 이 폴더의 파일들로 대체:
- `TodoWidgetBundle.swift` (Entry Point)
- `SharedData.swift` (Data Models)
- `TodoListWidget.swift` (Design B: Card with Color Bar)
- `TodoDetailWidget.swift` (Design E: Timeline Style)
- `TodoCalendarWidget.swift` (Calendar Widget)
- `Info.plist`
- `TodoWidgets.entitlements`

## 3. App Groups 설정

### Runner Target (메인 앱)
1. Runner 타겟 선택 > Signing & Capabilities
2. "+ Capability" 클릭 > "App Groups" 선택
3. "+" 클릭하여 `group.kr.bluesky.dodo` 추가

### TodoWidgets Target (위젯)
1. TodoWidgets 타겟 선택 > Signing & Capabilities
2. "+ Capability" 클릭 > "App Groups" 선택
3. "+" 클릭하여 `group.kr.bluesky.dodo` 추가 (동일한 그룹)

## 4. Build Settings 확인

TodoWidgets 타겟의 Build Settings:
- **iOS Deployment Target**: 15.0 이상
- **Swift Language Version**: 5.0

## 5. 파일 추가 확인

TodoWidgets 타겟의 Build Phases > Compile Sources에 다음 파일들이 포함되어 있는지 확인:
- `TodoWidgetBundle.swift`
- `SharedData.swift`
- `TodoListWidget.swift`
- `TodoDetailWidget.swift`
- `TodoCalendarWidget.swift`

## 6. 빌드 및 테스트

```bash
# Flutter에서 iOS 빌드
flutter build ios --simulator

# 또는 Xcode에서 직접 빌드
# Product > Build (Cmd+B)
```

## 위젯 디자인

### TodoListWidget (Design B: Card with Color Bar)
- 카드 형태의 할 일 목록
- 왼쪽에 카테고리 색상 바
- 체크박스, 제목, 시간, 카테고리 배지 표시

### TodoDetailWidget (Design E: Timeline Style)
- 타임라인 형태의 할 일 표시
- 세로 라인과 도트로 연결
- 각 카드에 제목, 설명, 시간 배지

### TodoCalendarWidget
- 월별 캘린더 그리드
- 할 일이 있는 날에 도트 표시
- 공휴일 표시 (빨간색)
- 하단에 예정된 이벤트 목록

## 문제 해결

### Widget이 표시되지 않는 경우
1. App Groups 설정이 올바른지 확인
2. Bundle Identifier가 올바른지 확인
3. 기기/시뮬레이터를 재시작

### 데이터가 동기화되지 않는 경우
1. Flutter 앱에서 `HomeWidget.setAppGroupId('group.kr.bluesky.dodo')` 호출 확인
2. SharedDataManager의 appGroupId가 일치하는지 확인
3. UserDefaults key가 `flutter.widget_todos` 형식인지 확인
