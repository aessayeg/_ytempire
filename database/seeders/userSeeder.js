/**
 * User Seeder
 * YTEmpire Project
 */

const mongoose = require('mongoose');
const User = require('../../backend/src/models/User');

const seedData = [
  // TODO: Add seed data
];

exports.seed = async () => {
  try {
    await User.deleteMany({});
    await User.insertMany(seedData);
    console.log('User seeded successfully');
  } catch (error) {
    console.error('Error seeding User:', error);
  }
};