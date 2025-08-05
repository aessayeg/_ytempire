/**
 * Models Index - Sequelize model initialization
 * YTEmpire Project
 */

const { sequelize, Sequelize } = require('../config/database');

// Import models
const User = require('./User');
const Profile = require('./Profile');
const Session = require('./Session');
const Channel = require('./Channel');
const Video = require('./Video');
const ChannelAnalytics = require('./ChannelAnalytics');
const VideoAnalytics = require('./VideoAnalytics');
const Campaign = require('./Campaign');
const CampaignVideo = require('./CampaignVideo');
const Notification = require('./Notification');
const ApiKey = require('./ApiKey');
const Configuration = require('./Configuration');
const AuditLog = require('./AuditLog');

// Initialize models
const models = {
  User: User(sequelize, Sequelize.DataTypes),
  Profile: Profile(sequelize, Sequelize.DataTypes),
  Session: Session(sequelize, Sequelize.DataTypes),
  Channel: Channel(sequelize, Sequelize.DataTypes),
  Video: Video(sequelize, Sequelize.DataTypes),
  ChannelAnalytics: ChannelAnalytics(sequelize, Sequelize.DataTypes),
  VideoAnalytics: VideoAnalytics(sequelize, Sequelize.DataTypes),
  Campaign: Campaign(sequelize, Sequelize.DataTypes),
  CampaignVideo: CampaignVideo(sequelize, Sequelize.DataTypes),
  Notification: Notification(sequelize, Sequelize.DataTypes),
  ApiKey: ApiKey(sequelize, Sequelize.DataTypes),
  Configuration: Configuration(sequelize, Sequelize.DataTypes),
  AuditLog: AuditLog(sequelize, Sequelize.DataTypes)
};

// Define associations
Object.keys(models).forEach(modelName => {
  if (models[modelName].associate) {
    models[modelName].associate(models);
  }
});

// Export models and sequelize instance
module.exports = {
  ...models,
  sequelize,
  Sequelize
};