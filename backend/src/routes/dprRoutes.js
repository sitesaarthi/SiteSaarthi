const router = require("express").Router();
const auth = require("../middleware/auth.middleware");
const dprCtrl = require("../controllers/dprController");

router.post("/", auth, dprCtrl.createDpr);
router.get("/:projectId", auth, dprCtrl.getProjectDprs);

module.exports = router;
