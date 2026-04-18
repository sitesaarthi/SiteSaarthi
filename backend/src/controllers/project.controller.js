const Project = require("../models/Project.model");
const { nanoid } = require("nanoid");
const mongoose = require("mongoose");

const User = require("../models/User.model"); // ✅ import your User model

const ProjectChatMeta = require("../models/ProjectChatMeta");
const ProjectChatState = require("../models/ProjectChatState");

// ✅ ADD THIS HERE (top of file)
const defaultDocs = [
  { key: "rera", title: "RERA Certificate", stage: "INIT" },
  { key: "iod", title: "IOD (Intimation of Disapproval)", stage: "INIT" },
  { key: "cc", title: "Commencement Certificate (CC)", stage: "INIT" },

  { key: "proposal_report", title: "Proposal Report", stage: "LATER" },
  { key: "quotation", title: "Quotation", stage: "LATER" },
  { key: "po", title: "PO", stage: "LATER" },
  { key: "gst", title: "GST", stage: "LATER" },
];

exports.getProjectMembers = async (req, res) => {
  try {
    const { id } = req.params;

    const project = await Project.findById(id);
    if (!project) return res.status(404).json({ message: "Project not found" });

    // ✅ collect all ids
    const ids = new Set();

    if (project.ownerId) ids.add(String(project.ownerId));
    (project.managers || []).forEach((x) => ids.add(String(x)));
    (project.engineers || []).forEach((x) => ids.add(String(x)));
    (project.clients || []).forEach((x) => ids.add(String(x)));

    const allUserIds = Array.from(ids);

    // ✅ fetch users
    const users = await User.find(
      { _id: { $in: allUserIds } },
      "name phone role"
    );

    // ✅ helper to map role
    const isIn = (arr, uid) => (arr || []).map(String).includes(String(uid));

    const members = users.map((u) => {
      let role = "MEMBER";

      if (String(project.ownerId) === String(u._id)) role = "OWNER";
      else if (isIn(project.managers, u._id)) role = "MANAGER";
      else if (isIn(project.engineers, u._id)) role = "ENGINEER";
      else if (isIn(project.clients, u._id)) role = "CLIENT";

      return {
        id: u._id,
        name: u.name,
        phone: u.phone,
        role,
      };
    });

    return res.json({ members });
  } catch (err) {
    console.error("getProjectMembers error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};


const makeInviteCode = () => nanoid(6).toUpperCase();

async function genUniqueInviteCode() {
  let code = makeInviteCode();
  while (await Project.findOne({ inviteCode: code })) {
    code = makeInviteCode();
  }
  return code;
}

exports.updateProjectMap = async (req, res) => {
  try {
    const projectId = req.params.id;
    const userId = req.user.userId;
    const { centerLat, centerLng, zoom } = req.body;

    const project = await Project.findById(projectId);
    if (!project) return res.status(404).json({ message: "Project not found" });

    if (String(project.ownerId) !== String(userId)) {
      return res.status(403).json({ message: "Only owner can update map" });
    }

    project.siteView = project.siteView || {};
    project.siteView.map = project.siteView.map || {};

    if (centerLat != null) project.siteView.map.centerLat = Number(centerLat);
    if (centerLng != null) project.siteView.map.centerLng = Number(centerLng);
    if (zoom != null) project.siteView.map.zoom = Number(zoom);

    await project.save();
    return res.json({ message: "Map updated", map: project.siteView.map });
  } catch (err) {
    console.error("updateProjectMap error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};

exports.addMapMarker = async (req, res) => {
  try {
    const projectId = req.params.id;
    const userId = req.user.userId;
    const { title, lat, lng } = req.body;

    if (lat == null || lng == null) {
      return res.status(400).json({ message: "lat + lng required" });
    }

    const project = await Project.findById(projectId);
    if (!project) return res.status(404).json({ message: "Project not found" });

    if (String(project.ownerId) !== String(userId)) {
      return res.status(403).json({ message: "Only owner can add marker" });
    }

    project.siteView = project.siteView || {};
    project.siteView.map = project.siteView.map || {};
    project.siteView.map.markers = project.siteView.map.markers || [];

    project.siteView.map.markers.push({
      title: title || "",
      lat: Number(lat),
      lng: Number(lng),
    });

    await project.save();
    return res.json({ message: "Marker added", markers: project.siteView.map.markers });
  } catch (err) {
    console.error("addMapMarker error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};
exports.deleteMapMarker = async (req, res) => {
  try {
    const projectId = req.params.id;
    const userId = req.user.userId;
    const idx = Number(req.params.index);

    const project = await Project.findById(projectId);
    if (!project) return res.status(404).json({ message: "Project not found" });

    if (String(project.ownerId) !== String(userId)) {
      return res.status(403).json({ message: "Only owner can delete marker" });
    }

    if (!project.siteView?.map?.markers || idx < 0 || idx >= project.siteView.map.markers.length) {
      return res.status(400).json({ message: "Invalid marker index" });
    }

    project.siteView.map.markers.splice(idx, 1);
    await project.save();

    return res.json({ message: "Marker deleted", markers: project.siteView.map.markers });
  } catch (err) {
    console.error("deleteMapMarker error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};
exports.updateSiteAssets = async (req, res) => {
  try {
    const projectId = req.params.id;
    const userId = req.user.userId;
    const { plan2dUrl, model3dUrl } = req.body;

    const project = await Project.findById(projectId);
    if (!project) return res.status(404).json({ message: "Project not found" });

    if (String(project.ownerId) !== String(userId)) {
      return res.status(403).json({ message: "Only owner can upload assets" });
    }

    project.siteView = project.siteView || {};

    // upload once only
    if (plan2dUrl) {
      if (project.siteView.plan2dUrl) return res.status(400).json({ message: "2D already uploaded" });
      project.siteView.plan2dUrl = plan2dUrl;
    }

    if (model3dUrl) {
      if (project.siteView.model3dUrl) return res.status(400).json({ message: "3D already uploaded" });
      project.siteView.model3dUrl = model3dUrl;
    }

    await project.save();
    return res.json({ message: "Assets updated", siteView: project.siteView });
  } catch (err) {
    console.error("updateSiteAssets error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};
exports.setDprUploaders = async (req, res) => {
  try {
    const projectId = req.params.id;
    const userId = req.user.userId;
    const { uploaderIds } = req.body;

    const project = await Project.findById(projectId);
    if (!project) return res.status(404).json({ message: "Project not found" });

    if (String(project.ownerId) !== String(userId)) {
      return res.status(403).json({ message: "Only owner can set DPR uploaders" });
    }

    if (!Array.isArray(uploaderIds) || uploaderIds.length > 3) {
      return res.status(400).json({ message: "Max 3 uploaders allowed" });
    }

    const engineerIds = (project.engineers || []).map(String);
    const ok = uploaderIds.every((id) => engineerIds.includes(String(id)));
    if (!ok) return res.status(400).json({ message: "All uploaders must be engineers in project" });

    project.dprUploaders = uploaderIds;
    await project.save();

    return res.json({ message: "DPR uploaders updated", dprUploaders: project.dprUploaders });
  } catch (err) {
    console.error("setDprUploaders error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};

exports.uploadProjectDoc = async (req, res) => {
  try {
    const projectId = req.params.id;
    const userId = req.user.userId;
    const { key, url } = req.body;

    if (!key || !url) return res.status(400).json({ message: "key + url required" });

    const project = await Project.findById(projectId);
    if (!project) return res.status(404).json({ message: "Project not found" });

    if (String(project.ownerId) !== String(userId)) {
      return res.status(403).json({ message: "Only owner can upload docs" });
    }

    const doc = (project.docs || []).find((d) => d.key === key);
    if (!doc) return res.status(404).json({ message: "Doc not found" });

    // ✅ upload once
    if (doc.uploaded) return res.status(400).json({ message: "Doc already uploaded" });

    doc.url = url;
    doc.uploaded = true;
    doc.uploadedAt = new Date();

    await project.save();
    return res.json({ message: "Doc uploaded", docs: project.docs });
  } catch (err) {
    console.error("uploadProjectDoc error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};


// ✅ Create Project (Owner only)
exports.createProject = async (req, res) => {
  try {
    if (req.user.role !== "OWNER") {
      return res.status(403).json({ message: "Only OWNER can create project" });
    }

    const { projectName, location, bmc, overview, totalProjectCostCr } = req.body;

    if (!projectName) {
      return res.status(400).json({ message: "projectName required" });
    }

    const inviteCode = await genUniqueInviteCode();

    const project = await Project.create({
      projectName,
      ownerId: req.user.userId,

      managers: [],
      engineers: [],
      clients: [],

      location: location || {},
      bmc: bmc || {},
      overview: overview || {},
      costs: {
        totalProjectCostCr: Number(totalProjectCostCr || 0),
      },

      inviteCode,
      inviteEnabled: true,

      // ✅ docs initialized here
      docs: defaultDocs.map((d) => ({
        key: d.key,
        title: d.title,
        type: "manual",
        stage: d.stage,
        uploaded: false,
        url: "",
      })),
    });

    // ✅ AUTO CREATE TEAM CHAT GROUP (meta + state)
    await ProjectChatMeta.updateOne(
      { projectId: project._id, chatType: "TEAM" },
      {
        $set: {
          projectId: project._id,
          projectName: project.projectName,
          chatType: "TEAM",
          lastMessage: "Project created",
          lastMessageAt: new Date(),
          lastSender: {
            id: String(req.user.userId),
            role: req.user.role,
            name: req.user.name || "Owner",
          },
        },
      },
      { upsert: true }
    );

    // ✅ create owner chat state
    await ProjectChatState.updateOne(
      { userId: req.user.userId, projectId: project._id, chatType: "TEAM" },
      { $setOnInsert: { unreadCount: 0 } },
      { upsert: true }
    );



    return res.status(201).json({ project });
  } catch (err) {
    console.error("CREATE PROJECT ERROR:", err);
    return res.status(500).json({ message: "Server error" });
  }
};

// ✅ Get projects role-wise
exports.getMyProjects = async (req, res) => {
  try {
    const userId = req.user.userId;
    const role = req.user.role;

    const oid = new mongoose.Types.ObjectId(userId);

    let query = {};
    if (role === "OWNER") query = { ownerId: oid };
    if (role === "MANAGER") query = { managers: oid };
    if (role === "ENGINEER") query = { engineers: oid };
    if (role === "CLIENT") query = { clients: oid };

    const projects = await Project.find(query).sort({ createdAt: -1 });

    return res.json({ projects });
  } catch (err) {
    console.error("GET PROJECTS ERROR:", err);
    return res.status(500).json({ message: "Server error" });
  }
};


// ✅ Get single project (must be member)
exports.getProjectById = async (req, res) => {
  try {
    const projectId = req.params.id;
    const userId = req.user.userId;

    const project = await Project.findById(projectId);
    if (!project) return res.status(404).json({ message: "Project not found" });

    const isOwner = project.ownerId.toString() === userId;
    const isMember =
      isOwner ||
      project.managers.map(String).includes(userId) ||
      project.engineers.map(String).includes(userId) ||
      project.clients.map(String).includes(userId);

    if (!isMember) return res.status(403).json({ message: "Access denied" });

    return res.json({ project });
  } catch (err) {
    console.error("GET PROJECT ERROR:", err);
    return res.status(500).json({ message: "Server error" });
  }
};

// ✅ Regenerate Invite Code (Owner only)
exports.regenerateInviteCode = async (req, res) => {
  try {
    const projectId = req.params.id;
    const userId = req.user.userId;

    const project = await Project.findById(projectId);
    if (!project) return res.status(404).json({ message: "Project not found" });

    if (project.ownerId.toString() !== userId) {
      return res.status(403).json({ message: "Only owner can regenerate code" });
    }

    project.inviteCode = await genUniqueInviteCode();
    project.inviteEnabled = true;

    await project.save();

    return res.json({ inviteCode: project.inviteCode });
  } catch (err) {
    console.error("INVITE ERROR:", err);
    return res.status(500).json({ message: "Server error" });
  }
};

// ✅ Join Project by invite code
exports.joinProjectByCode = async (req, res) => {

  try {
    const { inviteCode } = req.body;
    const userId = req.user.userId;
    const role = req.user.role;

    const project = await Project.findOne({ inviteCode: inviteCode.toUpperCase() });
    if (!project) return res.status(404).json({ message: "Invalid invite code" });


    const already =
      String(project.ownerId) === String(userId) ||
      project.managers.map(String).includes(userId) ||
      project.engineers.map(String).includes(userId) ||
      project.clients.map(String).includes(userId);

    if (already) return res.json({ message: "Already joined", project });

    if (role === "ENGINEER") project.engineers.push(userId);
    if (role === "CLIENT") project.clients.push(userId);
    if (role === "MANAGER") project.managers.push(userId);


    await project.save();

    // ✅ Create chat state for new joined member (TEAM)
    await ProjectChatState.updateOne(
      { userId: userId, projectId: project._id, chatType: "TEAM" },
      { $setOnInsert: { unreadCount: 0 } },
      { upsert: true }
    );

    // ✅ Ensure TEAM meta exists (in case old projects were created before patch)
    await ProjectChatMeta.updateOne(
      { projectId: project._id, chatType: "TEAM" },
      {
        $setOnInsert: {
          projectId: project._id,
          projectName: project.projectName,
          chatType: "TEAM",
          lastMessage: "New member joined",
          lastMessageAt: new Date(),
          lastSender: {
            id: String(userId),
            role: role,
            name: req.user.name || "Member",
          },
        },
        $set: {
          lastMessageAt: new Date(),
        },
      },
      { upsert: true }
    );


    // ✅ confirm DB reflect (important)
    const check = await Project.findById(project._id);

    return res.json({ message: "Joined successfully", project });
  } catch (err) {
    console.error("JOIN ERROR:", err);
    return res.status(500).json({ message: "Server error" });
  }
};

exports.updateMapBoundary = async (req, res) => {
  try {
    const projectId = req.params.id;
    const userId = req.user.userId;

    const { centerLat, centerLng, radiusMeters } = req.body;

    if (centerLat == null || centerLng == null) {
      return res.status(400).json({ message: "centerLat + centerLng required" });
    }

    const radius = Number(radiusMeters || 200);
    if (radius < 10) {
      return res.status(400).json({ message: "radiusMeters must be >= 10" });
    }

    const project = await Project.findById(projectId);
    if (!project) return res.status(404).json({ message: "Project not found" });

    if (String(project.ownerId) !== String(userId)) {
      return res.status(403).json({ message: "Only owner can update site boundary" });
    }

    project.siteView = project.siteView || {};
    project.siteView.map = project.siteView.map || {};

    project.siteView.map.centerLat = Number(centerLat);
    project.siteView.map.centerLng = Number(centerLng);
    project.siteView.map.radiusMeters = radius;

    await project.save();

    return res.json({
      message: "Boundary updated",
      map: project.siteView.map,
    });
  } catch (err) {
    console.error("updateMapBoundary error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};
