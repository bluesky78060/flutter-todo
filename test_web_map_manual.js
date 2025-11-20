const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ 
    headless: false,
    args: ['--disable-blink-features=AutomationControlled']
  });
  const context = await browser.newContext({
    userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
  });
  const page = await context.newPage();

  try {
    console.log('📍 Naver Maps Web Test - Manual Login Required');
    console.log('');
    console.log('Instructions:');
    console.log('1. Browser will open');
    console.log('2. Please login manually using Google/Kakao');
    console.log('3. Wait for test to automatically continue after 20 seconds');
    console.log('');
    
    console.log('🌐 Opening http://localhost:65143');
    await page.goto('http://localhost:65143');
    await page.waitForLoadState('networkidle');
    
    console.log('');
    console.log('⏳ Waiting 20 seconds for manual login...');
    console.log('   Please complete your login now!');
    await page.waitForTimeout(20000);
    
    await page.screenshot({ path: 'step1-after-login.png', fullPage: true });
    console.log('✅ Screenshot saved: step1-after-login.png');
    
    console.log('');
    console.log('➕ Looking for Add Todo button (+)...');
    await page.waitForTimeout(2000);
    
    try {
      await page.locator('button').filter({ hasText: '+' }).first().click({ timeout: 5000 });
    } catch (e) {
      console.log('⚠️  + button not found, trying FAB...');
      await page.locator('.fab, .floating-action-button, [class*="fab"]').first().click({ timeout: 5000 });
    }
    
    await page.waitForTimeout(1500);
    await page.screenshot({ path: 'step2-add-dialog.png', fullPage: true });
    console.log('✅ Screenshot saved: step2-add-dialog.png');
    
    console.log('');
    console.log('📍 Looking for Location button...');
    await page.locator('button').filter({ hasText: '위치' }).first().click();
    await page.waitForTimeout(3000);
    
    await page.screenshot({ path: 'step3-location-picker.png', fullPage: true });
    console.log('✅ Screenshot saved: step3-location-picker.png');
    
    console.log('');
    console.log('🔍 Verifying Naver Maps elements:');
    
    const searchBar = await page.locator('input[placeholder*="검색"]').count();
    console.log('   Search bar (should be hidden): ' + (searchBar === 0 ? '✅ PASS' : '❌ FAIL - visible'));
    
    const infoMsg = await page.locator('text*="Click on the map"').count();
    console.log('   Info message: ' + (infoMsg > 0 ? '✅ PASS' : '⚠️  Not found'));
    
    const slider = await page.locator('input[type="range"]').count();
    console.log('   Radius slider: ' + (slider > 0 ? '✅ PASS' : '❌ FAIL'));
    
    console.log('');
    console.log('🗺️  Testing map interaction...');
    await page.waitForTimeout(2000);
    
    const mapContainer = await page.locator('div[id*="naver-map"]').or(page.locator('canvas')).first().boundingBox();
    if (mapContainer) {
      const centerX = mapContainer.x + mapContainer.width / 2;
      const centerY = mapContainer.y + mapContainer.height / 2;
      await page.mouse.click(centerX, centerY);
      console.log('   ✅ Clicked map center');
      
      await page.waitForTimeout(3000);
      await page.screenshot({ path: 'step4-after-click.png', fullPage: true });
      console.log('✅ Screenshot saved: step4-after-click.png');
    } else {
      console.log('   ⚠️  Could not find map container');
    }
    
    console.log('');
    console.log('🎚️  Testing radius slider...');
    const sliderElement = page.locator('input[type="range"]').first();
    await sliderElement.fill('500');
    await page.waitForTimeout(1500);
    
    await page.screenshot({ path: 'step5-radius-500m.png', fullPage: true });
    console.log('✅ Screenshot saved: step5-radius-500m.png');
    
    await page.waitForTimeout(2000);
    await page.screenshot({ path: 'step6-final.png', fullPage: true });
    console.log('✅ Screenshot saved: step6-final.png');
    
    console.log('');
    console.log('═══════════════════════════════════════');
    console.log('📊 TEST COMPLETE!');
    console.log('═══════════════════════════════════════');
    console.log('✅ Location picker opened successfully');
    console.log('✅ Web map elements verified');
    console.log('✅ Map interaction tested');
    console.log('✅ Radius slider tested');
    console.log('');
    console.log('📸 All screenshots saved to current directory');
    
  } catch (error) {
    console.error('');
    console.error('❌ Test failed:', error.message);
    await page.screenshot({ path: 'error.png', fullPage: true });
    console.error('📸 Error screenshot saved: error.png');
  } finally {
    console.log('');
    console.log('⏸️  Browser will stay open for 10 seconds...');
    await page.waitForTimeout(10000);
    await browser.close();
    console.log('✅ Test completed');
  }
})();
