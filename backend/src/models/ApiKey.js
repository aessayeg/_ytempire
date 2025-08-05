/**
 * ApiKey Model - Sequelize model for system.api_keys table
 * YTEmpire Project
 */

const crypto = require('crypto');

module.exports = (sequelize, DataTypes) => {
  const ApiKey = sequelize.define(
    'ApiKey',
    {
      key_id: {
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
      key_name: {
        type: DataTypes.STRING(255),
        allowNull: false,
      },
      key_hash: {
        type: DataTypes.STRING(255),
        unique: true,
        allowNull: false,
      },
      key_prefix: {
        type: DataTypes.STRING(10),
        allowNull: false,
      },
      permissions: {
        type: DataTypes.ARRAY(DataTypes.STRING),
        defaultValue: ['read'],
      },
      rate_limit: {
        type: DataTypes.INTEGER,
        defaultValue: 1000,
      },
      is_active: {
        type: DataTypes.BOOLEAN,
        defaultValue: true,
      },
      last_used_at: {
        type: DataTypes.DATE,
      },
      last_used_ip: {
        type: DataTypes.INET,
      },
      expires_at: {
        type: DataTypes.DATE,
      },
      metadata: {
        type: DataTypes.JSONB,
        defaultValue: {},
      },
    },
    {
      tableName: 'api_keys',
      schema: 'system',
      timestamps: true,
      underscored: true,
      indexes: [
        {
          fields: ['key_hash'],
        },
        {
          fields: ['account_id'],
        },
        {
          fields: ['is_active'],
        },
      ],
    }
  );

  // Static methods
  ApiKey.generateApiKey = () => {
    const key = crypto.randomBytes(32).toString('hex');
    const prefix = key.substring(0, 8);
    const hash = crypto.createHash('sha256').update(key).digest('hex');
    return { key, prefix, hash };
  };

  // Instance methods
  ApiKey.prototype.validateKey = function (providedKey) {
    const hash = crypto.createHash('sha256').update(providedKey).digest('hex');
    return hash === this.key_hash;
  };

  // Associations
  ApiKey.associate = (models) => {
    ApiKey.belongsTo(models.User, {
      foreignKey: 'account_id',
      as: 'account',
    });
  };

  return ApiKey;
};
