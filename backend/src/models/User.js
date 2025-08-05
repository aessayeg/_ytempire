/**
 * User Model - Manages user accounts and authentication
 * YTEmpire Project
 */

const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  // TODO: Define schema fields
}, {
  timestamps: true
});

// TODO: Add model methods and virtuals

module.exports = mongoose.model('User', userSchema);