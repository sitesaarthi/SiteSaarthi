const mongoose = require("mongoose");
require("dotenv").config();

const Project = require("../src/models/Project.model");
const ProjectChatMeta = require("../src/models/ProjectChatMeta");
const ProjectChatState = require("../src/models/ProjectChatState");


async function run() {
  await mongoose.connect(process.env.MONGO_URI);

  const projects = await Project.find({});
  console.log("Projects found:", projects.length);

  for (const p of projects) {
    await ProjectChatMeta.updateOne(
      { projectId: p._id, chatType: "TEAM" },
      {
        $setOnInsert: {
          projectId: p._id,
          projectName: p.projectName,
          chatType: "TEAM",
          lastMessage: "Project created",
          lastMessageAt: p.createdAt || new Date(),
          lastSender: null,
        },
      },
      { upsert: true }
    );

    await ProjectChatState.updateOne(
      { userId: p.ownerId, projectId: p._id, chatType: "TEAM" },
      { $setOnInsert: { unreadCount: 0 } },
      { upsert: true }
    );

    console.log("✅ migrated:", p.projectName);
  }

  console.log("✅ Migration complete");
  process.exit(0);
}

run().catch((e) => {
  console.error("Migration failed:", e);
  process.exit(1);
});
