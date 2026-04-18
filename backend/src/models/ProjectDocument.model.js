const mongoose = require("mongoose");

const ProjectDocumentSchema = new mongoose.Schema(
  {
    projectId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Project",
      required: true,
      index: true,
    },
    docType: {
      type: String,
      enum: [
        "PROPOSAL",
        "QUOTATION",
        "PURCHASE_ORDER",
        "GST_INVOICE",
        "COMPLETION_CERT",
      ],
      required: true,
      index: true,
    },
    version: { type: Number, default: 1 },
    pdfUrl: { type: String, required: true }, // local path or s3 url
    originalName: { type: String, default: "" },

    generatedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    meta: { type: Object, default: {} },
  },
  { timestamps: true }
);

module.exports = mongoose.model("ProjectDocument", ProjectDocumentSchema);
