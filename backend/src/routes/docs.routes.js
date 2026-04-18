const express = require("express");
const router = express.Router();

const authMiddleware = require("../middleware/auth.middleware");
const upload = require("../middleware/uploadPdf.middleware");
const docsController = require("../controllers/docs.controller");

// ✅ all docs list
router.get("/:projectId", authMiddleware, docsController.getProjectDocs);

// ✅ single doc
router.get("/:projectId/single", authMiddleware, docsController.getSingleDoc);

// ✅ manual upload rera/iod/cc
router.post(
  "/:projectId/upload",
  authMiddleware,
  upload.single("pdf"),
  docsController.manualUploadDoc
);

// ✅ delete rera/iod/cc
router.delete("/:projectId/manual", authMiddleware, docsController.deleteManualDoc);

// ✅ generate auto docs
router.post(
  "/:projectId/generate",
  authMiddleware,
  upload.single("pdf"),
  docsController.generateDoc
);

router.get(
  "/:projectId/manual-url",
  authMiddleware,
  docsController.getManualSignedUrl
);
router.get("/:projectId/auto-url", authMiddleware, docsController.getAutoSignedUrl);

module.exports = router;
