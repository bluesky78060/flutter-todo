// 웹 브라우저 콘솔에서 실행할 디버깅 코드
// 1. window.ENV 확인
console.log('=== ENV CHECK ===');
console.log('SUPABASE_URL:', window.ENV?.SUPABASE_URL);
console.log('SUPABASE_ANON_KEY:', window.ENV?.SUPABASE_ANON_KEY);

// 2. Supabase 초기화 상태 확인
console.log('\n=== SUPABASE CLIENT CHECK ===');
if (window.Supabase) {
  console.log('Supabase client exists');
} else {
  console.log('Supabase client not found');
}

// 3. 현재 URL 정보
console.log('\n=== CURRENT URL ===');
console.log('Origin:', window.location.origin);
console.log('Pathname:', window.location.pathname);
console.log('Hash:', window.location.hash);
console.log('Full URL:', window.location.href);

// 4. OAuth Redirect URL 계산
const origin = window.location.origin;
const pathname = window.location.pathname || '/';
const pathParts = pathname.split('/').filter(p => p.length > 0);
const basePath = pathParts.length > 0 ? '/' + pathParts[0] : '';
const redirectUrl = origin + basePath + '/#/oauth-callback';
console.log('\n=== CALCULATED REDIRECT URL ===');
console.log('Redirect URL:', redirectUrl);

// 5. 직접 Supabase Auth 테스트
console.log('\n=== TEST SUPABASE AUTH ===');
async function testSupabaseAuth() {
  try {
    const response = await fetch('https://bulwfcsyqgsvmbadhlye.supabase.co/auth/v1/settings', {
      headers: {
        'apikey': window.ENV?.SUPABASE_ANON_KEY || 'NO_KEY'
      }
    });
    console.log('Auth settings response:', response.status);
    if (response.ok) {
      const data = await response.json();
      console.log('Auth settings:', data);
    } else {
      console.log('Auth settings error:', await response.text());
    }
  } catch (error) {
    console.error('Auth test error:', error);
  }
}

testSupabaseAuth();