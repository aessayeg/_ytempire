/**
 * Migration: Create Channels Table
 * YTEmpire Project
 */

exports.up = async (db) => {
  // TODO: Create table
  await db.createCollection('channels');
};

exports.down = async (db) => {
  // TODO: Drop table
  await db.dropCollection('channels');
};