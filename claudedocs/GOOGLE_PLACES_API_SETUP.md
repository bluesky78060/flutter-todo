# Google Places API 설정 가이드

## 문제 상황

Flutter Web에서 Google Maps JavaScript SDK를 사용하여 장소 검색을 시도했지만 `InvalidKeyMapError`가 발생했습니다.

## 오류 원인

현재 API 키 `AIzaSyCXsP-ZD0AucY0rDZIfEEjHGnOEVs2H80`에 **Places API**가 활성화되지 않았습니다.

## 해결 방법

### 1. Google Cloud Console 접속

1. [Google Cloud Console](https://console.cloud.google.com/) 접속
2. 프로젝트 선택

### 2. Places API 활성화

1. 왼쪽 메뉴에서 **"API 및 서비스" → "라이브러리"** 클릭
2. 검색창에 **"Places API"** 입력
3. **"Places API"** 선택
4. **"사용 설정"** 버튼 클릭

### 3. API 키 제한 설정 확인

1. **"API 및 서비스" → "사용자 인증 정보"** 클릭
2. API 키 `AIzaSyCXsP-ZD0AucY0rDZIfEEjHGnOEVs2H80` 클릭
3. **"API 제한사항"** 섹션 확인:
   - **"키 제한"** → "없음" 또는 다음 API들을 포함해야 함:
     - ✅ Maps JavaScript API
     - ✅ **Places API (new)** ← 이것이 중요!
     - ✅ Geocoding API

### 4. 웹사이트 제한 설정 (선택사항)

보안을 위해 웹사이트 제한을 설정할 수 있습니다:

1. **"애플리케이션 제한사항"** 섹션
2. **"HTTP 리퍼러(웹사이트)"** 선택
3. 웹사이트 제한사항 추가:
   ```
   http://localhost:*
   https://yourdomain.com/*
   ```

## 대안: Naver API 계속 사용

Google Places API 활성화가 어렵다면, **모바일에서만 검색 기능 제공**하고 **웹에서는 검색 비활성화**하는 방법도 있습니다.

### Flutter에서 플랫폼 감지

```dart
import 'package:flutter/foundation.dart';

// 웹 플랫폼 체크
if (kIsWeb) {
  // 웹: 검색 비활성화 또는 Supabase Edge Function 사용
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('알림'),
      content: Text('웹에서는 검색 기능이 제한됩니다. 모바일 앱을 사용해주세요.'),
    ),
  );
} else {
  // 모바일: Naver Local Search API 사용 (CORS 없음)
  final results = await locationService.searchPlaces(query);
}
```

## Supabase Edge Function을 프록시로 사용 (고급)

웹에서도 Naver API를 사용하려면 Supabase Edge Function을 프록시로 설정:

### 1. Edge Function 생성

```typescript
// supabase/functions/naver-search/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  const { query } = await req.json()

  const response = await fetch(
    `https://openapi.naver.com/v1/search/local.json?query=${encodeURIComponent(query)}&display=10`,
    {
      headers: {
        'X-Naver-Client-Id': 'quSL_7O8Nb5bh6hK4Kj2',
        'X-Naver-Client-Secret': 'raJroLJaYw',
      }
    }
  )

  const data = await response.json()

  return new Response(
    JSON.stringify(data),
    {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      }
    },
  )
})
```

### 2. Deploy

```bash
supabase functions deploy naver-search
```

### 3. Flutter에서 호출

```dart
final response = await http.post(
  Uri.parse('https://your-project.supabase.co/functions/v1/naver-search'),
  headers: {
    'Authorization': 'Bearer $supabaseAnonKey',
    'Content-Type': 'application/json',
  },
  body: jsonEncode({'query': searchQuery}),
);
```

## 추천 방안

1. **단기**: 웹에서 검색 기능 비활성화 (모바일만 지원)
2. **중기**: Google Places API 활성화
3. **장기**: Supabase Edge Function으로 Naver API 프록시 구현

## 참고 자료

- [Google Places API 문서](https://developers.google.com/maps/documentation/javascript/places)
- [Places API 마이그레이션 가이드](https://developers.google.com/maps/documentation/javascript/places-migration-overview)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)
