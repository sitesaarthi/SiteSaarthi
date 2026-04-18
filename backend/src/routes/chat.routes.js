const express = require("express");
const router = express.Router();
const mongoose = require("mongoose");

const Chat = require("../models/Chat");
const ProjectChatMeta = require("../models/ProjectChatMeta");
const ProjectChatState = require("../models/ProjectChatState");
const Project = require("../models/Project.model"); // ✅ same as your project controller

const authMiddleware = require("../middleware/auth.middleware");

// ✅ get projects user can access (matches your Project schema)
async function getProjectsForUser(user) {
  const userId = user.userId;
  const role = user.role;

  const oid = new mongoose.Types.ObjectId(userId);

  if (role === "OWNER") {
    return Project.find({ ownerId: oid })
      .select("_id projectName ownerId clients engineers")
      .lean();
  }

  if (role === "ENGINEER") {
    return Project.find({ engineers: oid })
      .select("_id projectName ownerId clients engineers")
      .lean();
  }

  if (role === "CLIENT") {
    return Project.find({ clients: oid })
      .select("_id projectName ownerId clients engineers")
      .lean();
  }

  return [];
}

function normalizeUser(user) {
  return {
    id: String(user.userId),
    role: user.role,
    name: user.name || "User",
  };
}

async function ensureState(userId, projectId, chatType) {
  return ProjectChatState.findOneAndUpdate(
    { userId, projectId, chatType },
    { $setOnInsert: { unreadCount: 0 } },
    { new: true, upsert: true }
  );
}

/**
 * ✅ INBOX
 * GET /api/chat/inbox?chatType=TEAM
 */
router.get("/inbox", authMiddleware, async (req, res) => {
  try {
    const chatType = (req.query.chatType || "TEAM").toUpperCase();
    if (!["TEAM", "CLIENT"].includes(chatType)) {
      return res.status(400).json({ success: false, message: "Invalid chatType" });
    }

    const projects = await getProjectsForUser(req.user);
    const projectIds = projects.map((p) => p._id);

    // ✅ meta list
    const metas = await ProjectChatMeta.find({
      projectId: { $in: projectIds },
      chatType,
    }).lean();

    // ✅ states for unread
    const states = await ProjectChatState.find({
      userId: req.user.userId,
      projectId: { $in: projectIds },
      chatType,
    }).lean();

    const stateMap = new Map(states.map((s) => [String(s.projectId), s]));
    const metaMap = new Map(metas.map((m) => [String(m.projectId), m]));

    // ✅ show all projects even if no meta exists
    const inbox = projects.map((p) => {
      const m = metaMap.get(String(p._id));
      return {
        projectId: p._id,
        projectName: p.projectName || "Project",
        chatType,
        lastMessage: m?.lastMessage ?? "No messages yet",
        lastMessageAt: m?.lastMessageAt ?? null,
        lastSender: m?.lastSender ?? null,
        unreadCount: stateMap.get(String(p._id))?.unreadCount || 0,
      };
    });

    // ✅ newest at top (null bottom)
    inbox.sort((a, b) => {
      if (!a.lastMessageAt) return 1;
      if (!b.lastMessageAt) return -1;
      return new Date(b.lastMessageAt).getTime() - new Date(a.lastMessageAt).getTime();
    });

    return res.json({ success: true, inbox });
  } catch (err) {
    console.error("inbox error:", err);
    return res.status(500).json({ success: false, message: "Server error" });
  }
});
router.get("/inbox-all", authMiddleware, async (req, res) => {
  try {
    const projects = await getProjectsForUser(req.user);
    const projectIds = projects.map((p) => p._id);

    const metas = await ProjectChatMeta.find({
      projectId: { $in: projectIds },
      chatType: { $in: ["TEAM", "CLIENT"] },
    })
      .sort({ lastMessageAt: -1 })
      .lean();

    const states = await ProjectChatState.find({
      userId: req.user.userId,
      projectId: { $in: projectIds },
      chatType: { $in: ["TEAM", "CLIENT"] },
    }).lean();

    const stateKey = (pid, ct) => `${String(pid)}_${ct}`;

    const stateMap = new Map(states.map((s) => [stateKey(s.projectId, s.chatType), s]));
    const metaMap = new Map(metas.map((m) => [stateKey(m.projectId, m.chatType), m]));

    let inbox = [];

    for (const p of projects) {
      for (const ct of ["TEAM", "CLIENT"]) {
        const key = stateKey(p._id, ct);
        const m = metaMap.get(key);

        inbox.push({
          projectId: p._id,
          projectName: p.projectName || "Project",
          chatType: ct,
          lastMessage: m?.lastMessage ?? "No messages yet",
          lastMessageAt: m?.lastMessageAt ?? null,
          lastSender: m?.lastSender ?? null,
          unreadCount: stateMap.get(key)?.unreadCount || 0,
        });
      }
    }

    // ✅ sort newest top
    inbox.sort((a, b) => {
      if (!a.lastMessageAt) return 1;
      if (!b.lastMessageAt) return -1;
      return new Date(b.lastMessageAt).getTime() - new Date(a.lastMessageAt).getTime();
    });

    return res.json({ success: true, inbox });
  } catch (err) {
    console.error("inbox-all error:", err);
    return res.status(500).json({ success: false, message: "Server error" });
  }
});

/**
 * ✅ GET messages
 * GET /api/chat/messages?projectId=...&chatType=TEAM
 */
router.get("/messages", authMiddleware, async (req, res) => {
  try {
    const { projectId } = req.query;
    const chatType = (req.query.chatType || "TEAM").toUpperCase();

    if (!projectId) return res.status(400).json({ success: false, message: "projectId required" });
    if (!["TEAM", "CLIENT"].includes(chatType)) {
      return res.status(400).json({ success: false, message: "Invalid chatType" });
    }

    // ✅ authorize project access
    const allowedProjects = await getProjectsForUser(req.user);
    const allowed = allowedProjects.some((p) => String(p._id) === String(projectId));
    if (!allowed) return res.status(403).json({ success: false, message: "Not authorized" });

    const messages = await Chat.find({ projectId, chatType })
      .sort({ createdAt: 1 })
      .limit(500)
      .lean();

    // ✅ mark delivered
    const myId = String(req.user.userId);
    await Chat.updateMany(
      {
        projectId,
        chatType,
        "sender.id": { $ne: myId },
        deliveredTo: { $ne: myId },
      },
      {
        $addToSet: { deliveredTo: myId },
        $set: { status: "DELIVERED" },
      }
    );

    await ProjectChatState.updateOne(
      { userId: req.user.userId, projectId, chatType },
      { $set: { lastDeliveredAt: new Date() } },
      { upsert: true }
    );

    return res.json({ success: true, messages });
  } catch (err) {
    console.error("messages error:", err);
    return res.status(500).json({ success: false, message: "Server error" });
  }
});

/**
 * ✅ SEND message
 * POST /api/chat/send
 */
router.post("/send", authMiddleware, async (req, res) => {
  try {
    const { projectId, projectName, chatType, receiver, message } = req.body;

    if (!projectId || !message?.trim()) {
      return res.status(400).json({ success: false, message: "projectId + message required" });
    }

    const ct = (chatType || "TEAM").toUpperCase();
    if (!["TEAM", "CLIENT"].includes(ct)) {
      return res.status(400).json({ success: false, message: "Invalid chatType" });
    }

    const allowedProjects = await getProjectsForUser(req.user);
    const project = allowedProjects.find((p) => String(p._id) === String(projectId));
    if (!project) return res.status(403).json({ success: false, message: "Not authorized" });

    const sender = normalizeUser(req.user);

    // ✅ determine members
    let members = [];
    if (ct === "TEAM") {
      members = [project.ownerId, ...(project.engineers || [])];
    } else {
      // your schema: clients is array
      members = [project.ownerId, ...(project.clients || [])];
    }
    members = [...new Set(members.filter(Boolean).map(String))];

    const recv =
      receiver?.id
        ? receiver
        : { id: String(project.ownerId), role: "OWNER", name: "Owner" };

    const msgDoc = await Chat.create({
      projectId,
      projectName: projectName || project.projectName || "Project",
      chatType: ct,
      sender,
      receiver: recv,
      message: message.trim(),
      type: "TEXT",
      status: "SENT",
      deliveredTo: [],
      seenBy: [],
    });

    await ProjectChatMeta.updateOne(
      { projectId, chatType: ct },
      {
        $set: {
          projectId,
          projectName: projectName || project.projectName || "Project",
          chatType: ct,
          lastMessage: message.trim(),
          lastMessageAt: msgDoc.createdAt,
          lastSender: sender,
        },
      },
      { upsert: true }
    );

    await ensureState(req.user.userId, projectId, ct);

    const others = members.filter((id) => id !== sender.id);

    // ensure state docs exist then increment
    for (const uid of others) await ensureState(uid, projectId, ct);

    await ProjectChatState.updateMany(
      { userId: { $in: others }, projectId, chatType: ct },
      { $inc: { unreadCount: 1 } }
    );

    return res.json({ success: true, message: msgDoc });
  } catch (err) {
    console.error("send error:", err);
    return res.status(500).json({ success: false, message: "Server error" });
  }
});

/**
 * ✅ SEEN
 * POST /api/chat/seen
 */
router.post("/seen", authMiddleware, async (req, res) => {
  try {
    const { projectId, chatType } = req.body;
    if (!projectId) return res.status(400).json({ success: false, message: "projectId required" });

    const ct = (chatType || "TEAM").toUpperCase();
    if (!["TEAM", "CLIENT"].includes(ct)) {
      return res.status(400).json({ success: false, message: "Invalid chatType" });
    }

    const allowedProjects = await getProjectsForUser(req.user);
    const allowed = allowedProjects.some((p) => String(p._id) === String(projectId));
    if (!allowed) return res.status(403).json({ success: false, message: "Not authorized" });

    const myId = String(req.user.userId);

    await Chat.updateMany(
      {
        projectId,
        chatType: ct,
        "sender.id": { $ne: myId },
        seenBy: { $ne: myId },
      },
      {
        $addToSet: { seenBy: myId },
        $set: { status: "SEEN" },
      }
    );

    await ProjectChatState.updateOne(
      { userId: req.user.userId, projectId, chatType: ct },
      { $set: { unreadCount: 0, lastSeenAt: new Date() } },
      { upsert: true }
    );

    return res.json({ success: true });
  } catch (err) {
    console.error("seen error:", err);
    return res.status(500).json({ success: false, message: "Server error" });
  }
});

module.exports = router;
