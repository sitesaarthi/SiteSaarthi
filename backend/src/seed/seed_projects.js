require("dotenv").config();
const mongoose = require("mongoose");
const Project = require("../models/Project.model");
const User = require("../models/User.model");
const { nanoid } = require("nanoid");

const invite = () => nanoid(6).toUpperCase();

async function connect() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log("✅ MongoDB connected for seeding projects");
}

async function seedProjects() {
  await Project.deleteMany({});

  const owner1 = await User.findOne({ phone: "9000000001" });
  const owner2 = await User.findOne({ phone: "9000000002" });
  const owner3 = await User.findOne({ phone: "9000000003" });

  const engineers = await User.find({ role: "ENGINEER" }).sort({ createdAt: 1 });
  const managers = await User.find({ role: "MANAGER" }).sort({ createdAt: 1 });
  const clients = await User.find({ role: "CLIENT" }).sort({ createdAt: 1 });

  // Allocation
  // Owner1:
  //  - Project1: 3 engineers, 1 client
  //  - Project3: 1 manager, 5 engineers, 1 client
  // Owner2:
  //  - Project2: 4 engineers, 1 client
  // Owner3:
  //  - Project4: 3 managers, 8 engineers, 2 clients

  const proj1Engineers = engineers.slice(0, 3).map((u) => u._id);
  const proj1Client = [clients[0]._id];

  const proj3Manager = [managers[0]._id];
  const proj3Engineers = engineers.slice(3, 8).map((u) => u._id);
  const proj3Client = [clients[1]._id];

  const proj2Engineers = engineers.slice(8, 12).map((u) => u._id);
  const proj2Client = [clients[2]._id];

  const proj4Managers = managers.slice(1, 4).map((u) => u._id);
  const proj4Engineers = engineers.slice(12, 20).map((u) => u._id);
  const proj4Clients = [clients[3]._id, clients[4]._id];

  // PROJECT 1 – ISKCON MANDIR
  await Project.create({
    projectName: "Shri Radha Krishna Mandir (ISKCON Mandir)",
    ownerId: owner1._id,
    managers: [],
    engineers: proj1Engineers,
    clients: proj1Client,
    inviteCode: invite(),
    inviteEnabled: true,

    location: {
      state: "Maharashtra",
      district: "Mumbai Suburban",
      taluka: "Andheri",
      addressLine: "Andheri West, Mumbai",
    },

    bmc: {
      ward: "K West (Andheri West)",
      zoneType: "Suburban – High land value",
      fsiBase: 1.33,
      effectiveFsi: 2.0,
      roadWidth: "18–24 m",
      heightControl: "~45–50 ft",
      wardCostIndexFactor: 1.20,
    },

    overview: {
      builtUpAreaSqft: 5200,
      floors: "G+0",
      structure: "RCC + stone cladding",
      finishLevel: "ISKCON-style (standard)",
      durationMonthsMin: 12,
      durationMonthsMax: 15,
      slab: "0–20 Cr",
    },

    labour: {
      totalAvgWorkforce: 71,
      categories: [
        { category: "Skilled artisans (stone/marble)", count: 22, approxCostLevel: "High" },
        { category: "RCC + shuttering labour", count: 18, approxCostLevel: "Medium" },
        { category: "Helpers & general labour", count: 28, approxCostLevel: "Medium" },
        { category: "Engineer", count: 3, approxCostLevel: "Fixed monthly" },
      ],
    },

    costs: {
      materialPercent: 46,
      labourPercent: 18,
      transportPercent: 6,
      contractorPercent: 12,
      consultantPercent: 8,

      materialCosts: [
        { item: "Cement, steel, aggregates", costCr: 2.10 },
        { item: "Marble (Makrana/Italian mix)", costCr: 3.20 },
        { item: "Stone cladding & carving", costCr: 2.10 },
        { item: "Electrical & lighting", costCr: 0.80 },
        { item: "Plumbing & utilities", costCr: 0.40 },
      ],
      labourCosts: [
        { item: "Skilled stone artisans", costCr: 1.30 },
        { item: "RCC & finishing labour", costCr: 0.90 },
        { item: "Helpers & misc labour", costCr: 0.40 },
        { item: "Engineer", costCr: 1.40 },
      ],
      transportCosts: [
        { item: "Marble transport (Rajasthan → Mumbai)", costCr: 0.55 },
        { item: "Stone, steel local transport", costCr: 0.35 },
        { item: "Crane, unloading, handling", costCr: 0.25 },
      ],
      contractorCosts: [
        { item: "Contractor margin (8–10%)", costCr: 1.35 },
        { item: "Site setup, temporary works", costCr: 0.45 },
      ],
      consultantCosts: [
        { item: "Architect + structural + MEP", costCr: 0.40 },
        { item: "BMC fees, NOCs, drawings", costCr: 0.30 },
        { item: "Contingency / Misc buffer", costCr: 0.60 },
      ],
      totalProjectCostCr: 16.85,
    },

    dpr: { expectedRangeMin: 365, expectedRangeMax: 500 },

    impact: {
      beforeProblems: [
        "Site progress dependent on manual registers and WhatsApp photos",
        "Labour attendance had fake entries and mismatches",
        "Material usage not tracked in real time",
        "Cost overruns discovered only at the end",
        "No single source of truth between engineer, contractor, and owner",
        "Delays and coordination issues common in long-duration projects",
      ],
      lossAreas: [
        { area: "Labour leakage", description: "Fake attendance, over-reporting workers, idle labour time", approxLossOrSavings: "₹35 lakh" },
        { area: "Material leakage", description: "Marble/stone wastage, cement & steel overuse, no daily reconciliation", approxLossOrSavings: "₹50 lakh" },
        { area: "Delay cost", description: "2–3 months delay, extra overhead, extended labour & supervision", approxLossOrSavings: "₹70 lakh" },
      ],
      totalOwnerLoss: "₹1.5–1.6 Cr",

      afterSolutions: [
        "Digital project dashboard with ward, slab, index-based costing",
        "Role-wise labour tracking",
        "Daily Progress Reports supported by geo-tagged photos",
        "Material inflow/outflow digitally logged and auditable",
        "Real-time cost vs budget visibility",
        "Contingency planning using data-backed risk tracking",
      ],
      benefitAreas: [
        { area: "Labour efficiency", description: "GPS + digital DPR, role-wise tracking, productivity visibility", approxLossOrSavings: "₹30 lakh" },
        { area: "Material control", description: "Inward–outward record, photo + quantity proof, reduced wastage", approxLossOrSavings: "₹40 lakh" },
        { area: "Time reduction", description: "Faster approvals, less rework, fewer disputes", approxLossOrSavings: "₹35 lakh" },
      ],
      totalOwnerSavings: "₹1.0–1.1 Cr",
      appCharges: "₹1,50,000",
      roi: "6,667%",
    },
  });

  // PROJECT 2 – WAREHOUSE STORAGE
  await Project.create({
    projectName: "Central Warehouse Storage Facility",
    ownerId: owner2._id,
    managers: [],
    engineers: proj2Engineers,
    clients: proj2Client,
    inviteCode: invite(),
    inviteEnabled: true,

    location: {
      state: "Maharashtra",
      district: "Mumbai",
      taluka: "Mulund",
      addressLine: "Mulund West, Mumbai",
    },

    bmc: {
      ward: "T Ward (Mulund West)",
      zoneType: "Industrial / Logistics Zone",
      fsiBase: 1.00,
      effectiveFsi: 1.50,
      roadWidth: "30 m",
      heightControl: "12–15 m",
      wardCostIndexFactor: 1.10,
    },

    overview: {
      builtUpAreaSqft: 120000,
      floors: "G + 1 (Mezzanine)",
      structure: "PEB + RCC",
      finishLevel: "Industrial – Heavy Duty",
      durationMonthsMin: 18,
      durationMonthsMax: 24,
      slab: "20–100 Cr",
    },

    labour: {
      totalAvgWorkforce: 170,
      categories: [
        { category: "RCC + foundation labour", count: 45, approxCostLevel: "Medium" },
        { category: "PEB steel erection workers", count: 40, approxCostLevel: "High" },
        { category: "Electrical & fire labour", count: 18, approxCostLevel: "Medium" },
        { category: "Flooring & finishing labour", count: 22, approxCostLevel: "Medium" },
        { category: "Helpers & general labour", count: 45, approxCostLevel: "Medium" },
        { category: "Engineers & supervisors", count: 8, approxCostLevel: "Fixed monthly" },
      ],
    },

    costs: {
      materialPercent: 50,
      labourPercent: 15,
      transportPercent: 7,
      contractorPercent: 10,
      consultantPercent: 5,

      materialCosts: [
        { item: "Structural steel (PEB + RCC)", costCr: 16.50 },
        { item: "Cement, aggregates", costCr: 8.20 },
        { item: "Industrial flooring", costCr: 6.10 },
        { item: "Electrical & fire systems", costCr: 4.30 },
        { item: "Roofing & cladding", costCr: 3.40 },
      ],
      labourCosts: [
        { item: "RCC & foundation labour", costCr: 3.10 },
        { item: "Steel / PEB erection labour", costCr: 3.40 },
        { item: "Flooring & finishing labour", costCr: 2.20 },
        { item: "Helpers & general labour", costCr: 2.10 },
        { item: "Engineers & supervisors", costCr: 2.20 },
      ],
      transportCosts: [
        { item: "Steel transport", costCr: 2.90 },
        { item: "Cranes & heavy equipment", costCr: 1.80 },
        { item: "Local material transport", costCr: 1.20 },
      ],
      contractorCosts: [
        { item: "Contractor margin", costCr: 4.20 },
        { item: "Site setup & temporary works", costCr: 1.40 },
      ],
      consultantCosts: [
        { item: "Architect + structural + MEP", costCr: 1.10 },
        { item: "Fire, factory & BMC approvals", costCr: 0.80 },
        { item: "Contingency / index buffer", costCr: 1.10 },
      ],

      totalProjectCostCr: 66.0,
    },

    impact: {
      beforeProblems: [
        "Labour attendance maintained manually for large workforce",
        "Steel, cement & flooring quantities not tracked daily",
        "No real-time cost vs progress visibility",
        "Delay risks due to coordination gaps",
        "High leakage risk in long-duration industrial projects",
      ],
      lossAreas: [
        { area: "Labour leakage", description: "Fake attendance, over-reporting workers, idle labour", approxLossOrSavings: "₹1.10 Cr" },
        { area: "Material leakage", description: "Steel wastage, cement overuse, no daily reconciliation", approxLossOrSavings: "₹1.40 Cr" },
        { area: "Delay cost", description: "2–3 months delay, extended supervision & site overhead", approxLossOrSavings: "₹1.20 Cr" },
        { area: "Rework & coordination gaps", description: "Incorrect execution, redoing works", approxLossOrSavings: "₹0.60 Cr" },
      ],
      totalOwnerLoss: "₹4.3 Cr",

      afterSolutions: [
        "Centralized dashboard for warehouse project",
        "GPS-based labour attendance & role-wise tracking",
        "Digital material inflow–outflow logs",
        "DPR with geo-tagged site photos",
        "Owner-level real-time cost & progress visibility",
      ],
      benefitAreas: [
        { area: "Labour efficiency", description: "GPS attendance, role-wise tracking, productivity visibility", approxLossOrSavings: "₹1.30 Cr" },
        { area: "Material control", description: "Inward–outward logs, quantity + photo proof", approxLossOrSavings: "₹1.50 Cr" },
        { area: "Time reduction", description: "Faster decisions, fewer disputes, reduced delays", approxLossOrSavings: "₹0.90 Cr" },
        { area: "Reduced rework", description: "Better coordination via DPR & reports", approxLossOrSavings: "₹0.50 Cr" },
      ],
      totalOwnerSavings: "₹4.2 Cr",
      appCharges: "₹7,65,000",
      roi: "~5,490%",
    },
  });

  // PROJECT 3 – WHOLE BUILDING (NEW CONSTRUCTION)
  await Project.create({
    projectName: "Sapphire Heights – Premium Residential Tower",
    ownerId: owner1._id,
    managers: proj3Manager,
    engineers: proj3Engineers,
    clients: proj3Client,
    inviteCode: invite(),
    inviteEnabled: true,

    location: {
      state: "Maharashtra",
      district: "Mumbai City",
      taluka: "Fort/Colaba",
      addressLine: "South Mumbai – Fort / Colaba belt",
    },

    bmc: {
      ward: "A Ward (South Mumbai – Fort/Colaba)",
      zoneType: "Prime CBD / High land value",
      fsiBase: 1.33,
      effectiveFsi: 3.50,
      roadWidth: "30–36 m",
      heightControl: "As per DP 2034 + Fire norms",
      wardCostIndexFactor: 1.45,
    },

    overview: {
      builtUpAreaSqft: 350000,
      floors: "B2 + G + 28 Floors",
      structure: "RCC Frame (Mivan / Shear Wall)",
      finishLevel: "Premium / Luxury",
      durationMonthsMin: 36,
      durationMonthsMax: 42,
      slab: "100–300 Cr",
    },

    costs: {
      materialPercent: 48,
      labourPercent: 18,
      transportPercent: 6,
      contractorPercent: 10,
      consultantPercent: 8,
      materialCosts: [
        { item: "Cement, steel & concrete", costCr: 55.0 },
        { item: "Façade & glazing", costCr: 26.0 },
        { item: "Premium flooring & fittings", costCr: 24.0 },
        { item: "Electrical, plumbing & fire", costCr: 18.0 },
        { item: "Lifts, DG, STP, solar", costCr: 12.0 },
      ],
      labourCosts: [
        { item: "RCC & structure labour", costCr: 18.0 },
        { item: "Finishing labour", costCr: 14.0 },
        { item: "Helpers & misc labour", costCr: 11.0 },
        { item: "Engineers & supervisors", costCr: 9.0 },
      ],
      transportCosts: [
        { item: "Material transport (restricted hours)", costCr: 9.5 },
        { item: "Tower cranes & machinery", costCr: 5.5 },
        { item: "Loading, unloading & storage", costCr: 2.0 },
      ],
      contractorCosts: [
        { item: "Contractor margin", costCr: 22.0 },
        { item: "Site setup, safety & temp works", costCr: 7.0 },
      ],
      consultantCosts: [
        { item: "Architect + structural + MEP", costCr: 6.5 },
        { item: "BMC, fire, aviation approvals", costCr: 5.0 },
        { item: "Contingency / index buffer", costCr: 7.5 },
      ],
      totalProjectCostCr: 252.0,
    },

    impact: {
      totalOwnerLoss: "₹23.5 Cr",
      totalOwnerSavings: "₹23.0 Cr",
      appCharges: "₹24 lakh",
      roi: "9,583%",
      afterSolutions: [
        "Centralized dashboard for entire tower",
        "GPS-based labour & subcontractor tracking",
        "Material tracking for high-value items",
        "Floor-wise DPR with geo-tagged photos",
        "Owner-level control over time, cost & quality",
      ],
    },
  });

  // PROJECT 4 – MEGA RESIDENTIAL SOCIETY
  await Project.create({
    projectName: "GreenVista Township – Borivali",
    ownerId: owner3._id,
    managers: proj4Managers,
    engineers: proj4Engineers,
    clients: proj4Clients,
    inviteCode: invite(),
    inviteEnabled: true,

    location: {
      state: "Maharashtra",
      district: "Mumbai Suburban",
      taluka: "Borivali",
      addressLine: "Borivali West, Mumbai",
    },

    bmc: {
      ward: "R Central Ward (Borivali West)",
      zoneType: "Suburban Residential (High Density)",
      fsiBase: 1.33,
      effectiveFsi: 3.80,
      roadWidth: "24–30 m",
      heightControl: "As per DP 2034 + Fire norms",
      wardCostIndexFactor: 1.25,
    },

    overview: {
      builtUpAreaSqft: 850000,
      floors: "B2 + G + 22–25 Floors",
      structure: "RCC (Shear Wall / Mivan)",
      finishLevel: "Premium",
      durationMonthsMin: 48,
      durationMonthsMax: 60,
      slab: "300 Cr+",
    },

    costs: {
      totalProjectCostCr: 575.0,
    },

    impact: {
      totalOwnerLoss: "₹55 Cr",
      totalOwnerSavings: "₹55 Cr",
      appCharges: "₹50 lakh",
      roi: "10,000%+",
    },
  });

  console.log("✅ Projects seeded successfully");
}

(async () => {
  try {
    await connect();
    await seedProjects();
    process.exit(0);
  } catch (err) {
    console.error("❌ seed_projects error:", err);
    process.exit(1);
  }
})();
