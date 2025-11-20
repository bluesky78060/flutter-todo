# Naver Maps Web Search Implementation Guide

## Overview

This document describes the implementation of place search functionality for Flutter Web using Naver Local Search API with a proxy server to bypass CORS restrictions.

**Date**: 2025-11-20
**Status**: ✅ Completed and tested

## Problem Statement

### Initial Challenge
- **Mobile**: Works perfectly with Naver Local Search API (direct API calls)
- **Web**: CORS policy blocks direct browser calls to Naver API
- **Google Maps Alternative**: Attempted but failed due to:
  - InvalidKeyMapError (billing account required)
  - Places API (New) activation issues
  - Deprecation of AutocompleteService (March 2025)

### Solution Approach
Create a proxy server that:
1. Runs locally for development (Python HTTP server)
2. Can be deployed to Supabase Edge Functions for production
3. Bypasses CORS by making server-side API calls
4. Returns results to Flutter web app

## Architecture

```
Flutter Web App
    ↓
JavaScript Bridge (naver_map_bridge.js)
    ↓
Proxy Server (localhost:3000)
    ↓
Naver Local Search API
    ↓
Results converted to WGS84 coordinates
    ↓
Flutter App displays results
```

## Implementation Details

### 1. Proxy Server (Development)

**File**: `/Users/leechanhee/todo_app/naver_proxy.py`

```python
#!/usr/bin/env python3
from http.server import BaseHTTPRequestHandler, HTTPServer
import urllib.request
import urllib.parse
import json

NAVER_CLIENT_ID = 'quSL_7O8Nb5bh6hK4Kj2'
NAVER_CLIENT_SECRET = 'raJroLJaYw'
PORT = 3000
```

**Key Features**:
- Handles CORS preflight (OPTIONS) requests
- Accepts POST requests to `/search` endpoint
- Proxies to `https://openapi.naver.com/v1/search/local.json`
- Returns JSON with CORS headers enabled

**Running**:
```bash
cd /Users/leechanhee/todo_app
python3 naver_proxy.py
```

**Verification**:
```bash
curl -X POST 'http://localhost:3000/search' \
  -H 'Content-Type: application/json' \
  -d '{"query":"스타벅스","display":5}'
```

### 2. JavaScript Bridge

**File**: `/Users/leechanhee/todo_app/web/naver_map_bridge.js`

**Function**: `window.searchNaverPlaces(query)`

**Implementation** (lines 162-236):
```javascript
window.searchNaverPlaces = async function(query) {
  // Call proxy server
  const response = await fetch('http://localhost:3000/search', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ query: query, display: 10 })
  });

  const data = await response.json();
  const items = data.items || [];

  // Convert Naver coordinates (mapx/mapy) to WGS84
  const results = items.map(item => ({
    name: item.title.replace(/<[^>]*>/g, ''),
    address: item.roadAddress || item.address,
    latitude: parseInt(item.mapy) / 10000000.0,
    longitude: parseInt(item.mapx) / 10000000.0,
    category: item.category
  }));

  return results;
};
```

**Key Points**:
- Uses `fetch` API for HTTP requests
- Converts Naver's integer coordinates to WGS84 decimal
- Removes HTML tags from place names
- Returns standardized format matching mobile implementation

### 3. Flutter Widget Update

**File**: `/Users/leechanhee/todo_app/lib/presentation/widgets/location_picker_dialog.dart`

**Change**: Removed `if (!kIsWeb)` check (line 369)

**Before**:
```dart
// Search bar (only available on mobile due to CORS restrictions on web)
if (!kIsWeb)
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: TextField(
```

**After**:
```dart
// Search bar (uses proxy server on web to bypass CORS)
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: TextField(
```

## API Credentials

### Naver Developers API
- **Client ID**: `quSL_7O8Nb5bh6hK4Kj2`
- **Client Secret**: `raJroLJaYw`
- **Purpose**: Local Search API (장소 검색)
- **URL**: https://developers.naver.com/

### Naver Cloud Platform (NCP)
- **Client ID**: `rzx12utf2x`
- **Client Secret**: `TWErCJbPnbFflibumhN3MfjJSz1tDsKXqX5Vff1C`
- **Purpose**: Maps API (지도 표시)
- **URL**: https://console.naver.com/ncloud/

**Important**: These are TWO SEPARATE API systems!
- Use **Naver Developers** for search
- Use **NCP** for maps display

## Coordinate Conversion

Naver Local Search API returns coordinates in a custom format:
- `mapx`: Longitude * 10,000,000 (integer)
- `mapy`: Latitude * 10,000,000 (integer)

**Conversion to WGS84**:
```javascript
const longitude = parseInt(item.mapx) / 10000000.0;
const latitude = parseInt(item.mapy) / 10000000.0;
```

**Example**:
- `mapx: 1269780493` → `126.9780493` (longitude)
- `mapy: 375672475` → `37.5672475` (latitude)

## Testing

### Test Page
**File**: `/tmp/test_naver_proxy.html`

Features:
- Tests proxy server connection
- Shows real-time console logs
- Displays search results with coordinates
- Auto-runs search on page load (3-second delay)

**Usage**:
```bash
open /tmp/test_naver_proxy.html
```

### Expected Results
Query: "스타벅스"
- Should return 5-10 results
- Each result should have:
  - Name (without HTML tags)
  - Address (도로명주소 or 지번주소)
  - Category (카페,디저트>카페)
  - Coordinates (WGS84 format)

## Production Deployment

### Option 1: Supabase Edge Function (Recommended)

**File**: `/Users/leechanhee/todo_app/supabase/functions/naver-search/index.ts`

**Deployment**:
```bash
# Install Supabase CLI
brew install supabase/tap/supabase

# Link project
supabase link --project-ref <project-id>

# Deploy function
supabase functions deploy naver-search
```

**Update naver_map_bridge.js**:
```javascript
const response = await fetch('https://<project-id>.supabase.co/functions/v1/naver-search', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer <anon-key>'
  },
  body: JSON.stringify({ query: query, display: 10 })
});
```

### Option 2: Custom Server

Deploy `naver_proxy.py` to:
- Vercel (Python serverless function)
- AWS Lambda (Python runtime)
- Google Cloud Functions
- Your own server

## Mobile Implementation (Reference)

**File**: `/Users/leechanhee/todo_app/lib/core/services/location_service.dart`

**Lines 420-436**: Mobile version makes direct API calls (no proxy needed)

```dart
Future<List<PlaceSearchResult>> _searchLocalAPI(String query) async {
  final url = Uri.parse(
    'https://openapi.naver.com/v1/search/local.json'
    '?query=${Uri.encodeComponent(query)}'
    '&display=10'
    '&start=1'
    '&sort=random',
  );

  final response = await http.get(
    url,
    headers: {
      'X-Naver-Client-Id': 'quSL_7O8Nb5bh6hK4Kj2',
      'X-Naver-Client-Secret': 'raJroLJaYw',
    },
  );
```

## Troubleshooting

### Proxy Server Not Running
**Symptom**: `Failed to fetch` error in browser console

**Solution**:
```bash
# Check if running
ps aux | grep naver_proxy.py

# Check port
lsof -i :3000

# Start if not running
cd /Users/leechanhee/todo_app
python3 naver_proxy.py
```

### CORS Error Despite Proxy
**Symptom**: CORS error when calling proxy

**Cause**: Proxy server not returning CORS headers

**Solution**: Verify `Access-Control-Allow-Origin: *` header in proxy response

### Empty Search Results
**Symptom**: Search returns empty array

**Possible Causes**:
1. Invalid API credentials
2. Query string encoding issue
3. Network connectivity problem

**Debug**:
```bash
# Test proxy directly
curl -X POST 'http://localhost:3000/search' \
  -H 'Content-Type: application/json' \
  -d '{"query":"test","display":5}'
```

### Coordinate Conversion Error
**Symptom**: Markers appear in wrong location

**Cause**: Incorrect division factor

**Solution**: Ensure dividing by `10000000.0` (7 zeros, not 6 or 8)

## Security Considerations

### API Keys in Code
- ⚠️ **Development**: Keys are in plaintext for ease of use
- 🔒 **Production**: Move to environment variables
- 📝 **Best Practice**: Use Supabase Edge Function with secrets

### CORS Headers
- **Development**: `Access-Control-Allow-Origin: *` (allow all)
- **Production**: Restrict to specific domain
- **Example**: `Access-Control-Allow-Origin: https://yourdomain.com`

### Rate Limiting
Naver API has rate limits:
- **Daily**: Check your plan limits
- **Per Second**: Implement client-side throttling

## Files Modified

1. ✅ `/Users/leechanhee/todo_app/web/naver_map_bridge.js` (lines 162-236)
   - Updated `searchNaverPlaces` to use proxy

2. ✅ `/Users/leechanhee/todo_app/lib/presentation/widgets/location_picker_dialog.dart` (line 369)
   - Removed `if (!kIsWeb)` check
   - Enabled search UI on web

3. ✅ `/Users/leechanhee/todo_app/naver_proxy.py` (NEW)
   - Created Python proxy server

4. ✅ `/Users/leechanhee/todo_app/supabase/functions/naver-search/index.ts` (NEW)
   - Created Supabase Edge Function template

5. ✅ `/tmp/test_naver_proxy.html` (NEW)
   - Created test page for verification

## Next Steps

1. **Test in Flutter Web App**:
   ```bash
   flutter run -d chrome
   # Open location picker dialog
   # Try searching for "스타벅스" or "카페"
   ```

2. **Deploy to Production**:
   - Deploy Supabase Edge Function
   - Update `naver_map_bridge.js` with production URL
   - Test with production domain

3. **Optional Enhancements**:
   - Add search result caching
   - Implement debouncing for search input
   - Add pagination for large result sets
   - Show search loading state

## Related Documentation

- [NAVER_MAPS_INTEGRATION.md](NAVER_MAPS_INTEGRATION.md) - Main integration guide
- [GOOGLE_PLACES_NEW_API_SETUP.md](GOOGLE_PLACES_NEW_API_SETUP.md) - Google API attempt (failed)
- Naver Developers Docs: https://developers.naver.com/docs/serviceapi/search/local/local.md

## Changelog

### 2025-11-20
- ✅ Created Python proxy server
- ✅ Updated naver_map_bridge.js to use proxy
- ✅ Tested proxy with curl (successful)
- ✅ Removed kIsWeb check from location_picker_dialog.dart
- ✅ Created test page for verification
- ✅ Documented complete implementation
