/**
 * Notification Model - Sequelize model for system.notifications table
 * YTEmpire Project
 */

module.exports = (sequelize, DataTypes) => {
  const Notification = sequelize.define(
    'Notification',
    {
      notification_id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
      },
      account_id: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
          model: 'accounts',
          key: 'account_id',
        },
      },
      notification_type: {
        type: DataTypes.ENUM('system', 'alert', 'update', 'achievement', 'warning'),
        allowNull: false,
      },
      title: {
        type: DataTypes.STRING(255),
        allowNull: false,
      },
      message: {
        type: DataTypes.TEXT,
        allowNull: false,
      },
      priority: {
        type: DataTypes.ENUM('low', 'medium', 'high', 'urgent'),
        defaultValue: 'medium',
      },
      is_read: {
        type: DataTypes.BOOLEAN,
        defaultValue: false,
      },
      read_at: {
        type: DataTypes.DATE,
      },
      action_url: {
        type: DataTypes.STRING(500),
      },
      metadata: {
        type: DataTypes.JSONB,
        defaultValue: {},
      },
      expires_at: {
        type: DataTypes.DATE,
      },
    },
    {
      tableName: 'notifications',
      schema: 'system',
      timestamps: true,
      underscored: true,
      indexes: [
        {
          fields: ['account_id', 'is_read'],
        },
        {
          fields: ['notification_type'],
        },
        {
          fields: ['created_at'],
        },
      ],
    }
  );

  // Associations
  Notification.associate = (models) => {
    Notification.belongsTo(models.User, {
      foreignKey: 'account_id',
      as: 'account',
    });
  };

  return Notification;
};
