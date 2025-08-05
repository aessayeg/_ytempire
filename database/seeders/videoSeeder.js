/**
 * Video Seeder
 * YTEmpire Project
 */

const mongoose = require('mongoose');
const Video = require('../../backend/src/models/Video');

const seedData = [
  // TODO: Add seed data
];

exports.seed = async () => {
  try {
    await Video.deleteMany({});
    await Video.insertMany(seedData);
    console.log('Video seeded successfully');
  } catch (error) {
    console.error('Error seeding Video:', error);
  }
};