const DocHistory = require("../models/DocHistory.model");

exports.createDocHistory = async (payload) => {
  return DocHistory.create(payload);
};
