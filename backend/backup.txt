const fs = require('fs');
const path = require('path');
const express = require('express');
const Epub = require('epub-gen');
const { Document, Packer, Paragraph, TextRun } = require('docx');
const { JSDOM } = require("jsdom"); // Thêm JSDOM để xử lý HTML

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
        const sanitizedTitle = title.replace(/[^a-zA-Z0-9]/g, '_');
        const outputPath = path.join(outputDir, `${sanitizedTitle}.epub`);

        const formattedChapters = chapters.map(chapter => ({
            title: chapter.title,
            data: chapter.content.replace(/\n/g, "<br>\n") // 🟢 Đảm bảo xuống dòng đúng format
        }));

        const options = {
            title,
            author: 'Epub Generator',
            output: outputPath,
            content: formattedChapters,
        };

        await new Epub(options).promise;
        res.json({ message: 'EPUB generated successfully', filePath: outputPath });
    } catch (error) {
        console.error('Error generating EPUB:', error);
        res.status(500).json({ error: 'Failed to generate EPUB', details: error.message });
    }
});

// 🟢 Cải tiến: Giữ format HTML khi tạo DOCX
router.post('/generate-word', async (req, res) => {
    const { title, chapters } = req.body;

    if (!title || !chapters || !Array.isArray(chapters)) {
        return res.status(400).json({ error: 'Invalid data for Word generation' });
    }

    try {
        const sanitizedTitle = title.replace(/[^a-zA-Z0-9]/g, '_');
        const outputPath = path.join(outputDir, `${sanitizedTitle}.docx`);
        const docContent = [];

        chapters.forEach((chapter) => {
            const dom = new JSDOM(chapter.content);
            const document = dom.window.document;

            // 🟢 Thêm tiêu đề chương
            docContent.push(new Paragraph({
                children: [new TextRun({ text: chapter.title, bold: true, size: 26 })],
            }));

            document.body.childNodes.forEach((node) => {
                let paragraph;
                if (node.nodeType === 1) {
                    switch (node.tagName.toLowerCase()) {
                        case "h1":
                            paragraph = new Paragraph({ text: node.textContent, heading: "Heading1" });
                            break;
                        case "h2":
                            paragraph = new Paragraph({ text: node.textContent, heading: "Heading2" });
                            break;
                        case "p":
                            paragraph = new Paragraph({ text: node.textContent });
                            break;
                        case "b":
                            paragraph = new Paragraph({ children: [new TextRun({ text: node.textContent, bold: true })] });
                            break;
                        case "i":
                            paragraph = new Paragraph({ children: [new TextRun({ text: node.textContent, italics: true })] });
                            break;
                        case "ul":
                            node.querySelectorAll("li").forEach(li => {
                                docContent.push(new Paragraph({ text: "• " + li.textContent }));
                            });
                            return;
                        case "img":
                            paragraph = new Paragraph({ text: `[Image: ${node.getAttribute("src")}]` });
                            break;
                        default:
                            paragraph = new Paragraph({ text: node.textContent });
                    }
                    docContent.push(paragraph);
                }
            });

            // 🟢 Thêm dấu xuống dòng giữa các chương
            docContent.push(new Paragraph({ children: [new TextRun({ text: "", break: 1 })] }));
        });

        const doc = new Document({ sections: [{ children: docContent }] });
        const buffer = await Packer.toBuffer(doc);
        fs.writeFileSync(outputPath, buffer);

        res.json({ message: 'Word file generated successfully', filePath: outputPath });
    } catch (error) {
        console.error('Error generating Word file:', error);
        res.status(500).json({ error: 'Failed to generate Word file', details: error.message });
    }
});

module.exports = router;
