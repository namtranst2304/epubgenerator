const puppeteer = require('puppeteer-extra');
const express = require('express');
const cors = require('cors'); // Import CORS middleware
const StealthPlugin = require('puppeteer-extra-plugin-stealth'); // Import Stealth Plugin
const RecaptchaPlugin = require('puppeteer-extra-plugin-recaptcha'); // Import Recaptcha Plugin

puppeteer.use(StealthPlugin()); // Use Stealth Plugin
puppeteer.use(
  RecaptchaPlugin({
    provider: {
      id: '2captcha',
      token: 'YOUR_2CAPTCHA_API_KEY', // Replace with your 2Captcha API key
    },
    visualFeedback: true, // Show visual feedback for solving captchas
  })
);

const app = express();
app.use(express.json());
app.use(cors()); // Enable CORS for all routes

// Endpoint to scrape content using Puppeteer
app.post('/scrape', async (req, res) => {
  const { url } = req.body;

  if (!url) {
    return res.status(400).json({ error: 'URL là bắt buộc' });
  }

  try {
    const browser = await puppeteer.launch({ headless: true });
    const page = await browser.newPage();

    // Đặt user agent để giả lập trình duyệt thật
    await page.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, như Gecko) Chrome/110.0.0.0 Safari/537.36'
    );

    // Điều hướng đến URL
    console.log(`Đang điều hướng đến URL: ${url}`);
    await page.goto(url, { waitUntil: 'networkidle2', timeout: 60000 }); // Tăng timeout lên 60 giây

    // Giải quyết captcha nếu có
    const { captchas, solved, error } = await page.solveRecaptchas();
    if (error) {
      console.error('Giải captcha thất bại:', error);
    } else {
      console.log('Captcha đã được giải:', solved);
    }

    // Lấy nội dung trang
    const content = await page.content();

    // Log nội dung để kiểm tra
    console.log('Nội dung HTML đã lấy:', content);

    // Kiểm tra nếu nội dung chứa trang xác minh của Cloudflare
    if (content.includes('Just a moment...') || content.includes('Verifying you are human')) {
      console.error('Phát hiện trang xác minh của Cloudflare. Không thể lấy nội dung.');
      throw new Error('Phát hiện trang xác minh của Cloudflare.');
    }

    await browser.close();

    // Thêm header CORS vào phản hồi
    res.set('Access-Control-Allow-Origin', '*');
    res.json({ content });
  } catch (error) {
    console.error('Lỗi khi scrape URL:', error); // Log lỗi
    res.status(500).json({ error: `Không thể scrape URL: ${error.message}`, stack: error.stack });
  }
});

// Start the server
const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Puppeteer scraper running on http://localhost:${PORT}`);
});
