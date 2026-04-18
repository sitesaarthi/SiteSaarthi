const express = require("express");
const router = express.Router();

const authMiddleware = require("../middleware/auth.middleware");
const approvalController = require("../controllers/approval.controller");

// ✅ OWNER approvals
router.get("/", authMiddleware, approvalController.getOwnerApprovals);

// ✅ ENGINEER/MANAGER global list
router.get("/global", authMiddleware, approvalController.getGlobalApprovals);

// ✅ per project approvals
router.get("/project/:projectId", authMiddleware, approvalController.getProjectApprovals);

// ✅ create requests
router.post("/material", authMiddleware, approvalController.createMaterialRequest);
router.post("/funds", authMiddleware, approvalController.createFundsRequest);
router.post("/task", authMiddleware, approvalController.createTaskRequest);


// ✅ decision
router.patch("/:id/approve", authMiddleware, approvalController.approveRequest);
router.patch("/:id/reject", authMiddleware, approvalController.rejectRequest);

module.exports = router;
