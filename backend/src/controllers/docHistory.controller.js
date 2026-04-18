const Project = require("../models/Project.model");
const PurchaseOrderDoc = require("../models/PurchaseOrderDoc.model");
const GstInvoiceDoc = require("../models/GstInvoiceDoc.model");
const ApprovalRequest = require("../models/ApprovalRequest.model");
const { createDocHistory } = require("../services/docHistory.service");


const { uploadPdfToS3 } = require("../utils/s3");

const { GetObjectCommand, S3Client } = require("@aws-sdk/client-s3");
const { getSignedUrl } = require("@aws-sdk/s3-request-presigner");

// ✅ single S3 client
const s3 = new S3Client({
  region: process.env.AWS_REGION,
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  },
});

// ✅ one sign helper only
const signS3Url = async (s3Url) => {
  const raw = s3Url.replace("s3://", "");
  const parts = raw.split("/");
  const bucket = parts.shift();
  const key = parts.join("/");

  return getSignedUrl(
    s3,
    new GetObjectCommand({
      Bucket: bucket,
      Key: key,
      ResponseContentDisposition: "inline",
      ResponseContentType: "application/pdf",
    }),
    { expiresIn: 60 * 5 }
  );
};

/// ============================================================
/// ✅ PURCHASE ORDER
/// ============================================================

exports.createPurchaseOrder = async (req, res) => {
  try {
    const { projectId } = req.params;
    const engineerId = req.user.userId;

    if (req.user.role !== "ENGINEER") {
      return res.status(403).json({ message: "Only ENGINEER can create PO" });
    }

    const { poNumber, vendor, issueDate, deliveryDate, totalAmount } = req.body;

    if (!req.file) {
      return res.status(400).json({ message: "PDF missing" });
    }

    const project = await Project.findById(projectId);
    if (!project) {
      return res.status(404).json({ message: "Project not found" });
    }

    const s3Url = await uploadPdfToS3({
      file: req.file,
      projectId,
      key: poNumber,
      folder: "purchase_orders",
    });

    const po = await PurchaseOrderDoc.create({
      projectId,
      engineerId,
      ownerId: project.ownerId,
      poNumber,
      vendor,
      issueDate,
      deliveryDate,
      totalAmount: Number(totalAmount || 0),
      s3Url,
      status: "DRAFT",
    });

    await createDocHistory({
      docType: "PO",
      docId: po._id,
      action: "CREATED",
      performedBy: engineerId,
      role: "ENGINEER",
    });

    return res.status(201).json({ message: "PO created", po });
  } catch (e) {
    console.error("createPurchaseOrder err:", e);
    return res.status(500).json({ message: "Server error" });
  }
};
exports.submitPurchaseOrder = async (req, res) => {
  try {
    const { poId } = req.params;
    const engineerId = req.user.userId;

    if (req.user.role !== "ENGINEER") {
      return res.status(403).json({ message: "Only ENGINEER can submit PO" });
    }

    const po = await PurchaseOrderDoc.findById(poId);
    if (!po) return res.status(404).json({ message: "PO not found" });

    if (String(po.engineerId) !== String(engineerId)) {
      return res.status(403).json({ message: "Not allowed" });
    }

    if (po.status !== "DRAFT" && po.status !== "REJECTED") {
      return res.status(400).json({ message: "PO cannot be submitted" });
    }

    const existingApproval = await ApprovalRequest.findOne({
      poId: po._id,
      status: "pending",
    });

    if (existingApproval) {
      return res.status(400).json({ message: "Already submitted" });
    }

    po.status = "SUBMITTED";
    await po.save();

    await ApprovalRequest.create({
      type: "MATERIAL",
      projectId: po.projectId,
      requestedBy: engineerId,
      poId: po._id,
      title: "Purchase Order Approval",
      status: "pending",
    });

    return res.json({ message: "PO submitted for approval" });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ message: "Server error" });
  }
};



exports.getPurchaseOrders = async (req, res) => {
  try {
    const { projectId } = req.params;
    const userId = req.user.userId;
    const role = req.user.role;

    const project = await Project.findById(projectId).lean();
    if (!project) {
      return res.status(404).json({ message: "Project not found" });
    }

    let filter = { projectId };

    if (role === "ENGINEER") {
      filter.engineerId = userId;
    } else if (role === "OWNER") {
      filter.ownerId = userId;
    } else {
      return res.status(403).json({ message: "Access denied" });
    }

    const list = await PurchaseOrderDoc.find(filter)
      .sort({ createdAt: -1 })
      .lean();

    return res.json({ purchaseOrders: list });
  } catch (e) {
    console.error("getPurchaseOrders err:", e);
    return res.status(500).json({ message: "Server error" });
  }
};

exports.getPoSignedUrl = async (req, res) => {
  try {
    const userId = req.user.userId;

    const po = await PurchaseOrderDoc.findById(req.params.poId).lean();
    if (!po) return res.status(404).json({ message: "Not found" });

    const project = await Project.findById(po.projectId).lean();
    if (!project) return res.status(404).json({ message: "Project missing" });

    const isOwner = String(project.ownerId) === String(userId);
    const isEngineer = String(po.engineerId) === String(userId);

    if (!isOwner && !isEngineer) {
      return res.status(403).json({ message: "Access denied" });
    }

    const signedUrl = await signS3Url(po.s3Url);
    return res.json({ url: signedUrl });
  } catch (e) {
    console.error("getPoSignedUrl err:", e);
    return res.status(500).json({ message: "Server error" });
  }
};

/// ============================================================
/// ✅ GST INVOICE (UNCHANGED & SAFE)
/// ============================================================

exports.createGstInvoice = async (req, res) => {
  try {
    const { projectId } = req.params;
    const userId = req.user.userId;

    const {
      invoiceNumber,
      clientName,
      clientGSTIN,
      placeOfSupply,
      totalAmount,
    } = req.body;

    if (req.user.role !== "OWNER") {
      return res.status(403).json({ message: "Only OWNER can generate GST" });
    }

    if (!req.file) return res.status(400).json({ message: "pdf missing" });

    if (!invoiceNumber || !clientName || !clientGSTIN || !placeOfSupply) {
      return res.status(400).json({ message: "Missing required GST fields" });
    }

    const project = await Project.findById(projectId);
    if (!project) return res.status(404).json({ message: "Project not found" });

    if (String(project.ownerId) !== String(userId)) {
      return res.status(403).json({ message: "Not your project" });
    }

    const s3Url = await uploadPdfToS3({
      file: req.file,
      projectId,
      key: invoiceNumber,
      folder: "gst_invoices",
    });

    const gst = await GstInvoiceDoc.create({
      ownerId: userId,
      projectId,
      invoiceNumber,
      clientName,
      clientGSTIN,
      placeOfSupply,
      totalAmount: Number(totalAmount || 0),
      s3Url,
    });

    return res.status(201).json({ message: "GST created", gst });
  } catch (e) {
    console.error("createGstInvoice err:", e);
    return res.status(500).json({ message: "Server error" });
  }
};

exports.getGstInvoices = async (req, res) => {
  try {
    const { projectId } = req.params;
    const userId = req.user.userId;

    const project = await Project.findById(projectId).lean();
    if (!project) return res.status(404).json({ message: "Project not found" });

    if (String(project.ownerId) !== String(userId)) {
      return res.status(403).json({ message: "Not your project" });
    }

    const list = await GstInvoiceDoc.find({ projectId })
      .sort({ createdAt: -1 })
      .lean();

    return res.json({ gstInvoices: list });
  } catch (e) {
    console.error("getGstInvoices err:", e);
    return res.status(500).json({ message: "Server error" });
  }
};

exports.getGstSignedUrl = async (req, res) => {
  try {
    const userId = req.user.userId;

    const gst = await GstInvoiceDoc.findById(req.params.gstId).lean();
    if (!gst) return res.status(404).json({ message: "Not found" });

    const project = await Project.findById(gst.projectId).lean();
    if (!project) return res.status(404).json({ message: "Project missing" });

    if (String(project.ownerId) !== String(userId)) {
      return res.status(403).json({ message: "Access denied" });
    }

    const signedUrl = await signS3Url(gst.s3Url);
    return res.json({ url: signedUrl });
  } catch (e) {
    console.error("getGstSignedUrl err:", e);
    return res.status(500).json({ message: "Server error" });
  }
};
