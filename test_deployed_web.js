const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();

  console.log('Navigating to deployed web app...');
  await page.goto('https://bluesky78060.github.io/flutter-todo/');

  // Wait for Flutter to load
  console.log('Waiting for Flutter app to load...');
  await page.waitForTimeout(5000);

  // Take screenshot
  await page.screenshot({ path: '/Users/leechanhee/todo_app/deployed_web_screenshot.png', fullPage: true });
  console.log('Screenshot saved: deployed_web_screenshot.png');

  // Keep browser open for 30 seconds for manual inspection
  console.log('Browser will stay open for 30 seconds for manual inspection...');
  await page.waitForTimeout(30000);

  await browser.close();
  console.log('Test completed');
})();
