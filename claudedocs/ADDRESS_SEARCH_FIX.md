# Address Search Fix for Web Deployment

**Date**: 2025-11-23
**Issue**: Address search works in local/mobile but not in web deployment
**Solution**: Integrate Naver Geocoding API via Supabase Edge Function

---

## Problem Analysis

### Root Cause
- **Business/Place Search** (e.g., "스타벅스"): Uses Naver Local Search API ✅
- **Address Search** (e.g., "문단길 15"): Falls back to Google Geocoding API
  - Mobile: Uses `geocoding` package (Google Geocoding) ✅
  - Web: Placeholder returns empty results ❌

### Search Strategy Flow
```
searchPlaces(query)
  ↓
Strategy 1: _searchLocalAPI(query) [Naver Local Search]
  ↓ (if empty)
Strategy 2: _searchGeocodingAPI(query) [Google/Naver Geocoding]
  ↓ (if empty)
Strategy 3: _searchLocalAPI(firstWord) [Retry with first word]
```

---

## Implementation

### 1. Created Naver Geocode Edge Function ✅

**File**: `supabase/functions/naver-geocode/index.ts`

**API**: Naver Geocoding API
- Endpoint: `https://naveropenapi.apigw.ntruss.com/map-geocode/v2/geocode`
- Headers: `X-NCP-APIGW-API-KEY-ID`, `X-NCP-APIGW-API-KEY`
- Response format:
  ```json
  {
    "addresses": [
      {
        "roadAddress": "서울특별시 강남구 문단길 15",
        "jibunAddress": "서울특별시 강남구 논현동 123",
        "x": "127.1234567",  // longitude
        "y": "37.1234567"    // latitude
      }
    ]
  }
  ```

**Key Features**:
- Environment variables: `NAVER_LOCAL_SEARCH_CLIENT_ID`, `NAVER_LOCAL_SEARCH_CLIENT_SECRET`
- CORS headers for web access
- Error handling with fallback to empty addresses array

### 2. Updated Flutter Location Service ✅

**File**: `lib/core/services/location_service.dart`

**Changes**:
- Modified `_searchGeocodingWeb()` method (lines 551-646)
- Added Supabase Edge Function call for web geocoding
- Integrated with existing search strategy

**Web Implementation**:
```dart
Future<List<PlaceSearchResult>> _searchGeocodingWeb(String query) async {
  // Get Supabase credentials from window.ENV
  final env = js_util.getProperty(window, 'ENV');
  final supabaseUrl = js_util.getProperty(env, 'SUPABASE_URL') ?? '';
  final supabaseAnonKey = js_util.getProperty(env, 'SUPABASE_ANON_KEY') ?? '';

  // Call naver-geocode Edge Function
  final response = await http.post(
    Uri.parse('$supabaseUrl/functions/v1/naver-geocode'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $supabaseAnonKey',
    },
    body: json.encode({'query': query}),
  );

  // Parse addresses and create PlaceSearchResult objects
  // Naver Geocoding: x = longitude, y = latitude (WGS84)
}
```

**Coordinate System**:
- Naver Geocoding uses WGS84 (same as Google Maps)
- `x` = longitude, `y` = latitude
- No conversion needed (unlike Naver Local Search API which uses KATECH)

---

## Deployment Steps

### 1. Deploy Naver Geocode Edge Function

**Prerequisites**: Supabase CLI installed
```bash
# Mac
brew install supabase/tap/supabase

# Login
supabase login
```

**Deploy Command**:
```bash
supabase functions deploy naver-geocode --project-ref bulwfcsyqgsvmbadhlye
```

**Verify Deployment**:
```bash
curl -X POST https://bulwfcsyqgsvmbadhlye.supabase.co/functions/v1/naver-geocode \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <SUPABASE_ANON_KEY>" \
  -d '{"query":"문단길 15"}'
```

**Expected Response**:
```json
{
  "addresses": [
    {
      "roadAddress": "서울특별시 강남구 문단길 15",
      "jibunAddress": "서울특별시 강남구 논현동 123",
      "x": "127.1234567",
      "y": "37.1234567"
    }
  ]
}
```

### 2. Build and Deploy Flutter Web App

**Environment Variables Required**:
- `SUPABASE_URL`: Already configured ✅
- `SUPABASE_ANON_KEY`: Already configured ✅
- `NAVER_LOCAL_SEARCH_CLIENT_ID`: Already set in Supabase Secrets ✅
- `NAVER_LOCAL_SEARCH_CLIENT_SECRET`: Already set in Supabase Secrets ✅

**Build and Deploy**:
```bash
# Inject environment variables
./scripts/inject_env.sh

# Build web app
flutter build web --release --base-href /flutter-todo/

# Push to GitHub (GitHub Actions will deploy to GitHub Pages)
git add .
git commit -m "feat: Add Naver Geocoding API support for web address search"
git push origin master
```

---

## Testing

### Test Cases

**1. Business/Place Search** (should still work):
```
Query: "스타벅스"
Expected: Uses naver-search Edge Function
Result: 5-10 business results with mapx/mapy coordinates
```

**2. Address Search** (NEW - should now work):
```
Query: "문단길 15"
Expected: Uses naver-geocode Edge Function
Result: Address results with x/y coordinates (WGS84)
```

**3. Mixed Query**:
```
Query: "강남구 스타벅스"
Expected: Strategy 1 (naver-search) → Strategy 2 (naver-geocode)
Result: Best matching results from either API
```

### Console Logs to Verify

**Business Search (naver-search)**:
```
🔍 Strategy 1: Direct "스타벅스"
🔍 Calling Supabase Edge Function: https://bulwfcsyqgsvmbadhlye.supabase.co/functions/v1/naver-search
🔍 Naver Local Search API Response:
   Status: 200
   Items count: 5
   First item title: 스타벅스 강남점
✅ Found 5 results
```

**Address Search (naver-geocode)**:
```
🔍 Strategy 1: Direct "문단길 15"
🔍 Calling Supabase Edge Function: https://bulwfcsyqgsvmbadhlye.supabase.co/functions/v1/naver-search
   Status: 200
   Items count: 0
🔍 Strategy 2: Google Geocoding "문단길 15"
🗺️ Using Google Geocoding for: "문단길 15"
🗺️ Calling Naver Geocode Edge Function for address: "문단길 15"
🗺️ Naver Geocode API Response:
   Status: 200
   Addresses count: 1
   📍 서울특별시 강남구 문단길 15 at (37.1234567, 127.1234567)
✅ Found 1 results with Geocoding
```

---

## Architecture Summary

### Before Fix (Web Only)
```
Flutter Web App
    ↓ Business Search
Supabase naver-search Edge Function ✅
    ↓
Naver Local Search API

Flutter Web App
    ↓ Address Search
_searchGeocodingWeb() → return [] ❌
```

### After Fix (Web)
```
Flutter Web App
    ↓ Business Search
Supabase naver-search Edge Function ✅
    ↓
Naver Local Search API

Flutter Web App
    ↓ Address Search
Supabase naver-geocode Edge Function ✅
    ↓
Naver Geocoding API
```

### Mobile (Unchanged)
```
Flutter Mobile App
    ↓ Business Search
Direct API Call (No CORS) ✅
    ↓
Naver Local Search API

Flutter Mobile App
    ↓ Address Search
geocoding package ✅
    ↓
Google Geocoding API
```

---

## Cost Considerations

**Naver Geocoding API**:
- Free tier: 100,000 calls/day
- Todo app usage: ~10-50 calls/day
- **Cost**: Completely free ✅

**Supabase Edge Functions**:
- Free tier: 500,000 invocations/month
- Todo app usage: ~100-200 calls/day = ~3,000-6,000/month
- **Cost**: Completely free ✅

---

## Related Files

### Created/Modified
- `supabase/functions/naver-geocode/index.ts` - NEW Geocoding Edge Function
- `lib/core/services/location_service.dart` - Updated web geocoding implementation

### Related Documentation
- [CORS_FIX_SUMMARY.md](CORS_FIX_SUMMARY.md) - Previous CORS fix for business search
- [SUPABASE_EDGE_FUNCTION_SETUP.md](SUPABASE_EDGE_FUNCTION_SETUP.md) - Edge Function deployment guide

---

## Checklist

- [x] Create naver-geocode Edge Function
- [x] Update location_service.dart with web geocoding
- [ ] **Deploy naver-geocode to Supabase** ← Next step
- [ ] **Build and deploy Flutter web app**
- [ ] **Test address search in deployment**

---

**Current Status**: ⚠️ Code ready, Edge Function deployment pending

**Next Action**: Deploy naver-geocode Edge Function using Supabase CLI

**Estimated Time**: 5 minutes
