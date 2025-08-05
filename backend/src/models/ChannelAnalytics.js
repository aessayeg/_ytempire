/**
 * ChannelAnalytics Model - Sequelize model for analytics.channel_analytics table
 * YTEmpire Project
 */

module.exports = (sequelize, DataTypes) => {
  const ChannelAnalytics = sequelize.define(
    'ChannelAnalytics',
    {
      analytics_id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
      },
      channel_id: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
          model: 'channels',
          key: 'channel_id',
        },
      },
      analytics_date: {
        type: DataTypes.DATEONLY,
        allowNull: false,
      },
      views: {
        type: DataTypes.BIGINT,
        defaultValue: 0,
      },
      watch_time_minutes: {
        type: DataTypes.BIGINT,
        defaultValue: 0,
      },
      subscribers_gained: {
        type: DataTypes.INTEGER,
        defaultValue: 0,
      },
      subscribers_lost: {
        type: DataTypes.INTEGER,
        defaultValue: 0,
      },
      revenue_usd: {
        type: DataTypes.DECIMAL(10, 2),
        defaultValue: 0,
      },
      impressions: {
        type: DataTypes.BIGINT,
        defaultValue: 0,
      },
      clicks: {
        type: DataTypes.BIGINT,
        defaultValue: 0,
      },
      ctr: {
        type: DataTypes.DECIMAL(5, 2),
        defaultValue: 0,
      },
      average_view_duration_seconds: {
        type: DataTypes.INTEGER,
        defaultValue: 0,
      },
      demographic_data: {
        type: DataTypes.JSONB,
        defaultValue: {},
      },
      geography_data: {
        type: DataTypes.JSONB,
        defaultValue: {},
      },
      device_data: {
        type: DataTypes.JSONB,
        defaultValue: {},
      },
      traffic_source_data: {
        type: DataTypes.JSONB,
        defaultValue: {},
      },
    },
    {
      tableName: 'channel_analytics',
      schema: 'analytics',
      timestamps: true,
      underscored: true,
      // Indexes are managed at the database level due to partitioning
      indexes: [],
    }
  );

  // Note: This table is partitioned by month in PostgreSQL
  // Partitioning is handled at the database level, not in Sequelize

  // Associations
  ChannelAnalytics.associate = (models) => {
    ChannelAnalytics.belongsTo(models.Channel, {
      foreignKey: 'channel_id',
      as: 'channel',
    });
  };

  return ChannelAnalytics;
};
