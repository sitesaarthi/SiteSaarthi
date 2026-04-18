const mongoose = require("mongoose");

const docHistorySchema = new mongoose.Schema(
  {
    docType: {
      type: String,
      required: true, // PO, GST, CC, IOD etc
    },

    docId: {
      type: mongoose.Schema.Types.ObjectId,
      required: true,
      index: true,
    },

    action: {
      type: String,
      required: true, // CREATED, SUBMITTED, APPROVED, REJECTED, CONFIRMED
    },

    performedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    role: {
      type: String,
      enum: ["ENGINEER", "OWNER", "MANAGER", "SYSTEM"],
      required: true,
    },

    comment: {
      type: String,
      default: "",
    },
  },
  {
    timestamps: true, // createdAt, updatedAt
  }
);

module.exports = mongoose.model("DocHistory", docHistorySchema);
