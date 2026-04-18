const mongoose = require("mongoose");

const dprSchema = new mongoose.Schema(
  {
    projectId: { type: mongoose.Schema.Types.ObjectId, ref: "Project", required: true },
    uploadedBy: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },

    date: { type: Date, required: true },

    title: { type: String, default: "" },
    workDone: { type: String, default: "" },
    issues: { type: String, default: "" },

    photos: [{ type: String }],
    fileUrl: { type: String, default: "" },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Dpr", dprSchema);
