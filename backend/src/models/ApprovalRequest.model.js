const mongoose = require("mongoose");

const ApprovalRequestSchema = new mongoose.Schema(
  {
    type: {
      type: String,
      enum: ["MATERIAL", "FUNDS", "TASK"],
      required: true,
      index: true,
    },


    projectId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Project",
      required: true,
      index: true,
    },

    requestedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },

    // 🔗 LINK TO PO (IMPORTANT)
    poId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "PurchaseOrderDoc",
      default: null,
      index: true,
    },

    status: {
      type: String,
      enum: ["pending", "approved", "rejected"],
      default: "pending",
      index: true,
    },

    // Common
    requestedAmount: { type: Number, default: 0 },
    approvedAmount: { type: Number, default: 0 },
    note: { type: String, default: "" },
    priority: {
      type: String,
      enum: ["LOW", "MED", "HIGH"],
      default: "MED",
    },
    neededBy: { type: Date, default: null },

    // MATERIAL
    materialName: { type: String, default: "" },
    requestedQty: { type: Number, default: 0 },
    approvedQty: { type: Number, default: 0 },
    unit: { type: String, default: "" },
    siteLocation: { type: String, default: "" },

    // FUNDS
    title: { type: String, default: "" },
    purpose: { type: String, default: "" },

    // TASK
    taskTitle: { type: String, default: "" },
    taskDescription: { type: String, default: "" },


    // Decision
    decisionNote: { type: String, default: "" },
    approvedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      default: null,
    },
    approvedAt: { type: Date, default: null },
  },
  { timestamps: true }
);

module.exports = mongoose.model("ApprovalRequest", ApprovalRequestSchema);
