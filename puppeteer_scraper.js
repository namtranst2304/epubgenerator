const puppeteer = require('puppeteer-extra');
const express = require('express');
const cors = require('cors'); // Import CORS middleware
const StealthPlugin = require('puppeteer-extra-plugin-stealth'); // Import Stealth Plugin
const AdblockerPlugin = require('puppeteer-extra-plugin-adblocker'); // Import Adblocker Plugin
const { Cluster } = require('puppeteer-cluster'); // Import Puppeteer Cluster

const stealth = StealthPlugin();
stealth.enabledEvasions.delete('iframe.contentWindow'); // Disable iframe.contentWindow evasion
puppeteer.use(stealth); // Use Stealth Plugin
puppeteer.use(AdblockerPlugin({ blockTrackers: true })); // Use Adblocker Plugin

const app = express();
app.use(express.json());
app.use(cors()); // Enable CORS for all routes

// Initialize Puppeteer Cluster
let cluster;
(async () => {
  cluster = await Cluster.launch({
    concurrency: Cluster.CONCURRENCY_CONTEXT,
    maxConcurrency: 2, // Adjust based on your system's resources
    puppeteerOptions: {
      headless: true,
      args: ['--no-sandbox', '--disable-setuid-sandbox', '--proxy-server=http://your-proxy-server:port'], // Add arguments for compatibility
    },
  });

  cluster.on('taskerror', (err, data) => {
    console.error(`Error crawling ${data}: ${err.message}`);
  });
})();

// Helper function to scrape content
async function scrapeContent(url) {
  return await cluster.execute(async ({ page }) => {
    // Set headers to mimic real browser behavior
    await page.setExtraHTTPHeaders({
      'Accept-Language': 'en-US,en;q=0.9',
      Referer: url,
    });

    // Set user agent to mimic a real browser
    await page.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, như Gecko) Chrome/110.0.0.0 Safari/537.36'
    );

    // Navigate to the URL
    console.log(`Navigating to URL: ${url}`);
    await page.goto(url, { waitUntil: 'networkidle2', timeout: 60000 });

    // Check for Cloudflare verification
    const content = await page.content();
    if (content.includes('Just a moment...') || content.includes('Verifying you are human')) {
      throw new Error('Phát hiện trang xác minh của Cloudflare.');
    }

    return content;
  });
}

// Endpoint to scrape content using Puppeteer
app.post('/scrape', async (req, res) => {
  const { url } = req.body;

  if (!url) {
    return res.status(400).json({ error: 'URL là bắt buộc' });
  }

  try {
    const content = await scrapeContent(url);
    console.log('Scraped content:', content);

    // Add CORS header to response
    res.set('Access-Control-Allow-Origin', '*');
    res.json({ content });
  } catch (error) {
    console.error('Error scraping URL:', error);
    res.status(500).json({ error: `Không thể scrape URL: ${error.message}`, stack: error.stack });
  }
});

// Start the server
const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Puppeteer scraper running on http://localhost:${PORT}`);
});
