const Project = require("../models/Project.model");


const { GetObjectCommand } = require("@aws-sdk/client-s3");
const { getSignedUrl } = require("@aws-sdk/s3-request-presigner");
const { S3Client } = require("@aws-sdk/client-s3");

const s3 = new S3Client({
  region: process.env.AWS_REGION,
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  },
});

exports.getManualSignedUrl = async (req, res) => {
  try {
    const { projectId } = req.params;
    const { key } = req.query;
    const userId = req.user.userId;

    if (!key) return res.status(400).json({ message: "key required" });
    if (!OWNER_UPLOAD_KEYS.includes(key)) {
      return res.status(400).json({ message: "Invalid key" });
    }

    const project = await Project.findById(projectId).lean();
    if (!project) return res.status(404).json({ message: "Project not found" });

    if (!hasAccess(project, userId)) {
      return res.status(403).json({ message: "Access denied" });
    }

    const doc = (project.docs || []).find((d) => d.key === key);
    if (!doc || !doc.uploaded || !doc.url) {
      return res.status(404).json({ message: "Doc not uploaded" });
    }

    // doc.url = s3://bucket/key
    const raw = doc.url.replace("s3://", "");
    const parts = raw.split("/");
    const bucket = parts.shift();
    const objectKey = parts.join("/");

    const signedUrl = await getSignedUrl(
      s3,
      new GetObjectCommand({
        Bucket: bucket,
        Key: objectKey,
        ResponseContentDisposition: "inline",
        ResponseContentType: "application/pdf",
      }),
      { expiresIn: 60 * 5 } // 5 min
    );

    return res.json({ url: signedUrl });
  } catch (err) {
    console.error("getManualSignedUrl error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};

// ✅ docs keys allowed (7)
const ALLOWED_KEYS = [
  "rera",
  "iod",
  "cc",
  "proposal_report",
  "quotation",
  "po",
  "gst",
];

const OWNER_UPLOAD_KEYS = ["rera", "iod", "cc"];
const AUTO_KEYS = ["proposal_report", "quotation", "po", "gst"];

// ✅ helper: project access
const hasAccess = (project, userId) => {
  const uid = userId.toString();
  if (String(project.ownerId) === uid) return true;
  if ((project.managers || []).map(String).includes(uid)) return true;
  if ((project.engineers || []).map(String).includes(uid)) return true;
  if ((project.clients || []).map(String).includes(uid)) return true;
  return false;
};

/**
 * ✅ GET docs array from Project schema
 * GET /api/docs/:projectId
 */
exports.getProjectDocs = async (req, res) => {
  try {
    const { projectId } = req.params;
    const userId = req.user.userId;

    const project = await Project.findById(projectId).lean();
    if (!project) return res.status(404).json({ message: "Project not found" });

    if (!hasAccess(project, userId)) {
      return res.status(403).json({ message: "Access denied" });
    }

    return res.json({ docs: project.docs || [] });
  } catch (err) {
    console.error("getProjectDocs error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};

/**
 * ✅ GET single doc by key
 * GET /api/docs/:projectId/single?key=rera
 */
exports.getSingleDoc = async (req, res) => {
  try {
    const { projectId } = req.params;
    const { key } = req.query;
    const userId = req.user.userId;

    if (!key) return res.status(400).json({ message: "key required" });
    if (!ALLOWED_KEYS.includes(key)) {
      return res.status(400).json({ message: "Invalid key" });
    }

    const project = await Project.findById(projectId).lean();
    if (!project) return res.status(404).json({ message: "Project not found" });

    if (!hasAccess(project, userId)) {
      return res.status(403).json({ message: "Access denied" });
    }

    const doc = (project.docs || []).find((d) => d.key === key);
    if (!doc) return res.status(404).json({ message: "Doc not found" });

    return res.json({ doc });
  } catch (err) {
    console.error("getSingleDoc error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};

/**
 * ✅ UPLOAD manual doc (RERA/IOD/CC) → OWNER only
 * POST /api/docs/:projectId/upload
 * form-data: pdf(file), key=rera
 */
const { uploadPdfToS3 } = require("../utils/s3");

exports.manualUploadDoc = async (req, res) => {
  try {
    const { projectId } = req.params;
    const { key } = req.body;

    if (!key) return res.status(400).json({ message: "key required" });
    if (!ALLOWED_KEYS.includes(key)) {
      return res.status(400).json({ message: "Invalid key" });
    }

    if (req.user.role !== "OWNER") {
      return res.status(403).json({ message: "Only OWNER can upload docs" });
    }

    if (!OWNER_UPLOAD_KEYS.includes(key)) {
      return res.status(400).json({
        message: "This doc is auto-generated, cannot upload manually",
      });
    }

    const project = await Project.findById(projectId);
    if (!project) return res.status(404).json({ message: "Project not found" });

    // ✅ inject default docs for old projects (PASTE HERE)
    if (!project.docs) project.docs = [];

    const defaults = [
      { key: "rera", title: "RERA Certificate", type: "manual", stage: "INIT" },
      { key: "iod", title: "IOD", type: "manual", stage: "INIT" },
      { key: "cc", title: "Commencement Certificate", type: "manual", stage: "INIT" },

      { key: "proposal_report", title: "Proposal Report", type: "auto", stage: "LATER" },
      { key: "quotation", title: "Quotation", type: "auto", stage: "LATER" },
      { key: "po", title: "Purchase Order", type: "auto", stage: "LATER" },
      { key: "gst", title: "GST Invoice", type: "auto", stage: "LATER" },
    ];

    for (const d of defaults) {
      if (!project.docs.find((x) => x.key === d.key)) {
        project.docs.push(d);
      }
    }

    // ✅ check ownership AFTER injection
    if (String(project.ownerId) !== String(req.user.userId)) {
      return res.status(403).json({ message: "Not your project" });
    }

    if (!req.file) {
      return res.status(400).json({ message: "PDF file missing" });
    }

    const doc = project.docs.find((d) => d.key === key);
    if (!doc) {
      return res.status(404).json({ message: "Doc not found in project.docs" });
    }

    if (doc.uploaded) {
      return res.status(400).json({
        message: "Already uploaded. Delete existing document first.",
      });
    }

    const s3Url = await uploadPdfToS3({
      file: req.file,
      projectId,
      key,
    });

    doc.uploaded = true;
    doc.url = s3Url;
    doc.uploadedAt = new Date();

    await project.save();

    return res.status(201).json({
      message: "Uploaded",
      doc,
      docs: project.docs,
    });
  } catch (err) {
    console.error("manualUploadDoc error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};



/**
 * ✅ DELETE manual doc (RERA/IOD/CC) → OWNER only
 * DELETE /api/docs/:projectId/manual?key=rera
 */
const { deleteFromS3ByUrl } = require("../utils/s3");

exports.deleteManualDoc = async (req, res) => {
  try {
    const { projectId } = req.params;
    const { key } = req.query;

    if (!key) return res.status(400).json({ message: "key required" });

    if (!OWNER_UPLOAD_KEYS.includes(key)) {
      return res.status(400).json({ message: "Invalid manual key" });
    }

    if (req.user.role !== "OWNER") {
      return res.status(403).json({ message: "Only OWNER can delete docs" });
    }

    const project = await Project.findById(projectId);
    if (!project) return res.status(404).json({ message: "Project not found" });

    if (String(project.ownerId) !== String(req.user.userId)) {
      return res.status(403).json({ message: "Not your project" });
    }

    const doc = (project.docs || []).find((d) => d.key === key);
    if (!doc) return res.status(404).json({ message: "Doc not found" });

    if (!doc.uploaded) {
      return res.status(400).json({ message: "Doc not uploaded yet" });
    }

    // ✅ delete from s3 first
    if (doc.url) {
      await deleteFromS3ByUrl(doc.url);
    }

    // ✅ reset
    doc.uploaded = false;
    doc.url = "";
    doc.uploadedAt = null;

    await project.save();

    return res.json({
      message: "Deleted",
      docs: project.docs,
    });
  } catch (err) {
    console.error("deleteManualDoc error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};


/**
 * ✅ AUTO GENERATE docs (proposal_report, quotation, po, gst)
 * POST /api/docs/:projectId/generate
 * body: { key: "quotation" }
 */
exports.generateDoc = async (req, res) => {
  try {
    const { projectId } = req.params;
    const { key } = req.body;

    if (!key) return res.status(400).json({ message: "key required" });
    if (!["proposal_report", "quotation"].includes(key)) {
      return res.status(400).json({ message: "Only quotation/proposal allowed here" });
    }

    if (req.user.role !== "OWNER") {
      return res.status(403).json({ message: "Only OWNER can generate docs" });
    }

    if (!req.file) return res.status(400).json({ message: "pdf missing" });

    const project = await Project.findById(projectId);
    if (!project) return res.status(404).json({ message: "Project not found" });

    if (String(project.ownerId) !== String(req.user.userId)) {
      return res.status(403).json({ message: "Not your project" });
    }

    // ✅ ensure docs array exists + inject defaults always
    if (!project.docs) project.docs = [];

    const defaults = [
      { key: "rera", title: "RERA Certificate", type: "manual", stage: "INIT" },
      { key: "iod", title: "IOD", type: "manual", stage: "INIT" },
      { key: "cc", title: "Commencement Certificate", type: "manual", stage: "INIT" },
      { key: "proposal_report", title: "Proposal Report", type: "auto", stage: "LATER" },
      { key: "quotation", title: "Quotation", type: "auto", stage: "LATER" },
      { key: "po", title: "Purchase Order", type: "auto", stage: "LATER" },
      { key: "gst", title: "GST Invoice", type: "auto", stage: "LATER" },
    ];

    for (const d of defaults) {
      if (!project.docs.find((x) => x.key === d.key)) {
        project.docs.push(d);
      }
    }

    const doc = project.docs.find((d) => d.key === key);
    if (!doc) return res.status(404).json({ message: "Doc missing in project.docs" });

    // ✅ upload to S3
    const s3Url = await uploadPdfToS3({
      file: req.file,
      projectId,
      key,
      folder: "docs",
    });

    // ✅ MUST UPDATE project.docs
    doc.uploaded = true;
    doc.url = s3Url;
    doc.uploadedAt = new Date();

    await project.save();

    return res.status(201).json({
      message: "Generated & Uploaded",
      doc,
      docs: project.docs,
    });
  } catch (err) {
    console.error("generateDoc error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};

const GstInvoiceDoc = require("../models/GstInvoiceDoc.model");

exports.createGstInvoice = async (req, res) => {
  try {
    const { projectId } = req.params;
    const userId = req.user.userId;

    const { invoiceNumber, clientName, clientGSTIN, placeOfSupply, totalAmount } = req.body;

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
      key: invoiceNumber || "gst",
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

    const list = await GstInvoiceDoc.find({ projectId }).sort({ createdAt: -1 }).lean();
    return res.json({ gstInvoices: list });
  } catch (e) {
    console.error("getGstInvoices err:", e);
    return res.status(500).json({ message: "Server error" });
  }
};

exports.getAutoSignedUrl = async (req, res) => {
  try {
    const { projectId } = req.params;
    const { key } = req.query;
    const userId = req.user.userId;

    if (!key) return res.status(400).json({ message: "key required" });
    if (!AUTO_KEYS.includes(key)) {
      return res.status(400).json({ message: "Invalid auto key" });
    }

    const project = await Project.findById(projectId).lean();
    if (!project) return res.status(404).json({ message: "Project not found" });

    if (!hasAccess(project, userId)) {
      return res.status(403).json({ message: "Access denied" });
    }

    const doc = (project.docs || []).find((d) => d.key === key);
    if (!doc || !doc.uploaded || !doc.url) {
      return res.status(404).json({ message: "Doc not uploaded" });
    }

    const raw = doc.url.replace("s3://", "");
    const parts = raw.split("/");
    const bucket = parts.shift();
    const objectKey = parts.join("/");

    const signedUrl = await getSignedUrl(
      s3,
      new GetObjectCommand({
        Bucket: bucket,
        Key: objectKey,
        ResponseContentDisposition: "inline",   // ✅ preview in browser/app
        ResponseContentType: "application/pdf", // ✅ tells browser it's pdf
      }),
      { expiresIn: 60 * 5 }
    );


    return res.json({ url: signedUrl });
  } catch (e) {
    console.error("getAutoSignedUrl error:", e);
    return res.status(500).json({ message: "Server error" });
  }
};
