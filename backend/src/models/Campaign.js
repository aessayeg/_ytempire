/**
 * Campaign Model - Sequelize model for campaigns.campaigns table
 * YTEmpire Project
 */

module.exports = (sequelize, DataTypes) => {
  const Campaign = sequelize.define('Campaign', {
    campaign_id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    account_id: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: 'accounts',
        key: 'account_id'
      }
    },
    campaign_name: {
      type: DataTypes.STRING(255),
      allowNull: false
    },
    campaign_type: {
      type: DataTypes.ENUM('product_launch', 'brand_awareness', 'engagement', 'monetization', 'custom'),
      allowNull: false
    },
    campaign_status: {
      type: DataTypes.ENUM('draft', 'scheduled', 'active', 'paused', 'completed'),
      defaultValue: 'draft'
    },
    start_date: {
      type: DataTypes.DATE
    },
    end_date: {
      type: DataTypes.DATE
    },
    budget_usd: {
      type: DataTypes.DECIMAL(10, 2)
    },
    spent_usd: {
      type: DataTypes.DECIMAL(10, 2),
      defaultValue: 0
    },
    target_audience: {
      type: DataTypes.JSONB,
      defaultValue: {
        demographics: {},
        interests: [],
        locations: []
      }
    },
    goals: {
      type: DataTypes.JSONB,
      defaultValue: {
        views: null,
        subscribers: null,
        engagement_rate: null,
        revenue: null
      }
    },
    performance_metrics: {
      type: DataTypes.JSONB,
      defaultValue: {
        total_views: 0,
        total_clicks: 0,
        total_revenue: 0,
        roi: 0
      }
    },
    settings: {
      type: DataTypes.JSONB,
      defaultValue: {}
    },
    metadata: {
      type: DataTypes.JSONB,
      defaultValue: {}
    }
  }, {
    tableName: 'campaigns',
    schema: 'campaigns',
    timestamps: true,
    underscored: true,
    indexes: [
      {
        fields: ['account_id']
      },
      {
        fields: ['campaign_status']
      },
      {
        fields: ['start_date', 'end_date']
      }
    ]
  });

  // Associations
  Campaign.associate = (models) => {
    Campaign.belongsTo(models.User, {
      foreignKey: 'account_id',
      as: 'account'
    });
    Campaign.hasMany(models.CampaignVideo, {
      foreignKey: 'campaign_id',
      as: 'videos'
    });
  };

  return Campaign;
};