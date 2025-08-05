/**
 * Channel Model - Sequelize model for content.channels table
 * YTEmpire Project
 */

module.exports = (sequelize, DataTypes) => {
  const Channel = sequelize.define(
    'Channel',
    {
      channel_id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
      },
      youtube_channel_id: {
        type: DataTypes.STRING(100),
        unique: true,
        allowNull: false,
      },
      account_id: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
          model: 'accounts',
          key: 'account_id',
        },
      },
      channel_name: {
        type: DataTypes.STRING(200),
        allowNull: false,
      },
      channel_handle: {
        type: DataTypes.STRING(100),
      },
      description: {
        type: DataTypes.TEXT,
      },
      thumbnail_url: {
        type: DataTypes.STRING(500),
      },
      banner_url: {
        type: DataTypes.STRING(500),
      },
      subscriber_count: {
        type: DataTypes.BIGINT,
        defaultValue: 0,
      },
      view_count: {
        type: DataTypes.BIGINT,
        defaultValue: 0,
      },
      video_count: {
        type: DataTypes.INTEGER,
        defaultValue: 0,
      },
      country: {
        type: DataTypes.STRING(10),
      },
      language: {
        type: DataTypes.STRING(10),
      },
      category: {
        type: DataTypes.STRING(100),
      },
      created_date: {
        type: DataTypes.DATEONLY,
      },
      status: {
        type: DataTypes.STRING(50),
        defaultValue: 'active',
      },
      last_sync_at: {
        type: DataTypes.DATE,
      },
      access_token: {
        type: DataTypes.TEXT,
      },
      refresh_token: {
        type: DataTypes.TEXT,
      },
      token_expiry: {
        type: DataTypes.DATE,
      },
      metadata: {
        type: DataTypes.JSONB,
        defaultValue: {},
      },
    },
    {
      tableName: 'channels',
      schema: 'content',
      timestamps: true,
      underscored: true,
      indexes: [
        {
          fields: ['youtube_channel_id'],
        },
        {
          fields: ['account_id'],
        },
        {
          fields: ['status'],
        },
      ],
    }
  );

  // Associations
  Channel.associate = (models) => {
    Channel.belongsTo(models.User, {
      foreignKey: 'account_id',
      as: 'owner',
    });
    Channel.hasMany(models.Video, {
      foreignKey: 'channel_id',
      as: 'videos',
    });
    Channel.hasMany(models.ChannelAnalytics, {
      foreignKey: 'channel_id',
      as: 'analytics',
    });
  };

  return Channel;
};
