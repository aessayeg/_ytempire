/**
 * User Model - Sequelize model for users.accounts table
 * YTEmpire Project
 */

const bcrypt = require('bcryptjs');

module.exports = (sequelize, DataTypes) => {
  const User = sequelize.define('User', {
    account_id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    email: {
      type: DataTypes.STRING(255),
      unique: true,
      allowNull: false,
      validate: {
        isEmail: true
      }
    },
    username: {
      type: DataTypes.STRING(100),
      unique: true,
      allowNull: false
    },
    password_hash: {
      type: DataTypes.STRING(255),
      allowNull: false
    },
    account_type: {
      type: DataTypes.ENUM('creator', 'manager', 'admin'),
      allowNull: false
    },
    account_status: {
      type: DataTypes.ENUM('active', 'suspended', 'pending'),
      defaultValue: 'active'
    },
    subscription_tier: {
      type: DataTypes.ENUM('free', 'pro', 'enterprise'),
      defaultValue: 'free'
    },
    last_login_at: {
      type: DataTypes.DATE
    },
    email_verified: {
      type: DataTypes.BOOLEAN,
      defaultValue: false
    },
    two_factor_enabled: {
      type: DataTypes.BOOLEAN,
      defaultValue: false
    }
  }, {
    tableName: 'accounts',
    schema: 'users',
    timestamps: true,
    underscored: true,
    hooks: {
      beforeCreate: async (user) => {
        if (user.password_hash && !user.password_hash.startsWith('$2')) {
          user.password_hash = await bcrypt.hash(user.password_hash, 10);
        }
      },
      beforeUpdate: async (user) => {
        if (user.changed('password_hash') && !user.password_hash.startsWith('$2')) {
          user.password_hash = await bcrypt.hash(user.password_hash, 10);
        }
      }
    }
  });

  // Instance methods
  User.prototype.validatePassword = async function(password) {
    return bcrypt.compare(password, this.password_hash);
  };

  User.prototype.toJSON = function() {
    const values = Object.assign({}, this.get());
    delete values.password_hash;
    return values;
  };

  // Associations
  User.associate = (models) => {
    User.hasOne(models.Profile, {
      foreignKey: 'account_id',
      as: 'profile'
    });
    User.hasMany(models.Session, {
      foreignKey: 'account_id',
      as: 'sessions'
    });
    User.hasMany(models.Channel, {
      foreignKey: 'account_id',
      as: 'channels'
    });
    User.hasMany(models.Campaign, {
      foreignKey: 'account_id',
      as: 'campaigns'
    });
    User.hasMany(models.Notification, {
      foreignKey: 'account_id',
      as: 'notifications'
    });
    User.hasMany(models.ApiKey, {
      foreignKey: 'account_id',
      as: 'apiKeys'
    });
  };

  return User;
};