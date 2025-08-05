/**
 * Session Model - Sequelize model for users.sessions table
 * YTEmpire Project
 */

module.exports = (sequelize, DataTypes) => {
  const Session = sequelize.define('Session', {
    session_id: {
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
    session_token: {
      type: DataTypes.STRING(255),
      unique: true,
      allowNull: false
    },
    ip_address: {
      type: DataTypes.INET
    },
    user_agent: {
      type: DataTypes.TEXT
    },
    expires_at: {
      type: DataTypes.DATE,
      allowNull: false
    },
    is_active: {
      type: DataTypes.BOOLEAN,
      defaultValue: true
    }
  }, {
    tableName: 'sessions',
    schema: 'users',
    timestamps: true,
    underscored: true,
    createdAt: 'created_at',
    updatedAt: false,
    indexes: [
      {
        fields: ['session_token']
      },
      {
        fields: ['account_id', 'is_active']
      }
    ]
  });

  // Associations
  Session.associate = (models) => {
    Session.belongsTo(models.User, {
      foreignKey: 'account_id',
      as: 'account'
    });
  };

  return Session;
};