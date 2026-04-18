const mongoose = require("mongoose");

const metaSchema = new mongoose.Schema(
  {
    projectId: { type: mongoose.Schema.Types.ObjectId, ref: "Project", required: true },
    projectName: { type: String, default: "Project" },
    chatType: { type: String, enum: ["TEAM", "CLIENT"], required: true },

    lastMessage: { type: String, default: "" },
    lastMessageAt: { type: Date, default: null },
    lastSender: { type: Object, default: null },
  },
  { timestamps: true }
);

metaSchema.index({ projectId: 1, chatType: 1 }, { unique: true });

module.exports = mongoose.model("ProjectChatMeta", metaSchema);
