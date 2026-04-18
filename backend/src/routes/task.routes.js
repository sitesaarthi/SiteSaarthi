const express = require("express");
const router = express.Router();

const authMiddleware = require("../middleware/auth.middleware");
const task = require("../controllers/task.controller");

// ✅ GLOBAL TASKS
router.get("/", authMiddleware, task.getGlobalTasks);

// ✅ PROJECT TASKS
router.get("/project/:projectId", authMiddleware, task.getProjectTasks);

// ✅ CREATE TASK
router.post("/", authMiddleware, task.createTask);

// ✅ UPDATE STATUS
router.patch("/:taskId/status", authMiddleware, task.updateTaskStatus);

// ✅ DELETE
router.delete("/:taskId", authMiddleware, task.deleteTask);

module.exports = router;
