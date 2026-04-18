const mongoose = require("mongoose");

const chatUserSchema = new mongoose.Schema(
  {
    id: { type: String, required: true },
    role: { type: String, required: true },
    name: { type: String, required: true },
  },
  { _id: false }
);

const chatSchema = new mongoose.Schema(
  {
    projectId: { type: mongoose.Schema.Types.ObjectId, ref: "Project", required: true },
    projectName: { type: String, default: "Project" },
    chatType: { type: String, enum: ["TEAM", "CLIENT"], default: "TEAM" },

    sender: { type: chatUserSchema, required: true },
    receiver: { type: chatUserSchema, required: true },

    message: { type: String, required: true, trim: true },
    type: { type: String, default: "TEXT" },

    // ✅ STATUS
    status: { type: String, enum: ["SENT", "DELIVERED", "SEEN"], default: "SENT" },
    deliveredTo: [{ type: String }], // list of userId strings
    seenBy: [{ type: String }],
  },
  { timestamps: { createdAt: "createdAt", updatedAt: false } }
);

chatSchema.index({ projectId: 1, chatType: 1, createdAt: 1 });

module.exports = mongoose.model("Chat", chatSchema);
