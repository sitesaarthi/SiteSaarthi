const multer = require("multer");

const upload = multer({
  storage: multer.memoryStorage(), // ✅ keeps file in req.file.buffer
  limits: { fileSize: 15 * 1024 * 1024 }, // 15MB
  fileFilter: (_, file, cb) => {
    const name = (file.originalname || "").toLowerCase();

    const isPdfMime =
      file.mimetype === "application/pdf" ||
      file.mimetype === "application/x-pdf" ||
      file.mimetype === "application/octet-stream";

    const isPdfExt = name.endsWith(".pdf");

    if (isPdfMime || isPdfExt) cb(null, true);
    else cb(new Error("Only PDF allowed"), false);
  },
});

module.exports = upload;
