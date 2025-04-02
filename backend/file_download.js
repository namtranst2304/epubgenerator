const fs = require('fs');
const path = require('path');
const express = require('express');
const Epub = require('epub-gen');

const router = express.Router();

// 🟢 Cải tiến: Kiểm tra và tạo thư mục lưu trữ
const outputDir = path.join(__dirname, 'output');
if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir);
}

// 🟢 Endpoint tải xuống file
router.get('/download', (req, res) => {
    const { filePath } = req.query;

    if (!filePath || !fs.existsSync(filePath)) {
        return res.status(404).json({ error: 'File not found' });
    }

    res.download(filePath, (err) => {
        if (err) console.error('Error sending file:', err);
    });
});

// 🟢 Cải tiến: Giữ format HTML khi tạo EPUB
router.post('/generate-epub', async (req, res) => {
    const { title, chapters } = req.body;

    if (!title || !chapters || !Array.isArray(chapters)) {
        return res.status(400).json({ error: 'Invalid data for EPUB generation' });
    }

    try {
        // Sanitize the title to create a valid filename
        const sanitizedTitle = title.replace(/[^a-zA-Z0-9]/g, '_');
        const outputPath = path.join(outputDir, `${sanitizedTitle}.epub`);

        const formattedChapters = chapters.map(chapter => ({
            title: chapter.title,
            data: chapter.content.replace(/\n/g, "<br>\n") // Ensure correct line breaks
        }));

        const options = {
            title,
            author: 'Epub Generator',
            output: outputPath,
            content: formattedChapters,
        };

        await new Epub(options).promise;
        res.json({ 
            message: 'EPUB generated successfully', 
            filePath: outputPath,        // 🔹 Đường dẫn đầy đủ (cho việc tải xuống)
        });
        
    } catch (error) {
        console.error('Error generating EPUB:', error);
        res.status(500).json({ error: 'Failed to generate EPUB', details: error.message });
    }
});

module.exports = router;
