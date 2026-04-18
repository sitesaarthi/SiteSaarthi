const mongoose = require("mongoose");

const labourCategorySchema = new mongoose.Schema(
  {
    category: { type: String, required: true }, // Skilled artisans etc
    count: { type: Number, default: 0 },
    approxCostLevel: { type: String, default: "" }, // High/Medium/Fixed monthly
  },
  { _id: false }
);

const costItemSchema = new mongoose.Schema(
  {
    item: { type: String, required: true }, // Cement, steel...
    costCr: { type: Number, default: 0 },
  },
  { _id: false }
);

const lossBenefitSchema = new mongoose.Schema(
  {
    area: { type: String, required: true },
    description: { type: String, default: "" },
    approxLossOrSavings: { type: String, default: "" }, // "₹35 lakh" etc
  },
  { _id: false }
);

const projectSchema = new mongoose.Schema(
  {
    // Basic
    projectName: { type: String, required: true, trim: true },
    status: { type: String, enum: ["ACTIVE", "COMPLETED"], default: "ACTIVE" },
    // ✅ DPR permissions
    dprUploaders: [{ type: mongoose.Schema.Types.ObjectId, ref: "User" }],

    // Location
    location: {
      state: { type: String, default: "" },
      district: { type: String, default: "" },
      taluka: { type: String, default: "" },
      addressLine: { type: String, default: "" },
    },

    // Owner + Team
    ownerId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    managers: [{ type: mongoose.Schema.Types.ObjectId, ref: "User" }],
    engineers: [{ type: mongoose.Schema.Types.ObjectId, ref: "User" }],
    clients: [{ type: mongoose.Schema.Types.ObjectId, ref: "User" }],

    // Invite join system
    inviteCode: { type: String, unique: true, sparse: true },
    inviteEnabled: { type: Boolean, default: true },

    // BMC Ward & Index
    bmc: {
      ward: { type: String, default: "" },
      zoneType: { type: String, default: "" },
      fsiBase: { type: Number, default: 0 },
      effectiveFsi: { type: Number, default: 0 },
      roadWidth: { type: String, default: "" },
      heightControl: { type: String, default: "" },
      wardCostIndexFactor: { type: Number, default: 0 },
    },

    // Overview
    overview: {
      builtUpAreaSqft: { type: Number, default: 0 },
      floors: { type: String, default: "" },
      structure: { type: String, default: "" },
      finishLevel: { type: String, default: "" },
      durationMonthsMin: { type: Number, default: 0 },
      durationMonthsMax: { type: Number, default: 0 },
      slab: { type: String, default: "" }, // 0–20 Cr, 20–100 Cr...
    },

    // Labour force peak
    labour: {
      totalAvgWorkforce: { type: Number, default: 0 },
      categories: [labourCategorySchema],
    },

    // Cost breakup
    costs: {
      materialPercent: { type: Number, default: 0 },
      labourPercent: { type: Number, default: 0 },
      transportPercent: { type: Number, default: 0 },
      contractorPercent: { type: Number, default: 0 },
      consultantPercent: { type: Number, default: 0 },

      materialCosts: [costItemSchema],
      labourCosts: [costItemSchema],
      transportCosts: [costItemSchema],
      contractorCosts: [costItemSchema],
      consultantCosts: [costItemSchema],

      totalProjectCostCr: { type: Number, default: 0 },
    },

    // ✅ Docs (7 docs)
    // ✅ Docs (7 docs)
docs: {
  type: [
    {
      key: { type: String, required: true },
      title: { type: String, default: "" },

      type: { type: String, enum: ["manual", "auto"], default: "manual" },
      stage: { type: String, enum: ["INIT", "LATER"], default: "INIT" },

      uploaded: { type: Boolean, default: false },
      url: { type: String, default: "" },

      uploadedAt: { type: Date, default: null },
    },
  ],

  // ✅ auto inject default docs when project created
  default: [
    { key: "rera", title: "RERA Certificate", type: "manual", stage: "INIT" },
    { key: "iod", title: "IOD", type: "manual", stage: "INIT" },
    { key: "cc", title: "Commencement Certificate", type: "manual", stage: "INIT" },

    { key: "proposal_report", title: "Proposal Report", type: "auto", stage: "LATER" },
    { key: "quotation", title: "Quotation", type: "auto", stage: "LATER" },
    { key: "po", title: "Purchase Order", type: "auto", stage: "LATER" },
    { key: "gst", title: "GST Invoice", type: "auto", stage: "LATER" },
  ],
},




    siteView: {
  map: {
    centerLat: { type: Number, default: null },
    centerLng: { type: Number, default: null },
    zoom: { type: Number, default: 16 },

    radiusMeters: { type: Number, default: null },

    markers: [
      {
        title: { type: String, default: "" },
        lat: { type: Number, default: 0 },
        lng: { type: Number, default: 0 },
      },
    ],
  },
  plan2dUrl: { type: String, default: "" },
  model3dUrl: { type: String, default: "" },
},




    // DPR
    dpr: {
      expectedRangeMin: { type: Number, default: 0 },
      expectedRangeMax: { type: Number, default: 0 },
    },
    // Before/After + ROI
    impact: {
      beforeProblems: [{ type: String }],
      afterSolutions: [{ type: String }],
      lossAreas: [lossBenefitSchema],
      benefitAreas: [lossBenefitSchema],

      totalOwnerLoss: { type: String, default: "" }, // "₹1.5–1.6 Cr"
      totalOwnerSavings: { type: String, default: "" }, // "₹1.0–1.1 Cr"
      appCharges: { type: String, default: "" }, // "₹1,50,000"
      roi: { type: String, default: "" }, // "6,667%"
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Project", projectSchema);
