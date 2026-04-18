const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const User = require("../models/User.model");

const signToken = (user) => {
  return jwt.sign(
    { userId: user._id, role: user.role },
    process.env.JWT_SECRET,
    { expiresIn: "30d" }
  );
};

// ==============================
// ✅ REGISTER
// ==============================
exports.register = async (req, res) => {
  try {
    const { name, phone, password, role } = req.body;

    if (!name || !phone || !password) {
      return res.status(400).json({
        message: "Name, phone, password required",
      });
    }

    const existing = await User.findOne({ phone });
    if (existing) {
      return res.status(409).json({
        message: "Phone already registered",
      });
    }

    const passwordHash = await bcrypt.hash(password, 10);

    const user = await User.create({
      name,
      phone,
      passwordHash,
      role: role || "OWNER",
    });

    const token = signToken(user);

    return res.status(201).json({
      message: "Registered successfully",
      token,
      user: {
        id: user._id,
        name: user.name,
        phone: user.phone,
        role: user.role,
      },
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: "Server error" });
  }
};

// ==============================
// ✅ LOGIN (FIXED + SALES AUTO LOGIN)
// ==============================
exports.login = async (req, res) => {
  try {
    const { phone, password } = req.body;

    // 🔥 HACKATHON: SALES AUTO LOGIN (NO PASSWORD)
    if (phone === "8104751559") {
      return res.status(200).json({
        message: "Sales login success",
        token: "demo-sales-token",
        user: {
          id: "sales_1",
          name: "Sales Executive",
          phone: "8104751559",
          role: "SALES",
        },
      });
    }

    // NORMAL LOGIN FLOW
    if (!phone || !password) {
      return res.status(400).json({
        message: "Phone + password required",
      });
    }

    const user = await User.findOne({ phone });
    if (!user) {
      return res.status(401).json({
        message: "Invalid credentials",
      });
    }

    const ok = await bcrypt.compare(password, user.passwordHash);
    if (!ok) {
      return res.status(401).json({
        message: "Invalid credentials",
      });
    }

    const token = signToken(user);

    return res.status(200).json({
      message: "Login success",
      token,
      user: {
        id: user._id,
        name: user.name,
        phone: user.phone,
        role: user.role,
      },
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: "Server error" });
  }
};

// ==============================
// ✅ ME PROFILE
// ==============================
exports.me = async (req, res) => {
  try {
    const user = await User.findById(req.user.userId).select("-passwordHash");
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }
    return res.json({ user });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: "Server error" });
  }
};
