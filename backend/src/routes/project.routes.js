const express = require("express");
const router = express.Router();
const project = require("../controllers/project.controller");
const authMiddleware = require("../middleware/auth.middleware"); 
// IMPORTANT: join/code should be above :id routes
router.post("/join/code", authMiddleware, project.joinProjectByCode);

router.post("/", authMiddleware, project.createProject);
router.get("/", authMiddleware, project.getMyProjects);
router.get("/:id", authMiddleware, project.getProjectById);

router.post("/:id/invite", authMiddleware, project.regenerateInviteCode);
router.get("/:id/members", authMiddleware, project.getProjectMembers);

// ✅ Docs Upload (Owner only)
router.patch("/:id/docs/upload", authMiddleware, project.uploadProjectDoc);

// ✅ SiteView Map
router.patch("/:id/siteview/map", authMiddleware, project.updateProjectMap);
router.patch("/:id/siteview/boundary", authMiddleware, project.updateMapBoundary);

router.post("/:id/siteview/marker", authMiddleware, project.addMapMarker);
router.delete("/:id/siteview/marker/:index", authMiddleware, project.deleteMapMarker);

// ✅ Upload 2D/3D URLs (Owner only)
router.patch("/:id/siteview/assets", authMiddleware, project.updateSiteAssets);

// ✅ Choose 3 DPR upload engineers (Owner only)
router.patch("/:id/dpr-uploaders", authMiddleware, project.setDprUploaders);

module.exports = router;
