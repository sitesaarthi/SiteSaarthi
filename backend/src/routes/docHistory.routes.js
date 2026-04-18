const express = require("express");
const router = express.Router();

const authMiddleware = require("../middleware/auth.middleware");
const upload = require("../middleware/uploadPdf.middleware");
const ctrl = require("../controllers/docHistory.controller");

// ✅ Purchase Orders
router.post(
  "/:projectId/purchase-orders",
  authMiddleware,
  upload.single("pdf"),
  ctrl.createPurchaseOrder
);

router.get(
  "/:projectId/purchase-orders",
  authMiddleware,
  ctrl.getPurchaseOrders
);

router.get(
  "/purchase-orders/:poId/url",
  authMiddleware,
  ctrl.getPoSignedUrl
);

// ✅ GST Invoices
router.post(
  "/:projectId/gst-invoices",
  authMiddleware,
  upload.single("pdf"),
  ctrl.createGstInvoice
);

router.get(
  "/:projectId/gst-invoices",
  authMiddleware,
  ctrl.getGstInvoices
);

router.get(
  "/gst-invoices/:gstId/url",
  authMiddleware,
  ctrl.getGstSignedUrl
);

// 🔥 SUBMIT PURCHASE ORDER FOR OWNER APPROVAL
router.patch(
  "/purchase-orders/:poId/submit",
  authMiddleware,
  ctrl.submitPurchaseOrder
);


module.exports = router;
