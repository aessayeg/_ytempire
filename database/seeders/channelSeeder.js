/**
 * Channel Seeder
 * YTEmpire Project
 */

const mongoose = require('mongoose');
const Channel = require('../../backend/src/models/Channel');

const seedData = [
  // TODO: Add seed data
];

exports.seed = async () => {
  try {
    await Channel.deleteMany({});
    await Channel.insertMany(seedData);
    console.log('Channel seeded successfully');
  } catch (error) {
    console.error('Error seeding Channel:', error);
  }
};