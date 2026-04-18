const mongoose = require("mongoose");

const GstInvoiceDocSchema = new mongoose.Schema(
  {
    ownerId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    projectId: { type: mongoose.Schema.Types.ObjectId, ref: "Project", required: true },

    invoiceNumber: { type: String, required: true },
    clientName: { type: String, required: true },
    clientGSTIN: { type: String, required: true },
    placeOfSupply: { type: String, required: true },

    totalAmount: { type: Number, default: 0 },

    s3Url: { type: String, required: true },
  },
  { timestamps: true }
);

module.exports = mongoose.model("GstInvoiceDoc", GstInvoiceDocSchema);
