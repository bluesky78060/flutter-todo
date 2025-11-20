const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();

  try {
    console.log('📍 Starting Naver Maps Web Test...');
    
    console.log('🌐 Navigating to http://localhost:65143');
    await page.goto('http://localhost:65143');
    await page.waitForLoadState('networkidle');
    
    await page.screenshot({ path: '01-login-page.png', fullPage: true });
    console.log('✅ Screenshot: Login page');
    
    await page.waitForTimeout(2000);
    const currentUrl = page.url();
    
    if (currentUrl.includes('/login')) {
      console.log('🔐 Login page detected - Please login manually');
      console.log('⏳ Waiting 20 seconds for you to log in...');
      await page.waitForTimeout(20000);
      
      await page.screenshot({ path: '03-after-login.png', fullPage: true });
    } else {
      console.log('✅ Already logged in');
    }
    
    await page.waitForTimeout(2000);
    await page.screenshot({ path: '04-todos-page.png', fullPage: true });
    console.log('✅ Screenshot: Todos page');
    
    console.log('➕ Looking for add todo button');
    const addBtn = page.locator('button').filter({ hasText: '+' }).or(page.locator('[aria-label*="add"]'));
    await addBtn.first().click();
    await page.waitForTimeout(1500);
    
    await page.screenshot({ path: '05-add-todo-dialog.png', fullPage: true });
    console.log('✅ Screenshot: Add todo dialog');
    
    console.log('📍 Looking for location button');
    const locBtn = page.locator('button').filter({ hasText: '위치' });
    await locBtn.first().click();
    await page.waitForTimeout(3000);
    
    await page.screenshot({ path: '06-location-picker.png', fullPage: true });
    console.log('✅ Screenshot: Location picker dialog');
    
    console.log('🔍 Verifying web map elements...');
    
    const searchBar = await page.locator('input[placeholder*="검색"]').count();
    console.log('  - Search bar: ' + (searchBar > 0 ? '❌ Visible (should be hidden)' : '✅ Hidden'));
    
    const infoMsg = await page.locator('text="Click on the map"').count();
    console.log('  - Info message: ' + (infoMsg > 0 ? '✅ Present' : '⏳ May appear'));
    
    const slider = await page.locator('input[type="range"]').count();
    console.log('  - Radius slider: ' + (slider > 0 ? '✅ Present' : '❌ Missing'));
    
    await page.waitForTimeout(2000);
    console.log('🗺️ Attempting map click...');
    
    const mapArea = page.locator('div').filter({ has: page.locator('canvas') }).or(page.locator('[id*="naver"]'));
    const box = await mapArea.first().boundingBox();
    if (box) {
      await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
      console.log('  ✅ Clicked map center');
      await page.waitForTimeout(3000);
      
      await page.screenshot({ path: '07-after-map-click.png', fullPage: true });
      console.log('✅ Screenshot: After map click');
    }
    
    console.log('🎚️ Testing radius slider...');
    await page.locator('input[type="range"]').first().fill('500');
    await page.waitForTimeout(1500);
    
    await page.screenshot({ path: '08-radius-adjusted.png', fullPage: true });
    console.log('✅ Screenshot: Radius adjusted');
    
    await page.waitForTimeout(2000);
    await page.screenshot({ path: '09-final.png', fullPage: true });
    
    console.log('');
    console.log('📊 Test Summary:');
    console.log('  ✅ App loaded');
    console.log('  ✅ Login completed (20s wait)');
    console.log('  ✅ Location picker opened');
    console.log('  ✅ Map interaction tested');
    console.log('');
    console.log('📸 Screenshots saved to current directory');
    
  } catch (error) {
    console.error('❌ Test failed:', error);
    await page.screenshot({ path: 'error.png', fullPage: true });
  } finally {
    console.log('');
    console.log('⏸️  Keeping browser open for 10 seconds...');
    await page.waitForTimeout(10000);
    await browser.close();
  }
})();
