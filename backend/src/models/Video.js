/**
 * Video Model - Sequelize model for content.videos table
 * YTEmpire Project
 */

module.exports = (sequelize, DataTypes) => {
  const Video = sequelize.define(
    'Video',
    {
      video_id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
      },
      youtube_video_id: {
        type: DataTypes.STRING(100),
        unique: true,
        allowNull: false,
      },
      channel_id: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
          model: 'channels',
          key: 'channel_id',
        },
      },
      title: {
        type: DataTypes.STRING(500),
        allowNull: false,
      },
      description: {
        type: DataTypes.TEXT,
      },
      privacy_status: {
        type: DataTypes.STRING(50),
      },
      upload_status: {
        type: DataTypes.STRING(50),
        defaultValue: 'processed',
      },
      duration_seconds: {
        type: DataTypes.INTEGER,
      },
      thumbnail_url: {
        type: DataTypes.STRING(500),
      },
      published_at: {
        type: DataTypes.DATE,
      },
      tags: {
        type: DataTypes.ARRAY(DataTypes.STRING),
        defaultValue: [],
      },
      category_id: {
        type: DataTypes.INTEGER,
      },
      category_name: {
        type: DataTypes.STRING(100),
      },
      language: {
        type: DataTypes.STRING(10),
      },
      view_count: {
        type: DataTypes.BIGINT,
        defaultValue: 0,
      },
      like_count: {
        type: DataTypes.INTEGER,
        defaultValue: 0,
      },
      comment_count: {
        type: DataTypes.INTEGER,
        defaultValue: 0,
      },
      favorite_count: {
        type: DataTypes.INTEGER,
        defaultValue: 0,
      },
      caption_status: {
        type: DataTypes.STRING(50),
      },
      definition: {
        type: DataTypes.STRING(10),
      },
      dimension: {
        type: DataTypes.STRING(10),
      },
      licensed_content: {
        type: DataTypes.BOOLEAN,
        defaultValue: false,
      },
      metadata: {
        type: DataTypes.JSONB,
        defaultValue: {},
      },
      created_at: {
        type: DataTypes.DATE,
      },
      updated_at: {
        type: DataTypes.DATE,
      },
    },
    {
      tableName: 'videos',
      schema: 'content',
      timestamps: true,
      underscored: true,
      indexes: [
        {
          fields: ['youtube_video_id'],
        },
        {
          fields: ['channel_id'],
        },
        {
          fields: ['privacy_status'],
        },
        {
          fields: ['published_at'],
        },
      ],
    }
  );

  // Associations
  Video.associate = (models) => {
    Video.belongsTo(models.Channel, {
      foreignKey: 'channel_id',
      as: 'channel',
    });
    Video.hasMany(models.VideoAnalytics, {
      foreignKey: 'video_id',
      as: 'analytics',
    });
    Video.hasMany(models.CampaignVideo, {
      foreignKey: 'video_id',
      as: 'campaigns',
    });
  };

  return Video;
};
