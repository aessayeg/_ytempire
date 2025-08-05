/**
 * Migration: Create Users Table
 * YTEmpire Project
 */

exports.up = async (db) => {
  // TODO: Create table
  await db.createCollection('users');
};

exports.down = async (db) => {
  // TODO: Drop table
  await db.dropCollection('users');
};