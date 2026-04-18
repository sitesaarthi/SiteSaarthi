const mongoose = require("mongoose");

const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    phone: { type: String, required: true, unique: true, trim: true },
    passwordHash: { type: String, required: true },
    role: {
      type: String,
      enum: ["OWNER", "MANAGER", "ENGINEER", "CLIENT"],
      default: "OWNER",
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model("User", userSchema);
