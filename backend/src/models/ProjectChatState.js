const mongoose = require("mongoose");

const projectChatStateSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    projectId: { type: mongoose.Schema.Types.ObjectId, ref: "Project", required: true },
    chatType: { type: String, enum: ["TEAM", "CLIENT"], required: true },

    unreadCount: { type: Number, default: 0 },
    lastSeenAt: { type: Date, default: null },
    lastDeliveredAt: { type: Date, default: null },
  },
  { timestamps: true }
);

projectChatStateSchema.index({ userId: 1, projectId: 1, chatType: 1 }, { unique: true });

module.exports = mongoose.model("ProjectChatState", projectChatStateSchema);
