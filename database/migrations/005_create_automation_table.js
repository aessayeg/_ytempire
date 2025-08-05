/**
 * Migration: Create Automation Table
 * YTEmpire Project
 */

exports.up = async (db) => {
  // TODO: Create table
  await db.createCollection('automation');
};

exports.down = async (db) => {
  // TODO: Drop table
  await db.dropCollection('automation');
};