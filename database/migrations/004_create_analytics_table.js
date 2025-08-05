/**
 * Migration: Create Analytics Table
 * YTEmpire Project
 */

exports.up = async (db) => {
  // TODO: Create table
  await db.createCollection('analytics');
};

exports.down = async (db) => {
  // TODO: Drop table
  await db.dropCollection('analytics');
};