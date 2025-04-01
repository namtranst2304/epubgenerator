const express = require('express');
const cors = require('cors');
const { Builder, By, until } = require('selenium-webdriver');
const chrome = require('selenium-webdriver/chrome');
const { SessionNotCreatedError, NoSuchSessionError, WebDriverError } = require('selenium-webdriver/lib/error');
const fileDownloadRoutes = require('./file_download'); // Import the download and generation routes

require('chromedriver');

const app = express();
app.use(express.json({ limit: '50mb' })); // Increase the limit to 50MB
app.use(express.urlencoded({ limit: '50mb', extended: true })); // Increase the limit for URL-encoded data
app.use(cors()); // Allow all origins

let driver = null;
let initializing = false;

// Check if the Selenium driver is valid
async function isDriverValid(currentDriver) {
  try {
    await currentDriver.getTitle(); // Try to get the title of the current page
    return true;
  } catch (error) {
    console.error("⚠️ Driver is invalid:", error.message);
    return false;
  }
}

// Initialize the Selenium driver
async function getDriver() {
  if (driver) {
    const valid = await isDriverValid(driver);
    if (!valid) {
      console.log("🔄 Driver is invalid, reinitializing...");
      await driver.quit().catch(() => {}); // Close the browser if the session exists
      driver = null;
    }
  }

  if (!driver && !initializing) {
    initializing = true;
    console.log("🚀 Launching a new browser...");
    let options = new chrome.Options();
    options.addArguments(
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-dev-shm-usage',
      '--disable-blink-features=AutomationControlled'
    );

    driver = await new Builder()
      .forBrowser('chrome')
      .setChromeOptions(options)
      .build();

    initializing = false;
  }

  while (initializing) {
    await new Promise(r => setTimeout(r, 200)); // Wait until the browser is ready
  }

  return driver;
}

// Scrape the content of a page
async function scrapeContent(url) {
  const driver = await getDriver();
  try {
    console.log(`🌐 Navigating to URL: ${url}`);
    await driver.get(url);

    // Hide the webdriver property to avoid detection
    await driver.executeScript(() => {
      Object.defineProperty(navigator, 'webdriver', { get: () => false });
    });

    // Wait for the page to load completely
    await driver.wait(until.elementLocated(By.tagName('body')), 10000);

    // Get the page source
    const content = await driver.getPageSource();
    return content;
  } catch (error) {
    console.error("❌ Error while loading the page:", error);
    throw error;
  }
}

// Endpoint to handle scrape requests
app.post('/scrape', async (req, res) => {
  const { url } = req.body;
  if (!url || typeof url !== 'string') {
    return res.status(400).json({ error: 'Invalid URL' });
  }

  try {
    const content = await scrapeContent(url);
    res.json({ content });
  } catch (error) {
    if (
      error instanceof SessionNotCreatedError ||
      error instanceof NoSuchSessionError ||
      error instanceof WebDriverError
    ) {
      console.error("⚠️ Browser was unexpectedly closed. Restarting...");
      driver = null; // Reset the driver for the next request
    }
    res.status(500).json({ error: "Unable to scrape URL", details: error.message });
  }
});

// Endpoint to check the browser status
app.get('/status', async (req, res) => {
  const isValid = driver ? await isDriverValid(driver) : false;
  res.json({ status: isValid ? "Browser is running" : "No active browser" });
});

// Endpoint to close the browser (if needed)
app.post('/close-browser', async (req, res) => {
  if (driver) {
    console.log("🛑 Closing the browser...");
    await driver.quit();
    driver = null;
    res.json({ message: "Browser has been closed." });
  } else {
    res.json({ message: "No browser is currently running." });
  }
});

// Use the file download and generation routes
app.use(fileDownloadRoutes);

// Listen on port 3000
const PORT = 3000;
app.listen(PORT, () => {
  console.log(`🚀 Server is running at http://localhost:${PORT}`);
});