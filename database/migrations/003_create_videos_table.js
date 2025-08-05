/**
 * Migration: Create Videos Table
 * YTEmpire Project
 */

exports.up = async (db) => {
  // TODO: Create table
  await db.createCollection('videos');
};

exports.down = async (db) => {
  // TODO: Drop table
  await db.dropCollection('videos');
};