const Task = require("../models/Task.model");
const Project = require("../models/Project.model");

/**
 * ✅ helper: check if user is member of project
 */
async function ensureProjectAccess(projectId, userId, role) {
  const project = await Project.findById(projectId);
  if (!project) return { ok: false, code: 404, message: "Project not found" };

  const uid = String(userId);

  const isOwner = String(project.ownerId) === uid;
  const isEngineer = (project.engineers || []).map(String).includes(uid);
  const isManager = (project.managers || []).map(String).includes(uid);
  const isClient = (project.clients || []).map(String).includes(uid);

  // Only Engineer/Manager allowed for tasks
  if (role === "ENGINEER" && !isEngineer) {
    return { ok: false, code: 403, message: "Not engineer of this project" };
  }
  if (role === "MANAGER" && !isManager) {
    return { ok: false, code: 403, message: "Not manager of this project" };
  }

  // Owner / Client not allowed
  if (role === "OWNER" || role === "CLIENT") {
    return { ok: false, code: 403, message: "Access denied" };
  }

  // If engineer/manager but not member
  if (!isEngineer && !isManager) {
    return { ok: false, code: 403, message: "Access denied" };
  }

  return { ok: true, project };
}

/**
 * ✅ GET GLOBAL TASKS
 * GET /api/tasks
 * returns tasks of ALL projects user is part of (ENGINEER / MANAGER)
 */
exports.getGlobalTasks = async (req, res) => {
  try {
    const userId = req.user.userId;
    const role = req.user.role;

    if (role === "OWNER" || role === "CLIENT") {
      return res.status(403).json({ message: "Access denied" });
    }

    let projectQuery = {};
    if (role === "ENGINEER") projectQuery = { engineers: userId };
    if (role === "MANAGER") projectQuery = { managers: userId };

    const projects = await Project.find(projectQuery, "_id projectName").lean();
    const ids = projects.map((p) => p._id);

    if (ids.length === 0) return res.json({ tasks: [] });

    const tasks = await Task.find({ projectId: { $in: ids } })
      .populate("projectId", "projectName location status")
      .populate("createdBy", "name role")
      .sort({ createdAt: -1 })
      .lean();

    return res.json({ tasks });
  } catch (err) {
    console.error("getGlobalTasks error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};

/**
 * ✅ GET PROJECT TASKS
 * GET /api/tasks/project/:projectId
 */
exports.getProjectTasks = async (req, res) => {
  try {
    const userId = req.user.userId;
    const role = req.user.role;
    const { projectId } = req.params;

    const access = await ensureProjectAccess(projectId, userId, role);
    if (!access.ok) {
      return res.status(access.code).json({ message: access.message });
    }

    const tasks = await Task.find({ projectId })
      .populate("projectId", "projectName location status")
      .populate("createdBy", "name role")
      .sort({ createdAt: -1 })
      .lean();

    return res.json({ tasks });
  } catch (err) {
    console.error("getProjectTasks error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};

/**
 * ✅ CREATE TASK (Engineer/Manager)
 * POST /api/tasks
 * body: { projectId, title, desc, priority, dueDate }
 */
exports.createTask = async (req, res) => {
  try {
    const userId = req.user.userId;
    const role = req.user.role;

    if (role === "OWNER" || role === "CLIENT") {
      return res.status(403).json({ message: "Access denied" });
    }

    const { projectId, title, desc, priority, dueDate } = req.body;

    if (!projectId || !title) {
      return res.status(400).json({ message: "projectId and title required" });
    }

    const access = await ensureProjectAccess(projectId, userId, role);
    if (!access.ok) {
      return res.status(access.code).json({ message: access.message });
    }

    const task = await Task.create({
      projectId,
      title,
      desc: desc || "",
      priority: priority || "MED",
      dueDate: dueDate ? new Date(dueDate) : null,
      createdBy: userId,
    });

    const populated = await Task.findById(task._id)
      .populate("projectId", "projectName location status")
      .populate("createdBy", "name role")
      .lean();

    return res.status(201).json({ task: populated });
  } catch (err) {
    console.error("createTask error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};

/**
 * ✅ UPDATE TASK STATUS
 * PATCH /api/tasks/:taskId/status
 * body: { status: "PENDING" | "DONE" }
 */
exports.updateTaskStatus = async (req, res) => {
  try {
    const userId = req.user.userId;
    const role = req.user.role;
    const { taskId } = req.params;
    const { status } = req.body;

    if (role === "OWNER" || role === "CLIENT") {
      return res.status(403).json({ message: "Access denied" });
    }

    if (!status || !["PENDING", "DONE"].includes(status)) {
      return res.status(400).json({ message: "Invalid status" });
    }

    const task = await Task.findById(taskId);
    if (!task) return res.status(404).json({ message: "Task not found" });

    const access = await ensureProjectAccess(task.projectId, userId, role);
    if (!access.ok) {
      return res.status(access.code).json({ message: access.message });
    }

    task.status = status;
    await task.save();

    const populated = await Task.findById(task._id)
      .populate("projectId", "projectName location status")
      .populate("createdBy", "name role")
      .lean();

    return res.json({ task: populated });
  } catch (err) {
    console.error("updateTaskStatus error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};

/**
 * ✅ DELETE TASK
 * DELETE /api/tasks/:taskId
 */
exports.deleteTask = async (req, res) => {
  try {
    const userId = req.user.userId;
    const role = req.user.role;
    const { taskId } = req.params;

    if (role === "OWNER" || role === "CLIENT") {
      return res.status(403).json({ message: "Access denied" });
    }

    const task = await Task.findById(taskId);
    if (!task) return res.status(404).json({ message: "Task not found" });

    const access = await ensureProjectAccess(task.projectId, userId, role);
    if (!access.ok) {
      return res.status(access.code).json({ message: access.message });
    }

    await Task.deleteOne({ _id: taskId });
    return res.json({ message: "Task deleted" });
  } catch (err) {
    console.error("deleteTask error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};
