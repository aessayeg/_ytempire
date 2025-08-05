/**
 * Configuration Model - Sequelize model for system.configurations table
 * YTEmpire Project
 */

module.exports = (sequelize, DataTypes) => {
  const Configuration = sequelize.define('Configuration', {
    config_id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    config_key: {
      type: DataTypes.STRING(255),
      unique: true,
      allowNull: false
    },
    config_value: {
      type: DataTypes.JSONB,
      allowNull: false
    },
    config_type: {
      type: DataTypes.ENUM('system', 'feature', 'limit', 'integration'),
      allowNull: false
    },
    description: {
      type: DataTypes.TEXT
    },
    is_public: {
      type: DataTypes.BOOLEAN,
      defaultValue: false
    },
    is_encrypted: {
      type: DataTypes.BOOLEAN,
      defaultValue: false
    },
    updated_by: {
      type: DataTypes.UUID,
      references: {
        model: 'accounts',
        key: 'account_id'
      }
    }
  }, {
    tableName: 'configurations',
    schema: 'system',
    timestamps: true,
    underscored: true,
    indexes: [
      {
        fields: ['config_key']
      },
      {
        fields: ['config_type']
      },
      {
        fields: ['is_public']
      }
    ]
  });

  // Static methods
  Configuration.getConfig = async function(key, defaultValue = null) {
    const config = await this.findOne({ where: { config_key: key } });
    return config ? config.config_value : defaultValue;
  };

  Configuration.setConfig = async function(key, value, type = 'system', description = null) {
    const [config, created] = await this.findOrCreate({
      where: { config_key: key },
      defaults: {
        config_value: value,
        config_type: type,
        description: description
      }
    });
    
    if (!created) {
      config.config_value = value;
      config.config_type = type;
      if (description) config.description = description;
      await config.save();
    }
    
    return config;
  };

  return Configuration;
};