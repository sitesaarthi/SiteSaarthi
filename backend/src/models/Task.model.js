const mongoose = require("mongoose");

const taskSchema = new mongoose.Schema(
  {
    projectId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Project",
      required: true,
      index: true,
    },

    title: { type: String, required: true, trim: true },
    desc: { type: String, default: "" },

    status: {
      type: String,
      enum: ["PENDING", "DONE"],
      default: "PENDING",
      index: true,
    },

    priority: {
      type: String,
      enum: ["LOW", "MED", "HIGH"],
      default: "MED",
    },

    dueDate: { type: Date },

    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    assignedTo: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      default: null,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Task", taskSchema);
