const express = require("express");
const router = express.Router();
const path = require("path");
const multer = require("multer");
const authMiddleware = require("../middleware/auth.middleware");
const fs = require("fs");

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
  const dir = path.join(__dirname, "../../uploads/dprs");

  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }

  cb(null, dir);
},
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, `dpr_${Date.now()}${ext}`);
  },
});

const upload = multer({
  storage,
  fileFilter: (req, file, cb) => {
    if (file.mimetype === "application/pdf") cb(null, true);
    else cb(new Error("Only PDF allowed"), false);
  },
  limits: { fileSize: 20 * 1024 * 1024 },
});

// ✅ POST /api/upload/dpr
router.post("/dpr", authMiddleware, upload.single("pdf"), (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ message: "PDF file missing" });

    const fileUrl = `http://10.0.2.2:5000/uploads/dprs/${req.file.filename}`;


    return res.json({
      message: "PDF uploaded ✅",
      fileUrl,
    });
  } catch (err) {
    console.error("UPLOAD PDF ERROR:", err);
    res.status(500).json({ message: "Server error" });
  }
});
router.use((err, req, res, next) => {
  if (err) {
    return res.status(400).json({ message: err.message || "Upload error" });
  }
  next();
});


module.exports = router;
