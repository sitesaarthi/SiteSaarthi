const express = require("express");
const cors = require("cors");
require("dotenv").config();

const authRoutes = require("./routes/auth.routes");
const projectRoutes = require("./routes/project.routes");
const taskRoutes = require("./routes/task.routes");
const approvalRoutes = require("./routes/approval.routes"); // ✅ ADD THIS
const chatRoutes = require("./routes/chat.routes");
const docsRoutes = require("./routes/docs.routes");

const app = express();

app.use(cors());
app.use(express.json());

app.get("/", (req, res) => res.send("✅ SiteSaarthi backend running"));

app.use("/api/auth", authRoutes);
app.use("/api/projects", projectRoutes);
app.use("/api/tasks", taskRoutes);

app.use("/api/approvals", approvalRoutes); // ✅ ADD THIS LINE
app.use("/api/chat", chatRoutes);
app.use("/api/docs", docsRoutes);
const path = require("path");
app.use("/uploads", express.static(path.join(__dirname, "../uploads")));
const docHistoryRoutes = require("./routes/docHistory.routes");
app.use("/api/doc-history", docHistoryRoutes);

const dprRoutes = require("./routes/dprRoutes");
app.use("/api/dpr", dprRoutes);
const uploadRoutes = require("./routes/upload.routes");
app.use("/api/upload", uploadRoutes);

module.exports = app;
