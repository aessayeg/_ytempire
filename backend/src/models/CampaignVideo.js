/**
 * CampaignVideo Model - Sequelize model for campaigns.campaign_videos table
 * YTEmpire Project
 */

module.exports = (sequelize, DataTypes) => {
  const CampaignVideo = sequelize.define('CampaignVideo', {
    campaign_video_id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    campaign_id: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: 'campaigns',
        key: 'campaign_id'
      }
    },
    video_id: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: 'videos',
        key: 'video_id'
      }
    },
    inclusion_date: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW
    },
    scheduled_publish_date: {
      type: DataTypes.DATE
    },
    campaign_tags: {
      type: DataTypes.ARRAY(DataTypes.STRING),
      defaultValue: []
    },
    performance_data: {
      type: DataTypes.JSONB,
      defaultValue: {
        views: 0,
        clicks: 0,
        conversions: 0,
        revenue: 0
      }
    },
    metadata: {
      type: DataTypes.JSONB,
      defaultValue: {}
    }
  }, {
    tableName: 'campaign_videos',
    schema: 'campaigns',
    timestamps: true,
    underscored: true,
    indexes: [
      {
        unique: true,
        fields: ['campaign_id', 'video_id']
      },
      {
        fields: ['video_id']
      }
    ]
  });

  // Associations
  CampaignVideo.associate = (models) => {
    CampaignVideo.belongsTo(models.Campaign, {
      foreignKey: 'campaign_id',
      as: 'campaign'
    });
    CampaignVideo.belongsTo(models.Video, {
      foreignKey: 'video_id',
      as: 'video'
    });
  };

  return CampaignVideo;
};