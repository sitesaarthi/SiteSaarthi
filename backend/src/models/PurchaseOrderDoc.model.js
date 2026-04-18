const mongoose = require("mongoose");

const PurchaseOrderDocSchema = new mongoose.Schema(
  {
    projectId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Project",
      required: true,
    },

    engineerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    ownerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    poNumber: { type: String, required: true },
    vendor: { type: String, required: true },

    issueDate: { type: Date, required: true },
    deliveryDate: { type: Date, required: true },

    status: {
      type: String,
      enum: [
        "DRAFT",        // engineer editing
        "SUBMITTED",    // sent to owner
        "REJECTED",     // owner rejected
        "APPROVED",     // owner approved
        "CONFIRMED"     // locked
      ],
      default: "DRAFT",
      index: true,
    },

    totalAmount: { type: Number, default: 0 },

    s3Url: { type: String, required: true },
  },
  { timestamps: true }
);

module.exports = mongoose.model("PurchaseOrderDoc", PurchaseOrderDocSchema);
