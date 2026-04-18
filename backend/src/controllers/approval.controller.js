const ApprovalRequest = require("../models/ApprovalRequest.model");
const Project = require("../models/Project.model");
const PurchaseOrderDoc = require("../models/PurchaseOrderDoc.model");
const { createDocHistory } = require("../services/docHistory.service");


/**
 * ✅ helper: ensure user is part of project
 */
async function ensureProjectAccess(projectId, userId, role) {
  const project = await Project.findById(projectId).lean();
  if (!project) return { ok: false, code: 404, message: "Project not found" };

  const uid = String(userId);

  const isOwner = String(project.ownerId) === uid;
  const isEngineer = (project.engineers || []).map(String).includes(uid);
  const isManager = (project.managers || []).map(String).includes(uid);

  if (role === "OWNER" && isOwner) return { ok: true, project };

  if (role === "ENGINEER" && !isEngineer) {
    return { ok: false, code: 403, message: "Not engineer of this project" };
  }

  if (role === "MANAGER" && !isManager) {
    return { ok: false, code: 403, message: "Not manager of this project" };
  }

  if (!isEngineer && !isManager && !isOwner) {
    return { ok: false, code: 403, message: "Access denied" };
  }

  return { ok: true, project };
}

/**
 * ============================================================
 * ✅ GET APPROVALS
 * ============================================================
 */
exports.getOwnerApprovals = async (req, res) => {
  try {
    if (req.user.role !== "OWNER") {
      return res.status(403).json({ message: "Only OWNER can view approvals" });
    }

    const projects = await Project.find({ ownerId: req.user.userId })
      .select("_id")
      .lean();

    const projectIds = projects.map(p => p._id);
    if (!projectIds.length) return res.json({ approvals: [] });

    const approvals = await ApprovalRequest.find({
      projectId: { $in: projectIds },
    })
      .populate("requestedBy", "name phone role")
      .populate("projectId", "projectName location")
      .sort({ createdAt: -1 })
      .lean();

    return res.json({ approvals });
  } catch (err) {
    console.error("getOwnerApprovals error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};

exports.getGlobalApprovals = async (req, res) => {
  try {
    const role = req.user.role;
    if (!["ENGINEER", "MANAGER"].includes(role)) {
      return res.status(403).json({ message: "Access denied" });
    }

    let projectQuery = {};
    if (role === "ENGINEER") projectQuery = { engineers: req.user.userId };
    if (role === "MANAGER") projectQuery = { managers: req.user.userId };

    const projects = await Project.find(projectQuery, "_id").lean();
    const projectIds = projects.map((p) => p._id);

    if (!projectIds.length) return res.json({ approvals: [] });

    const approvals = await ApprovalRequest.find({
      projectId: { $in: projectIds },
    })
      .populate("requestedBy", "name phone role")
      .populate("projectId", "projectName location")
      .sort({ createdAt: -1 })
      .lean();

    return res.json({ approvals });
  } catch (err) {
    console.error("getGlobalApprovals error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};

exports.getProjectApprovals = async (req, res) => {
  try {
    const { projectId } = req.params;
    const access = await ensureProjectAccess(
      projectId,
      req.user.userId,
      req.user.role
    );
    if (!access.ok) {
      return res.status(access.code).json({ message: access.message });
    }

    const approvals = await ApprovalRequest.find({ projectId })
      .populate("requestedBy", "name phone role")
      .populate("projectId", "projectName location")
      .sort({ createdAt: -1 })
      .lean();

    return res.json({ approvals });
  } catch (err) {
    console.error("getProjectApprovals error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};

/**
 * ============================================================
 * ✅ CREATE MATERIAL / FUNDS (UNCHANGED)
 * ============================================================
 */

exports.createMaterialRequest = async (req, res) => {
  try {
    const role = req.user.role;
    if (!["ENGINEER", "MANAGER"].includes(role)) {
      return res.status(403).json({ message: "Only Engineer/Manager can request" });
    }

    const {
      projectId,
      materialName,
      requestedQty,
      unit,
      siteLocation,
      requestedAmount,
      priority,
      note,
      neededBy,
    } = req.body;

    const access = await ensureProjectAccess(
      projectId,
      req.user.userId,
      role
    );
    if (!access.ok) {
      return res.status(access.code).json({ message: access.message });
    }

    const approval = await ApprovalRequest.create({
      type: "MATERIAL",
      projectId,
      requestedBy: req.user.userId,
      materialName,
      requestedQty: Number(requestedQty),
      unit,
      siteLocation: siteLocation || "",
      requestedAmount: Number(requestedAmount || 0),
      priority: priority || "MED",
      note: note || "",
      neededBy: neededBy ? new Date(neededBy) : null,
      status: "pending",
    });

    return res.status(201).json({ request: approval });
  } catch (err) {
    console.error("createMaterialRequest error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};

exports.createFundsRequest = async (req, res) => {
  try {
    const role = req.user.role;
    if (!["ENGINEER", "MANAGER"].includes(role)) {
      return res.status(403).json({ message: "Only Engineer/Manager can request" });
    }

    const {
      projectId,
      title,
      purpose,
      requestedAmount,
      priority,
      note,
      neededBy,
    } = req.body;

    const access = await ensureProjectAccess(
      projectId,
      req.user.userId,
      role
    );
    if (!access.ok) {
      return res.status(access.code).json({ message: access.message });
    }

    const approval = await ApprovalRequest.create({
      type: "FUNDS",
      projectId,
      requestedBy: req.user.userId,
      title: title || "Funds Request",
      purpose: purpose || "",
      requestedAmount: Number(requestedAmount),
      priority: priority || "MED",
      note: note || "",
      neededBy: neededBy ? new Date(neededBy) : null,
      status: "pending",
    });

    return res.status(201).json({ request: approval });
  } catch (err) {
    console.error("createFundsRequest error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};

/**
 * ============================================================
 * ✅ APPROVE / REJECT (PO + NORMAL REQUESTS)
 * ============================================================
 */

exports.approveRequest = async (req, res) => {
  try {
    const { id } = req.params;
    const ownerId = req.user.userId;

    if (req.user.role !== "OWNER") {
      return res.status(403).json({ message: "Only OWNER can approve" });
    }

    const approval = await ApprovalRequest.findById(id);
    if (!approval) return res.status(404).json({ message: "Request not found" });

    const project = await Project.findById(approval.projectId);
    if (!project) return res.status(404).json({ message: "Project not found" });

    if (String(project.ownerId) !== String(ownerId)) {
      return res.status(403).json({ message: "Access denied" });
    }

    approval.status = "approved";
    approval.approvedBy = ownerId;
    approval.approvedAt = new Date();
    approval.decisionNote = req.body?.decisionNote ?? "";

    await approval.save();

    // 🔥 PO APPROVAL HANDLING
    if (approval.poId) {
      const po = await PurchaseOrderDoc.findById(approval.poId);
      if (po) {
        po.status = "CONFIRMED";
        await po.save();

        await createDocHistory({
          docType: "PO",
          docId: po._id,
          action: "APPROVED",
          performedBy: ownerId,
          role: "OWNER",
        });

        await createDocHistory({
          docType: "PO",
          docId: po._id,
          action: "CONFIRMED",
          performedBy: ownerId,
          role: "SYSTEM",
        });
      }
    }

    return res.json({ message: "Approved", request: approval });
  } catch (err) {
    console.error("approveRequest error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};

exports.rejectRequest = async (req, res) => {
  try {
    const { id } = req.params;
    const ownerId = req.user.userId;

    if (req.user.role !== "OWNER") {
      return res.status(403).json({ message: "Only OWNER can reject" });
    }

    const approval = await ApprovalRequest.findById(id);
    if (!approval) return res.status(404).json({ message: "Request not found" });

    const project = await Project.findById(approval.projectId);
    if (!project) return res.status(404).json({ message: "Project not found" });

    if (String(project.ownerId) !== String(ownerId)) {
      return res.status(403).json({ message: "Access denied" });
    }

    approval.status = "rejected";
    approval.decisionNote = req.body?.decisionNote ?? "";
    approval.approvedBy = ownerId;
    approval.approvedAt = new Date();

    await approval.save();

    // 🔥 PO REJECTION HANDLING
    if (approval.poId) {
      const po = await PurchaseOrderDoc.findById(approval.poId);
      if (po) {
        po.status = "REJECTED";
        await po.save();

        await createDocHistory({
          docType: "PO",
          docId: po._id,
          action: "REJECTED",
          performedBy: ownerId,
          role: "OWNER",
          comment: approval.decisionNote,
        });
      }
    }

    return res.json({ message: "Rejected", request: approval });
  } catch (err) {
    console.error("rejectRequest error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};

exports.createTaskRequest = async (req, res) => {
  try {
    const role = req.user.role;
    if (!["ENGINEER", "MANAGER"].includes(role)) {
      return res
        .status(403)
        .json({ message: "Only Engineer/Manager can create tasks" });
    }

    // ✅ FIXED FIELD NAMES
    const {
      projectId,
      taskTitle,
      taskDescription,
      priority,
      neededBy,
    } = req.body;

    if (!projectId || !taskTitle) {
      return res.status(400).json({
        message: "Project and task title required",
      });
    }

    const access = await ensureProjectAccess(
      projectId,
      req.user.userId,
      role
    );
    if (!access.ok) {
      return res.status(access.code).json({ message: access.message });
    }

    const task = await ApprovalRequest.create({
      type: "TASK",
      projectId,
      requestedBy: req.user.userId,
      taskTitle,
      taskDescription: taskDescription || "",
      priority: priority || "MED",
      neededBy: neededBy ? new Date(neededBy) : null,
      status: "pending",
    });

    return res.status(201).json({ request: task });
  } catch (err) {
    console.error("createTaskRequest error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};