require("dotenv").config();
const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");

const User = require("../models/User.model");

async function connect() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log("✅ MongoDB connected for seeding users");
}

async function seedUsers() {
  // Clear existing users (optional)
  await User.deleteMany({});

  const passwordHash = await bcrypt.hash("123456", 10);

  // Owners
  const owner1 = await User.create({
    name: "Owner 1",
    phone: "9000000001",
    passwordHash,
    role: "OWNER",
  });

  const owner2 = await User.create({
    name: "Owner 2",
    phone: "9000000002",
    passwordHash,
    role: "OWNER",
  });

  const owner3 = await User.create({
    name: "Owner 3",
    phone: "9000000003",
    passwordHash,
    role: "OWNER",
  });

  // Engineers
  const engineers = [];
  for (let i = 1; i <= 20; i++) {
    engineers.push(
      await User.create({
        name: `Engineer ${i}`,
        phone: `91111000${String(i).padStart(2, "0")}`,
        passwordHash,
        role: "ENGINEER",
      })
    );
  }

  // Managers
  const managers = [];
  for (let i = 1; i <= 5; i++) {
    managers.push(
      await User.create({
        name: `Manager ${i}`,
        phone: `92222000${String(i).padStart(2, "0")}`,
        passwordHash,
        role: "MANAGER",
      })
    );
  }

  // Clients
  const clients = [];
  for (let i = 1; i <= 5; i++) {
    clients.push(
      await User.create({
        name: `Client ${i}`,
        phone: `93333000${String(i).padStart(2, "0")}`,
        passwordHash,
        role: "CLIENT",
      })
    );
  }

  console.log("✅ Users seeded successfully");

  return { owner1, owner2, owner3, engineers, managers, clients };
}

(async () => {
  try {
    await connect();
    await seedUsers();
    process.exit(0);
  } catch (err) {
    console.error("❌ seed_users error:", err);
    process.exit(1);
  }
})();
