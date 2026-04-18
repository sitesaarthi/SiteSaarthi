const Project = require("../models/Project.model");
const Dpr = require("../models/Dpr.model");

exports.createDpr = async (req, res) => {
  try {
    const { projectId, date, title, workDone, issues, photos, fileUrl } = req.body;
    const userId = req.user.userId;

    if (!projectId || !date) {
      return res.status(400).json({ message: "projectId + date required" });
    }

    const project = await Project.findById(projectId);
    if (!project) return res.status(404).json({ message: "Project not found" });

    // must be project engineer
    const isEngineer = (project.engineers || []).map(String).includes(String(userId));
    if (!isEngineer) return res.status(403).json({ message: "Only engineers can upload DPR" });

    // must be allowed uploader
    const allowed = (project.dprUploaders || []).map(String).includes(String(userId));
    if (!allowed) return res.status(403).json({ message: "Not allowed to upload DPR" });

    const dpr = await Dpr.create({
      projectId,
      uploadedBy: userId,
      date: new Date(date),
      title: title || "",
      workDone: workDone || "",
      issues: issues || "",
      photos: photos || [],
      fileUrl: fileUrl || "",
    });

    return res.status(201).json({ dpr });
  } catch (err) {
    console.error("CREATE DPR ERROR:", err);
    return res.status(500).json({ message: "Server error" });
  }
};

exports.getProjectDprs = async (req, res) => {
  try {
    const { projectId } = req.params;
    const userId = req.user.userId;

    const project = await Project.findById(projectId);
    if (!project) return res.status(404).json({ message: "Project not found" });

    const isMember =
      String(project.ownerId) === String(userId) ||
      (project.managers || []).map(String).includes(String(userId)) ||
      (project.engineers || []).map(String).includes(String(userId)) ||
      (project.clients || []).map(String).includes(String(userId));

    if (!isMember) return res.status(403).json({ message: "Access denied" });

    const dprs = await Dpr.find({ projectId }).sort({ date: -1 });
    return res.json({ dprs });
  } catch (err) {
    console.error("GET DPR ERROR:", err);
    return res.status(500).json({ message: "Server error" });
  }
};
